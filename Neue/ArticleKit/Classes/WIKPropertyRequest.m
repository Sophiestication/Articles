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

#import "WIKPropertyRequest.h"

#import "WIKPage+Private.h"
#import "WIKProperty+Mutating.h"
#import "WIKProperty+Private.h"

#import "WIKPageDecoder.h"

#import "WIKMediaWiki.h"
#import "WIKMediaWikiClient.h"
#import "WIKQueryEnumerator.h"

@interface WIKPropertyRequest()

@property(nonatomic, strong) WIKMediaWiki* mediaWiki;
@property(nonatomic, copy) NSArray* properties;

@property(nonatomic, strong) NSSet* mediaWikiProperties;
@property(nonatomic, strong) NSSet* mediaWikiPages;

@property(nonatomic, strong) NSOperationQueue* operationQueue;

@property(nonatomic, strong) NSMutableSet* requestedImages;

@property(atomic, getter=isRequestRunning) BOOL requestRunning;
@property(atomic, getter=isImageRequestRunning) BOOL imageRequestRunning;

@property(nonatomic, copy) void (^completionBlock)(void);

@end

@implementation WIKPropertyRequest

#pragma mark - Construction & Destruction

- (id)initWithProperties:(NSArray*)properties mediaWiki:(WIKMediaWiki*)mediaWiki {
	if((self = [super init])) {
		self.mediaWiki = mediaWiki;
		self.properties = properties;
		
		self.mediaWikiProperties = [self mediaWikiPropertiesForProperties:properties];
		self.mediaWikiPages = [self mediaWikiPagesForProperties:properties];
	}
	
	return self;
}

#pragma mark - WIKPropertyRequest

- (void)performRequestWithCompletionHandler:(void (^)(void))completion {
	self.operationQueue = [NSOperationQueue currentQueue];
	self.completionBlock = completion;

	WIKMediaWikiClient* client = self.mediaWiki.client;
	
	NSArray* mediaWikiProperties = [[self mediaWikiProperties] allObjects];
	NSArray* mediaWikiPages = [[self mediaWikiPages] allObjects];

	WIKQueryEnumerator* enumerator = [client properties:mediaWikiProperties forPageTitles:mediaWikiPages];
	
	__block WIKPageDecoder* decoder = [[WIKPageDecoder alloc] init];
	
	[enumerator setCompletionBlockWithSuccess:^(WIKQueryEnumerator* enumerator, NSDictionary* responseObject) {
		[self decodeFragment:responseObject withDecoder:decoder finalizeOrRequestNext:enumerator];
	} failure:^(WIKQueryEnumerator* enumerator, NSError* error) {
		[self finalizeRequestWithDecoder:decoder error:error];
	}];

	self.requestRunning = [enumerator requestNext];
}

#pragma mark - Private

- (NSSet*)mediaWikiPropertiesForProperties:(NSArray*)properties {
	NSMutableSet* mediaWikiProperties = [NSMutableSet setWithCapacity:[properties count]];

	for(NSDictionary* dictionary in properties) {
		WIKProperty* property = dictionary[WIKPropertyRequestPropertyKey];
		SEL selector = property.selector;

		if(selector == @selector(URL) ||
		   selector == @selector(title)) {
			[mediaWikiProperties addObject:WIKMediaWikiInfoProperty];
		}

		if(selector == @selector(summary)) {
			[mediaWikiProperties addObject:WIKMediaWikiExtractsProperty];
		}

		if(selector == @selector(representativeImage)) {
			[mediaWikiProperties addObject:WIKMediaWikiPageInfoProperty];
		}

		if(selector == @selector(images)) {
			[mediaWikiProperties addObject:WIKMediaWikiImagesProperty];
		}

//		if(selector == @selector(location)) {
//			[mediaWikiProperties addObject:WIKMediaWikiCoordinatesProperty];
//		}
	}

	return mediaWikiProperties;
}

- (NSSet*)mediaWikiPagesForProperties:(NSArray*)properties {
	NSMutableSet* pageTitles = [NSMutableSet setWithCapacity:[properties count]];

	for(NSDictionary* dictionary in properties) {
		WIKProperty* property = dictionary[WIKPropertyRequestPropertyKey];

		NSString* identifier = property.page.identifier;
		if(identifier.length > 0) { [pageTitles addObject:identifier]; }
	}

	return pageTitles;
}

