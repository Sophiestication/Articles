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

#import <libxml/tree.h>
#import <libxml/xpath.h>

@interface SDWikipediaEventImporter()

@property(nonatomic, readwrite, strong) NSURL* wikipediaURL;
@property(nonatomic, strong) NSArray* eventGroups;

- (void)parseAllEventGroups:(xmlXPathContextPtr)XPathContext;
- (NSArray*)parseEventsInGroup:(xmlNodePtr)groupNode context:(xmlXPathContextPtr)XPathContext;
- (NSString*)parseEventGroupTitle:(xmlNodePtr)groupNode context:(xmlXPathContextPtr)XPathContext;
- (NSDictionary*)parseEvent:(xmlNodePtr)eventNode context:(xmlXPathContextPtr)XPathContext;
- (NSString*)parseYearInNode:(xmlNodePtr)node context:(xmlXPathContextPtr)XPathContext;

- (void)restructureEventGroups:(xmlDocPtr)document context:(xmlXPathContextPtr)XPathContext;
- (void)restructureEvent:(xmlNodePtr)node context:(xmlXPathContextPtr)XPathContext;
- (void)restructureWikipediaLinksInNode:(xmlNodePtr)node context:(xmlXPathContextPtr)XPathContext;

- (NSSet*)separatorStrings;

- (xmlNodePtr)parentWithName:(const xmlChar*)name forNode:(xmlNodePtr)node;
- (NSArray*)previousSiblingsForNode:(xmlNodePtr)node;

- (void)deleteNodesMatchingExpression:(const xmlChar*)XPath context:(xmlXPathContextPtr)XPathContext;

- (NSString*)stringFromLibXMLNode:(xmlNodePtr)node;
- (NSString*)yearStringFromString:(NSString*)string;

@end
