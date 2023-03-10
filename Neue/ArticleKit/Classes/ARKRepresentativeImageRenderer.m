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

#import "ARKRepresentativeImageRenderer.h"

#import "SUISharedObjectPool.h"

@interface ARKRepresentativeImageRenderer()

@property(nonatomic, strong) UIImage* image;

@property(nonatomic) CGSize contentSize;
@property(nonatomic) CGFloat borderWidth;
@property(nonatomic) CGSize canvasSize;

@property(nonatomic) CGFloat scale;

@end

@implementation ARKRepresentativeImageRenderer

#pragma mark - Construction & Destruction

- (id)initWithImage:(UIImage*)image {
	if((self = [super init])) {
		self.image = image;
		self.scaleMode = ARKRepresentativeImageRendererScaleModeAutomatic;
		self.shouldApplyPadding = YES;
		self.shouldFitFrameToImageHeight = NO;
		
		self.contentSize = CGSizeMake(60.0, 60.0);
		self.borderWidth = 3.0;
		
		CGFloat const margin = 5.0;
		self.canvasSize = CGSizeMake(
			self.contentSize.width + self.borderWidth * 2.0 + margin * 2.0,
			self.contentSize.height + self.borderWidth * 2.0 + margin * 2.0);

		self.scale = [[UIScreen mainScreen] scale];
	}
	
	return self;
}

#pragma mark - ARKRepresentativeImageRenderer

- (UIImage*)renderedImage {
	if(!self.image) { return nil; }

	UIImage* renderedImage = nil;
	
	CGSize imageSize = self.canvasSize;
	CGFloat scale = self.scale;
	
	UIGraphicsBeginImageContextWithOptions(imageSize, NO, scale); {
		CGContextRef context = UIGraphicsGetCurrentContext();
		NSAssert(context != NULL, @"Invalid CGContext.");
		
		CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
	
		[self renderInContext:context];

		renderedImage = UIGraphicsGetImageFromCurrentImageContext();
		NSAssert(renderedImage != nil, @"Could not render UIImage.");
		
		renderedImage = [renderedImage imageWithAlignmentRectInsets:
			[self alignmentRectInsetsForSize:imageSize]];
	} UIGraphicsEndImageContext();
	
	return renderedImage;
}

- (void)renderInContext:(CGContextRef)context {
	CGRect contentRect = [self contentRect];
	CGRect backgroundRect = [self backgroundRect];
	
	[self renderBackgroundInRect:backgroundRect context:context];
	[self renderGenericImageIfNeededInRect:contentRect context:context];
	[self renderImageInRect:contentRect context:context];
	[self renderImageHighlightInRect:contentRect context:context];
}

#pragma mark - Private

- (CGRect)contentRect {
	CGSize canvasSize = self.canvasSize;
	CGSize contentSize = self.contentSize;

	CGRect contentRect = CGRectMake(
		floor(canvasSize.width * 0.5 - contentSize.width * 0.5),
		floor(canvasSize.height * 0.5 - contentSize.height * 0.5),
		contentSize.width,
		contentSize.height);

	if(self.shouldFitFrameToImageHeight) {
		CGSize imageSize = self.image.size;
	
		if(imageSize.height < imageSize.width) {
			CGFloat scale = imageSize.height / imageSize.width;

			CGFloat newHeight = floor(contentSize.height * scale);
			newHeight = MAX(newHeight, contentSize.height * 0.5); // at least half the content size

			contentRect.size.height = newHeight;
		}
	}
		
	return contentRect;
}

- (CGRect)backgroundRect {
	CGFloat borderWith = self.borderWidth;
	CGRect contentRect = [self contentRect];
	CGRect backgroundRect = CGRectInset(contentRect, -borderWith, -borderWith);
	
	return backgroundRect;
}

- (UIEdgeInsets)alignmentRectInsetsForSize:(CGSize)size {
	CGRect contentRect = [self contentRect];
	
	UIEdgeInsets insets = UIEdgeInsetsMake(
		CGRectGetMinY(contentRect),
		CGRectGetMinX(contentRect),
		size.height - CGRectGetMaxY(contentRect),
		size.width - CGRectGetMaxX(contentRect));
	return insets;
}

#pragma mark -

- (void)renderBackgroundInRect:(CGRect)rect context:(CGContextRef)context {
	CGContextSaveGState(context); {
		
		UIColor* shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
		CGContextSetShadowWithColor(context, CGSizeMake(0.0, 1.0), 4.0, [shadowColor CGColor]);
		
		// [[UIColor whiteColor] set];
		[[UIColor colorWithWhite:0.995 alpha:1.0] set];
		CGContextFillRect(context, rect);
	} CGContextRestoreGState(context);
}

