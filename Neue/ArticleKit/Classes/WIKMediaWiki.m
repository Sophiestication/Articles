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

#import "WIKMediaWiki.h"
#import "WIKPage+Private.h"
#import "WIKMediaWikiClient.h"

@interface WIKMediaWiki()

@property(nonatomic, readwrite, copy) NSURL* URL;
@property(nonatomic, readwrite, strong) WIKMediaWikiClient* client;
@property(nonatomic, strong) NSRegularExpression* normalizedTitleStringRegEx;

@property(nonatomic, strong) NSCache* pageCache;

@end

@implementation WIKMediaWiki

#pragma mark - Construction & Destruction

- (id)initWithURL:(NSURL*)URL {
	NSParameterAssert(URL);
	if(!URL) { return nil; }

	if((self = [super init])) {
		self.URL = URL;
		self.pageCache = [[NSCache alloc] init];
	}

	return self;
}

#pragma mark - WIKMediaWiki

- (WIKMediaWikiClient*)client {
	if(!_client) { _client = [WIKMediaWikiClient clientWithBaseURL:[self URL]]; }
	return _client;
}

- (WIKPage*)pageForIdentifier:(id)identifier {
	WIKPage* page = [[self pageCache] objectForKey:identifier];

	if(!page) {
		page = [[WIKPage alloc] initWithIdentifier:identifier mediaWiki:self];
		[[self pageCache] setObject:page forKey:identifier];
	}

	return page;
}

- (NSURL*)URLForPageTitle:(NSString*)pageTitle {
	if(pageTitle.length == 0) { return nil; }
	
	NSString* newTitle = [self normalizedTitleString:pageTitle];
		
	NSURL* URL = [[[self URL]
		URLByAppendingPathComponent:@"wiki" isDirectory:YES]
		URLByAppendingPathComponent:newTitle];
	
	return URL;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
	if(self == object) { return YES; }
	if(![object isKindOfClass:[self class]]) { return NO; }
	return [[self URL] isEqual:[object URL]];
}

- (NSUInteger)hash {
	return [[self URL] hash];
}

- (NSString*)description {
	return [NSString stringWithFormat:@"%@ %@",
		[super description],
		[[self URL] absoluteString]];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone*)zone {
	WIKMediaWiki* copy = [[WIKMediaWiki allocWithZone:zone] initWithURL:[self URL]];

	copy.normalizedTitleStringRegEx = self.normalizedTitleStringRegEx;

	return copy;
}

#pragma mark - Private

- (NSString*)normalizedTitleString:(NSString*)titleString {
	if(!self.normalizedTitleStringRegEx) {
		self.normalizedTitleStringRegEx = [NSRegularExpression
			regularExpressionWithPattern:@"\\s+"
			options:NSRegularExpressionDotMatchesLineSeparators
			error:nil];
	}

	NSString* newTitleString = [[self normalizedTitleStringRegEx]
		stringByReplacingMatchesInString:titleString
		options:0
		range:NSMakeRange(0, [titleString length])
		withTemplate:@"_"];

	return newTitleString;
}

@end

#pragma mark - WIKMediaWiki+Wikipedia

@implementation WIKMediaWiki(Wikipedia)

+ (WIKMediaWiki*)mediaWikiForWikipediaSubdomain:(NSString*)subdomain {
	NSString* wikipediaURLString = [NSString stringWithFormat:@"http://%@.wikipedia.org/", subdomain];
	NSURL* wikipediaURL = [NSURL URLWithString:wikipediaURLString];

	return [[self alloc] initWithURL:wikipediaURL];
}

@end
