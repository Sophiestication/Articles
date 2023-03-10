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

#import "AKDownloadOperation.h"
#import "AKDownloadOperation+Private.h"

@implementation AKDownloadOperation

#pragma mark - Construction & Destruction

- (id)init {
	if(self = [super init]) {
		self.progress = 0.0;
	
		self.expectedContentLength = 0;
		self.numberOfBytesTransferred = 0;
	
		NSString* UUID = [[NSProcessInfo processInfo]
			globallyUniqueString];
		NSString* temporaryURLString = [NSTemporaryDirectory()
			stringByAppendingPathComponent:UUID];
		self.temporaryURL = [NSURL fileURLWithPath:temporaryURLString];
	}
	
	return self;
}

- (void)dealloc {
	[[self connection] cancel];
	[[self outputStream] close];	
}

#pragma mark - AKDownloadOperation

- (void)start {
//	NS_DURING
		NSMutableURLRequest* request = [NSMutableURLRequest
			requestWithURL:[self remoteURL]];
		[request setCachePolicy:NSURLRequestReloadIgnoringCacheData];

		NSURLConnection* connection = [NSURLConnection
			connectionWithRequest:request
			delegate:self];
		self.connection = connection;	
//	NS_HANDLER
//		NSLog(@"Exception in AKDownloadOperation: %@", localException);
//	NS_ENDHANDLER
}

- (void)cancel {
	[[self connection] cancel];

	NSError* error = [NSError
		errorWithDomain:NSURLErrorDomain
		code:NSURLErrorCancelled
		userInfo:nil];
	[self connection:nil didFailWithError:error];
}

#pragma mark - NSURLConnectionDelegate

- (NSURLRequest*)connection:(NSURLConnection*)connection willSendRequest:(NSURLRequest*)request redirectResponse:(NSURLResponse*)response {
	[[self outputStream] close];
	self.outputStream = nil;

	[self deleteLocalFile];
	
	self.progress = 0.0;
	
	self.expectedContentLength = 0;
	self.numberOfBytesTransferred = 0;
		
	return request;
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSHTTPURLResponse*)response {
	if([response statusCode] >= 500) {
		[[self connection] cancel];
		
		NSError* error = [NSError
			errorWithDomain:NSURLErrorDomain
			code:NSURLErrorFileDoesNotExist
			userInfo:nil];
		[self connection:nil didFailWithError:error];
		
		return;
	}
	
	long long contentLength = [response expectedContentLength];
	
	if(contentLength <= 0) {
		contentLength = [[[response allHeaderFields] objectForKey:@"Content-Length"] longLongValue];
	}
	
	self.expectedContentLength = contentLength;
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
	if(!self.outputStream) {
		NSString* localFilePath = [[self temporaryURL] path];
		self.outputStream = [NSOutputStream
			outputStreamToFileAtPath:localFilePath
			append:NO];
			
		[[self outputStream] open];
	}
	
	[[self outputStream] write:[data bytes] maxLength:[data length]];
	
	self.numberOfBytesTransferred += [data length];
	
	[self updateLoadProgress];
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
	[[self outputStream] close];
	self.outputStream = nil;
	
	self.error = nil;
	
	NSError* error = nil;
	BOOL succeeded = [[NSFileManager defaultManager] 
		moveItemAtPath:[[self temporaryURL] path]
		toPath:[[self localURL] path]
		error:&error];
		
	if(!succeeded) {
		// TODO
	}
	
	[self updateLoadProgress];
    
	if(![[self delegate] respondsToSelector:@selector(downloadOperationDidFinish:)]) { return; }
	[[self delegate] downloadOperationDidFinish:self];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
	[[self outputStream] close];
	self.outputStream = nil;
	
	[self deleteLocalFile];
	
	self.error = error;
	
	if(![[self delegate] respondsToSelector:@selector(downloadOperation:didFailWithError:)]) { return; }
	
	dispatch_async(dispatch_get_main_queue(), ^() {
		[[self delegate] downloadOperation:self didFailWithError:error];
	});
}

#pragma mark - NSURLConnectionDataDelegate

- (NSCachedURLResponse*)connection:(NSURLConnection*)connection willCacheResponse:(NSCachedURLResponse*)cachedResponse {
	return nil;
}

#pragma mark - Private

- (void)deleteLocalFile {
	// Delete the local file
	NSString* localFilePath = [[self temporaryURL] absoluteString];
	[[NSFileManager defaultManager]
		removeItemAtPath:localFilePath
		error:nil];
}

- (void)updateLoadProgress {
	float progress = 0.0;

	if(self.expectedContentLength > 0) {
		progress = (float)self.numberOfBytesTransferred / (float)self.expectedContentLength;
	}
	
	progress = MAX(progress, 0.0);
	progress = MIN(progress, 1.0);
	
	self.progress = MAX(progress, self.progress);
	
	if(![[self delegate] respondsToSelector:@selector(downloadOperation:didProgress:)]) { return; }
	[[self delegate]
		performSelector:@selector(downloadOperation:didProgress:)
		withObject:self
		withObject:[NSNumber numberWithFloat:progress]];
}

@end