- (void)renderGenericImageIfNeededInRect:(CGRect)rect context:(CGContextRef)context {
	if(self.image) { return; }

	CGContextSaveGState(context); {

		UIRectClip(rect);

		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		CGFloat locations[2] = { 0.0, 1.0 };
		
		// the context is flipped so switch start and end color
		NSArray* colors = @[
			(id)[[UIColor colorWithWhite:0.840 alpha:1.000] CGColor],
			(id)[[UIColor colorWithWhite:0.603 alpha:1.000] CGColor]];
			
		CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);

		CGContextDrawLinearGradient(
			context,
			gradient,
			rect.origin,
			CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect)),
			kCGGradientDrawsBeforeStartLocation|kCGGradientDrawsAfterEndLocation);
		
		CGGradientRelease(gradient);
		CGColorSpaceRelease(colorSpace);

	} CGContextRestoreGState(context);
}

- (void)renderImageInRect:(CGRect)rect context:(CGContextRef)context {
	if(!self.image) { return; }

	CGContextSaveGState(context); {
	
		CGSize contentSize = self.contentSize;
		contentSize.width *= self.scale; contentSize.height *= self.scale;

		UIImage* rasterImage = self.image;
		ARKRepresentativeImageRendererScaleMode scaleMode = self.scaleMode;

		// detect faces
		if(self.detectorPool) {
			CIImage* image = [CIImage imageWithCGImage:[rasterImage CGImage]];
			CIImage* targetImage = [self imageByCroppingToFace:image];
		
			if(targetImage) {
				scaleMode = ARKRepresentativeImageRendererScaleModeAspectFill;
			} else {
				targetImage = image;
			}
			
			rasterImage = [UIImage imageWithCIImage:targetImage];
		}

		CGFloat const optionalPadding = self.shouldApplyPadding ?
			2.0 : 0.0;

		// scale to fit and fill with the background with the average color
		if(scaleMode == ARKRepresentativeImageRendererScaleModeAspectFit) {
			UIColor* borderColor = [self averageBorderColorForImage:rasterImage];

			if([self isBlackColor:borderColor]) {
				[borderColor set];
				UIRectFillUsingBlendMode(rect, kCGBlendModeMultiply);
			}

			rect = CGRectInset(rect, optionalPadding, optionalPadding);
		}

		// scale to fit if needed
		if(scaleMode == ARKRepresentativeImageRendererScaleModeAutomatic) {
			UIColor* borderColor = [self averageBorderColorForImage:rasterImage];

			if(borderColor && [self isWhiteColor:borderColor]) {
				scaleMode = ARKRepresentativeImageRendererScaleModeAspectFit;
				rect = CGRectInset(rect, optionalPadding, optionalPadding);
			} else {
				scaleMode = ARKRepresentativeImageRendererScaleModeAspectFill;
			}
		}

		if(NO) {
			scaleMode = ARKRepresentativeImageRendererScaleModeAspectFit;
		}
		
		CGRect imageRect = CGRectMake(0.0, 0.0, rasterImage.size.width, rasterImage.size.height);
		CGRect targetRect = [self applyScaleMode:scaleMode toRect:imageRect targetRect:rect];
		
		UIRectClip(rect);
		[rasterImage drawInRect:targetRect];
	
	} CGContextRestoreGState(context);
}

- (void)renderImageHighlightInRect:(CGRect)rect context:(CGContextRef)context {
	CGContextSaveGState(context); {

		CGFloat const lineWidth = 1.0 / self.scale;
		CGContextSetLineWidth(context, lineWidth);

		[[[UIColor blackColor] colorWithAlphaComponent:0.2] set];
		UIRectFrameUsingBlendMode(rect, kCGBlendModeDarken);
	
	} CGContextRestoreGState(context);
}

