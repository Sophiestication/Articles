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

#import "ARKHTMLMarkupFormatter.h"

#import <libxml/HTMLparser.h>
#import <libxml/xpath.h>

@interface ARKHTMLMarkupFormatter()

@property(nonatomic, copy) NSDictionary* styles;
@property(nonatomic, strong) NSCharacterSet* requiredCharacters;

@end

@implementation ARKHTMLMarkupFormatter

- (id)init {
	if((self = [super init])) {
		NSCharacterSet* characterSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
		self.requiredCharacters = characterSet;

		[self initDefaultStyles];
	}

	return self;
}

#pragma mark - ARKHTMLMarkupFormatter

/* - (void)setContentFontDescriptor:(UIFontDescriptor*)contentFontDescriptor {
	if([[self contentFontDescriptor] isEqual:contentFontDescriptor]) { return; }
	
	_contentFontDescriptor = [contentFontDescriptor copy];
	[self initDefaultStylesWithTextKit];
} */

- (NSAttributedString*)attributedStringFromString:(NSString*)string error:(NSError* __autoreleasing*)error {
	if(string.length == 0) { return nil; }
	
	NSData* buffer = [string dataUsingEncoding:NSUTF8StringEncoding];

	int parserOptions = HTML_PARSE_NOBLANKS|HTML_PARSE_RECOVER|HTML_PARSE_NONET/*|HTML_PARSE_NOIMPLIED*/|HTML_PARSE_NODEFDTD;
	if(YES) { parserOptions |= HTML_PARSE_NOERROR|HTML_PARSE_NOWARNING; }

	htmlDocPtr document = htmlReadMemory(
		[buffer bytes],
		[buffer length],
		NULL,
		NULL,
		parserOptions);

	if(document == NULL) {
		NSError* parserError =  [NSError errorWithDomain:NSXMLParserErrorDomain code:NSXMLParserInternalError userInfo:nil];
		if(error) { *error = parserError; }

		NSLog(@"Could not parse HTML markup string: %@", string);

		return nil;
	}

	NSAttributedString* attributedString = [self formatHTMLDocument:document error:error];

	if(!attributedString) {
		NSLog(@"Could not format HTML markup string: %@", string);
	}
	
	if(document) { xmlFreeDoc(document); }

	return attributedString;
}

- (NSString*)stringFromString:(NSString*)string error:(NSError* __autoreleasing*)error {
	return [[self attributedStringFromString:string error:error] string]; // good enough for now
}

#pragma mark - Private

- (void)initDefaultStyles {
	CGFloat fontSize = 13.0;

	self.styles = @{
		@"body": @{
			NSFontAttributeName: [UIFont systemFontOfSize:fontSize] },
		@"b": @{
			NSFontAttributeName: [UIFont systemFontOfSize:fontSize] },
		@"i": @{
			NSFontAttributeName: [UIFont italicSystemFontOfSize:fontSize] }
	};
}

- (void)initDefaultStylesWithTextKit {
/*	NSMutableParagraphStyle* paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	paragraphStyle.hyphenationFactor = 1.0;

	self.styles = @{
		@"body": @{
			NSParagraphStyleAttributeName: paragraphStyle },
//		@"b": @{
//			UIFontDescriptorTraitsAttribute: @{ UIFontSymbolicTrait: @(UIFontDescriptorTraitBold) },
//			NSParagraphStyleAttributeName: paragraphStyle },
		@"i": @{
			UIFontDescriptorTraitsAttribute: @{ UIFontSymbolicTrait: @(UIFontDescriptorTraitItalic) },
			NSParagraphStyleAttributeName: paragraphStyle }
	}; */
}

- (NSAttributedString*)formatHTMLDocument:(htmlDocPtr)document error:(NSError* __autoreleasing*)error {
	__block NSMutableAttributedString* attributedString = [[NSMutableAttributedString alloc] init];
	
	[attributedString beginEditing];

	// NSString* XPath = @"//body//node()[not(ancestor-or-self::dl)]";
	NSString* XPath = @"//body//node()";

	[self enumerateChildrenOfDocument:document matchingExpression:XPath usingBlock:^(xmlNodePtr node, BOOL* stop) {
		const xmlChar* buffer = node->content;
		int bufferSize = xmlStrlen(buffer);

		NSString* substring = buffer && bufferSize > 0 ?
			[[NSString alloc] initWithBytes:buffer length:bufferSize encoding:NSUTF8StringEncoding] : nil;
			
		if(substring.length == 0) { return; }
		if(![self isValidSubstring:substring]) { return; }
		
		NSDictionary* styles = [self styleAttributesForNode:node];
		NSAttributedString* attributedSubstring = [[NSAttributedString alloc]
			initWithString:substring
			attributes:styles];
		[attributedString appendAttributedString:attributedSubstring];
	}];
	
	[attributedString endEditing];

	return attributedString;
}

