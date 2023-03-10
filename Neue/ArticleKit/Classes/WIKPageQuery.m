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

#import "WIKPageQuery.h"

#import "WIKMediaWikiClient.h"
#import "WIKQueryEnumerator.h"
#import "WIKOpensearchRequestOperation.h"

#import "WIKPredicateFormatter.h"

#import "WIKPage.h"

#import "WIKProperty+Mutating.h"

@interface WIKPageQuery()

@property(nonatomic, readwrite, copy) WIKPredicate* predicate;
@property(nonatomic, readwrite, strong) WIKMediaWiki* mediaWiki;

@property(nonatomic, copy) void (^completionBlock)(WIKPageQuery* query, NSArray* pages, NSError* error);

@property(nonatomic, readwrite) BOOL continuing;
@property(nonatomic, readwrite) BOOL canFetchNext;
@property(nonatomic, readwrite) BOOL fetching;
@property(nonatomic, readwrite) BOOL cancelled;

@property(nonatomic) NSUInteger preferredFetchBatchSize;

@property(nonatomic, strong) WIKQueryEnumerator* runningQueryEnumerator;
@property(nonatomic, strong) NSArray* queuedResultItems;

@property(nonatomic) BOOL needsToRunOpensearchOperation;
@property(nonatomic) BOOL opensearchOperationRunning;
@property(nonatomic, copy) NSArray* openSearchResultItems;

@property(nonatomic, strong) NSMutableSet* enumeratedPageTitles; // workaround for a media wiki bug

@end

@implementation WIKPageQuery

#pragma mark - Construction & Destruction

+ (instancetype)queryForPredicate:(WIKPredicate*)predicate mediaWiki:(WIKMediaWiki*)mediaWiki completion:(void (^)(WIKPageQuery* query, NSArray* pages, NSError* error))completion {
	if(predicate.tokens.count == 0) { return nil; }

	WIKPageQuery* query = [[self alloc] initWithPredicate:predicate mediaWiki:mediaWiki completion:completion];
	return query;
}

