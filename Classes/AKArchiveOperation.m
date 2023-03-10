//
// MIT License
//
// Copyright (c) 2009-2023 Sophiestication Software, Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

#import "AKArchiveOperation.h"
#import "AKArchiveOperation+Private.h"

#import "AKArchive.h"
#import "AKArchive+Private.h"

#import "AKArchiveController.h"

#import "NSArray+Additions.h"
#import "NSString+Additions.h"
#import "NSURL+Wikipedia.h"
#import "NSURL+REST.h"

#import "AKImageURLProtocol.h"

#import <libxml/tree.h>
#import <libxml/HTMLTree.h>
#import <libxml/HTMLParser.h>
#import <libxml/xpath.h>
#import <libxml/xmlsave.h>

@implementation AKArchiveOperation

@synthesize expectedContentLength = _expectedContentLength;
@synthesize numberOfBytesTransferred = _numberOfBytesTransferred;
@synthesize images = _images;
@synthesize imageNodesNeedingRelease = _imageNodesNeedingRelease;
@synthesize tables = _tables;
@synthesize languages = _languages;
@synthesize TOC = _TOC;
@synthesize articleURL = _articleURL;
@synthesize archiveURL = _archiveURL;
@synthesize delegate = _delegate;

#pragma mark -
#pragma mark Construction & Destruction

- (id)init {
	if((self = [super init])) {
		_didPostFinishNotification = NO;
		_waitingForInput = NO;
		_parserContext = NULL;
		
		self.expectedContentLength = 0.0;
		self.numberOfBytesTransferred = 0.0;
		
		self.images = [NSMutableArray array];
		self.imageNodesNeedingRelease = [NSMutableSet set];
		self.tables = [NSMutableArray array];
		self.languages = [NSMutableArray array];
		self.TOC = [NSMutableArray array];
	}
	
	return self;
}

- (void)dealloc {
	if(_parserContext) { xmlFreeParserCtxt(_parserContext); }
}

#pragma mark -
#pragma mark NSOperation

- (void)main {
	@autoreleasepool {
	
		[[NSThread currentThread] setName:@"com.sophiestication.Articles.archive-operation"];
		
		NS_DURING
			// Make a new runloop
			[NSRunLoop currentRunLoop];

			// Prepare the HTTP request
			NSMutableURLRequest* request = [NSMutableURLRequest 
				requestWithURL:[self articleURL]];

			[request setCachePolicy:NSURLRequestReloadIgnoringCacheData];

			NSDictionary* properties = @{
				NSHTTPCookieName: @"stopMobileRedirect",
				NSHTTPCookieValue: @"true",
				NSHTTPCookiePath: @"/",
				NSHTTPCookieDomain: [[self articleURL] host] };
			NSHTTPCookie* cookie = [NSHTTPCookie cookieWithProperties:properties];
			NSDictionary* headers = [NSHTTPCookie requestHeaderFieldsWithCookies:@[ cookie ]];

			[request setAllHTTPHeaderFields:headers];
			
			NSURLConnection* connection = [NSURLConnection
				connectionWithRequest:request
				delegate:self];
			
			if(connection) {
				_waitingForInput = YES;
				
				do {
					[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
				} while(_waitingForInput && ![self isCancelled]);
				
				if([self isCancelled]) {
					// Notify our delegate
					if(_waitingForInput) {
						NSError* error = [NSError
							errorWithDomain:NSURLErrorDomain
							code:NSURLErrorCancelled
							userInfo:nil];
						
						[[NSOperationQueue mainQueue] addOperationWithBlock:^() {
							if(![[self delegate] respondsToSelector:@selector(archiveOperation:didFailLoadWithError:)]) { return; }
							[[self delegate] archiveOperation:self didFailLoadWithError:error];
						}];
					}
					
					// Cancel this connection
					[connection cancel];
				}
			}		
		NS_HANDLER
			NSLog(@"%@", localException);
		NS_ENDHANDLER
	}
}

#pragma mark -
#pragma mark NSURLConnectionDelegate

- (NSURLRequest*)connection:(NSURLConnection*)connection willSendRequest:(NSURLRequest*)request redirectResponse:(NSURLResponse*)response {
	if(_parserContext) {
		xmlFreeParserCtxt(_parserContext);
		_parserContext = NULL;
	}
	
	self.expectedContentLength = 0;
	self.numberOfBytesTransferred = 0;
	
	self.articleURL = [request URL];
	self.archiveURL = [AKArchive archiveURLForArticle:[self articleURL] archiveType:AKArchiveTypeCache];
	
	return request;
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSHTTPURLResponse*)response {
	long long contentLength = [response expectedContentLength];
	
	if(contentLength <= 0) {
		contentLength = [[[response allHeaderFields] objectForKey:@"Content-Length"] longLongValue];
	}
	
	self.expectedContentLength = contentLength;
	
	// Check for the HTTP status
	NSInteger statusCode = [response statusCode];
	
	if(statusCode == 404) {
		[connection cancel];
		
		NSError* error = [NSError
			errorWithDomain:NSURLErrorDomain
			code:NSURLErrorFileDoesNotExist
			userInfo:nil];
		[self connection:connection didFailWithError:error];
	}
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
	if(!_parserContext) {
		_parserContext = htmlCreatePushParserCtxt(NULL, (__bridge void *)(self), NULL, 0, NULL, XML_CHAR_ENCODING_UTF8);
		htmlCtxtUseOptions(_parserContext, HTML_PARSE_NONET|HTML_PARSE_RECOVER|HTML_PARSE_NOBLANKS/*|HTML_PARSE_COMPACT*/); //HTML_PARSE_RECOVER|HTML_PARSE_NOBLANKS|HTML_PARSE_COMPACT);
	}
	
	htmlParseChunk(_parserContext, [data bytes], [data length], 0);
	
	self.numberOfBytesTransferred += [data length];
	[self postDocumentLoadProgress];
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
	// Finish parsing
	htmlParseChunk(_parserContext, NULL, 0, 1);
	
	// Finish document loading
	[self postDocumentLoadProgress:1.0];

	// We're working with the tree API
	xmlDocPtr doc = _parserContext->myDoc;
	xmlXPathContextPtr XPathContext = xmlXPathNewContext(doc);
	
	// We first find all alternate language and TOC links
	if(![self isCancelled]) {
		[self parseAlternateLanguages:doc context:XPathContext];
		[self parseTOC:doc context:XPathContext];
	}

	// Restructure the document header
	if(![self isCancelled]) {
		[self restructureHeader:doc context:XPathContext];
	}

	// Restructure the while document for our needs first
	if(![self isCancelled]) {
		[self restructureDocument:doc context:XPathContext];
	}

	// Now get rid of some unwanted nodes
	if(![self isCancelled]) {
		[self deleteUnwantedNodes:doc context:XPathContext];
	}

	// Now fix all internal wikipedia links
	if(![self isCancelled]) {
		[self fixWikipediaLinks:XPathContext];
	}
	
	// ...
	if(![self isCancelled]) {
		[self postDocumentParseProgress:0.25];

			@autoreleasepool { {
				// Restructure all image files
				[self restructureImages:doc context:XPathContext];
			} }
	}
	
	// ...
	if(![self isCancelled]) {
		[self postDocumentParseProgress:0.5];
	
			@autoreleasepool { {
				// Replace all tables with placeholders. Has to be *after* restructure images.
				[self restructureTables:doc context:XPathContext];
			} }
	}

	// ...
	if(![self isCancelled]) {
		[self postDocumentParseProgress:0.75];

		// Save the article markup to disk
		NSFileManager* fileManager = [[NSFileManager alloc] init];

		NSURL* archiveURL = self.archiveURL;
		[fileManager createDirectoryAtURL:archiveURL withIntermediateDirectories:YES attributes:nil error:nil];

		// Save the actual file
		NSURL* documentURL = [NSURL URLWithString:@"index.html" relativeToURL:archiveURL];

		const char* documentPathBuffer = [fileManager fileSystemRepresentationWithPath:[documentURL path]];
		xmlSaveCtxtPtr saveContext = xmlSaveToFilename(documentPathBuffer, NULL, XML_SAVE_FORMAT);
		
		int result = xmlSaveDoc(saveContext, doc);
		
		if(result < 0) {
			NSLog(@"Could not save article to URL: %@", documentURL);
		}

		xmlSaveClose(saveContext);
		
		// Cleanup
		xmlXPathFreeContext(XPathContext);
		xmlFreeDoc(doc);
		
		// Make the article infoPlist
		NSMutableDictionary* infoPlist = [NSMutableDictionary dictionary];
		
		[infoPlist setValue:[self tables] forKey:@"tables"];
		[infoPlist setValue:[self images] forKey:@"images"];
		[infoPlist setValue:[self languages] forKey:@"languages"];
		[infoPlist setValue:[self TOC] forKey:@"chapters"];
		
		// ...
		[self postDocumentParseProgress:1.0];

		// Notify our delegate
		[[NSOperationQueue mainQueue] addOperationWithBlock:^() {
			[[self delegate] archiveOperation:self didFinishWithInfoPlist:infoPlist];
		}];
			
		_didPostFinishNotification = YES;
			
		// We no longer wait for input sources
		_waitingForInput = NO;
	} else {
		// Cleanup
		xmlXPathFreeContext(XPathContext);
		xmlFreeDoc(doc);
	}
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
	_waitingForInput = NO;
	// if(_parserContext) { xmlParseChunk(_parserContext, NULL, 0, 1); }

	// Notify our delegate
	[[NSOperationQueue mainQueue] addOperationWithBlock:^() {
		[[self delegate] archiveOperation:self didFailLoadWithError:error];
	}];
}

#pragma mark -
#pragma mark Private

- (NSString*)stringFromLibXMLNode:(xmlNodePtr)node {
	NSString* string = nil;
	xmlBufferPtr buffer = xmlBufferCreate();
	
	xmlSaveCtxtPtr context = xmlSaveToBuffer(buffer, NULL, 0);
	
	int result = xmlSaveTree(context, node);
	
	if(result >= 0) {
		string = [NSString stringWithUTF8String:(const char*)buffer->content];
	}

	xmlSaveClose(context);
	xmlBufferFree(buffer);
	
	return string;
}

- (NSString*)stylesheetURLString {
	NSBundle* bundle = [NSBundle bundleForClass:[self class]];
	NSString* stylesheetPath = [bundle
		pathForResource:@"articles"
		ofType:@"css"];
	NSURL* stylesheetURL = [NSURL fileURLWithPath:stylesheetPath];
	
	return [stylesheetURL absoluteString];
}

- (void)appendSupportFiles:(xmlNodePtr)header {
	// Link to the default stylesheet
	NSString* stylesheetPath = @"x-articlekit-resource://articlekit.css";
	xmlNodePtr stylesheet = xmlNewChild(
		header,
		NULL,
		BAD_CAST("link"),
		NULL);
	xmlSetProp(stylesheet, BAD_CAST("rel"), BAD_CAST("stylesheet"));
	xmlSetProp(stylesheet, BAD_CAST("type"), BAD_CAST("text/css"));
	xmlSetProp(stylesheet, BAD_CAST("href"), BAD_CAST([stylesheetPath UTF8String]));
	xmlSetProp(stylesheet, BAD_CAST("media"), BAD_CAST("all"));
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		NSString* stylesheetPath = @"x-articlekit-resource://articlekit-ipad.css";
		xmlNodePtr stylesheet = xmlNewChild(
			header,
			NULL,
			BAD_CAST("link"),
			NULL);
		xmlSetProp(stylesheet, BAD_CAST("rel"), BAD_CAST("stylesheet"));
		xmlSetProp(stylesheet, BAD_CAST("type"), BAD_CAST("text/css"));
		xmlSetProp(stylesheet, BAD_CAST("href"), BAD_CAST([stylesheetPath UTF8String]));
		xmlSetProp(stylesheet, BAD_CAST("media"), BAD_CAST("all"));
	}
	
	// Link to the print stylesheet
	NSString* printStylesheetPath = @"x-articlekit-resource://print.css";
	xmlNodePtr printStylesheet = xmlNewChild(
		header,
		NULL,
		BAD_CAST("link"),
		NULL);
	xmlSetProp(printStylesheet, BAD_CAST("rel"), BAD_CAST("stylesheet"));
	xmlSetProp(printStylesheet, BAD_CAST("type"), BAD_CAST("text/css"));
	xmlSetProp(printStylesheet, BAD_CAST("href"), BAD_CAST([printStylesheetPath UTF8String]));
	xmlSetProp(printStylesheet, BAD_CAST("media"), BAD_CAST("print"));

	// Link to the default javascript
	NSString* javascriptPath = @"x-articlekit-resource://articlekit.js";
	xmlNodePtr javascript = xmlNewChild(
		header,
		NULL,
		BAD_CAST("script"),
		NULL);
	xmlSetProp(javascript, BAD_CAST("type"), BAD_CAST("text/javascript"));
	xmlSetProp(javascript, BAD_CAST("src"), BAD_CAST([javascriptPath UTF8String]));
	
	// Link to the search javascript
	NSString* searchJavascriptPath = @"x-articlekit-resource://search.js";
	xmlNodePtr searchJavascript = xmlNewChild(
		header,
		NULL,
		BAD_CAST("script"),
		NULL);
	xmlSetProp(searchJavascript, BAD_CAST("type"), BAD_CAST("text/javascript"));
	xmlSetProp(searchJavascript, BAD_CAST("src"), BAD_CAST([searchJavascriptPath UTF8String]));
}

