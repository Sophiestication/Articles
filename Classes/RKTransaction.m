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

#import "RKTransaction.h"
#import "RKTransaction+Private.h"

#import "NSArray+Additions.h"
#import "NSString+Additions.h"

@implementation RKTransaction

@synthesize delegate = _delegate;
@synthesize resultFormatter = _resultFormatter;
@synthesize cachePolicy = _cachePolicy;
@synthesize connection = _connection;
@synthesize request = _request;
@synthesize response = _response;
@synthesize expectedContentLength = _expectedContentLength;
@synthesize numberOfBytesTransferred = _numberOfBytesTransferred;
@synthesize responseData = _responseData;
@synthesize responseStream = _responseStream;
@synthesize succeeded = _succeeded;
@synthesize result = _result;
@synthesize error = _error;
@synthesize userInfo = _userInfo;

#pragma mark -
#pragma mark Construction & Destruction

+ (RKTransaction*)transactionWithURLRequest:(NSURLRequest*)request {
	return [[self alloc] initWithURLRequest:request];
}

+ (RKTransaction*)transactionWithURL:(NSURL*)URL {
	NSURLRequest* request = [NSURLRequest requestWithURL:URL];
	return [self transactionWithURLRequest:request];
}

- (id)initWithURLRequest:(NSURLRequest*)request {
	if(self = [super init]) {
		_succeeded = NO;
		
		self.responseData = [NSMutableData data];
		self.expectedContentLength = NSURLResponseUnknownLength;
		self.numberOfBytesTransferred = 0;
		
		self.request = request;
	}
	
	return self;
}

- (void)dealloc {
	[[self connection] cancel];
	
	
}

#pragma mark -
#pragma mark RKTransaction

- (void)begin {
	if(!self.connection) {
		NSURLConnection* connection = [NSURLConnection
			connectionWithRequest:[self request]
			delegate:self];
		
		[connection start];
		
		self.connection = connection;
	}
}

- (void)cancel {
	[[self connection] cancel];
}

#pragma mark -
#pragma mark NSURLConnectionDelegate

- (NSURLRequest*)connection:(NSURLConnection*)connection willSendRequest:(NSURLRequest*)request redirectResponse:(NSURLResponse*)response {
	if(response) {
		NSLog(@"transaction %@ will redirect to %@", self, [response URL]);
	}
	
	// Keep the new request
	self.request = request;
	return request;
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response {
	// Keep the response
	self.response = response;
	self.expectedContentLength = [response expectedContentLength];
	
	// Reset the response data
	[[self responseData] setLength:0];
	self.numberOfBytesTransferred = 0;
	
	// Handle the HTTP error code if we have one
	if([response isKindOfClass:[NSHTTPURLResponse class]]) {
		// Notify our delegate about the response
		if([[self delegate] respondsToSelector:@selector(transaction:didReceiveResponse:)]) {
			[[self delegate] transaction:self didReceiveResponse:(NSHTTPURLResponse*)response];
		}

		// Handle errors if needed
		NSInteger statusCode = [(NSHTTPURLResponse*)response statusCode];
		
		if(statusCode >= 400) { // TODO?
			NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				[[response URL] absoluteString], NSURLErrorFailingURLStringErrorKey,
				[NSHTTPURLResponse localizedStringForStatusCode:statusCode], NSLocalizedDescriptionKey,
				nil];
			self.error = [NSError errorWithDomain:NSURLErrorDomain code:statusCode userInfo:userInfo];
			
			// Cancel on error
			[self cancel];
		}
	}
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
	// Check if we use a output stream for the reponse data
	NSOutputStream* responseStream = self.responseStream;

	if(responseStream) {
		// Open the stream if needed
		if([responseStream streamStatus] != NSStreamStatusOpen) {
			[responseStream open];
		}
		
		// Fail on error
		NSError* error = [responseStream streamError];
		
		if(error) {
			self.error = error;
			[self cancel];
			return;
		}
		
		// Write to our stream
		[responseStream write:[data bytes] maxLength:[data length]];
		self.numberOfBytesTransferred += [data length];
	} else {
		// Append the received data
		NSMutableData* responseData = self.responseData;
		
		if(responseData) {
			[responseData appendData:data];
			self.numberOfBytesTransferred += [data length];
		} else {
			self.responseData = [NSMutableData dataWithData:data];
			self.numberOfBytesTransferred = [data length];
		}
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
	[self transactionShouldFinalizeWithConnection:connection error:nil];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
	[self transactionShouldFinalizeWithConnection:connection error:error];
}

- (void)connection:(NSURLConnection*)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge {
	// Re-reoute this to our transaction delegate
	if([[self delegate] respondsToSelector:@selector(transaction:didReceiveAuthenticationChallenge:)]) {
		[[self delegate] transaction:self didReceiveAuthenticationChallenge:challenge];
	}
}

- (void)connection:(NSURLConnection*)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge {
	// Re-reoute this to our transaction delegate
	if([[self delegate] respondsToSelector:@selector(transaction:didCancelAuthenticationChallenge:)]) {
		[[self delegate] transaction:self didCancelAuthenticationChallenge:challenge];
	}
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection*)connection {
	return YES;
}

#pragma mark -
#pragma mark Private

- (void)transactionShouldFinalizeWithConnection:(NSURLConnection*)connection error:(NSError*)error {
	// Keep the error for later
	self.error = error;
	
	// Check for errors
	if(self.error) {
		self.succeeded = NO;
	} else {
		// We use the response stream for our result,
		// otherwise the reponse data
		id result = self.responseStream ?
			(id)self.responseStream :
			(id)self.responseData;
		NSError* error = nil;
		
		// Hand over our transaction result to a formatter if needed
		id<RKResultFormatter> resultFormatter = self.resultFormatter;
		
		if(resultFormatter) {
			result = [resultFormatter formatResultData:result error:&error response:[self response]];
		}

		self.result = result;
		self.succeeded = result != nil && error == nil;
		self.error = error;
	}
	
	// Give the delegate the chance to change the transaction result and error
	if([[self delegate] respondsToSelector:@selector(transactionShouldFinish:withResult:error:)]) {
		NSError* error = self.error;
		
		self.result = [[self delegate]
			transactionShouldFinish:self
			withResult:[self result]
			error:&error];

		self.succeeded = self.result != nil && error == nil;
		self.error = error;
	}
	
	// Close the response stream if needed
	[[self responseStream] close];
	
	// Now notify the delegate on our main thread
	if(self.succeeded) {
		if([[self delegate] respondsToSelector:@selector(transactionDidFinish:withResult:)]) {
			[[self delegate] transactionDidFinish:self withResult:[self result]];
		}
	} else {
		NSLog(@"transaction: %@ failed with error: %@", self, self.error);
		
		if([[self delegate] respondsToSelector:@selector(transaction:didFailWithError:)]) {
			[[self delegate] transaction:self didFailWithError:[self error]];
		}
	}
}

@end
