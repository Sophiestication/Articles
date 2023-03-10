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

#import "AKLockOrientationArrowView.h"

@implementation AKLockOrientationArrowView

@dynamic rotation;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
		self.arrowImage = [UIImage imageNamed:@"lockOrientationArrow.png"];
		
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
		
		self.clipsToBounds = NO;
		
		self.rotation = 180.0;
		self.pointingDown = YES;
	}

    return self;
}

- (void)dealloc {
	self.delegate = nil;
}

#pragma mark -
#pragma mark AKLockOrientationArrowView

- (CGFloat)rotation {
	return _rotation;
}

- (void)setRotation:(CGFloat)rotation {
	if(rotation != _rotation) {
		_rotation = MIN(MAX(rotation, 0.0), 180.0);

		[self setNeedsDisplay];
	}
}

- (void)pointUpwardAnimated:(BOOL)animated {
	if(!self.pointingDown) {
		return;
	}
	
	self.pointingDown = NO;
	
	if(animated) {
		[_animationTimer invalidate];
	
		_animationTimer = [NSTimer 
			timerWithTimeInterval:1.0 / 30.0
			target:self
			selector:@selector(upward)
			userInfo:nil
			repeats:YES];
		
		[[NSRunLoop currentRunLoop] addTimer:_animationTimer forMode:UITrackingRunLoopMode];
	} else {
		self.rotation = 0.0;
	}
}

- (void)upward {
	if(self.rotation <= 0.0 || self.rotation >= 360.0) {
		[_animationTimer invalidate], _animationTimer = nil;
		
		if([[self delegate] respondsToSelector:@selector(lockOrientationArrowView:didChangeOrientation:)]) {
			[[self delegate] lockOrientationArrowView:self didChangeOrientation:[self pointingDown]];
		}
	} else {
		self.rotation -= 30.0;
	}
}

- (void)pointDownwardAnimated:(BOOL)animated {
	if(self.pointingDown) {
		return;
	}
	
	self.pointingDown = YES;
	
	if(animated) {
		[_animationTimer invalidate];
		
		_animationTimer = [NSTimer 
			timerWithTimeInterval:1.0 / 30.0
			target:self
			selector:@selector(downward)
			userInfo:nil
			repeats:YES];
			
		[[NSRunLoop currentRunLoop] addTimer:_animationTimer forMode:UITrackingRunLoopMode];
	} else {
		self.rotation = 180.0;
	}
}

- (void)downward {
	if(self.rotation >= 180.0 || self.rotation <= -180.0) {
		[_animationTimer invalidate], _animationTimer = nil;
		
		if([[self delegate] respondsToSelector:@selector(lockOrientationArrowView:didChangeOrientation:)]) {
			[[self delegate] lockOrientationArrowView:self didChangeOrientation:[self pointingDown]];
		}
	} else {
		self.rotation += 30.0;
	}
}

#pragma mark -
#pragma mark UIView

- (CGSize)sizeThatFits:(CGSize)size {
	size = self.arrowImage.size;
	size.width += 10.0;
	size.height += 10.0;

	return size;
}

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGRect bounds = self.bounds;
	
	UIColor* shadowColor = [[UIColor blackColor]
		colorWithAlphaComponent:0.3];
		
	CGSize shadowOffset = CGSizeMake(0.0, 1.0);
		
//	if([[UIDevice currentDevice] systemVersionNumber] >= SYSTEMVERSION_3_2_0) {
		shadowOffset = CGSizeApplyAffineTransform(
			shadowOffset,
			CGContextGetCTM(UIGraphicsGetCurrentContext()));
//	}
	
//	if([UIScreen instancesRespondToSelector:@selector(scale)]) {
		if(self.window.screen.scale > 1.0) {
			shadowOffset.height = -1.0;
		}
//	}
	
	CGContextSetShadowWithColor(
		context,
		shadowOffset,
		0.0,
		[shadowColor CGColor]);
	
	CGContextTranslateCTM(context, bounds.size.width * 0.5, bounds.size.height * 0.5);
	CGContextRotateCTM(context, self.rotation * M_PI / 180.0f);
	CGContextTranslateCTM(context, -bounds.size.width * 0.5, -bounds.size.height * 0.5);

	CGPoint point = CGPointMake(
		floorf(CGRectGetMidX(bounds) - self.arrowImage.size.width * 0.5),
		floorf(CGRectGetMidY(bounds) - self.arrowImage.size.height * 0.5));
    [[self arrowImage] drawAtPoint:point];
}

@end
