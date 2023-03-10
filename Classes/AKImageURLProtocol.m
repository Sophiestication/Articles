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

#import "AKImageURLProtocol.h"

NSString* const AKImageProtocolScheme = @"x-articlekit-image";

@implementation AKImageURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest*)request {
	NSURL* URL = [request URL];
	
	if([[URL scheme] isEqualToString:AKImageProtocolScheme]) {
		return YES;
	}
	
	return NO;
}

+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest*)request {
	return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest*)a toRequest:(NSURLRequest*)b {
	return [[a URL] isEqual:[b URL]];
}

- (void)startLoading {
	NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc]
		initWithURL:[[self request] URL]
		statusCode:204
		HTTPVersion:@"HTTP/1.1"
		headerFields:nil];
	[[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
			
	[[self client] URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {
}

@end
