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

#import "WIKProperty.h"
#import "WIKProperty+Mutating.h"
#import "WIKProperty+Private.h"

#import "WIKPropertyRequestBroker.h"

@implementation WIKProperty

#pragma mark - Construction & Destruction

- (id)init {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

#pragma mark - WIKProperty

- (void)loadValueWithCompletionHandler:(void (^)(id value, NSError* error))completion {
	NSParameterAssert(completion);
	
	WIKPropertyStatus status = self.status;
	BOOL needsToRequestValue =
		status == WIKPropertyStatusUnknown ||
		status == WIKPropertyStatusFailed ||
		status == WIKPropertyStatusCancelled;
	BOOL valueIsLoading = status == WIKPropertyStatusLoading;
	BOOL valueIsLoaded = status == WIKPropertyStatusLoaded;

	if(needsToRequestValue || valueIsLoading) {
		if(!self.completionHandler) { self.completionHandler = [NSMutableArray arrayWithCapacity:1]; }
		[[self completionHandler] addObject:completion];
	}

	if(needsToRequestValue) {
		[self requestValue];
	}
	
	if(valueIsLoaded) {
		completion(self.value, nil);
	}
}

- (void)cancelLoading {
	if(self.status == WIKPropertyStatusLoading) {
		[[WIKPropertyRequestBroker sharedPropertyRequestBroker] cancelLoadingOfProperty:self];
		[self setValue:nil status:WIKPropertyStatusCancelled error:nil];
	}
}

#pragma mark - NSObject

- (NSString*)description {
	return [NSString stringWithFormat:@"%@ {name = %@, status = %@}",
		[super description],
		NSStringFromSelector([self selector]),
		NSStringFromWIKPropertyStatus([self status])];
}

#pragma mark - Private

- (void)requestValue {
	self.status = WIKPropertyStatusLoading;
	[[WIKPropertyRequestBroker sharedPropertyRequestBroker] requestProperty:self];
}

@end

#pragma mark - NSStringFromWIKPropertyStatus

NSString* NSStringFromWIKPropertyStatus(WIKPropertyStatus status) {
	if(status == WIKPropertyStatusLoading) { return @"WIKPropertyStatusLoading"; }
	if(status == WIKPropertyStatusLoaded) { return @"WIKPropertyStatusLoaded"; }
	if(status == WIKPropertyStatusFailed) { return @"WIKPropertyStatusFailed"; }
	if(status == WIKPropertyStatusCancelled) { return @"WIKPropertyStatusCancelled"; }
	return @"WIKPropertyStatusUnknown";
}