- (void)decodeFragment:(id)fragment withDecoder:(WIKPageDecoder*)decoder finalizeOrRequestNext:(WIKQueryEnumerator*)enumerator {
	[[self operationQueue] addOperationWithBlock:^() {
		BOOL canRequestNext = [enumerator canRequestNext];
		NSError* error;

		if(![decoder decodeFragment:fragment error:&error]) {
			NSLog(@"%@", error); // TODO?
			canRequestNext = NO;
		}
		
		[self requestImagesNeedingCompletionWithDecoderIfNeeded:decoder];

		if(canRequestNext) {
			self.requestRunning = [enumerator requestNext];
		} else {
			self.requestRunning = NO;
			[self finalizeRequestWithDecoderIfNeeded:decoder error:error];
		}
	}];
}

- (void)requestImagesNeedingCompletionWithDecoderIfNeeded:(WIKPageDecoder*)decoder {
	NSMutableSet* incompleteImages = [[decoder imagesNeedingCompletion] mutableCopy];

	@synchronized(self) {
		NSMutableSet* requestedImages = self.requestedImages;

		if(!requestedImages) {
			requestedImages = [NSMutableSet set];
			self.requestedImages = requestedImages;
		}

		[incompleteImages minusSet:requestedImages];
		[requestedImages unionSet:incompleteImages];
	}

	WIKMediaWikiClient* client = self.mediaWiki.client;
	WIKQueryEnumerator* enumerator = [client imagesNamed:[incompleteImages allObjects]];

	[enumerator setCompletionBlockWithSuccess:^(WIKQueryEnumerator* enumerator, NSDictionary* responseObject) {
		[self decodeImageFragment:responseObject withDecoder:decoder finalizeOrRequestNext:enumerator];
	} failure:^(WIKQueryEnumerator* enumerator, NSError* error) {
		[self finalizeRequestWithDecoder:decoder error:error];
	}];

	self.imageRequestRunning = [enumerator requestNext];
}

- (void)decodeImageFragment:(id)fragment withDecoder:(WIKPageDecoder*)decoder finalizeOrRequestNext:(WIKQueryEnumerator*)enumerator {
	[[self operationQueue] addOperationWithBlock:^() {
		BOOL canRequestNext = [enumerator canRequestNext];
		NSError* error;

		if(![decoder decodeFragment:fragment error:&error]) {
			NSLog(@"%@", error); // TODO?
			canRequestNext = NO;
		}

		if(canRequestNext) {
			self.imageRequestRunning = [enumerator requestNext];
		} else {
			self.imageRequestRunning = NO;
			[self finalizeRequestWithDecoderIfNeeded:decoder error:error];
		}
	}];
}

- (void)finalizeRequestWithDecoderIfNeeded:(WIKPageDecoder*)decoder error:(NSError*)error {
	if(self.requestRunning || self.imageRequestRunning) { return; }
	[self finalizeRequestWithDecoder:decoder error:error];
}

- (void)finalizeRequestWithDecoder:(WIKPageDecoder*)decoder error:(NSError*)error {
	NSArray* properties = self.properties;
		
	WIKPropertyStatus status = error ?
		WIKPropertyStatusFailed :
		WIKPropertyStatusLoaded;
		
	for(NSDictionary* dictionary in properties) {
		WIKProperty* property = dictionary[WIKPropertyRequestPropertyKey];
		NSString* propertyName = NSStringFromSelector([property selector]);

		WIKPage* article = dictionary[WIKPropertyRequestArticleKey];
		NSString* page = article.identifier;
			
		id value = [[decoder propertiesForPage:page] objectForKey:propertyName];

		NSOperationQueue* operationQueue = dictionary[WIKPropertyRequestQueueKey];
			
		[operationQueue addOperationWithBlock:^() {
			[property setValue:value status:status error:error];
		}];
	}

	[[self operationQueue] addOperationWithBlock:[self completionBlock]];
}

@end

NSString* const WIKPropertyRequestPropertyKey = @"property";
NSString* const WIKPropertyRequestArticleKey = @"page";
NSString* const WIKPropertyRequestQueueKey = @"queue";
