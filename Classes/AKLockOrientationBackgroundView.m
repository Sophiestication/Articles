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

#import "AKLockOrientationBackgroundView.h"

@implementation AKLockOrientationBackgroundView

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
	}

    return self;
}


#pragma mark -
#pragma mark UIView

- (CGSize)sizeThatFits:(CGSize)size {
	size.height = 50.0;
	return size;
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];

	CGRect bounds = self.bounds;
	
	CGSize size = [self sizeThatFits:bounds.size];
	
	// Now draw the inner shadow
	UIColor* startColor = [[UIColor blackColor] colorWithAlphaComponent:1.0 / 3.0];
	UIColor* endColor = [UIColor clearColor];
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGFloat locations[2] = { 0.0, 1.0 };
    		
	// the context is flipped so switch start and end color
	NSArray* colors = [NSArray arrayWithObjects:
		(id)[endColor CGColor],
		(id)[startColor CGColor],
		nil];
				
	CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);
	CGColorSpaceRelease(colorSpace);  // release owned Core Foundation object
	
	CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeSoftLight);
	
	CGContextDrawLinearGradient(
		UIGraphicsGetCurrentContext(),
		gradient,
		CGPointMake(CGRectGetMinX(bounds), CGRectGetMaxY(bounds)),
		CGPointMake(CGRectGetMinX(bounds), CGRectGetMaxY(bounds) - size.height),
		kCGGradientDrawsBeforeStartLocation|kCGGradientDrawsAfterEndLocation);
    		
	CGGradientRelease(gradient);  // release owned Core Foundation object
}

@end
