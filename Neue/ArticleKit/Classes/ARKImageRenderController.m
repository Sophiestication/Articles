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

#import "ARKImageRenderController.h"

#import "ARKRepresentativeImageRenderer.h"
#import "SUISharedObjectPool.h"

#import <CoreImage/CoreImage.h>

@interface ARKImageRenderController()

@property(nonatomic, strong) NSOperationQueue* operationQueue;
@property(nonatomic, strong) NSMutableSet* imageURLsInProgress;

@property(nonatomic, strong) SUISharedObjectPool* detectorPool;

@end

@implementation ARKImageRenderController

#pragma mark - Construction & Destruction

- (id)init {
	if((self = [super init])) {
		self.operationQueue = [[NSOperationQueue alloc] init];
		self.imageURLsInProgress = [NSMutableSet set];

//		self.detectorPool = [[SUISharedObjectPool alloc] initWithFactoryBlock:^id (void) {
//			return [ARKRepresentativeImageRenderer newPreferredFaceDetector];
//		} maximumNumberOfObjects:1];
	}

	return self;
}

#pragma mark - ARKImageRenderController

- (BOOL)renderImageForURL:(NSURL*)URL options:(ARKImageRenderOptions)options completion:(void (^)(UIImage* image, NSError* error))completion {
	if(!URL) {
		[self performSelector:@selector(invokeCompletionForMissingImageIfNeeded:) withObject:completion afterDelay:0.0];
		return YES;
	}

	if([[self imageURLsInProgress] containsObject:URL]) {
		return NO;
	}

	[self requestAndRenderImageForURL:URL options:options completion:completion];

	return YES;
}

#pragma mark - Private

- (void)invokeCompletionForMissingImageIfNeeded:(void (^)(UIImage* image, NSError* error))completion {
	if(!completion) { return; }
	completion(nil, nil);
}

- (void)requestAndRenderImageForURL:(NSURL*)URL options:(ARKImageRenderOptions)options completion:(void (^)(UIImage* image, NSError* error))completion {
	[[self imageURLsInProgress] addObject:URL];

	NSURLRequest* request = [NSURLRequest requestWithURL:URL];
	[NSURLConnection sendAsynchronousRequest:request queue:[self operationQueue] completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {
		if(error) {
			[self finalizeRequestForURL:URL image:nil error:error completion:completion];
		} else {
			[self renderImageForURL:URL data:data options:options completion:completion];
		}
	}];
}

- (void)renderImageForURL:(NSURL*)URL data:(NSData*)data options:(ARKImageRenderOptions)options completion:(void (^)(UIImage* image, NSError* error))completion {
	UIImage* image = [UIImage imageWithData:data];
	ARKRepresentativeImageRenderer* renderer = [[ARKRepresentativeImageRenderer alloc] initWithImage:image];
	
	if(options & ARKImageRenderOptionDetectFaces) {
		renderer.detectorPool = self.detectorPool;
	}
	
	if(options & ARKImageRenderOptionSuppressPadding) {
		renderer.shouldApplyPadding = NO;
	}
	
	if(options & ARKImageRenderOptionFrameFitsToImageHeight) {
		renderer.shouldFitFrameToImageHeight = YES;
	}

	if(options & ARKImageRenderOptionScaleAspectFit) { renderer.scaleMode = ARKRepresentativeImageRendererScaleModeAspectFit; }
	if(options & ARKImageRenderOptionScaleAspectFill) { renderer.scaleMode = ARKRepresentativeImageRendererScaleModeAspectFill; }
	
	UIImage* renderedImage = [renderer renderedImage];

	[self finalizeRequestForURL:URL image:renderedImage error:nil completion:completion];
}

- (void)finalizeRequestForURL:(NSURL*)URL image:(UIImage*)image error:(NSError*)error completion:(void (^)(UIImage* image, NSError* error))completion {
	[[NSOperationQueue mainQueue] addOperationWithBlock:^() {
		[[self imageURLsInProgress] removeObject:URL];
		completion(image, error);
	}];
}

@end
