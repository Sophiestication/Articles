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

#import <Foundation/Foundation.h>
#import <libxml/tree.h>
#import <libxml/xpath.h>

@interface AKArchiveOperation()

@property(nonatomic) long long expectedContentLength;
@property(nonatomic) unsigned long long numberOfBytesTransferred;

@property(nonatomic, strong) NSMutableArray* images;
@property(nonatomic, strong) NSMutableSet* imageNodesNeedingRelease;
@property(nonatomic, strong) NSMutableArray* tables;
@property(nonatomic, strong) NSMutableArray* languages;
@property(nonatomic, strong) NSMutableArray* TOC;

- (NSString*)stylesheetURLString;
- (NSString*)stringFromLibXMLNode:(xmlNodePtr)node;

- (void)appendSupportFiles:(xmlNodePtr)header;
- (void)appendClass:(NSString*)classString toNode:(xmlNodePtr)node;

- (BOOL)array:(NSArray*)array containsObjectsInSet:(NSSet*)set;

- (xmlNodePtr)findNodeById:(NSString*)nodeId withContext:(xmlXPathContextPtr)XPathContext;
- (xmlNodePtr)findFirstNodeByClass:(NSString*)nodeClass withContext:(xmlXPathContextPtr)XPathContext;
- (xmlNodePtr)parentWithName:(const xmlChar*)name forNode:(xmlNodePtr)node;
- (xmlNodePtr)parentAnchorForNode:(xmlNodePtr)node;
- (xmlNodePtr)parentWithClass:(NSString*)classString forNode:(xmlNodePtr)node context:(xmlXPathContextPtr)context;

- (NSString*)contentForChildOfClass:(const xmlChar*)class ofNode:(xmlNodePtr)node context:(xmlXPathContextPtr)XPathContext;

- (NSArray*)classStringsForNode:(xmlNodePtr)node;
- (void)setClasses:(NSArray*)classes forNode:(xmlNodePtr)node;

- (void)removeAllInlineStylesFromNode:(xmlNodePtr)parentNode context:(xmlXPathContextPtr)XPathContext;

- (void)parseTOC:(xmlDocPtr)document context:(xmlXPathContextPtr)XPathContext;
- (void)parseAlternateLanguages:(xmlDocPtr)document context:(xmlXPathContextPtr)XPathContext;

- (void)restructureHeader:(xmlDocPtr)document context:(xmlXPathContextPtr)XPathContext;
- (void)restructureDocument:(xmlDocPtr)document context:(xmlXPathContextPtr)XPathContext;
- (void)restructureTables:(xmlDocPtr)document context:(xmlXPathContextPtr)XPathContext;
- (void)restructureImages:(xmlDocPtr)document context:(xmlXPathContextPtr)XPathContext;
- (void)restructureImage:(xmlNodePtr)imageNode context:(xmlXPathContextPtr)XPathContext;
- (BOOL)isThumbnailImage:(xmlNodePtr)imageNode context:(xmlXPathContextPtr)XPathContext;
- (xmlNodePtr)wrapperForImageNode:(xmlNodePtr)imageNode context:(xmlXPathContextPtr)XPathContext;
- (xmlNodePtr)placeholderForImageNode:(xmlNodePtr)imageNode wrapper:(xmlNodePtr)wrapperNode imageID:(NSString*)imageID classes:(NSArray*)classes context:(xmlXPathContextPtr)XPathContext;
- (xmlNodePtr)findFirstTableHeader:(xmlNodePtr)node context:(xmlXPathContextPtr)XPathContext;
- (xmlNodePtr)singleCellTableContent:(xmlNodePtr)tableNode context:(xmlXPathContextPtr)XPathContext;
- (BOOL)isEmptyTable:(xmlNodePtr)tableNode context:(xmlXPathContextPtr)XPathContext;

- (NSArray*)adjustWrapperNodeClassesIfNeeded:(xmlNodePtr)wrapperNode classes:(NSArray*)classes context:(xmlXPathContextPtr)XPathContext;

- (void)deleteUnwantedNodes:(xmlDocPtr)document context:(xmlXPathContextPtr)XPathContext;
- (void)deleteNodesMatchingExpression:(const xmlChar*)XPath context:(xmlXPathContextPtr)XPathContext;
- (void)deleteReferencesChapter:(xmlXPathContextPtr)XPathContext;

- (void)fixWikipediaLinks:(xmlXPathContextPtr)XPathContext;
- (xmlNodePtr)previousElement:(xmlNodePtr)node;
- (xmlNodePtr)nextElement:(xmlNodePtr)node;

- (BOOL)shouldForceLeftOrientation:(xmlNodePtr)node;
- (BOOL)shouldForceRightOrientation:(xmlNodePtr)node;

- (void)addPageFooter:(xmlNodePtr)node context:(xmlXPathContextPtr)XPathContext;

- (void)postDocumentLoadProgress;
- (void)postDocumentLoadProgress:(float)progress;
- (void)postDocumentParseProgress:(float)progress;

@end