- (void)appendClass:(NSString*)classString toNode:(xmlNodePtr)node {
	xmlChar* previousClass = xmlGetProp(node, (xmlChar*)"class");
	
	if(previousClass) {
		xmlChar* newClass = xmlStrncat(previousClass, (xmlChar*)[classString UTF8String], [classString length]);
		xmlSetProp(node, (xmlChar*)"class", newClass);
		
		if(newClass != previousClass) {
			xmlFree(newClass);
		}
	} else {
		xmlSetProp(node, (xmlChar*)"class", (xmlChar*)[classString UTF8String]);
	}
	
	xmlFree(previousClass);
}

- (BOOL)array:(NSArray*)array containsObjectsInSet:(NSSet*)set {
	for(id object in array) {
		if([set containsObject:object]) {
			return YES;
		}
	}
	
	return NO;
}

- (xmlNodePtr)findNodeById:(NSString*)nodeId withContext:(xmlXPathContextPtr)XPathContext {
	NSString* XPath = [NSString stringWithFormat:@"//*[@id='%@'][1]", nodeId];
	xmlNodePtr node = NULL;
	
	XPathContext->node = NULL;
	xmlXPathObjectPtr result = xmlXPathEval(BAD_CAST([XPath UTF8String]), XPathContext);
	
	if(!xmlXPathNodeSetIsEmpty(result->nodesetval)) {
		node = xmlXPathNodeSetItem(result->nodesetval, 0);
	}
	
	xmlXPathFreeObject(result);

	return node;
}

- (xmlNodePtr)findFirstNodeByClass:(NSString*)nodeClass withContext:(xmlXPathContextPtr)XPathContext {
	NSString* XPath = [NSString stringWithFormat:@".//*[contains(@class, '%@')]", nodeClass];
	xmlNodePtr node = NULL;

	xmlXPathObjectPtr result = xmlXPathEval(BAD_CAST([XPath UTF8String]), XPathContext);
	
	if(!xmlXPathNodeSetIsEmpty(result->nodesetval)) {
		node = xmlXPathNodeSetItem(result->nodesetval, 0);
	}
	
	xmlXPathFreeObject(result);

	return node;
}

- (xmlNodePtr)parentWithName:(const xmlChar*)name forNode:(xmlNodePtr)node {
	xmlNodePtr parent = node;
	
	while(parent != NULL && xmlStrcasecmp(parent->name, name) != 0) {
		parent = parent->parent;
	}
	
	if(parent == node) {
		parent = NULL;
	}

	return parent;
}