- (NSDictionary*)styleAttributesForNode:(xmlNodePtr)node {
	NSMutableArray* parentStyles = [NSMutableArray array];
	
	[self enumerateParentElementsOfNode:node usingBlock:^(xmlNodePtr element, BOOL* stop) {
		const xmlChar* buffer = element->name;
		int bufferSize = xmlStrlen(buffer);
		
		NSString* tagName = [[NSString alloc] initWithBytesNoCopy:(void*)buffer length:bufferSize encoding:NSUTF8StringEncoding freeWhenDone:NO];
		
		NSDictionary* style = [self styleAttributesForTag:tagName];
		if(style) { [parentStyles addObject:style]; }
	}];
	
	NSMutableDictionary* styles = [NSMutableDictionary dictionary];
	
	for(NSDictionary* parentStyle in [parentStyles reverseObjectEnumerator]) {
		[styles addEntriesFromDictionary:parentStyle];
	}

/*	NSDictionary* traits = styles[UIFontDescriptorTraitsAttribute];
	UIFontDescriptor* contentFontDescriptor = self.contentFontDescriptor;

	if(traits && contentFontDescriptor) {
		UIFontDescriptorSymbolicTraits symbolicTraits = [[traits objectForKey:UIFontSymbolicTrait] integerValue];
		UIFontDescriptor* descriptor = [contentFontDescriptor
			fontDescriptorWithSymbolicTraits:symbolicTraits];

		styles[NSFontAttributeName] = [UIFont fontWithDescriptor:descriptor size:0.0];
		[styles removeObjectForKey:UIFontDescriptorTraitsAttribute];
	} */
	
	return  styles;
}

- (NSDictionary*)styleAttributesForTag:(NSString*)tag {
	tag = [tag lowercaseString];
	return [[self styles] objectForKey:tag];
}

- (void)enumerateChildrenOfDocument:(htmlDocPtr)document matchingExpression:(NSString*)XPath usingBlock:(void (^)(xmlNodePtr node, BOOL* stop))block {
	if(document == NULL) { return; }
	if(XPath.length == 0) { return; }

	xmlXPathContextPtr context = xmlXPathNewContext(document);
	if(context == NULL) { return; }

	xmlXPathObjectPtr resultSet = xmlXPathEvalExpression(BAD_CAST([XPath UTF8String]), context);

	if(resultSet && resultSet->type == XPATH_NODESET) {
		xmlNodeSetPtr nodes = resultSet->nodesetval;
		NSUInteger numberOfResultItems = xmlXPathNodeSetGetLength(nodes);

		BOOL shouldStop = NO;

		for(NSUInteger index = 0; index < numberOfResultItems; ++index) {
			xmlNodePtr node = nodes->nodeTab[index];

			block(node, &shouldStop);
			if(shouldStop) { break; }
		}
	}

	if(resultSet) { xmlXPathFreeObject(resultSet); }
	if(context) { xmlXPathFreeContext(context); }
}

- (void)enumerateParentElementsOfNode:(xmlNodePtr)node usingBlock:(void (^)(xmlNodePtr node, BOOL* stop))block {
	BOOL shouldStop = NO;
	
	for(xmlNodePtr current = node; current != NULL; current = current->parent) {
		if(current->type != XML_ELEMENT_NODE) { continue; }
		
		block(current, &shouldStop);
		if(shouldStop) { break; }
	}
}

- (BOOL)isValidSubstring:(NSString*)substring {
	if([substring hasPrefix:@"Coordinates: "]) { return NO; }
	if([substring hasPrefix:@" ([Image] listen)"]) { return NO; }
	
	NSRange range = [substring rangeOfCharacterFromSet:[self requiredCharacters]];
	if(range.location == NSNotFound) { return NO; }
	
	return YES;
}

@end
