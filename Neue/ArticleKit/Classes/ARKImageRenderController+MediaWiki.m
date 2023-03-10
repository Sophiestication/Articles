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

#import "ARKImageRenderController+MediaWiki.h"

@implementation ARKImageRenderController(MediaWiki)

- (BOOL)renderRepresentativeImageForArticleIfNeeded:(WIKPage*)article completion:(void (^)(UIImage* renderedImage, NSError* error))completion {
	WIKProperty* representativeImage = article.representativeImage;

	if(representativeImage.status == WIKPropertyStatusLoaded) {
		WIKImage* image = representativeImage.value;
		return [self renderRepresentativeImageForImage:image ofArticle:article completion:completion];
	}

	[representativeImage loadValueWithCompletionHandler:^(WIKImage* image, NSError* error) {
		[self renderRepresentativeImageForImage:image ofArticle:article completion:completion];
	}];

	return YES;
}

- (BOOL)renderRepresentativeImageForImage:(WIKImage*)image ofArticle:(WIKPage*)article completion:(void (^)(UIImage* renderedImage, NSError* error))completion {
	if(!image) { return [self renderImageForURL:nil options:0 completion:completion]; } // rely on standard implementation

	CGFloat preferredWidth = 120.0;
	preferredWidth *= [[UIScreen mainScreen] scale];

	WIKImageRepresentation* representation = [image representationForWidth:preferredWidth];
	
	CGFloat aspectRatio = fabs(1.0 - representation.size.width / representation.size.height);
	BOOL isSquareImage = aspectRatio <= 0.09;

	BOOL isLandscapeOrientation =
		!isSquareImage &&
		representation.size.width > representation.size.height;
	
	ARKImageRenderOptions options;
	
	if(isLandscapeOrientation && !WIKIsRasterImageTypeIdentifier(image.representation.typeIdentifier)) {
		// most likely a logo
		options = ARKImageRenderOptionScaleAspectFit;
	} else if(isSquareImage) {
		// just fill as is, no need for expansive color and face detection
		options = ARKImageRenderOptionScaleAspectFill;
	} else {
		// do it the hard way
		options = ARKImageRenderOptionScaleAutomatic|ARKImageRenderOptionDetectFaces;
	}
	
	// make some extra tweaks by filename
	NSString* imageFileName = [[[[image representation] URL]
		URLByDeletingPathExtension]
		lastPathComponent];
		
	// check if this is a flag image
	if([imageFileName hasPrefix:@"Flag_of_"]) {
		options |= ARKImageRenderOptionSuppressPadding|ARKImageRenderOptionFrameFitsToImageHeight;
	}
		
	// always aspect fill maps
	if([imageFileName hasSuffix:@"_location_map.svg"]) {
		options |= ARKImageRenderOptionScaleAspectFill|ARKImageRenderOptionSuppressPadding;
	}
	
	NSURL* previewURL = representation.URL;
	return [self renderImageForURL:previewURL options:options completion:completion];
}

@end
