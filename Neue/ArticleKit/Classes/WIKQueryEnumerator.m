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

#import "WIKQueryEnumerator.h"
#import "WIKMediaWikiClient.h"

@interface WIKQueryEnumerator()

@property(nonatomic, strong) WIKMediaWikiClient* client;

@property(nonatomic, strong) NSDictionary* parameters;
@property(nonatomic, strong) NSDictionary* continueParameters;

@property(nonatomic) BOOL shouldContinue;
@property(nonatomic) BOOL needsRequestNext;

@property(nonatomic, strong) AFURLConnectionOperation* runningOperation;

@end

@implementation WIKQueryEnumerator

@dynamic canRequestNext;
@dynamic requesting;

#pragma mark - Construction & Destruction

- (id)initWithParameters:(NSDictionary*)parameters client:(WIKMediaWikiClient*)client shouldContinue:(BOOL)shouldContinue {
	if((self = [super init])) {
		self.client = client;
		self.parameters = parameters;
		self.continueParameters = @{ @"continue": @"" }; // see media wiki api docs
		self.shouldContinue = shouldContinue;
		self.needsRequestNext = YES;
	}
	
	return self;
}

- (void)setCompletionBlockWithSuccess:(void (^)(WIKQueryEnumerator* enumerator, id responseObject))success failure:(void (^)(WIKQueryEnumerator* enumerator, NSError* error))failure {
	// removed soon(ish)
	[self setCompletionBlock:^(WIKQueryEnumerator* enumerator, id value, NSError* error) {
		if(error) {
			if(failure) { failure(enumerator, error); }
		} else {
			if(success) { success(enumerator, value); }
		}
	}];
}

- (BOOL)canRequestNext {
	if(self.needsRequestNext) { return YES; }
	if(!self.shouldContinue) { return NO; }
	
	return self.continueParameters.count > 0;
}

- (BOOL)requestNext {
	if(![self canRequestNext]) { return NO; }
	
	// cancel currently running operations
	if(self.runningOperation) {
		[[self runningOperation] cancel];
		self.runningOperation = nil;
	}
	
	// make a new operation for this request
	NSMutableDictionary* newParameters = [[self parameters] mutableCopy];
	[newParameters addEntriesFromDictionary:[self continueParameters]];
	
	id privateSuccess = ^(AFJSONRequestOperation* operation, id responseObject) {
		if(operation != self.runningOperation) { return; }
		self.runningOperation = nil;
		
		self.needsRequestNext = NO;
		self.continueParameters = [self continueParametersFromResponseObject:responseObject];
		
		if(self.completionBlock) {
			NSDictionary* value = [responseObject valueForKeyPath:WIKMediaWikiQueryAction];
			self.completionBlock(self, value, nil);
		}
	};
	
	id privateFailure = ^(AFJSONRequestOperation* operation, NSError* error) {
		if(operation != self.runningOperation) { return; }
		self.runningOperation = nil;
		
		self.needsRequestNext = NO;
		
		if(self.completionBlock) { self.completionBlock(self, nil, error); }
	};
	
	AFHTTPRequestOperation* operation = [[self client]
		performAction:WIKMediaWikiQueryAction
		parameters:newParameters
		success:privateSuccess
		failure:privateFailure];

//	NSLog(@"Request %@", [[[operation request] URL] absoluteString]);

	self.runningOperation = operation;

	return operation != nil;
}

- (BOOL)isRequesting {
	return self.runningOperation != nil;
}

- (void)cancel {
	[[self runningOperation] cancel];
}

#pragma mark - Private

- (NSDictionary*)continueParametersFromResponseObject:(id)responseObject {
	NSDictionary* continueParameters = [responseObject valueForKeyPath:@"continue"];
	if(![continueParameters isKindOfClass:[NSDictionary class]]) { return nil; }
	return continueParameters;
}

@end