- (CIImage*)imageByCroppingToFace:(CIImage*)image {
	__block NSArray* features;

	[[self detectorPool] dequeueSharedObjectWithinBlock:^(CIDetector* detector) {
		features = [detector featuresInImage:image];
	}];

	if(features.count == 0) { return nil; }
	if(features.count > 1) { return nil; }
	
	CGRect faceBounds = CGRectNull;
	
	for(CIFaceFeature* feature in features) {
		BOOL hasAEye = feature.hasLeftEyePosition || feature.hasRightEyePosition;
		BOOL hasAMouth = feature.hasMouthPosition;

		BOOL validFace = hasAEye && hasAMouth;
		if(!validFace) { continue; }

		CGRect bounds = feature.bounds;
		
		CGFloat featureSize = CGRectGetWidth(bounds) / CGRectGetWidth([image extent]);
		if(features.count > 1 && featureSize < 0.3) { continue; }

		if(CGRectIsNull(faceBounds)) {
			faceBounds = bounds;
		} else {
			faceBounds = CGRectUnion(faceBounds, bounds);
		}
	}
	
	if(CGRectIsNull(faceBounds) && features.count > 0) {
		for(CIFaceFeature* feature in features) {
			CGRect bounds = feature.bounds;

			if(CGRectIsNull(faceBounds)) {
				faceBounds = bounds;
			} else {
				faceBounds = CGRectUnion(faceBounds, bounds);
			}
		}
	}

	if(CGRectIsNull(faceBounds)) { return nil; }

	CGFloat padding = MIN(CGRectGetWidth(faceBounds), CGRectGetHeight(faceBounds));
	padding = floor(padding * 0.15);
	
	CGRect bounds = faceBounds;
	bounds = CGRectInset(bounds, -padding, -padding);
	
	CGSize contentSize = self.contentSize;
	contentSize.width *= self.scale; contentSize.height *= self.scale;
	
	if(CGRectGetWidth(bounds) < contentSize.width ||
	   CGRectGetHeight(bounds) < contentSize.height) {
		bounds = CGRectMake(
			floor(CGRectGetMidX(bounds) - contentSize.width * 0.5),
			floor(CGRectGetMidY(bounds) - contentSize.height * 0.5),
			contentSize.width,
			contentSize.height);
	}
	
	CGRect imageRect = image.extent;
	bounds = CGRectIntersection(bounds, imageRect);

	bounds = [self squareSubrectForRect:bounds];
	
	CIImage* croppedImage = [image imageByCroppingToRect:bounds];
	return croppedImage;
}

- (CGRect)applyScaleMode:(ARKRepresentativeImageRendererScaleMode)scaleMode toRect:(CGRect)rect targetRect:(CGRect)targetRect {
	CGFloat ratio = 1.0;
	CGFloat targetRatio = 1.0;
	
	if(scaleMode == ARKRepresentativeImageRendererScaleModeAspectFit) {
		ratio = CGRectGetWidth(rect) / CGRectGetHeight(rect);
		targetRatio = CGRectGetWidth(targetRect) / CGRectGetHeight(targetRect);
	} else if(scaleMode == ARKRepresentativeImageRendererScaleModeAspectFill ||
	          scaleMode == ARKRepresentativeImageRendererScaleModeAutomatic) {
		ratio = CGRectGetHeight(rect) / CGRectGetWidth(rect);
		targetRatio = CGRectGetHeight(targetRect) / CGRectGetWidth(targetRect);
	}
	
	CGRect newRect = targetRect;
	
	if(ratio > targetRatio) { // scale by width
		newRect.size.height = CGRectGetWidth(targetRect) * CGRectGetHeight(rect) / CGRectGetWidth(rect);

		if(CGRectGetWidth(rect) > CGRectGetHeight(rect)) {
			newRect.origin.y += (CGRectGetHeight(targetRect) - CGRectGetHeight(newRect)) * 0.5;
		}
	} else {
		newRect.size.width = CGRectGetHeight(targetRect)  * CGRectGetWidth(rect) / CGRectGetHeight(rect);
		newRect.origin.x += (CGRectGetWidth(targetRect) - CGRectGetWidth(newRect)) * 0.5;
	}
	
	newRect = CGRectIntegral(newRect);
	
	return newRect;
}

- (CGRect)squareSubrectForRect:(CGRect)rect {
	if(CGRectGetWidth(rect) > CGRectGetHeight(rect)) {
		rect.origin.x = round(CGRectGetMidX(rect) - CGRectGetHeight(rect) * 0.5);
		rect.size.width = CGRectGetHeight(rect);
	} else if(CGRectGetHeight(rect) > CGRectGetWidth(rect)) {
		if(YES) {
			rect.origin.y = (CGRectGetHeight(rect) - CGRectGetWidth(rect)) - 1.0;
		} else {
			rect.origin.y = round(CGRectGetMidY(rect) - CGRectGetWidth(rect) * 0.5);
		}

		rect.size.height = CGRectGetWidth(rect);
	}
	
	return rect;
}

#pragma mark -

