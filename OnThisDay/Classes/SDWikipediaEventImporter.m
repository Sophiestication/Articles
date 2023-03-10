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

#import "SDWikipediaEventImporter.h"
#import "SDWikipediaEventImporter+Private.h"

#import "SDEventGroup.h"

#import "NSArray+Additions.h"
#import "NSURL+Wikipedia.h"

#import <libxml/tree.h>
#import <libxml/HTMLTree.h>
#import <libxml/HTMLParser.h>
#import <libxml/xpath.h>
#import <libxml/xmlsave.h>

@implementation SDWikipediaEventImporter

NSString* const SDWikipediaEventImporterErrorDomain = @"SDWikipediaEventImporterErrorDomain";

#pragma mark -
#pragma mark Construction & Destruction

+ (SDWikipediaEventImporter*)eventImporterForURL:(NSURL*)wikipediaURL {
	SDWikipediaEventImporter* eventImporter = [[self alloc] init];
	
	eventImporter.wikipediaURL = wikipediaURL;
	
	return eventImporter;
}

- (id)init {
	if(self = [super init]) {
		_waitingForInput = NO;
		_parserContext = NULL;
	}
	
	return self;
}

- (void)dealloc {
	if(_parserContext) {
		xmlFreeParserCtxt(_parserContext);
	}

	self.delegate = nil;
	self.userInfo = nil;
	self.wikipediaURL = nil;
	self.eventGroups = nil;
}

#pragma mark -
#pragma mark SDWikipediaEventImporter

#pragma mark -
#pragma mark NSOperation

