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

#import "SFDownloadOperation.h"
#import "SFDownloadOperation+Private.h"

@implementation SFDownloadOperation

@dynamic delegate;

#pragma mark -
#pragma mark Construction & Destruction

- (id)init {
	if((self = [super init])) {
		_delegateRespondsToWillBegin = NO;
		_delegateRespondsToDidFinish = NO;
		_delegateRespondsToDidFail = NO;
		_delegateRespondsToDidProgress = NO;
		_delegateRespondsToDidReceiveResponse = NO;
	
		self.progress = 0.0;
	
		self.expectedContentLength = 0;
		self.numberOfBytesTransferred = 0;
		
		// We always download to a temporary file and move it over to the localURL when done
		NSFileManager* fileManager = [[NSFileManager alloc] init];

		NSURL* applicationCacheURL = [fileManager URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];

		NSString* bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
		NSURL* temporaryFilesURL = [applicationCacheURL URLByAppendingPathComponent:bundleIdentifier isDirectory:YES];
		temporaryFilesURL = [temporaryFilesURL URLByAppendingPathComponent:@"Downloads" isDirectory:YES];

		[fileManager createDirectoryAtURL:temporaryFilesURL withIntermediateDirectories:YES attributes:nil error:nil];

		NSString* UUID = [[NSProcessInfo processInfo] globallyUniqueString];
		NSURL* temporaryURL = [temporaryFilesURL URLByAppendingPathComponent:UUID isDirectory:NO];
		self.temporaryURL = temporaryURL;
	}
	
	return self;
}

- (void)dealloc {
	[[self connection] cancel];
	[[self outputStream] close];
	self.delegate = nil;	
}

#pragma mark -
#pragma mark AKDownloadOperation

- (id<SFDownloadOperationDelegate>)delegate {
	return _delegate;
}

- (void)setDelegate:(id<SFDownloadOperationDelegate>)delegate {
	if(delegate != self.delegate) {
		_delegate = delegate;
		
		_delegateRespondsToWillBegin = [delegate respondsToSelector:@selector(downloadOperation:willDownloadWithRequest:)];
		_delegateRespondsToDidFinish = [delegate respondsToSelector:@selector(downloadOperationDidFinish:)];
		_delegateRespondsToDidFail = [delegate respondsToSelector:@selector(downloadOperation:didFailWithError:)];
		_delegateRespondsToDidProgress = [delegate respondsToSelector:@selector(downloadOperation:didProgress:)];
		_delegateRespondsToDidReceiveResponse = [delegate respondsToSelector:@selector(downloadOperation:didReceiveResponse:)];
	}
}

- (void)begin {
	NS_DURING
		NSMutableURLRequest* request = [NSMutableURLRequest 
			requestWithURL:[self remoteURL]];
		
		if(_delegateRespondsToWillBegin) {
			[[self delegate] downloadOperation:self willDownloadWithRequest:request];
		}
		
		NSURLConnection* connection = [NSURLConnection
			connectionWithRequest:request
			delegate:self];
		self.connection = connection;	
	NS_HANDLER
		NSLog(@"Exception in AKDownloadOperation: %@", localException);
	NS_ENDHANDLER
}

- (void)cancel {
	[[self connection] cancel];

	NSError* error = [NSError
		errorWithDomain:NSURLErrorDomain
		code:NSURLErrorCancelled
		userInfo:nil];
	[self connection:nil didFailWithError:error];
}

#pragma mark -
#pragma mark NSURLConnectionDelegate

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
//	NSLog(@"%@", [response allHeaderFields]); // Debug
	
	if([response statusCode] >= 500) {
		[[self connection] cancel];
		
		NSError* error = [NSError
			errorWithDomain:NSURLErrorDomain
			code:NSURLErrorFileDoesNotExist
			userInfo:nil];
		[self connection:nil didFailWithError:error];
		
		return;
	}
	
	// Retrieve the content length
	long long contentLength = [response expectedContentLength];
	
	if(contentLength <= 0) {
		contentLength = [[[response allHeaderFields] objectForKey:@"Content-Length"] longLongValue];
	}
	
	self.expectedContentLength = contentLength;
	
	// And the MIME type
	NSString* contentType = [[response allHeaderFields] objectForKey:@"Content-Type"];
	self.contentType = contentType;
	
	// Notifiy our delegate if needed
	if(_delegateRespondsToDidReceiveResponse) {
		[[self delegate] downloadOperation:self didReceiveResponse:response];
	}
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
	
	NSFileManager* fileManager = [[NSFileManager alloc] init];
	NSError* error = nil;

	NSURL* localURL = self.localURL;
	NSURL* localDirectoryURL = [localURL URLByDeletingLastPathComponent];

	if(![fileManager createDirectoryAtURL:localDirectoryURL withIntermediateDirectories:YES attributes:nil error:&error]) {
		NSLog(@"Error in %@: %@", NSStringFromClass([self class]), error);
		[self connection:connection didFailWithError:error]; return;
	}

	[fileManager removeItemAtURL:localURL error:nil]; // ignore errors since file might not exist yet
	
	NSURL* temporaryURL = self.temporaryURL;
		
	if(![fileManager moveItemAtURL:temporaryURL toURL:localURL error:&error]) {
		NSLog(@"Error in %@: %@, %@", NSStringFromClass([self class]), error, [error userInfo]);
		[self connection:connection didFailWithError:error]; return;
	}
	
	[self updateLoadProgress];
	[self deleteLocalFile];

	if(_delegateRespondsToDidFinish) {
		[[self delegate] downloadOperationDidFinish:self];
	}
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
	[[self outputStream] close];
	self.outputStream = nil;
	
	[self deleteLocalFile];
	
	self.error = error;
	
	if(_delegateRespondsToDidFail) {
		[[self delegate] downloadOperation:self didFailWithError:[self error]];
	}
}

#pragma mark -
#pragma mark Private

- (void)deleteLocalFile {
	NSFileManager* fileManager = [[NSFileManager alloc] init];
	[fileManager removeItemAtURL:[self temporaryURL] error:nil];
}

- (void)updateLoadProgress {
	float progress = 0.0;

	if(self.expectedContentLength > 0) {
		progress = (float)self.numberOfBytesTransferred / (float)self.expectedContentLength;
	}
	
	progress = MAX(progress, 0.0);
	progress = MIN(progress, 1.0);
	
	self.progress = MAX(progress, self.progress);
	
	if(_delegateRespondsToDidProgress) {
		[[self delegate] downloadOperation:self didProgress:[self progress]];
	}
}

@end