- (UIColor*)averageBorderColorForImage:(UIImage*)image {
	if(!image) { return nil; }
	if(image.size.width <= 16.0) { return nil; }
	if(image.size.height <= 16.0) { return nil; }

	CGSize size = image.size;

	CGFloat const edgeHeight = 4.0;

	CGRect edgeRect = CGRectMake(0.0, 0.0, edgeHeight, edgeHeight);
	UIColor* topColor = [self averageColorForImage:image inRect:edgeRect];

	edgeRect = CGRectMake(size.width - edgeHeight, size.height - edgeHeight, edgeHeight, edgeHeight);
	UIColor* bottomColor = [self averageColorForImage:image inRect:edgeRect];
	
	if([topColor isEqual:bottomColor]) {
		return topColor;
	}

	return nil;
}

- (UIColor*)averageColorForImage:(UIImage*)image inRect:(CGRect)rect {
	if(image == NULL) { return nil; }

	CGImageRef CGImage = image.CGImage;
	UIImage* subimage;

	if(CGImage) {
		CGImageRef CGSubimage = CGImageCreateWithImageInRect(CGImage, rect);
		subimage = [UIImage imageWithCGImage:CGSubimage];
		CGImageRelease(CGSubimage);
	} else {
		CIImage* CISubimage = [[image CIImage] imageByCroppingToRect:rect];
		subimage = [UIImage imageWithCIImage:CISubimage];
	}

	if(subimage) {
		UIColor* averageColor = [self averageColorForImage:subimage];
		return averageColor;
	}

	return nil;
}

- (UIColor*)averageColorForImage:(UIImage*)image {
	if(image == NULL) { return nil; }

	unsigned char rgba[4];

    {	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		CGContextRef context = CGBitmapContextCreate(rgba, 1, 1, 8, 4, colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);

		UIGraphicsPushContext(context); {

			CGRect contentRect = CGRectMake(0.0, 0.0, 1.0, 1.0);

			[[UIColor clearColor] set];
			UIRectFill(contentRect);

			[image drawInRect:contentRect];

		} UIGraphicsPopContext();
	
		CGContextRelease(context);
		CGColorSpaceRelease(colorSpace); }
 
    if(rgba[3] > 0) {
		CGFloat alpha = ((CGFloat)rgba[3]) / 255.0;
        CGFloat multiplier = alpha / 255.0;

		return [UIColor
			colorWithRed:((CGFloat)rgba[0]) * multiplier
			green:((CGFloat)rgba[1]) * multiplier
			blue:((CGFloat)rgba[2]) * multiplier
			alpha:alpha];
    } else {
        return [UIColor
			colorWithRed:((CGFloat)rgba[0]) / 255.0
			green:((CGFloat)rgba[1]) / 255.0
			blue:((CGFloat)rgba[2]) / 255.0
			alpha:((CGFloat)rgba[3]) / 255.0];
    }
}

- (BOOL)isWhiteColor:(UIColor*)color {
	if(!color) { return NO; }

	CGFloat red, green, blue, alpha;

	if([color getRed:&red green:&green blue:&blue alpha:&alpha]) {
		if(alpha < 0.5) { return YES; }
		return red > 0.98 && green > 0.98 && blue > 0.98;
	}

	return NO;
}

- (BOOL)isBlackColor:(UIColor*)color {
	if(!color) { return NO; }

	CGFloat red, green, blue, alpha;

	if([color getRed:&red green:&green blue:&blue alpha:&alpha]) {
		if(alpha < 0.5) { return NO; }
		return red < 0.09 && green < 0.09 && blue < 0.09;
	}

	return NO;
}

@end

#pragma mark - ARKRepresentativeImageRenderer+Detector

@implementation ARKRepresentativeImageRenderer(Detector)

+ (CIDetector*)newPreferredFaceDetector {
	NSDictionary* options = @{
		CIDetectorAccuracy: CIDetectorAccuracyLow,
		CIDetectorTracking: @(YES),
		CIDetectorMinFeatureSize: @(0.3) };
	
	CIDetector* detector = [CIDetector
		detectorOfType:CIDetectorTypeFace
		context:nil
		options:options];
	
	return detector;
}

@end

#pragma mark - ARKRepresentativeImageRenderer+GenericImage

@implementation ARKRepresentativeImageRenderer(GenericImage)

+ (UIImage*)genericImage {
	ARKRepresentativeImageRenderer* renderer = [[ARKRepresentativeImageRenderer alloc] initWithImage:nil];
	return [renderer renderedImage];
}

@end
