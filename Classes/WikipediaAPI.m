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

#import "WikipediaAPI.h"
#import "WikipediaAPI+Private.h"

#import "NSURL+Wikipedia.h"

@implementation WikipediaAPI

NSString* const WPMatchingArticlesKey = @"articles";
NSString* const WPArticleTitleKey = @"title";
NSString* const WPArticleSummaryKey = @"snippet";
NSString* const WPSearchResultOffsetKey = @"offset";
NSString* const WPSpellingSuggestionKey = @"suggestion";
NSString* const WPPageLimitOption = @"srlimit";
NSString* const WPContinuePagingOffsetOption = @"sroffset";
NSString* const WPNumberOfArticlesKey = @"totalhits";

@dynamic baseURLString;

#pragma mark -
#pragma mark Construction & Destruction

- (id)init {
	if((self = [super init])) {
	}
	
	return self;
}

#pragma mark -
#pragma mark WikipediaAPI

- (NSString*)baseURLString {
	NSString* languageCode = self.preferredLanguage.length > 0 ?
		self.preferredLanguage :
		@"en";
	return [NSString stringWithFormat:@"http://%@.wikipedia.org", languageCode];
}

- (RKTransaction*)autocompleteArticleTitle:(NSString*)searchString options:(NSDictionary*)options {
	// First check if we have a valid string
	if(searchString.length <= 0) {
		return nil;
	}
	
	// Now prepare the transaction
	NSMutableDictionary* parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		@"json", @"format",
		@"opensearch", @"action",
		searchString, @"search",
		@(15), @"limit",
		nil];
	if(options) {
		[parameters addEntriesFromDictionary:options];
	}
		
	NSURL* URL = [NSURL URLWithString:[self APIURLString] parameters:parameters];
	
	RKTransaction* transaction = [RKTransaction transactionWithURL:URL];

	transaction.resultFormatter = [WPAutocompleteSearchResultFormatter formatter];
	transaction.delegate = self.transactionDelegate;
	
	return transaction;
}

- (RKTransaction*)findArticlesByString:(NSString*)searchString scope:(WPSearchScope)scope options:(NSDictionary*)options {
	if(searchString.length == 0) { return nil; }

	if(scope == WPSearchScopeTitle) {
		return [self autocompleteArticleTitle:searchString options:nil];

//		if(![searchString hasPrefix:@"intitle:"]) { searchString = [@"intitle:" stringByAppendingString:searchString]; }
//		if(![searchString hasSuffix:@"*"]) { searchString = [searchString stringByAppendingString:@"*"]; }
	}

	NSString* properties = scope == WPSearchScopeTitle ?
		@"" :
		@"snippet";
	
	// Now prepare the transaction
	NSMutableDictionary* parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		@"json", @"format",
		@"query", @"action",
		@"search", @"list",
		@"text", @"srwhat",
		@"totalhits", @"srinfo",
		@"1", @"srredirects",
		searchString, @"srsearch",
		@"3", @"srlimit",
		properties, @"srprop",
		nil];
	if(options) {
		[parameters addEntriesFromDictionary:options];
	}
		
	NSURL* URL = [NSURL URLWithString:[self APIURLString] parameters:parameters];
	
	RKTransaction* transaction = [RKTransaction transactionWithURL:URL];
	
	transaction.resultFormatter = [WPQuerySearchResultFormatter formatter];
	transaction.delegate = self.transactionDelegate;
	
	return transaction;
}

- (RKTransaction*)articleForTitle:(NSString*)articleTitle options:(NSDictionary*)options {
	NSURL* articleURL = [self articleURLForTitle:articleTitle];
	return [self articleForURL:articleURL options:options];
}

- (RKTransaction*)articleForURL:(NSURL*)articleURL options:(NSDictionary*)options {
	NSURLRequest* request = [NSURLRequest requestWithURL:articleURL];
	
	RKTransaction* transaction = [RKTransaction transactionWithURLRequest:request];
	transaction.delegate = self.transactionDelegate;
	return transaction;
}

- (NSURL*)featuredArticleURLForDate:(NSDate*)date options:(NSDictionary*)options {
	return nil;
}

- (NSURL*)filePathForResourceURL:(NSURL*)resourceURL options:(NSDictionary*)options {
	if(!resourceURL) { return nil; }

	resourceURL = [resourceURL standardizedURL];

	NSDictionary* parameters = [resourceURL parameters];
	NSString* resource = nil;
	
	resource = [parameters objectForKey:@"title"];
	if(resource.length == 0) { resource = [resourceURL lastPathComponent]; }
	
	NSRange range = [resource rangeOfString:@":"];
	if(range.location != NSNotFound) { resource = [resource substringFromIndex:range.location + range.length]; }

	NSString* baseURLString = [NSString stringWithFormat:@"%@://%@",
		[resourceURL scheme],
		[resourceURL host]];
	NSURL* baseURL = [NSURL URLWithString:baseURLString];

	NSURL* fileURL = [[[baseURL
		URLByAppendingPathComponent:@"wiki"]
		URLByAppendingPathComponent:@"Special:FilePath"]
		URLByAppendingPathComponent:resource];

	return fileURL;
}

+ (NSRegularExpression*)sharedThumbnailSizeRegularExpression {
	static NSRegularExpression* _wik_sharedThumbnailSizeRegularExpression = nil;
    static dispatch_once_t _wik_sharedThumbnailSizeRegularExpressionOnce;

    dispatch_once(&_wik_sharedThumbnailSizeRegularExpressionOnce, ^{
		_wik_sharedThumbnailSizeRegularExpression = [NSRegularExpression
			regularExpressionWithPattern:@"^\\d+px-"
			options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators
			error:nil];
    });

    return _wik_sharedThumbnailSizeRegularExpression;
}