- (xmlNodePtr)parentAnchorForNode:(xmlNodePtr)node {
	xmlNodePtr parent = [self parentWithName:BAD_CAST("a") forNode:node];
	return parent ? parent : node;
}

- (xmlNodePtr)parentWithClass:(NSString*)classString forNode:(xmlNodePtr)node context:(xmlXPathContextPtr)context {
	xmlNodePtr wrapper = NULL;
	context->node = node;
	
	NSString* XPath = [NSString stringWithFormat:@"./ancestor::*[contains(concat(' ', normalize-space(@class), ' '), ' %@ ')]", classString];
	xmlXPathObjectPtr result = xmlXPathEval(BAD_CAST([XPath UTF8String]), context);
	
	if(!xmlXPathNodeSetIsEmpty(result->nodesetval)) {
		wrapper = xmlXPathNodeSetItem(result->nodesetval, 0);
	}
	
	xmlXPathFreeObject(result);
	
	return wrapper;
}

- (NSString*)contentForChildOfClass:(const xmlChar*)class ofNode:(xmlNodePtr)node context:(xmlXPathContextPtr)XPathContext {
	xmlNodePtr previousContextNode = XPathContext->node;
	
	for(xmlNodePtr child=node->children; child != NULL; child=child->next) {
		if(xmlHasProp(child, BAD_CAST("class"))) {
			const xmlChar* childClass = xmlGetProp(child, BAD_CAST("class"));
				
			if(xmlStrcasecmp(childClass, class) == 0) {
				XPathContext->node = child;
				xmlXPathObjectPtr result = xmlXPathEval(BAD_CAST(".//text()"), XPathContext);

				xmlChar* buffer = xmlXPathCastToString(result);
				NSString* string = [NSString stringWithUTF8String:(const char*)buffer];
				xmlFree(buffer);
				
				xmlXPathFreeObject(result);
				XPathContext->node = previousContextNode;
				
				return string;
			}
		}
	}
	
	return nil;
}

- (NSArray*)classStringsForNode:(xmlNodePtr)node {
	if(xmlHasProp(node, BAD_CAST("class"))) {
		xmlChar* classString = xmlGetProp(node, BAD_CAST("class"));
		
		NSString* s = [NSString stringWithUTF8String:(const char*)classString];
		NSArray* classes = [s componentsSeparatedByString:@" "];
		
		xmlFree(classString);
		
		return classes;
	}
	
	return [NSArray array];
}

- (void)setClasses:(NSArray*)classes forNode:(xmlNodePtr)node {
	NSString* classString = [classes componentsJoinedByString:@" "];
	xmlSetProp(node, BAD_CAST("class"), BAD_CAST([classString UTF8String]));
}

- (void)removeAllInlineStylesFromNode:(xmlNodePtr)parentNode context:(xmlXPathContextPtr)XPathContext {
	XPathContext->node = parentNode;

	xmlXPathObjectPtr result = xmlXPathEval(BAD_CAST("./descendant-or-self::*[@style and not(contains(concat(' ', normalize-space(@class), ' '), ' thumbnail-placeholder '))]"), XPathContext);

	NSInteger numberOfNodes = xmlXPathNodeSetGetLength(result->nodesetval);
		
	for(NSInteger nodeIndex=0; nodeIndex<numberOfNodes; ++nodeIndex) {
		xmlNodePtr node = xmlXPathNodeSetItem(result->nodesetval, nodeIndex);
		xmlUnsetProp(node, BAD_CAST("style"));
	}
	
	xmlXPathFreeObject(result);
	XPathContext->node = NULL;
}

- (void)parseTOC:(xmlDocPtr)document context:(xmlXPathContextPtr)XPathContext {
	XPathContext->node = NULL;

	xmlXPathObjectPtr result = xmlXPathEval(BAD_CAST("id('toc')//li/a"), XPathContext);

	NSInteger numberOfNodes = xmlXPathNodeSetGetLength(result->nodesetval);
		
	for(NSInteger nodeIndex=0; nodeIndex<numberOfNodes; ++nodeIndex) {
		xmlNodePtr linkNode = xmlXPathNodeSetItem(result->nodesetval, nodeIndex);
		
		if(linkNode != NULL) {
			NSMutableDictionary* TOCItem = [NSMutableDictionary dictionary];
			
			xmlChar* linkURL = xmlGetProp(linkNode, BAD_CAST("href"));
			NSString* linkURLString = linkURL ?
				[NSString stringWithUTF8String:(const char*)linkURL] :
				nil;
            
            if(linkURLString) {
                [TOCItem setValue:linkURLString forKey:@"link"];
			}

			xmlChar* listItemClass = xmlGetProp(linkNode->parent, BAD_CAST("class"));
			NSString* listItemClassString = listItemClass ?
				[NSString stringWithUTF8String:(const char*)listItemClass] :
				nil;
            
            if(listItemClassString) {
                [TOCItem setValue:listItemClassString forKey:@"class"];
			}

			NSString* number = [self contentForChildOfClass:BAD_CAST("tocnumber") ofNode:linkNode context:XPathContext];
            
            if(number) {
                [TOCItem setValue:number forKey:@"number"];
            }
			
			NSString* text = [self contentForChildOfClass:BAD_CAST("toctext") ofNode:linkNode context:XPathContext];
            
            if(text) {
                [TOCItem setValue:text forKey:@"text"];
            }

			[[self TOC] addObject:TOCItem];
		}
	}
	
	xmlXPathFreeObject(result);
}

- (void)parseAlternateLanguages:(xmlDocPtr)document context:(xmlXPathContextPtr)XPathContext {
	XPathContext->node = NULL;

	xmlXPathObjectPtr result = xmlXPathEval(BAD_CAST("//div[@id='p-lang'][1]/div/ul/li/a/@href"), XPathContext);

	NSInteger numberOfNodes = xmlXPathNodeSetGetLength(result->nodesetval);
		
	for(NSInteger nodeIndex=0; nodeIndex<numberOfNodes; ++nodeIndex) {
		xmlNodePtr languageNode = xmlXPathNodeSetItem(result->nodesetval, nodeIndex);
		
		if(languageNode != NULL) {
			NSString* URLString = [NSString stringWithUTF8String:(const char*)XML_GET_CONTENT(languageNode->children)];
			[[self languages] addObject:URLString];
		}
	}
	
	xmlXPathFreeObject(result);
}

- (void)restructureHeader:(xmlDocPtr)document context:(xmlXPathContextPtr)XPathContext {
	// Retrieve the header tag
	xmlXPathObjectPtr result = xmlXPathEval(BAD_CAST("//head[1]"), XPathContext);
	xmlNodePtr header = NULL;
	
	if(!xmlXPathNodeSetIsEmpty(result->nodesetval)) {
		header = xmlXPathNodeSetItem(result->nodesetval, 0);
	}

	// Remove all link, style and script tags from the html header
	XPathContext->node = header;
	xmlXPathObjectPtr result2 = xmlXPathEval(BAD_CAST("./link | ./script | ./style | ./comment()"), XPathContext);
	
	NSInteger numberOfHeaderTags = xmlXPathNodeSetGetLength(result2->nodesetval);
		
	for(NSInteger headerTagIndex=0; headerTagIndex<numberOfHeaderTags; ++headerTagIndex) {
		xmlNodePtr headerTag = xmlXPathNodeSetItem(result2->nodesetval, headerTagIndex);
		xmlUnlinkNode(headerTag);
		xmlFreeNode(headerTag);
	}
	
	XPathContext->node = NULL;
	
	xmlXPathFreeObject(result2);
	xmlXPathFreeObject(result);
	
	// Add the viewport header
	// Link to the default javascript
	xmlNodePtr viewport = xmlNewChild(
		header,
		NULL,
		BAD_CAST("meta"),
		NULL);
	xmlSetProp(viewport, BAD_CAST("name"), BAD_CAST("viewport"));
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		xmlSetProp(viewport, BAD_CAST("content"), BAD_CAST("user-scalable=no, width=device-width, initial-scale=1.0"));
	} else {
		xmlSetProp(viewport, BAD_CAST("content"), BAD_CAST("user-scalable=no, initial-scale=1.0"));
	}
	
	// ...
	[self appendSupportFiles:header];
}

