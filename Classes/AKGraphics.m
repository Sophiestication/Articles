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

#import "AKGraphics.h"

void AKRectFillOrnamentBackground(CGRect rect) {
	CGAffineTransform transform = CGAffineTransformIdentity;
	
	// Draw the top separator
	[[UIColor colorWithRed:0.353 green:0.388 blue:0.408 alpha:1.000] set];
	CGRect separatorRect = CGRectApplyAffineTransform(
		CGRectMake(0.0, -20.0, CGRectGetWidth(rect), 1.0),
		transform);
	UIRectFill(separatorRect);
	
	// Draw the background gradient
	UIColor* startColor = [UIColor colorWithRed:0.522 green:0.596 blue:0.682 alpha:1.000];
	UIColor* endColor = [UIColor colorWithRed:0.369 green:0.451 blue:0.565 alpha:1.000];
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGFloat locations[2] = { 0.0, 1.0 };
    		
	NSArray* colors = [NSArray arrayWithObjects:
		(id)[startColor CGColor],
		(id)[endColor CGColor],
		nil];
				
	CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);
	
	CGPoint startPoint = CGPointApplyAffineTransform(
		rect.origin,
		transform);
	CGPoint endPoint = CGPointApplyAffineTransform(
		CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect)),
		transform);
	
	CGContextDrawLinearGradient(
		UIGraphicsGetCurrentContext(),
		gradient,
		startPoint,
		endPoint,
		kCGGradientDrawsBeforeStartLocation|kCGGradientDrawsAfterEndLocation);
    		
	CGGradientRelease(gradient);  // release owned Core Foundation object
	
	// Now draw the inner shadow
	startColor = [[UIColor blackColor] colorWithAlphaComponent:1.0 / 3.0];
	endColor = [UIColor clearColor];
	
	CGFloat shadowLocations[2] = { 0.0, 0.1 };

	CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeSoftLight);
	
	startPoint = CGPointApplyAffineTransform(
		CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect)),
		transform);
	endPoint = CGPointApplyAffineTransform(
		CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect) - 50.0),
		transform);
		
	colors = [NSArray arrayWithObjects:
		(id)[startColor CGColor],
		(id)[endColor CGColor],
		nil];
				
	gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, shadowLocations);
	
	CGContextDrawLinearGradient(
		UIGraphicsGetCurrentContext(),
		gradient,
		startPoint,
		endPoint,
		kCGGradientDrawsBeforeStartLocation|kCGGradientDrawsAfterEndLocation);
	
	CGGradientRelease(gradient);
	
	CGColorSpaceRelease(colorSpace);  // release owned Core Foundation object
}

UIColor* AKOrnamentBackgroundColorWithHeight(CGFloat backgroundHeight) {
	CGSize imageSize = CGSizeMake(2.0, backgroundHeight);
	
	if(UIGraphicsBeginImageContextWithOptions) {
		UIGraphicsBeginImageContextWithOptions(imageSize, YES, 0.0);
	} else {
		UIGraphicsBeginImageContext(imageSize);
	}
	
	AKRectFillOrnamentBackground(CGRectMake(0.0, 0.0, 2.0, backgroundHeight));
	
	UIImage* backgroundImage = UIGraphicsGetImageFromCurrentImageContext();
	UIColor* backgroundColor = [UIColor colorWithPatternImage:backgroundImage];
	
	UIGraphicsEndImageContext();
	
	return backgroundColor;
}