- (id)init {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithPredicate:(WIKPredicate*)predicate mediaWiki:(WIKMediaWiki*)mediaWiki completion:(void (^)(WIKPageQuery* query, NSArray* pages, NSError* error))completion {
	if((self = [super init])) {
		self.predicate = predicate;
		self.mediaWiki = mediaWiki;

		self.completionBlock = completion;

		self.preferredFetchBatchSize = 10;

		self.continuing = NO;

		self.canFetchNext = YES;
		self.needsToRunOpensearchOperation = YES;
	}

	return self;
}

#pragma mark - WIKPageQuery

- (BOOL)fetchNext {
	if(self.fetching) { return NO; }
	if(!self.canFetchNext) { return NO; }

	self.cancelled = NO;

	[self fetchOpenSearchResultsIfNeeded];

	WIKQueryEnumerator* enumerator = self.runningQueryEnumerator;

	if(!enumerator) {
		enumerator = [self newQueryEnumerator];
		
		__block __weak WIKPageQuery* query = self;

		[enumerator setCompletionBlock:^(WIKQueryEnumerator* enumerator, id responseObject, NSError* error) {
			if(enumerator != query.runningQueryEnumerator) { return; } // do nothing

			BOOL canRequestNext = [[query runningQueryEnumerator] canRequestNext];
			if(!canRequestNext) { query.runningQueryEnumerator = nil; }

			self.canFetchNext = canRequestNext;
			self.fetching = NO;

			if(error) {
				[query finalizeBatchWithResultItems:nil error:error];
			} else {
				NSArray* resultItems = [query resultsFromResponseObject:responseObject];

				[self loadPropertiesForResultItemsIfNeeded:resultItems completion:^(NSError* error) {
					[self finalizeBatchWithResultItems:resultItems error:error];
				}];
			}
		}];

		self.runningQueryEnumerator = enumerator;
	}

	BOOL fetching = [enumerator requestNext];
	self.fetching = fetching;

	return fetching;
}

- (void)cancel {
	[[self runningQueryEnumerator] cancel];
	self.runningQueryEnumerator = nil;

	self.continuing = NO;
}

#pragma mark - Private

- (WIKQueryEnumerator*)newQueryEnumerator {
	NSString* string = [WIKPredicateFormatter queryStringForPredicate:[self predicate]];
	if(string.length == 0) { return nil; }
	
	NSMutableDictionary* parameters = [NSMutableDictionary dictionaryWithCapacity:5];
	
	parameters[@"list"] = @"search";
	parameters[@"srwhat"] = @"text";
	parameters[@"srinfo"] = @"totalhits";
	parameters[@"srsearch"] = string;
	parameters[@"srprop"] = [NSNull null];
	parameters[@"srredirects"] = [NSNull null];
	
	if(self.preferredFetchBatchSize > 0) {
		parameters[@"srlimit"] = @(self.preferredFetchBatchSize);
	}

	WIKMediaWikiClient* client = self.mediaWiki.client;

	WIKQueryEnumerator* enumerator = [[WIKQueryEnumerator alloc]
		initWithParameters:parameters
		client:client
		shouldContinue:YES];

	return enumerator;
}

- (NSArray*)resultsFromResponseObject:(id)responseObject {
	NSArray* responseArray = [responseObject mutableArrayValueForKeyPath:@"search"];
	
	NSMutableArray* result = [NSMutableArray arrayWithCapacity:[responseArray count]];
	WIKMediaWiki* mediaWiki = self.mediaWiki;

	if(!self.enumeratedPageTitles) { self.enumeratedPageTitles = [NSMutableSet setWithCapacity:[responseArray count]]; }
	
	for(NSDictionary* responseItem in responseArray) {
		if(![responseItem isKindOfClass:[NSDictionary class]]) { continue; }

		NSString* title = responseItem[@"title"];
		if(title.length == 0) { continue; }
		if([[self enumeratedPageTitles] containsObject:title]) { continue; } // we already have this result item
		
		WIKPage* resultItem = [mediaWiki pageForIdentifier:title];
		if(resultItem) { [result addObject:resultItem]; }

		[[self enumeratedPageTitles] addObject:title];
	}
	
	return result;
}

- (void)finalizeBatchWithResultItems:(NSArray*)resultItems error:(NSError*)error {
	if(self.opensearchOperationRunning) {
		self.queuedResultItems = resultItems;
		return;
	}

	if(resultItems.count == 0) { // last result set
		self.canFetchNext = NO;
	}

	if(self.openSearchResultItems) {
		NSMutableArray* newResultItems = [resultItems mutableCopy];
		[newResultItems removeObjectsInArray:[self openSearchResultItems]];
		resultItems = newResultItems;

		self.openSearchResultItems = nil;
		error = nil; // ignore
	}

	[self completeBatchWithResultItems:resultItems error:error];
}

#pragma mark -

- (void)fetchOpenSearchResultsIfNeeded {
	if(!self.needsToRunOpensearchOperation) { return; }
	if(self.opensearchOperationRunning) { return; }
	if(self.cancelled) { return; }

	NSString* string = self.predicate.predicateFormat;
	if(string.length == 0) { return; }

	WIKMediaWiki* mediaWiki = self.mediaWiki;

	id completion = ^(WIKOpensearchRequestOperation* operation, NSArray* resultItems, NSError* error) {
		[self finalizeOpensearchOperationWithResultItems:resultItems error:error];
	};

	id factory = ^(NSString* title, NSString* summary, NSURL* URL, BOOL hasRepresentativeImage) {
		WIKPage* page = [mediaWiki pageForIdentifier:title];

		[self setValue:title forProperty:[page title] ifNeeded:YES];
		[self setValue:summary forProperty:[page summary] ifNeeded:YES];

		[self setValue:URL forProperty:[page URL] ifNeeded:YES];

		return page;
	};

	WIKMediaWikiClient* client = self.mediaWiki.client;

	WIKOpensearchRequestOperation* operation = [WIKOpensearchRequestOperation
		opensearchRequestOperationWithString:string
		mediaWiki:[self mediaWiki]
		completion:completion
		factory:factory];
	
	[client enqueueHTTPRequestOperation:operation];

	self.needsToRunOpensearchOperation = NO;
	self.opensearchOperationRunning = YES;
}

- (void)setValue:(id)value forProperty:(WIKProperty*)property ifNeeded:(BOOL)ifNeeded {
	if(ifNeeded && property.status == WIKPropertyStatusLoaded) { return; }
	[property setValue:value status:WIKPropertyStatusLoaded error:nil];
}

- (void)finalizeOpensearchOperationWithResultItems:(NSArray*)resultItems error:(NSError*)error {
	self.opensearchOperationRunning = NO;

	if(self.queuedResultItems) {
		resultItems = [self unionOpensearchResultItems:resultItems withResultItems:[self queuedResultItems]];

		self.queuedResultItems = nil;
		error = nil; // ignore if we completed the regular query
	} else {
		self.openSearchResultItems = resultItems;
		if(resultItems.count == 0) { return; } // don't call the completion on empty result sets
	}

	[self completeBatchWithResultItems:resultItems error:error];
}

- (void)completeBatchWithResultItems:(NSArray*)resultItems error:(NSError*)error {
	if(self.cancelled) { return; }
	if(!self.completionBlock) { return; }

	self.completionBlock(self, resultItems, error);
	self.continuing = YES;
}

#pragma mark -

- (void)loadPropertiesForResultItemsIfNeeded:(NSArray*)resultItems completion:(void (^)(NSError* error))completion {
	[WIKPage
		loadPropertiesIfNeeded:@[ WIKPropertyName(URL), WIKPropertyName(title), WIKPropertyName(summary), WIKPropertyName(representativeImage) ]
		pages:resultItems
		completion:completion];
}

- (NSArray*)unionOpensearchResultItems:(NSArray*)opensearchResultItems withResultItems:(NSArray*)resultItems {
	if(opensearchResultItems.count == 0) { return resultItems; }

	NSMutableArray* newResultItems = [resultItems mutableCopy];
	[newResultItems removeObjectsInArray:opensearchResultItems];

	NSArray* unionResultItems = resultItems = [opensearchResultItems arrayByAddingObjectsFromArray:newResultItems];
	return unionResultItems;
}

@end