- (void)restructureDocument:(xmlDocPtr)document context:(xmlXPathContextPtr)XPathContext {
	// Unlink the heading from our doc
	xmlNodePtr heading = [self findNodeById:@"firstHeading" withContext:XPathContext];
	xmlUnlinkNode(heading);
	
	// Ditto for the bodyContent
	xmlNodePtr content = [self findNodeById:@"bodyContent" withContext:XPathContext];
	xmlUnlinkNode(content);
	
	// and Copyright
	xmlNodePtr copyright = [self findNodeById:@"footer-info" withContext:XPathContext];
	
	if(!copyright) {
		copyright = [self findNodeById:@"f-list" withContext:XPathContext];
	}
	
	if(copyright) {
		xmlUnlinkNode(copyright);
	}

	// Get the body element
	xmlXPathObjectPtr result = xmlXPathEval(BAD_CAST("/html/body[1]"), XPathContext);
	xmlNodePtr body = xmlXPathNodeSetIsEmpty(result->nodesetval) ?
		NULL :
		xmlXPathNodeSetItem(result->nodesetval, 0);
	xmlXPathFreeObject(result);
	
	// Now remove all remaining elements within the html body
	XPathContext->node = body;
	result = xmlXPathEval(BAD_CAST("node()"), XPathContext);
	
	if(!xmlXPathNodeSetIsEmpty(result->nodesetval)) {
		for(NSInteger nodeIndex=0; nodeIndex<xmlXPathNodeSetGetLength(result->nodesetval); ++nodeIndex) {
			xmlNodePtr node = xmlXPathNodeSetItem(result->nodesetval, nodeIndex);
			xmlUnlinkNode(node);
			xmlFreeNode(node);
		}
	}

	xmlXPathFreeObject(result);
	
	// Now re-add the header and content nodes
	xmlAddChild(body, heading);
	xmlAddChild(body, content);
	
	if(copyright) {
		xmlAddChild(body, copyright);
	}
	
	// ...
	[self addPageFooter:body context:XPathContext];
	
	XPathContext->node = NULL;
}

- (void)restructureTables:(xmlDocPtr)document context:(xmlXPathContextPtr)XPathContext {
	XPathContext->node = NULL;

	xmlXPathObjectPtr result = xmlXPathEval(BAD_CAST("//table | //*[contains(concat(' ', normalize-space(@class), ' '), ' infobox ')]"), XPathContext);

	NSInteger numberOfNodes = xmlXPathNodeSetGetLength(result->nodesetval);
	
	NSMutableArray* obsoleteNodes = [NSMutableArray array];
	
	NSSet* noneTableClasses = [NSSet setWithObjects:
		@"metadata",
		// @"nowraplinks",
		@"noprint",
		@"gallery",
		@"Vorlage_Belege_fehlen",
		@"persondata",
		@"multicol",
		@"cquote",
		@"selfref",
		@"bandeau",
		@"ambox",
		// @"vertical-navbox",
		@"box",
		// @"editmode",
		// @"navbox",
		nil];
		
	NSSet* vcardClasses = [NSSet setWithObjects:
		@"vcard",
		@"infobox",
		@"infobox_v2",
		// @"toptextcells", // is wrapped within infobox
		@"taxobox",
		@"vatop",
		@"sinottico",
		nil];
	NSSet* possibleVcardClasses = [NSSet setWithObjects:
		// @"prettytable",
		@"toccolours",
		// @"float-right",
		// @"wikitable",
		nil];
	BOOL foundVCard = NO;
	
	for(NSInteger nodeIndex=0; nodeIndex<numberOfNodes; ++nodeIndex) {
		xmlNodePtr node = xmlXPathNodeSetItem(result->nodesetval, nodeIndex);
		
		// First check if we're already worked on this table in a previous iteration
		if([obsoleteNodes containsObject:[NSValue valueWithPointer:node]]) {
			continue;
		}
		
//		// Skip tables nested in inline styled divs
//		if(node->parent && xmlHasProp(node->parent, BAD_CAST("style")) && xmlStrcasecmp(BAD_CAST("div"), node->name)) {
//			continue;
//		}
		
		// Look for specific table classes
		NSArray* classStrings = [self classStringsForNode:node];
		
		// A navbox with a vcard style is a no go for us
		if([classStrings containsObject:@"navbox"] && [classStrings containsObject:@"vcard"]) {
			classStrings = [classStrings arrayByRemovingObject:@"vcard"];
		}
		
//		// We simply skip if the table is not of a particular class
//		if(classStrings.count == 0) {
//			continue;
//		}
		
		// Skip this table if it's of a specific class
		if([self array:classStrings containsObjectsInSet:noneTableClasses]) {
			continue;
		}
		
		// Skip it if it's empty
		if([self isEmptyTable:node context:XPathContext]) {
			// xmlUnlinkNode(node);
			// [obsoleteNodes addObject:[NSValue valueWithPointer:node]];
			
			continue;
		}
		
		// Sometimes tables are wrapped in other useless wrapper tables
		xmlNodePtr inlineTable = classStrings.count == 0 ?
			[self singleCellTableContent:node context:XPathContext] :
			NULL;
		
		if(inlineTable != NULL) {
			classStrings = [self classStringsForNode:inlineTable];
			node = inlineTable;
		} else {
			// First check if we're not within another table
			if([self parentWithName:BAD_CAST("table") forNode:node] != NULL) {
				continue;
			}
		}
		
		// Make sure the table is not wrapped in a definition list
		if([self parentWithName:BAD_CAST("dl") forNode:node] != NULL) {
			continue;
		}
        
        // The german wiki has infoboxes as div element instead of table
        if([self parentWithClass:@"infobox" forNode:node context:XPathContext]) {
        	continue;
        }

		// Someone must have put tables into thumbnails
//		if([self parentWithClass:@"thumb" forNode:node context:XPathContext]) {
//			continue;
//		}

		// Could this be a vcard table?
		BOOL isVCard = NO;

		if(!foundVCard) {
			if([self array:classStrings containsObjectsInSet:vcardClasses] ||
			   (nodeIndex <= 1 && [self array:classStrings containsObjectsInSet:possibleVcardClasses])) {
//				xmlNodePtr nextElement = [self nextElement:node];
//				
//				if(nextElement &&
//				   nextElement->name &&
//				   xmlStrcasecmp(nextElement->name, BAD_CAST("table")) == 0) {
//					isVCard = NO;
//					foundVCard = YES;
//				} else {
					isVCard = YES;
					foundVCard = NO;
//				}
			}
		}

		// Remove all reference nodes
		XPathContext->node = node;
//		[self deleteNodesMatchingExpression:BAD_CAST(".//*[contains(concat(' ', normalize-space(@class), ' '), ' reference ')]") context:XPathContext];
//		TODO
		
		// Look for the summary attribute
		NSString* captionString = nil;
		xmlChar* summary = xmlGetProp(node, BAD_CAST("summary"));
		
		if(summary != NULL) {
			captionString = [NSString stringWithUTF8String:(const char*)summary];
			xmlFree(summary);
		}
		
		if(captionString.length == 0) {
			// Retrieve the table caption
			XPathContext->node = node;
			xmlXPathObjectPtr captionResult = xmlXPathEval(BAD_CAST(".//caption"), XPathContext);

			xmlChar* caption = xmlXPathCastNodeSetToString(captionResult->nodesetval);
			
			if(caption != NULL) {
				captionString = [NSString stringWithUTF8String:(const char*)caption];
				xmlFree(caption);
			}
			
			xmlXPathFreeObject(captionResult);
			XPathContext->node = NULL;
		}

		// Make a new table ID
		NSString* tableID = [NSString stringWithFormat:@"AKTable%i", [[self tables] count]];
		
		// Update our table ID
		xmlSetProp(node, BAD_CAST("id"), BAD_CAST([tableID UTF8String]));
		
		// Mark this as print only
		classStrings = [classStrings arrayByAddingObject:@"printonly"];
		[self setClasses:classStrings forNode:node];
		
		// Retrieve the table markup
		NSString* tableMarkup = [self stringFromLibXMLNode:node];
		
		// Store the table info dictionary
		NSDictionary* tableInfo = [NSDictionary dictionaryWithObjectsAndKeys:
			tableID, @"id",
			tableMarkup, @"markup",
			captionString, @"caption",
			classStrings, @"classes",
			nil];
		[[self tables] addObject:tableInfo];
		
		// Retrieve the vcard image if needed
		xmlNodePtr previewImageNode = NULL;
		
		if(isVCard) {
			XPathContext->node = node;
			previewImageNode = [self findFirstNodeByClass:@"vcard-photo-canditate" withContext:XPathContext];
			
			if(!previewImageNode) {
				previewImageNode = [self findFirstNodeByClass:@"thumbnail-placeholder" withContext:XPathContext];
			}
			
			if(previewImageNode) {
				xmlUnsetProp(previewImageNode, BAD_CAST("onclick"));
			
				[[self imageNodesNeedingRelease]
					removeObject:[NSValue valueWithPointer:previewImageNode]];
				xmlUnlinkNode(previewImageNode);
			} else {
				// It's probably no vcard
				if(nodeIndex > 0) {
					isVCard = NO;
				}
			}
		}

		// Make a new table placeholder
		xmlNodePtr placeholder = xmlNewDocRawNode(
			XPathContext->doc,
			NULL,
			BAD_CAST("div"),
			BAD_CAST(""));
		xmlSetProp(placeholder, BAD_CAST("id"), BAD_CAST([tableID UTF8String]));
		
		if(isVCard) {
			if(previewImageNode) {
				xmlSetProp(placeholder, BAD_CAST("class"), BAD_CAST("table-placeholder article-summary tright"));
			} else {
				xmlSetProp(placeholder, BAD_CAST("class"), BAD_CAST("table-placeholder article-summary no-photo tright"));
			}
		} else {
			xmlSetProp(placeholder, BAD_CAST("class"), BAD_CAST("table-placeholder table-cell"));
		}
		
		// xmlSetProp(placeholder, BAD_CAST("onclick"), BAD_CAST("document.location = 'x-articlekit-internal://openTablePlaceholder'"));
		
		// Now add the placeholder content
		xmlNodePtr placeholderContent = previewImageNode; // Use the image as content 
		
		if(placeholderContent == NULL) {
			// Retrieve the table header instead if needed
			if(captionString.length == 0) {
				xmlNodePtr tableHeader = [self findFirstTableHeader:node context:XPathContext];
				
				if(tableHeader) {
					XPathContext->node = tableHeader;
					[self deleteNodesMatchingExpression:BAD_CAST(".//*[contains(concat(' ', normalize-space(@class), ' '), ' noprint ')]") context:XPathContext];
					
					xmlChar* tableHeaderContentString = xmlXPathCastNodeToString(tableHeader);
					
					xmlNodePtr newPlaceholderContent = xmlNewDocRawNode(
						XPathContext->doc,
						NULL,
						BAD_CAST("span"),
						tableHeaderContentString);
					xmlSetProp(newPlaceholderContent, BAD_CAST("class"), BAD_CAST("placeholder-title"));
			
					placeholderContent = newPlaceholderContent;
					
					xmlFree(tableHeaderContentString);
				}
			}
			
			if(placeholderContent == NULL) {
				NSString* contentString = captionString.length > 0 ?
					captionString :
					NSLocalizedString(@"AKTablePlaceholderText", @"");
				
				placeholderContent = xmlNewDocRawNode(
					XPathContext->doc,
					NULL,
					BAD_CAST("span"),
					BAD_CAST([contentString UTF8String]));
			}
		}
		
		xmlAddChild(placeholder, placeholderContent);
		
		// Add the vcard border markup if needed
		if(isVCard) {
			xmlNodePtr vcardBorderNode = xmlNewDocRawNode(
				XPathContext->doc,
				NULL,
				BAD_CAST("span"),
				NULL);
			xmlSetProp(vcardBorderNode, BAD_CAST("class"), BAD_CAST("vcard-border"));
			
			xmlAddChild(placeholder, vcardBorderNode);
		}

		// Set the action URL
//		NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
//			tableID, @"id",
//			nil];
//		NSURL* actionURL = [NSURL
//			URLWithString:@"x-articlekit-internal://showTable"
//			parameters:parameters];
//		
//		NSString* onClickHandler = [NSString stringWithFormat:
//			@"document.location = '%@'",
//			[actionURL absoluteString]];
//		
//		xmlSetProp(placeholder, BAD_CAST("onclick"), BAD_CAST([onClickHandler UTF8String]));
		
		// Now replace the table node with our placeholder
		xmlReplaceNode(node, placeholder);
//		xmlAddPrevSibling(node, placeholder); // TODO
		[obsoleteNodes addObject:[NSValue valueWithPointer:node]];
	}
	
	for(NSValue* obsoleteNode in obsoleteNodes) {
		xmlFreeNode([obsoleteNode pointerValue]);
	}
	
	xmlXPathFreeObject(result);
}

