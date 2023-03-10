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

#import "WIKPropertyRequestBroker.h"

#import "WIKPropertyRequest.h"

#import "WIKMediaWiki.h"
#import "WIKPage+Private.h"
#import "WIKProperty+Private.h"

#import "WIKMediaWikiClient.h"
#import "WIKQueryEnumerator.h"

#import "WIKPageDecoder.h"

@interface WIKPropertyRequestBroker()

@property(nonatomic, strong) NSMapTable* propertiesByMediaWiki;
@property(nonatomic, strong) NSMutableSet* runningRequests;
@property(nonatomic, strong) NSOperationQueue* requestQueue;
@property(nonatomic, weak) NSTimer* currentRequestTimer;

@end

@implementation WIKPropertyRequestBroker

+ (WIKPropertyRequestBroker*)sharedPropertyRequestBroker {
	static dispatch_once_t wik_sharedPropertyRequestBrokerOnce;
    static WIKPropertyRequestBroker* wik_sharedPropertyRequestBroker;
	
    dispatch_once(&wik_sharedPropertyRequestBrokerOnce, ^{
		wik_sharedPropertyRequestBroker = [[self alloc] init];
	});

    return wik_sharedPropertyRequestBroker;
}

- (id)init {
	if((self = [super init])) {
		self.propertiesByMediaWiki = [NSMapTable strongToStrongObjectsMapTable];
		self.runningRequests = [NSMutableSet setWithCapacity:1];

		NSOperationQueue* requestQueue = [[NSOperationQueue alloc] init];
		[requestQueue setName:@"com.sophiestication.CoreMediaWiki.requestBrokerQueue"];
		self.requestQueue = requestQueue;
	}

	return self;
}

- (void)requestProperty:(WIKProperty*)property {
	NSOperationQueue* propertyQueue = [NSOperationQueue currentQueue];
	NSOperationQueue* mainQueue = [NSOperationQueue mainQueue];

	WIKPage* page = property.page;
	WIKMediaWiki* mediaWiki = page.mediaWiki;
	
	void (^operation)(void) = ^() {
		NSArray* properties = [[self propertiesByMediaWiki] objectForKey:mediaWiki];
		
		NSDictionary* dictionary = @{
			WIKPropertyRequestPropertyKey: property,
			WIKPropertyRequestArticleKey: page, // keep here since property.page is a weak reference
			WIKPropertyRequestQueueKey: propertyQueue };
		
		properties = properties ?
			[properties arrayByAddingObject:dictionary] :
			[NSArray arrayWithObject:dictionary];
		
		[[self propertiesByMediaWiki] setObject:properties forKey:mediaWiki];
		
		[self scheduleNextRequest];
	};
	
	if([propertyQueue isEqual:mainQueue]) {
		operation();
	} else {
		[[NSOperationQueue mainQueue] addOperationWithBlock:operation];
	}
}

- (void)cancelLoadingOfProperty:(WIKProperty*)property {
	WIKMediaWiki* mediaWiki = property.page.mediaWiki;
	
	void (^operation)(void) = ^() {
		NSMapTable* propertiesByMediaWiki = self.propertiesByMediaWiki;
		__block NSMutableArray* properties = [[propertiesByMediaWiki objectForKey:mediaWiki] mutableCopy];
		
		[properties enumerateObjectsUsingBlock:^(NSDictionary* dictionary, NSUInteger index, BOOL* stop) {
			WIKProperty* scheduledProperty = dictionary[WIKPropertyRequestPropertyKey];
			if(scheduledProperty != property) { return; }

			[properties removeObjectAtIndex:index];
			*stop = YES;
		}];
		
		[propertiesByMediaWiki setObject:properties forKey:mediaWiki];
	};

	NSOperationQueue* mainQueue = [NSOperationQueue mainQueue];
	
	if([[NSOperationQueue currentQueue] isEqual:mainQueue]) {
		operation();
	} else {
		[[NSOperationQueue mainQueue] addOperationWithBlock:operation];
	}
}

#pragma mark -

- (void)scheduleNextRequest {
	NSTimer* currentTimer = self.currentRequestTimer;
	if(currentTimer) { [currentTimer invalidate]; }

	NSTimer* timer = [NSTimer
		timerWithTimeInterval:0.0
		target:self
		selector:@selector(requestPropertiesIfNeeded)
		userInfo:nil
		repeats:NO];

	[[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
	[[NSRunLoop mainRunLoop] addTimer:timer forMode:UITrackingRunLoopMode];

	self.currentRequestTimer = timer;
}

- (void)requestPropertiesIfNeeded {
	if(self.runningRequests.count > 2) { return; }

	static NSUInteger const maximumNumberOfPropertiesForRequest = 20; // max defined by media wiki

	NSMapTable* propertiesByMediaWiki = [[self propertiesByMediaWiki] copy];

	for(WIKMediaWiki* mediaWiki in propertiesByMediaWiki) {
		NSArray* properties = [[self propertiesByMediaWiki] objectForKey:mediaWiki];

		// limit the number of properties for each request
		if(properties.count > maximumNumberOfPropertiesForRequest) {
			NSRange range = NSMakeRange(0, maximumNumberOfPropertiesForRequest);
			NSArray* propertiesForRequest = [properties subarrayWithRange:range];

			NSRange remainingRange = NSMakeRange(NSMaxRange(range), properties.count - range.length);
			NSArray* remainingProperties = [properties subarrayWithRange:remainingRange];

			properties = propertiesForRequest;
			[[self propertiesByMediaWiki] setObject:remainingProperties forKey:mediaWiki];
		} else {
			[[self propertiesByMediaWiki] removeObjectForKey:mediaWiki];
		}

		WIKPropertyRequest* request = [[WIKPropertyRequest alloc] initWithProperties:properties mediaWiki:mediaWiki];
		[[self runningRequests] addObject:request];

		__weak __block WIKPropertyRequest* weakRequest = request;

		[[self requestQueue] addOperationWithBlock:^() {
			[request performRequestWithCompletionHandler:^() {
				[[NSOperationQueue mainQueue] addOperationWithBlock:^() {
					[self finalizeRequest:weakRequest];
				}];
			}];
		}];
	}
}

- (void)finalizeRequest:(WIKPropertyRequest*)request {
	if(!request) { return; }

	[[self runningRequests] removeObject:request];
	if(self.runningRequests.count == 0) { [self scheduleNextRequest]; }
}

@end
