//
//  ARKResourceURLProtocol.m
//  Articles
//
//  Created by Sophia Teutschler on 26.04.10.
//  Copyright 2010 Sophia Teutschler. All rights reserved.
//

#import "ARKResourceURLProtocol.h"

NSString* const ARKBundleProtocolScheme = @"x-articlekit-resource";

@implementation ARKResourceURLProtocol

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
	
	NSBundle* bundle = [NSBundle bundleForClass:[self class]];
	
	NSString* resourcePath = [bundle pathForResource:resource ofType:nil];
	
	if(resourcePath.length == 0) {
		resource = [[[self request] URL] resourceSpecifier];
	
		if([resource hasPrefix:@"//"]) {
			resource = [resource substringFromIndex:2];
		}
	
		resourcePath = [bundle resourcePath];
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