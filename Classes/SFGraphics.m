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

#import "SFGraphics.h"

void SFGraphicsDrawImage(UIImage* image, CGRect rect, SFGraphicsInterfaceStyle interfaceStyle, UIControlState controlState) {
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGContextSaveGState(context); {
	
		// First setup our transforms
		CGRect bounds = CGContextGetClipBoundingBox(context);
		
		CGContextTranslateCTM(context, 0.0, CGRectGetHeight(bounds));
		CGContextScaleCTM(context, 1.0, -1.0);
	
		// Setup our colors
		UIColor* color = nil;
		
		UIColor* shadowColor = nil;
		CGSize shadowOffset = CGSizeZero;
		CGFloat shadowBlur = 0.0;
		
		if(interfaceStyle == SFGraphicsInterfaceStyleGraphite) {
			if(controlState == UIControlStateNormal ||
			   controlState & UIControlStateDisabled) {
				color = [UIColor colorWithRed:69.0 / 256.0 green:90.0 / 256.0 blue:119.0 / 256.0 alpha:1.0];
				
				shadowColor = [[UIColor whiteColor] colorWithAlphaComponent:0.75];
				shadowOffset = CGSizeMake(0.0, 1.0);
				shadowBlur = 1.0;
			} else {
				color = [UIColor whiteColor];
				
				shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
				shadowOffset = CGSizeMake(0.0, -1.0);
				shadowBlur = 1.0;
			}
		}
		
		CGImageRef CGImage = [image CGImage];
		
		// ...
		CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
		
		// Set out shadow
		CGContextSetShadowWithColor(context, shadowOffset, shadowBlur, [shadowColor CGColor]);
		CGContextDrawImage(context, rect, CGImage);
		
		// Now clip the context to our image and fill using color
		CGContextClipToMask(context, rect, CGImage);
		
		[color set];
		UIRectFill(rect);
		
	} CGContextRestoreGState(context);
}