- (void)main {
	NS_DURING
		// Make a new runloop
		[NSRunLoop currentRunLoop];

		// Prepare the HTTP request
		NSMutableURLRequest* request = [NSMutableURLRequest 
			requestWithURL:[self wikipediaURL]
			cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
			timeoutInterval:120.0];
		
		NSURLConnection* connection = [NSURLConnection
			connectionWithRequest:request
			delegate:self];
		
		if(connection) {
			_waitingForInput = YES;
			
			do {
				[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
			} while(_waitingForInput && ![self isCancelled]);
		}		
	NS_HANDLER
		NSLog(@"Exception in SDWikipediaEventImporter: %@", localException);
	NS_ENDHANDLER
}

#pragma mark -
#pragma mark NSURLConnectionDelegate

- (NSURLRequest*)connection:(NSURLConnection*)connection willSendRequest:(NSURLRequest*)request redirectResponse:(NSURLResponse*)response {
	if(_parserContext) {
		xmlFreeParserCtxt(_parserContext);
		_parserContext = NULL;
	}

	return request;
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response {
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
	if(!_parserContext) {
		_parserContext = htmlCreatePushParserCtxt(NULL, (__bridge void *)(self), NULL, 0, NULL, XML_CHAR_ENCODING_UTF8);
		htmlCtxtUseOptions(_parserContext, HTML_PARSE_RECOVER|HTML_PARSE_NOBLANKS|HTML_PARSE_COMPACT);
	}
	
	htmlParseChunk(_parserContext, [data bytes], [data length], 0);
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
	// We no longer wait for input sources
	_waitingForInput = NO;

	// Finish parsing
	htmlParseChunk(_parserContext, NULL, 0, 1);
	
	// ...
	// NSLog(@"Done loading %@", [self wikipediaURL]);
	
	// We're working with the tree API
	xmlDocPtr doc = _parserContext->myDoc;
	xmlXPathContextPtr XPathContext = xmlXPathNewContext(doc);
	
	// NSLog(@"%@", [self stringFromLibXMLNode:doc->last]);
	
	[self restructureEventGroups:doc context:XPathContext];
	// [self deleteNodesMatchingExpression:BAD_CAST("//a[@class='image']") context:XPathContext];
	
	// Do the actual parsing job
	[self parseAllEventGroups:XPathContext];
	
	// Cleanup
	xmlXPathFreeContext(XPathContext);
	xmlFreeDoc(doc);
	
	// ...
	// NSLog(@"Done parsing %@", [self wikipediaURL]);
	
	// Now check if we parsed events at all
	if(self.eventGroups.count <= 0) {
		NSError* error = [NSError
			errorWithDomain:SDWikipediaEventImporterErrorDomain
			code:SDWikipediaEventImporterErrorParserFailed
			userInfo:nil];
			
		NSLog(@"Error in SDWikipediaEventImporter: %@", error);
		
		// Report this error to our delegate if needed
		if([[self delegate] respondsToSelector:@selector(wikipediaEventImporter:didFailWithError:)]) {
			dispatch_async(dispatch_get_main_queue(), ^() {
				[[self delegate] wikipediaEventImporter:self didFailWithError:error];
			});
		}
		
		return;
	}
	
	// Notify our delegate
	if([[self delegate] respondsToSelector:@selector(wikipediaEventImporter:didFinishWithEventGroups:)]) {
		NSArray* eventGroups = self.eventGroups;

		dispatch_async(dispatch_get_main_queue(), ^() {
			[[self delegate] wikipediaEventImporter:self didFinishWithEventGroups:eventGroups];
		});
	}
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
	_waitingForInput = NO;
	xmlParseChunk(_parserContext, NULL, 0, 1);
	
	NSLog(@"Error in SDWikipediaEventImporter: %@", error);
	
	// Report this error to our delegate if needed
	if([[self delegate] respondsToSelector:@selector(wikipediaEventImporter:didFailWithError:)]) {
		dispatch_async(dispatch_get_main_queue(), ^() {
			[[self delegate] wikipediaEventImporter:self didFailWithError:error];
		});
	}
}

#pragma mark -
#pragma mark Private

- (void)parseAllEventGroups:(xmlXPathContextPtr)XPathContext {
	xmlXPathObjectPtr result = xmlXPathEvalExpression(BAD_CAST("//h2"), XPathContext);

	NSInteger numberOfNodes = xmlXPathNodeSetGetLength(result->nodesetval);
	NSMutableArray* eventGroups = [NSMutableArray arrayWithCapacity:numberOfNodes];
	
    NSArray* allowedEventGroups = [NSArray arrayWithObjects:
    	@"Events",
        @"Ereignisse",
        @"Évènements",
		@"Événements",
        @"Eventi",
        @"Gebeurtenissen",
        @"Acontecimientos",
        @"できごと",
    	nil];
        
    NSArray* allowedBirthsGroups = [NSArray arrayWithObjects:
    	@"Births",
        @"Geboren",
        @"Naissances",
        @"Nati",
        @"Geboren",
        @"Nacimientos",
        @"誕生日",
    	nil];
        
     NSArray* allowedDeathGroups = [NSArray arrayWithObjects:
    	@"Deaths",
        @"Gestorben",
        @"Décès",
        @"Morti",
        @"Overleden",
        @"Fallecimientos",
        @"忌日",
    	nil];
    
	NSArray* allowedGroups = [[allowedEventGroups
    	arrayByAddingObjectsFromArray:allowedBirthsGroups]
        arrayByAddingObjectsFromArray:allowedDeathGroups];
	
	for(NSInteger nodeIndex=0; nodeIndex<numberOfNodes; ++nodeIndex) {
		xmlNodePtr node = xmlXPathNodeSetItem(result->nodesetval, nodeIndex);

		NSString* title = [self parseEventGroupTitle:node context:XPathContext];

		if([allowedGroups containsObject:title]) {
			NSMutableDictionary* eventGroup = [NSMutableDictionary dictionary];

			[eventGroup setObject:title forKey:@"title"];
            
            NSString* kind = nil;

            if([allowedEventGroups containsObject:title]) { kind = SDEventGroupKindEvents; }
            if([allowedBirthsGroups containsObject:title]) { kind = SDEventGroupKindBirths; }
            if([allowedDeathGroups containsObject:title]) { kind = SDEventGroupKindDeaths; }
			
            if(kind) {
            	[eventGroup setObject:kind forKey:@"kind"];
            }
            
			NSArray* events = [self parseEventsInGroup:node context:XPathContext];
			[eventGroup setObject:events forKey:@"events"];
		
			[eventGroups addObject:eventGroup];
		}
	}
	
	self.eventGroups = eventGroups;
	
	xmlXPathFreeObject(result);
}

- (NSArray*)parseEventsInGroup:(xmlNodePtr)groupNode context:(xmlXPathContextPtr)XPathContext {
	NSMutableArray* events = [NSMutableArray array];
	xmlNodePtr sibling = groupNode;
	
	while(1) {
		sibling = sibling->next;
		
		if(sibling == NULL) {
			break;
		}
		
		// A h2 element ends the group
		if(xmlStrcasecmp(sibling->name, BAD_CAST("h2")) == 0) {
			break;
		}
		
		if(YES /* xmlStrcasecmp(sibling->name, BAD_CAST("ul")) == 0*/) {
			if(xmlHasProp(sibling, BAD_CAST("class"))) {
				xmlChar* classString = xmlGetProp(sibling, BAD_CAST("class"));
				
				BOOL shouldSkip = 
					xmlStrcasecmp(classString, BAD_CAST("gallery")) == 0;
				
				xmlFree(classString);
				
				if(shouldSkip) {
					continue;
				}
			}
			
			XPathContext->node = sibling;
			xmlXPathObjectPtr result = xmlXPathEvalExpression(BAD_CAST(".//li"), XPathContext);

			NSInteger numberOfNodes = xmlXPathNodeSetGetLength(result->nodesetval);
		
			for(NSInteger nodeIndex=0; nodeIndex<numberOfNodes; ++nodeIndex) {
				xmlNodePtr node = xmlXPathNodeSetItem(result->nodesetval, nodeIndex);
				
				if([self parentWithName:BAD_CAST("li") forNode:node->parent] != NULL) {
					continue;
				}

				NSDictionary* event = [self parseEvent:(xmlNodePtr)node context:(xmlXPathContextPtr)XPathContext];
			
				if(event) {
					[events addObject:event];
				}
			}
	
			xmlXPathFreeObject(result);
		}
	}
	
	[events sortWithOptions:NSSortStable usingComparator:^(id obj1, id obj2) {
		NSString* firstYearString = [self yearStringFromString:[obj1 objectForKey:@"year"]];
		NSString* secondYearString = [self yearStringFromString:[obj2 objectForKey:@"year"]];
		
		NSInteger firstYear = [firstYearString integerValue];
		NSInteger secondYear = [secondYearString integerValue];
		
		if(firstYear < secondYear) { return NSOrderedAscending; }
		if(firstYear > secondYear) { return NSOrderedDescending; }
		
		return NSOrderedSame;
		
		// return [firstYearString compare:secondYearString options:NSNumericSearch];
	}];
	
	return events;
}

- (NSString*)parseEventGroupTitle:(xmlNodePtr)groupNode context:(xmlXPathContextPtr)XPathContext {
	XPathContext->node = groupNode;
	xmlXPathObjectPtr result = xmlXPathEvalExpression(BAD_CAST(".//*[contains(concat(' ', normalize-space(@class), ' '), ' mw-headline ')]"), XPathContext);

	NSString* title = @"";

	if(!xmlXPathNodeSetIsEmpty(result->nodesetval)) {
		xmlNodePtr node = xmlXPathNodeSetItem(result->nodesetval, 0);
		xmlChar* s = xmlNodeGetContent(node);
		
		title = [NSString stringWithUTF8String:(const char*)s];
		
		xmlFree(s);
	}
	
	xmlXPathFreeObject(result);
	
	return title;
}

- (NSDictionary*)parseEvent:(xmlNodePtr)eventNode context:(xmlXPathContextPtr)XPathContext {
	NSMutableDictionary* event = [NSMutableDictionary dictionary];
	
//	// First delete unwatend nodes
//	XPathContext->node = eventNode;
//	[self deleteNodesMatchingExpression:BAD_CAST(".//div") context:XPathContext];
//	XPathContext->node = NULL;
	
	// Now restructe the whole node
	[self restructureEvent:eventNode context:XPathContext];
	
	// Restructure wikipedia internal links
	[self restructureWikipediaLinksInNode:eventNode context:XPathContext];
	
	// Retrieve the year attribute
	NSString* yearString = [self parseYearInNode:eventNode context:XPathContext];
	if(yearString) {
		[event setObject:yearString forKey:@"year"];
	}
	
	// Retrieve the markup string
	NSString* markupString = [self stringFromLibXMLNode:eventNode];
	[event setObject:markupString forKey:@"markup"];
	
	return event;
}

- (void)restructureEventGroups:(xmlDocPtr)document context:(xmlXPathContextPtr)XPathContext {
	xmlXPathObjectPtr result = xmlXPathEvalExpression(BAD_CAST("//li/a[@class='image']"), XPathContext);
	
	if(!result) {
		NSLog(@"Invalid XPath result set");
		return;
	}
	
	NSInteger numberOfImages = xmlXPathNodeSetGetLength(result->nodesetval);
		
	for(NSInteger imageIndex=0; imageIndex<numberOfImages; ++imageIndex) {
		xmlNodePtr imageNode = xmlXPathNodeSetItem(result->nodesetval, imageIndex);
		xmlNodePtr imageListNode = imageNode->parent;
		xmlNodePtr listParentNode = imageNode->parent->parent;
		
		XPathContext->node = imageNode;
		
		xmlXPathObjectPtr titleResult = xmlXPathEvalExpression(BAD_CAST("following-sibling::b[1]"), XPathContext);
		
		if(titleResult) {
			xmlNodePtr titleNode = xmlXPathNodeSetItem(titleResult->nodesetval, 0);
			
			// Make a new year wrapper node
			xmlNodePtr titleListItemNode = xmlNewDocRawNode(
				document,
				NULL,
				BAD_CAST("li"),
				NULL);
			xmlSetProp(titleListItemNode, BAD_CAST("class"), BAD_CAST("subtitle"));
			
			xmlUnlinkNode(titleNode);
			xmlAddChild(titleListItemNode, titleNode);
			xmlAddChild(listParentNode, titleListItemNode);

			xmlXPathFreeObject(titleResult);
		}
		
		xmlXPathObjectPtr eventResult = xmlXPathEvalExpression(BAD_CAST("following-sibling::ul/li"), XPathContext);
		
		if(eventResult) {
			NSInteger numberOfEvents = xmlXPathNodeSetGetLength(eventResult->nodesetval);
			
			for(NSInteger eventIndex=0; eventIndex<numberOfEvents; ++eventIndex) {
				xmlNodePtr eventNode = xmlXPathNodeSetItem(eventResult->nodesetval, eventIndex);
				xmlUnlinkNode(eventNode);
				xmlAddChild(listParentNode, eventNode);
			}
			
			xmlXPathFreeObject(eventResult);
		}
		
		XPathContext->node = NULL;
		
		xmlUnlinkNode(imageListNode);
		xmlFree(imageListNode);
	}
	
	xmlXPathFreeObject(result);
}

- (void)restructureEvent:(xmlNodePtr)node context:(xmlXPathContextPtr)XPathContext {
	NSSet* separators = [self separatorStrings];
	
	xmlNodePtr child = node->children;
	
	// Make a new year wrapper node
	xmlNodePtr yearNode = xmlNewDocRawNode(
		node->doc,
		NULL,
		BAD_CAST("span"),
		NULL);
	xmlSetProp(yearNode, BAD_CAST("class"), BAD_CAST("year"));
	
	// Make a new year wrapper node
	xmlNodePtr contentNode = xmlNewDocRawNode(
		node->doc,
		NULL,
		BAD_CAST("span"),
		NULL);
	xmlSetProp(contentNode, BAD_CAST("class"), BAD_CAST("content"));
	
	// Find the year separator
	NSInteger const maxParseDepth = 16;
	NSInteger parseDepth = 0;
	
	while(1) {
		if(child == NULL) {
			break;
		}
		
		// Look for the separator string in the current text node
		if(xmlNodeIsText(child)) {
			xmlChar* contentString = xmlNodeGetContent(child);
			
			NSString* string = [NSString stringWithUTF8String:(const char*)contentString];
			NSRange range = NSMakeRange(NSNotFound, 0);
			
			for(NSString* separator in separators) {
				range = [string rangeOfString:separator options:NSWidthInsensitiveSearch|NSDiacriticInsensitiveSearch];
				
				if(range.location != NSNotFound) {
					break;
				}
			}
			
			if(range.location != NSNotFound) {
				// Set our year nodes content
				NSString* yearString = [string substringToIndex:range.location];
				
				if(yearString.length > 0) {
					xmlNodeSetContent(yearNode, BAD_CAST([yearString UTF8String]));
				}

				// Adjust the current text nodes content
				NSString* newContentString = [string substringFromIndex:(range.location + 1) + (range.length - 1)];
				xmlNodeSetContent(child, BAD_CAST([newContentString UTF8String]));
				
				// Add all previous siblings to our year node
				NSArray* previousSiblings = [self previousSiblingsForNode:child];
				
				for(NSInteger siblingIndex=previousSiblings.count - 1; siblingIndex >= 0; --siblingIndex) {
					xmlNodePtr previousSibling = [[previousSiblings objectAtIndex:siblingIndex] pointerValue];
					
					xmlUnlinkNode(previousSibling);
					xmlAddChild(yearNode, previousSibling);
				}
				
				// Add the remaining child nodes to our content node
				// xmlAddChildList(contentNode, child);
				
				xmlNodePtr nextSibling = child;
				
				while(nextSibling != NULL) {
					xmlNodePtr nextSibling2 = nextSibling->next;
					
					xmlUnlinkNode(nextSibling);
					xmlAddChild(contentNode, nextSibling);
					
					nextSibling = nextSibling2;
				}
				
				parseDepth = maxParseDepth;
			}
			
			xmlFree(contentString);
			
			if(parseDepth >= maxParseDepth) {
				break;
			}
		}
	
		child = child->next;
		++parseDepth;
	}
	
	if(yearNode->content == NULL && yearNode->children == NULL) {
		child = node->children;
		
		while(1) {
			if(child == NULL) {
				break;
			}
			
			if(child->type == XML_ELEMENT_NODE) {
				if(xmlStrcasecmp(child->name, BAD_CAST("ul")) == 0) {
					NSArray* previousSiblings = [self previousSiblingsForNode:child];
					
					for(NSValue* previousSibling in previousSiblings) {
						xmlNodePtr sibling = [previousSibling pointerValue];
						xmlUnlinkNode(sibling);
						xmlAddChild(yearNode, sibling);
					}
					
					xmlUnlinkNode(child);
					xmlAddChild(contentNode, child);
					
					break;
				}
			}
			
			child = child->next;
		}
	}
	
	if(yearNode->content != NULL || yearNode->children != NULL) {
		xmlAddChild(node, yearNode);
	}

	xmlAddChild(node, contentNode);
	
//	NSLog(@"%@", [self stringFromLibXMLNode:yearNode]);
//	NSLog(@"%@", [self stringFromLibXMLNode:contentNode]);
//	NSLog(@"%@", [self stringFromLibXMLNode:node]);
}

- (void)restructureWikipediaLinksInNode:(xmlNodePtr)node context:(xmlXPathContextPtr)XPathContext {
	XPathContext->node = node;
	
	NSString* hostString = [NSString stringWithFormat:@"%@://%@", [[self wikipediaURL] scheme], [[self wikipediaURL] host]];
	xmlXPathObjectPtr internalLinks = xmlXPathEvalExpression(BAD_CAST(".//a[starts-with(@href, '/wiki/') or starts-with(@href, '/w/')]"), XPathContext);
	
	NSInteger numberOfInternalLinks = xmlXPathNodeSetGetLength(internalLinks->nodesetval);
		
	for(NSInteger internalLinkIndex=0; internalLinkIndex<numberOfInternalLinks; ++internalLinkIndex) {
		xmlNodePtr internalLink = xmlXPathNodeSetItem(internalLinks->nodesetval, internalLinkIndex);
		
		xmlChar* resource = xmlGetProp(internalLink, BAD_CAST("href"));
		NSString* newResource = [hostString stringByAppendingFormat:@"%s", resource];
		
		xmlSetProp(internalLink, BAD_CAST("href"), BAD_CAST([newResource UTF8String]));
		xmlFree(resource);
	}

	xmlXPathFreeObject(internalLinks);
	XPathContext->node = NULL;
}

- (NSString*)parseYearInNode:(xmlNodePtr)node context:(xmlXPathContextPtr)XPathContext {
	XPathContext->node = node;
	
	NSString* yearString = nil;
	
	xmlXPathObjectPtr xpath = xmlXPathEvalExpression(BAD_CAST(".//*[@class='year']/a/@title"), XPathContext);
	
	NSInteger numberOfTitleAttributes = xmlXPathNodeSetGetLength(xpath->nodesetval);
	
	if(numberOfTitleAttributes == 0) {
		xmlXPathFreeObject(xpath);
		
		xpath = xmlXPathEvalExpression(BAD_CAST(".//*[@class='year']/text()"), XPathContext);
		numberOfTitleAttributes = xmlXPathNodeSetGetLength(xpath->nodesetval);
	}
	
	if(numberOfTitleAttributes > 0) {
		xmlChar* s = xmlXPathCastNodeToString(xmlXPathNodeSetItem(xpath->nodesetval, 0));
		yearString = [NSString stringWithUTF8String:(const char*)s];
	}
	
	xmlXPathFreeObject(xpath);
	XPathContext->node = NULL;
	
	return yearString;
}

- (NSSet*)separatorStrings {
	NSString* languageCode = [[self wikipediaURL] wikipediaLanguageCode];
	
	if([languageCode isEqualToString:@"en"]) {
		return  [NSSet setWithObject:@"\u2013"];
	}
	
	if([languageCode isEqualToString:@"de"]) {
		return  [NSSet setWithObject:@":"];
	}
	
	if([languageCode isEqualToString:@"fr"]) {
		return [NSSet setWithObjects:@"\u00a0:", @" :", @"\u00a0:", nil];
	}
	
	if([languageCode isEqualToString:@"it"]) {
		return  [NSSet setWithObjects:@" -", @"- ", nil];
	}
	
	if([languageCode isEqualToString:@"nl"]) {
		return  [NSSet setWithObjects:@" -", @"- ", nil];
	}
	
	if([languageCode isEqualToString:@"es"]) {
		return  [NSSet setWithObject:@":"];
	}
	
	if([languageCode isEqualToString:@"ja"]) {
		return  [NSSet setWithObjects:@" -", @"- ", @"）-", nil];
	}
	
	return [NSSet setWithObject:@" -"];
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

- (NSArray*)previousSiblingsForNode:(xmlNodePtr)node {
	NSMutableArray* previousSiblings = [NSMutableArray array];
	
	xmlNodePtr sibling = node;
	
	while(sibling->prev != NULL) {
		sibling = sibling->prev;

		NSValue* value = [NSValue valueWithPointer:sibling];
		[previousSiblings addObject:value];
	}
	
	return previousSiblings;
}

- (void)deleteNodesMatchingExpression:(const xmlChar*)XPath context:(xmlXPathContextPtr)XPathContext {
	xmlXPathObjectPtr result = xmlXPathEvalExpression(XPath, XPathContext);
	
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

- (NSString*)yearStringFromString:(NSString*)string {
	if(!string) { return nil; }
	
	if([string rangeOfString:@"BC"].location != NSNotFound || 
	   [string rangeOfString:@"v. Chr."].location != NSNotFound) {
		NSScanner* scanner = [NSScanner scannerWithString:string];
		
		if([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&string]) {
			string = [@"-" stringByAppendingString:string];
		}
	}
	
	return string;
}

@end
