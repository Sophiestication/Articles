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

#import "AKResourceURLProtocol.h"

NSString* const AKBundleProtocolScheme = @"x-articlekit-resource";

@implementation AKResourceURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest*)request {
	NSURL* URL = [request URL];
	
	if([[URL scheme] isEqualToString:AKBundleProtocolScheme]) {
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
	NSString* resource = [[[self request] URL] host];
	
	NSString* resourcePath = [[NSBundle bundleForClass:[self class]]
		pathForResource:resource ofType:nil];
	
	if(resourcePath.length == 0) {
		resource = [[[self request] URL] resourceSpecifier];
	
		if([resource hasPrefix:@"//"]) {
			resource = [resource substringFromIndex:2];
		}
	
		resourcePath = [[NSBundle bundleForClass:[self class]] resourcePath];
		resourcePath = [resourcePath stringByAppendingPathComponent:resource];
	}

	if(resourcePath.length > 0) {
		// NSLog(@"Load resource %@", [[[self request] URL] absoluteString]);
		
		NSHTTPURLResponse* redirectResponse = [[NSHTTPURLResponse alloc]
			initWithURL:[[self request] URL]
			MIMEType:nil
			expectedContentLength:-1
			textEncodingName:nil];
			
		NSURLRequest* redirectRequest = [NSURLRequest requestWithURL:
			[NSURL fileURLWithPath:resourcePath]];
		
		[[self client] URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:redirectResponse];
		[[self client] URLProtocolDidFinishLoading:self];
	} else {
		// NSLog(@"Could not find resource %@", [[[self request] URL] absoluteString]);
		
		NSError* error = [NSError
			errorWithDomain:NSURLErrorDomain
			code:NSURLErrorFileDoesNotExist
			userInfo:nil];
		[[self client] URLProtocol:self didFailWithError:error];
	}
}

- (void)stopLoading {
}

@end