- (NSURL*)thumbnailURLWithWidth:(CGFloat)imageWidth forURL:(NSURL*)URL {
	NSString* fileName = [URL lastPathComponent];
	
	NSString* imageWidthString = [NSString stringWithFormat:@"%ldpx-", (long)imageWidth];
	NSString* newFileName = [[[self class] sharedThumbnailSizeRegularExpression]
		stringByReplacingMatchesInString:fileName
		options:0
		range:NSMakeRange(0, [fileName length])
		withTemplate:imageWidthString];
	
	NSURL* newURL = [URL URLByDeletingLastPathComponent];
	newURL = [newURL URLByAppendingPathComponent:newFileName];
	
	return newURL;
}

- (NSURL*)articleURLForTitle:(NSString*)articleTitle {
	if(articleTitle.length == 0) { return nil; }
	
	NSString* newTitle = [self normalizedTitleString:articleTitle];
		
	NSURL* baseURL = [NSURL URLWithString:[self baseURLString]];
	NSURL* URL = [[baseURL
		URLByAppendingPathComponent:@"wiki"]
		URLByAppendingPathComponent:newTitle];
	
	return URL;
}

- (NSURL*)randomArticleURL {
	return [self articleURLForTitle:@"Special:Random"];
}

- (NSURL*)eventURLForDate:(NSDate*)date {
	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	
	NSString* languageCode = self.preferredLanguage ?
		self.preferredLanguage :
		@"en";
	
	NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:languageCode];
	[formatter setLocale:locale];
	
	if([languageCode isEqualToString:@"de"]) {
		[formatter setDateFormat:@"d._MMMM"];
	} else if([languageCode isEqualToString:@"fr"]) {
		[formatter setDateFormat:@"d_MMMM"];
	} else {
		// We default to english
		[formatter setDateFormat:@"MMMM_dd"];
	}
	
	NSString* pageTitle = [formatter stringFromDate:date];
	
	return [self articleURLForTitle:pageTitle];
}

#pragma mark -
#pragma mark Private

- (NSString*)APIURLString {
	NSString* URLString = [NSString stringWithFormat:@"http://%@.wikipedia.org/w/api.php",
		self.preferredLanguage.length > 0 ? self.preferredLanguage : @"en"];
	return URLString;
}

- (NSString*)URLEncodeParameter:(NSString*)parameterString {
	NSString* encodedString = (NSString*)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
		kCFAllocatorDefault, 
		(CFStringRef)parameterString, 
		NULL, 
		CFSTR("!*'();:@&=+$,/?%#[]"),
		kCFStringEncodingUTF8));
		
	return encodedString;
}

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

#pragma mark -
#pragma mark WPAutocompleteSearchResultFormatter

@implementation WPAutocompleteSearchResultFormatter

- (id)formatResultData:(NSData*)resultData error:(NSError**)error response:(NSURLResponse*)response {
	id resultObject = [super formatResultData:resultData error:error response:response];
	NSArray* foundArticleTitles;

	if([resultObject isKindOfClass:[NSDictionary class]]) {
		foundArticleTitles = [resultObject objectForKey:@"1"];
	} else if([resultObject isKindOfClass:[NSArray class]]) {
		foundArticleTitles = [resultObject count] > 1 ?
			[resultObject objectAtIndex:1] :
			nil;
	}
	
	NSMutableArray* searchResults = [NSMutableArray arrayWithCapacity:[foundArticleTitles count]];
	
	for(NSString* title in foundArticleTitles) {
		NSDictionary* searchResult = [NSDictionary dictionaryWithObjectsAndKeys:
			title, WPArticleTitleKey,
			nil];
		[searchResults addObject:searchResult];
	}
	
	return [NSDictionary
		dictionaryWithObject:searchResults
		forKey:WPMatchingArticlesKey];
}

@end

#pragma mark -
#pragma mark WPQuerySearchResultFormatter

@implementation WPQuerySearchResultFormatter

- (id)formatResultData:(NSData*)resultData error:(NSError**)error response:(NSURLResponse*)response {
	NSDictionary* resultDictionary = [super formatResultData:resultData error:error response:response];
	
	NSArray* searchResults = [[resultDictionary objectForKey:@"query"] objectForKey:@"search"];
	
	if(!searchResults) {
		searchResults = [NSArray array];
	}
	
	NSInteger offset = [[[[resultDictionary
		objectForKey:@"query-continue"]
		objectForKey:@"search"]
		objectForKey:@"sroffset"]
		integerValue];
	NSNumber* offsetValue = offset > 0 ?
		[NSNumber numberWithInteger:offset] :
		nil;
		
	NSString* spellingSuggestion = [[[resultDictionary
		objectForKey:@"query"]
		objectForKey:@"searchinfo"]
		objectForKey:@"suggestion"];
		
	NSString* numberOfArticles = [[[resultDictionary
		objectForKey:@"query"]
		objectForKey:@"searchinfo"]
		objectForKey:@"totalhits"];
		
	NSMutableDictionary* result = [NSMutableDictionary dictionary];

	[result setValue:searchResults forKey:WPMatchingArticlesKey];
	[result setValue:offsetValue forKey:WPSearchResultOffsetKey];
	[result setValue:spellingSuggestion forKey:WPSpellingSuggestionKey];
	[result setValue:numberOfArticles forKey:WPNumberOfArticlesKey];
	
	return result;
}

@end