- (void)restructureImages:(xmlDocPtr)document context:(xmlXPathContextPtr)XPathContext {
	xmlXPathObjectPtr result = xmlXPathEval(BAD_CAST("/html/body//img"), XPathContext);
	NSInteger numberOfNodes = xmlXPathNodeSetGetLength(result->nodesetval);
		
	for(NSInteger nodeIndex=0; nodeIndex<numberOfNodes; ++nodeIndex) {
		xmlNodePtr node = xmlXPathNodeSetItem(result->nodesetval, nodeIndex);
		[self restructureImage:node context:XPathContext];
	}
	
	// Make the image info dictionaries for each image node wrapper
	for(NSMutableDictionary* image in self.images) {
		// Unwrap our image nodes
		xmlNodePtr imageNode = [[image objectForKey:@"node"] pointerValue];
		xmlNodePtr wrapperNode = [[image objectForKey:@"wrapper"] pointerValue];
		
		// Retrieve the thumbnail image URL
		xmlChar* thumbnailURL = xmlGetProp(imageNode, BAD_CAST("src"));

		if(thumbnailURL) {
			NSString* thumbnailURLString = [NSString stringWithUTF8String:(const char*)thumbnailURL];
		
			if([thumbnailURLString hasPrefix:@"//"]) {
				thumbnailURLString = [@"http:" stringByAppendingString:thumbnailURLString];
			}
		
			[image
				setValue:thumbnailURLString
				forKey:@"thumbnail"];
		
			xmlFree(thumbnailURL);
		}

		xmlChar* thumbnailSetURL = xmlGetProp(imageNode, BAD_CAST("srcset"));

		if(thumbnailSetURL) {
			NSString* thumbnailSetURLString = [NSString stringWithUTF8String:(const char*)thumbnailSetURL];
			NSString* thumbnailURLString = [self URLStringForImageSetString:thumbnailSetURLString];

			if(thumbnailURLString) {
				if([thumbnailURLString hasPrefix:@"//"]) {
					thumbnailURLString = [@"http:" stringByAppendingString:thumbnailURLString];
				}

				[image setValue:thumbnailURLString forKey:@"thumbnail"];
			}
		
			xmlFree(thumbnailSetURL);
			xmlUnsetProp(imageNode, BAD_CAST("srcset"));
		}

		// …
		NSString* imageIdentifier = [NSString stringWithFormat:@"%@Element", image[@"id"]];
		xmlSetProp(imageNode, BAD_CAST("id"), BAD_CAST([imageIdentifier UTF8String]));
		xmlSetProp(imageNode, BAD_CAST("src"), NULL);

		xmlSetProp(imageNode, BAD_CAST("alt"), NULL); // remove the alt attribute to workaround a special character issue
		
		// Now retrieve the high-res image URL
		xmlNodePtr anchor = [self parentAnchorForNode:imageNode];
		
		if(anchor && xmlHasProp(anchor, BAD_CAST("href"))) {
			xmlChar* imageURL = xmlGetProp(anchor, BAD_CAST("href"));
			
			NSString* imageURLString = [NSString stringWithUTF8String:(const char*)imageURL];
			[image
				setValue:imageURLString
				forKey:@"image"];

			xmlFree(imageURL);
			
			BOOL mightBeVector = [imageURLString hasSuffix:@".svg"] || [imageURLString hasSuffix:@".SVG"];
			if(mightBeVector) {
				[self appendClass:@" svg-image" toNode:anchor];
			}
		}
		
		// Retrieve the markup for our wrapper node
		NSString* imageMarkup = [self stringFromLibXMLNode:wrapperNode];
		
		// Escape the markup string for javascript
		imageMarkup = [imageMarkup stringByReplacingOccurrencesOfString:@"\n" withString:@""];
		imageMarkup = [imageMarkup stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
		
		[image setValue:imageMarkup forKey:@"markup"];
		
		// We no longer need the node objects
		[image removeObjectForKey:@"node"];
		[image removeObjectForKey:@"wrapper"];
		
//		NSLog(@"\n\n%@\n\n\n\n", imageMarkup);
	}
	
	// Release obsolete nodes
	for(NSValue* imageNode in self.imageNodesNeedingRelease) {
		xmlNodePtr node = [imageNode pointerValue];
		
		if(node != NULL) {
			xmlFreeNode(node);
		}
	}
	
	[[self imageNodesNeedingRelease] removeAllObjects];
	
	// Clean up
	xmlXPathFreeObject(result);
	XPathContext->node = NULL;
}

- (NSString*)URLStringForImageSetString:(NSString*)imageSetString {
	if(imageSetString.length == 0) { return nil; }

	NSCharacterSet* whitespaceCharacters = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	NSCharacterSet* separatorCharacters = [NSCharacterSet characterSetWithCharactersInString:@","];

	NSArray* strings = [imageSetString componentsSeparatedByCharactersInSet:separatorCharacters];

	CGFloat preferredScale = 0.0;
	NSString* URLString = nil;

	for(__strong NSString* string in strings) {
		string = [string stringByTrimmingCharactersInSet:whitespaceCharacters];
		string = [string stringByTrimmingCharactersInSet:separatorCharacters];

		NSArray* componentStrings = [string componentsSeparatedByCharactersInSet:whitespaceCharacters];
		if(componentStrings.count <= 1) { continue; }

		NSString* scaleString = [componentStrings lastObject];
		CGFloat scale = [scaleString floatValue];

		if(scale > preferredScale) {
			preferredScale = scale;
			URLString = [componentStrings objectAtIndex:0];
		}
	}

	if(URLString.length == 0) {return nil; }
	return URLString;
}

- (void)restructureImage:(xmlNodePtr)imageNode context:(xmlXPathContextPtr)XPathContext {
	// First check if this is a valid thumbnail image
	BOOL needsToRemove = YES;
	
	// NSLog(@"\n\n%@\n\n", [self stringFromLibXMLNode:imageNode]);
	
	if([self isThumbnailImage:imageNode context:XPathContext]) {
		xmlNodePtr wrapperTable = [self parentWithName:BAD_CAST("TABLE") forNode:imageNode];

		// Now retrieve the wrapper node
		xmlNodePtr wrapperNode = NULL;

		// Try thumb elements first
		if(!wrapperTable) {
			wrapperNode = [self parentWithClass:@"thumb" forNode:imageNode context:XPathContext];
		}

		if(!wrapperNode) {
			wrapperNode = [self wrapperForImageNode:imageNode context:XPathContext];
		}

		// Might be within a table
		if(!wrapperNode) {
			wrapperNode = [self parentWithClass:@"image" forNode:imageNode context:XPathContext];
		}
		
		if(!wrapperNode) {
			// Might be a TeX image
			if([[self classStringsForNode:imageNode] containsObject:@"tex"]) {
				wrapperNode = imageNode;
			}
		}
		
		if(wrapperNode) {
			// We keep this image
			needsToRemove = NO;
			
			// Remove all inline styles
			// [self removeAllInlineStylesFromNode:wrapperNode context:XPathContext]; // TODO
			
			// Retrieve the wrapper node classes
			NSArray* classes = [self classStringsForNode:wrapperNode];
			classes = [self adjustWrapperNodeClassesIfNeeded:wrapperNode classes:classes context:XPathContext];
			
			// Retrieve the thumbimage node
			xmlNodePtr thumbImageNode = [self parentWithClass:@"thumbimage" forNode:imageNode context:XPathContext];

			if(!thumbImageNode) {
				thumbImageNode = wrapperNode;
			}
			
			// Make a new id for this image
			NSString* imageID = [NSString stringWithFormat:@"AKImage%i", [[self images] count]];
			
			// Set our custom image ID
			xmlSetProp(thumbImageNode, BAD_CAST("id"), BAD_CAST([imageID UTF8String]));
			
			// Replace the image wrapper node with our placeholder
			xmlNodePtr placeholderNode = [self placeholderForImageNode:imageNode wrapper:wrapperNode imageID:imageID classes:classes context:XPathContext];
			xmlReplaceNode(thumbImageNode, placeholderNode);
			[[self imageNodesNeedingRelease] addObject:[NSValue valueWithPointer:thumbImageNode]];
		
			// NSLog(@"\n\nobsolete:\n%@\n\n", [self stringFromLibXMLNode:obsoleteNode]);
			
			// Make a new image info object
			NSMutableDictionary* imageInfo = [NSMutableDictionary dictionary];
			
			[imageInfo setValue:imageID forKey:@"id"];
			[imageInfo setValue:[NSValue valueWithPointer:imageNode] forKey:@"node"];
			[imageInfo setValue:[NSValue valueWithPointer:thumbImageNode] forKey:@"wrapper"];
			
			[[self images] addObject:imageInfo];
		}
	}
	
	// We remove all internal images
	if(needsToRemove) {
		xmlUnlinkNode(imageNode);
		[[self imageNodesNeedingRelease] addObject:[NSValue valueWithPointer:imageNode]];
	}
}

- (BOOL)isThumbnailImage:(xmlNodePtr)imageNode context:(xmlXPathContextPtr)XPathContext {
	XPathContext->node = imageNode;
	
	xmlXPathObjectPtr result = xmlXPathEval(BAD_CAST("./ancestor-or-self::*[contains(concat(' ', normalize-space(@class), ' '), ' noprint ') or contains(concat(' ', normalize-space(@class), ' '), ' internal ') or contains(concat(' ', normalize-space(@class), ' '), ' metadata ') or contains(concat(' ', normalize-space(@class), ' '), ' thumbcaption ')]"), XPathContext);
	
	BOOL isThumbnailImage = xmlXPathNodeSetIsEmpty(result->nodesetval);
	
	xmlXPathFreeObject(result);
	
	// Check if this is a http resource
	if(isThumbnailImage) {
		if(xmlHasProp(imageNode, BAD_CAST("src"))) {
			xmlChar* srcString =  xmlGetProp(imageNode, BAD_CAST("src"));
			
			isThumbnailImage =
				xmlStrncasecmp(srcString, BAD_CAST("http"), xmlStrlen(BAD_CAST("http"))) == 0 ||
				xmlStrncasecmp(srcString, BAD_CAST("//"), xmlStrlen(BAD_CAST("//"))) == 0;
			
			if(!isThumbnailImage) {
				// NSLog(@"Ignored %s", srcString);
			}
			
			xmlFree(srcString);
		}
	}
	
	// Now check the image size
	if(isThumbnailImage) {
		if(xmlHasProp(imageNode, BAD_CAST("height"))) {
			xmlChar* heightString = xmlGetProp(imageNode, BAD_CAST("height"));
			NSInteger imageHeight = [[NSString stringWithUTF8String:(const char*)heightString] integerValue];
			xmlFree(heightString);
			
			if(imageHeight <= 24.0) {
				isThumbnailImage = NO;
			}
		}
	}
	
	return isThumbnailImage;
}

- (xmlNodePtr)wrapperForImageNode:(xmlNodePtr)imageNode context:(xmlXPathContextPtr)XPathContext {
	xmlNodePtr wrapper = NULL;
	XPathContext->node = imageNode;
	
	xmlXPathObjectPtr result = xmlXPathEval(BAD_CAST("./ancestor::*[contains(concat(' ', normalize-space(@class), ' '), ' thumb ') or contains(concat(' ', normalize-space(@class), ' '), ' gallerybox ') or contains(concat(' ', normalize-space(@class), ' '), ' tleft ') or contains(concat(' ', normalize-space(@class), ' '), ' tright ') or contains(concat(' ', normalize-space(@class), ' '), ' tnone ')]"), XPathContext);
		
	if(!xmlXPathNodeSetIsEmpty(result->nodesetval)) {
		wrapper = xmlXPathNodeSetItem(result->nodesetval, 0);
	}
	
	xmlXPathFreeObject(result);
	
	return wrapper;
}

- (xmlNodePtr)placeholderForImageNode:(xmlNodePtr)imageNode wrapper:(xmlNodePtr)wrapperNode imageID:(NSString*)imageID classes:(NSArray*)classes context:(xmlXPathContextPtr)XPathContext {
	if(!imageNode) { return NULL; }

	// Adjust the placeholder classes
	classes = [classes arrayByRemovingObject:@"thumb"];
	classes = [classes arrayByAddingObject:@"thumbnail-placeholder"];
	
	// Make a new placeholder node
	xmlNodePtr placeholderNode = xmlNewDocRawNode(
		imageNode->doc,
		NULL,
		BAD_CAST("div"),
		NULL);
			
	xmlSetProp(placeholderNode, BAD_CAST("id"), BAD_CAST([imageID UTF8String]));
	
	// Retrieve the height attribute
	NSString* imageHeight = nil;

	if(xmlHasProp(imageNode, BAD_CAST("height"))) {
		xmlChar* heightString = xmlGetProp(imageNode, BAD_CAST("height"));
		imageHeight = [NSString stringWithUTF8String:(const char*)heightString];
		xmlFree(heightString);
	}
	
	// Retrieve the width attribute
	NSString* imageWidth = nil;

	if(xmlHasProp(imageNode, BAD_CAST("width"))) {
		xmlChar* widthString = xmlGetProp(imageNode, BAD_CAST("width"));
		imageWidth = [NSString stringWithUTF8String:(const char*)widthString];
		xmlFree(widthString);
	}
	
	// Make a new style declaration
	if(imageHeight && imageWidth) {
		NSString* style = [NSString stringWithFormat:@"height:%@px; width:%@px;", imageHeight, imageWidth];
		xmlSetProp(placeholderNode, BAD_CAST("style"), BAD_CAST([style UTF8String]));
	}
	
	if(imageWidth && [imageWidth integerValue] >= 100.0) {
		classes = [classes arrayByAddingObject:@"vcard-photo-canditate"];
	}
	
	// ...
	[self setClasses:classes forNode:placeholderNode];

	return placeholderNode;
}

- (xmlNodePtr)findFirstTableHeader:(xmlNodePtr)node context:(xmlXPathContextPtr)XPathContext {
	XPathContext->node = node;
	xmlXPathObjectPtr result = xmlXPathEval(BAD_CAST(".//tr[position()=1 and count(th)=1]/th"), XPathContext);
	
	xmlNodePtr tableHeader = NULL;
	
	// Only return if we're have a single item
	if(xmlXPathNodeSetGetLength(result->nodesetval) == 1) {
		tableHeader = xmlXPathNodeSetItem(result->nodesetval, 0);
	}
	
	xmlXPathFreeObject(result);

	return tableHeader;
}

- (xmlNodePtr)singleCellTableContent:(xmlNodePtr)tableNode context:(xmlXPathContextPtr)XPathContext {
	XPathContext->node = tableNode;
	xmlXPathObjectPtr result = xmlXPathEval(BAD_CAST("./tr[count(td)=1]/td[count(*)=1]/table"), XPathContext);
	
	xmlNodePtr contentNode = NULL;
	
	// Only return if we're have a single item
	if(xmlXPathNodeSetGetLength(result->nodesetval) == 1) {
		contentNode = xmlXPathNodeSetItem(result->nodesetval, 0);
	}
	
	xmlXPathFreeObject(result);

	return contentNode;
}

- (BOOL)isEmptyTable:(xmlNodePtr)tableNode context:(xmlXPathContextPtr)XPathContext {
	xmlChar* content = xmlNodeGetContent(tableNode);
	BOOL isEmpty = YES;
	
	if(content != NULL) {
		int length = xmlUTF8Strlen(content);
		NSCharacterSet* noneWhitespace = [[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
		
		for(int i=0; i<length; ++i) {
			unichar c = content[i];

			if([noneWhitespace characterIsMember:c]) {
				isEmpty = NO;
				break;
			}
		}
		
		xmlFree(content);
	}
	
	return isEmpty;
}

- (NSArray*)adjustWrapperNodeClassesIfNeeded:(xmlNodePtr)wrapperNode classes:(NSArray*)classes context:(xmlXPathContextPtr)XPathContext {
	BOOL needsUpdate = NO;
	
	if([classes containsObject:@"tright"]) {
		if([self shouldForceLeftOrientation:wrapperNode]) {
			classes = [classes arrayByReplacingObject:@"tright" withObject:@"tleft"];
			needsUpdate = YES;
		}
	} else {
		if([self shouldForceRightOrientation:wrapperNode]) {
			classes = [classes arrayByReplacingObject:@"tleft" withObject:@"tright"];
			needsUpdate = YES;
		}
	}
	
	if(needsUpdate) {
		[self setClasses:classes forNode:wrapperNode];
	}
	
	return classes;
}

- (void)deleteUnwantedNodes:(xmlDocPtr)document context:(xmlXPathContextPtr)XPathContext {
	// Remove all script elements within the body tag
	XPathContext->node = NULL;
	[self deleteNodesMatchingExpression:BAD_CAST("/html/body//script") context:XPathContext];
	
	// Delete the TOC
	XPathContext->node = NULL;
	[self deleteNodesMatchingExpression:BAD_CAST("id('toc')") context:XPathContext];
	
//	// Delete the references section
//	[self deleteReferencesChapter:XPathContext];
}

- (void)deleteNodesMatchingExpression:(const xmlChar*)XPath context:(xmlXPathContextPtr)XPathContext {
//	XPathContext->node = NULL;
	xmlXPathObjectPtr result = xmlXPathEval(XPath, XPathContext);
	
	if(!result) {
		NSLog(@"Invalid XPath result set");
		return;
	}
	
	NSInteger numberOfNodes = xmlXPathNodeSetGetLength(result->nodesetval);
		
	for(NSInteger nodeIndex=0; nodeIndex<numberOfNodes; ++nodeIndex) {
		xmlNodePtr node = xmlXPathNodeSetItem(result->nodesetval, nodeIndex);
		xmlUnlinkNode(node);
		xmlFreeNode(node);
	}
	
	xmlXPathFreeObject(result);
}

- (void)fixWikipediaLinks:(xmlXPathContextPtr)XPathContext {
	XPathContext->node = NULL;
	
	NSString* hostString = [NSString stringWithFormat:@"%@://%@", [[self articleURL] scheme], [[self articleURL] host]];
	xmlXPathObjectPtr internalLinks = xmlXPathEval(BAD_CAST("//*[starts-with(@href, '/wiki/') or starts-with(@href, '/w/')]"), XPathContext);
	
	NSInteger numberOfInternalLinks = xmlXPathNodeSetGetLength(internalLinks->nodesetval);
		
	for(NSInteger internalLinkIndex=0; internalLinkIndex<numberOfInternalLinks; ++internalLinkIndex) {
		xmlNodePtr internalLink = xmlXPathNodeSetItem(internalLinks->nodesetval, internalLinkIndex);
		
		xmlChar* resource = xmlGetProp(internalLink, BAD_CAST("href"));
		NSString* newResource = [hostString stringByAppendingFormat:@"%s", resource];
		
		xmlSetProp(internalLink, BAD_CAST("href"), BAD_CAST([newResource UTF8String]));
		xmlFree(resource);
	}

	xmlXPathFreeObject(internalLinks);
}

- (void)deleteReferencesChapter:(xmlXPathContextPtr)XPathContext {
	XPathContext->node = NULL;
	xmlXPathObjectPtr result = xmlXPathEval(BAD_CAST("//*[contains(concat(' ', normalize-space(@class), ' '), ' references ')]"), XPathContext); // or contains(concat(' ', normalize-space(@class), ' '), ' sisterproject ')]"), XPathContext);
	
	NSInteger numberOfNodes = xmlXPathNodeSetGetLength(result->nodesetval);
		
	for(NSInteger nodeIndex=0; nodeIndex<numberOfNodes; ++nodeIndex) {
		xmlNodePtr references = xmlXPathNodeSetItem(result->nodesetval, nodeIndex);
		xmlNodePtr node = references;
		
		while(node != NULL && node->parent != NULL) {
			xmlChar* nodeID = xmlGetProp(node->parent, BAD_CAST("id"));
				
			if(nodeID && xmlStrEqual(nodeID, BAD_CAST("bodyContent"))) {
				xmlNodePtr previous = [self previousElement:node];
				
				NSMutableArray* nodesToRemove = [NSMutableArray array];
				xmlNodePtr sibling = previous;
				
				while(sibling != NULL) {
					[nodesToRemove addObject:[NSValue valueWithPointer:sibling]];
					
					if(xmlStrEqual(sibling->name, BAD_CAST("h2"))) {
						break;
					}
					
					sibling = sibling->prev;
				}
				
				sibling = previous ?
					previous->next :
					NULL;
				
				while(sibling != NULL) {
					if(xmlStrEqual(sibling->name, BAD_CAST("h2"))) {
						break;
					}

					[nodesToRemove addObject:[NSValue valueWithPointer:sibling]];
					
					sibling = sibling->next;
				}
				
				for(NSValue* value in nodesToRemove) {
					xmlNodePtr nodeToRemove = [value pointerValue];
					xmlUnlinkNode(nodeToRemove);
					xmlFreeNode(nodeToRemove);
				}
				
				xmlFree(nodeID);
				
				break;
			}
			
			xmlFree(nodeID);
			
			node = node->parent;
		}
	}
	
	xmlXPathFreeObject(result);
}

- (void)addPageFooter:(xmlNodePtr)node context:(xmlXPathContextPtr)XPathContext {
/*	xmlNodePtr footer = xmlNewChild(
		node,
		NULL,
		BAD_CAST("div"),
		NULL);
	xmlSetProp(footer, BAD_CAST("id"), BAD_CAST("document-footer"));*/
}

- (xmlNodePtr)previousElement:(xmlNodePtr)node {
	xmlNodePtr previous = node->prev;
	
	while(previous != NULL) {
		if(previous->type == XML_ELEMENT_NODE) {
			return previous;
		}
		
		previous = previous->prev;
	}
	
	return NULL;
}

- (xmlNodePtr)nextElement:(xmlNodePtr)node {
	xmlNodePtr next = node->next;
	
	while(next != NULL) {
		if(next->type == XML_ELEMENT_NODE) {
			return next;
		}
		
		next = next->next;
	}
	
	return NULL;
}

- (BOOL)shouldForceLeftOrientation:(xmlNodePtr)node {
/*	xmlNodePtr sibling = node->next;
	
	while(sibling != NULL) {
		if(sibling->type == XML_ELEMENT_NODE) {
			if(xmlStrcasecmp(sibling->name, BAD_CAST("p")) == 0) {
				return NO;
			} else {
				if(xmlStrcasecmp(sibling->name, BAD_CAST("h2")) == 0 ||
				   xmlStrcasecmp(sibling->name, BAD_CAST("h3")) == 0 ||
				   xmlStrcasecmp(sibling->name, BAD_CAST("h4")) == 0 ||
				   xmlStrcasecmp(sibling->name, BAD_CAST("h5")) == 0 ||
				   xmlStrcasecmp(sibling->name, BAD_CAST("ul")) == 0 ||
				   xmlStrcasecmp(sibling->name, BAD_CAST("ol")) == 0) {
					return YES;
				}
				
				if(xmlStrcasecmp(sibling->name, BAD_CAST("table")) == 0) {
					xmlNodePtr previousElement = [self previousElement:node];
					
					if(xmlStrcasecmp(previousElement->name, BAD_CAST("h2")) == 0 ||
					   xmlStrcasecmp(previousElement->name, BAD_CAST("h3")) == 0 ||
					   xmlStrcasecmp(previousElement->name, BAD_CAST("h4")) == 0 ||
					   xmlStrcasecmp(previousElement->name, BAD_CAST("h5")) == 0) {
						return YES;
					}
				}
				
				// return NO;
			}
		}
		
		sibling = sibling->next;
	}
*/	
	return NO;
}

- (BOOL)shouldForceRightOrientation:(xmlNodePtr)node {
/*	xmlNodePtr previousElement = [self previousElement:node];
	
	if(previousElement) {
		NSArray* previousClasses = [self classStringsForNode:previousElement];
		
		if([previousClasses containsObject:@"tright"]) {
			return YES;
		}
		
		if(xmlStrcasecmp(previousElement->name, BAD_CAST("h2")) == 0 ||
		   xmlStrcasecmp(previousElement->name, BAD_CAST("h3")) == 0 ||
		   xmlStrcasecmp(previousElement->name, BAD_CAST("h4")) == 0 ||
		   xmlStrcasecmp(previousElement->name, BAD_CAST("h5")) == 0 ||
		   xmlStrcasecmp(previousElement->name, BAD_CAST("p")) == 0 ||
		   [previousClasses containsObject:@"thumb"] ||
		   [previousClasses containsObject:@"rellink"]) {
			xmlNodePtr nextElement = [self nextElement:node];
			
			if(nextElement) {
				if(xmlStrcasecmp(nextElement->name, BAD_CAST("p")) == 0) {
					return YES;
				}
				
				NSArray* nextClasses = [self classStringsForNode:nextElement];
				
				if([nextClasses containsObject:@"tright"]) {
					return YES;
				}
				
				if([nextClasses containsObject:@"tleft"]) {
					return [self shouldForceRightOrientation:nextElement];
				}
			}
		} else {
			xmlNodePtr nextElement = [self nextElement:node];
		
			if(nextElement) {
				NSArray* nextClasses = [self classStringsForNode:nextElement];
					
				if([nextClasses containsObject:@"tright"]) {
					return YES;
				}
					
				if([nextClasses containsObject:@"tleft"]) {
					return [self shouldForceRightOrientation:nextElement];
				}
			}
		}
	} else {
		xmlNodePtr nextElement = [self nextElement:node];
		
		if(nextElement) {
			NSArray* nextClasses = [self classStringsForNode:nextElement];
				
			if([nextClasses containsObject:@"tright"]) {
				return YES;
			}
				
			if([nextClasses containsObject:@"tleft"]) {
				return [self shouldForceRightOrientation:nextElement];
			}
		}
	}
*/	
	return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

- (void)postDocumentLoadProgress {
	float progress = 0.0;

	if(self.expectedContentLength > 0) {
		progress = (float)self.numberOfBytesTransferred / (float)self.expectedContentLength;
	}
	
	progress = MAX(progress, 0.0);
	progress = MIN(progress, 1.0);
	
	[self postDocumentLoadProgress:progress];
}

- (void)postDocumentLoadProgress:(float)progress {
	[[NSOperationQueue mainQueue] addOperationWithBlock:^() {
		[[self delegate] updateDocumentLoadProgress:@(progress)];
	}];
}

- (void)postDocumentParseProgress:(float)progress {
	[[NSOperationQueue mainQueue] addOperationWithBlock:^() {
		[[self delegate] updateDocumentParseProgress:@(progress)];
	}];
}

@end
