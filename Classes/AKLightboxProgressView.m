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

#import "AKLightboxProgressView.h"
#import "AKLightboxProgressView+Private.h"

#import <QuartzCore/QuartzCore.h>

@implementation AKLightboxProgressView

@dynamic progress;
@dynamic style;
@synthesize rotation = _rotation;
@synthesize color = _color;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
		self.rotation = 270.0;
		_rotationTimer = nil;
		
		self.style = AKLightboxProgressViewStyleDetermined;
		
		self.progress = 0.0;
		self.color = [UIColor whiteColor];
		
		self.userInteractionEnabled = NO;
		
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
		
		/*CAShapeLayer* shapeLayer = (CAShapeLayer*)self.layer;
		shapeLayer.fillColor = [[self color] CGColor];
		//shapeLayer.fillRule = kCAFillRuleEvenOdd;
		
		UIBezierPath* path = [self pathForContentRect:CGRectMake(0.0, 0.0, 38.0, 38.0)];
		shapeLayer.path = [path CGPath];*/
	}

    return self;
}

- (void)dealloc {
	[_rotationTimer invalidate];
}

#pragma mark -
#pragma mark AKLightboxProgressView

- (float)progress {
	return _progress;
}

- (void)setProgress:(float)progress {
	if(self.progress != progress) {
		_progress = progress;
		[self setNeedsDisplay];
	}
}

- (AKLightboxProgressViewStyle)style {
	return _style;
}

- (void)setStyle:(AKLightboxProgressViewStyle)style {
	if(self.style != style) {
		_style = style;
		
		if(self.style == AKLightboxProgressViewStyleActivity) {
			[self rotate];
		} else {
			[_rotationTimer invalidate], _rotationTimer = nil;
		}
		
		[self setNeedsDisplay];
	}
}

#pragma mark -
#pragma mark UIView

/*+ (Class)layerClass {
	return [CAShapeLayer class];
}*/

- (CGSize)sizeThatFits:(CGSize)size {
	return CGSizeMake(32.0, 32.0);
}

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();

	[[self color] set];
	[[self color] setStroke];
	
	UIColor* shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
	CGSize shadowOffset = CGSizeMake(0.0, 1.0);

	CGContextSetShadowWithColor(context, shadowOffset, 0.75, [shadowColor CGColor]);
	
	CGRect bounds = self.bounds;
	CGRect contentRect = CGRectInset(bounds, 3.0, 3.0);

	CGContextSetLineWidth(context, 3.0);
	
	CGFloat rotation = _rotationTimer ?
		self.rotation :
		270.0;
	
	CGContextTranslateCTM(context, CGRectGetWidth(bounds) * 0.5, CGRectGetWidth(bounds) * 0.5);
	CGContextRotateCTM(context, rotation * M_PI / 180.0);
	CGContextTranslateCTM(context, -CGRectGetWidth(bounds) * 0.5, -CGRectGetWidth(bounds) * 0.5);
	
	CGFloat progress = _rotationTimer ?
		MAX(self.progress, 0.25) :
		self.progress;
	
	// ...
	CGContextBeginPath(context);

	CGContextAddEllipseInRect(context, contentRect);
	CGContextReplacePathWithStrokedPath(context);

	CGContextMoveToPoint(context, CGRectGetMidX(contentRect), CGRectGetMidY(contentRect));
	CGContextAddArc(context, CGRectGetMidX(contentRect), CGRectGetMidY(contentRect), CGRectGetWidth(contentRect) / 2.4 /*14.0*/, 0.0, (360.0 * progress) * M_PI / 180.0, 0);
	CGContextAddLineToPoint(context, CGRectGetMidX(contentRect), CGRectGetMidY(contentRect));

	CGContextClosePath(context);
	
	CGContextFillPath(context);
}

#pragma mark -
#pragma mark Private

- (void)rotate {
	[_rotationTimer invalidate];

	CGFloat framesPerSecond = 60.0;

	_rotationTimer = [NSTimer 
		scheduledTimerWithTimeInterval:1.25 / framesPerSecond
		target:self
		selector:@selector(advanceRotation)
		userInfo:nil
		repeats:YES];
		
	[[NSRunLoop currentRunLoop] addTimer:_rotationTimer forMode:UITrackingRunLoopMode];
}

- (void)advanceRotation {
	if(self.style == AKLightboxProgressViewStyleDetermined) {
		if(self.rotation < 270.0 && self.rotation + 6.0 >= 270.0) {
			[_rotationTimer invalidate], _rotationTimer = nil;
			self.rotation = 270.0;
			[self setNeedsDisplay];
		
			return;
		}
	}

	self.rotation += 6.0;
	
	if(self.rotation > 360.0) {
		self.rotation -= 360.0;
	}
	
	[self setNeedsDisplay];
}

- (UIBezierPath*)pathForContentRect:(CGRect)contentRect {
	UIBezierPath* path = [UIBezierPath bezierPath];
	
	float start = (M_PI * 2.0 * 0.25) - (M_PI / 2.0);
	
	[path moveToPoint:CGPointMake(CGRectGetMidX(contentRect), CGRectGetMidY(contentRect))];
	[path addArcWithCenter:CGPointMake(CGRectGetMidX(contentRect), CGRectGetMidY(contentRect)) radius:14.0 startAngle:start endAngle: start + (M_PI/2.0) clockwise:YES];
	[path addLineToPoint:CGPointMake(CGRectGetMidX(contentRect), CGRectGetMidY(contentRect))];
	
	[path closePath];
	
	CGAffineTransform transform = CGAffineTransformIdentity;
	
	transform = CGAffineTransformTranslate(transform, CGRectGetWidth(contentRect) * 0.5, CGRectGetWidth(contentRect) * 0.5);
	transform = CGAffineTransformRotate(transform, -90.0 * M_PI / 180.0);
	
	[path applyTransform:transform];
	
//	[path moveToPoint:CGPointMake(CGRectGetMidX(contentRect), CGRectGetMidY(contentRect))];
//	[path addArcWithCenter:CGPointMake(CGRectGetMidX(contentRect), CGRectGetMidY(contentRect)) radius:14.0 startAngle:0.0 endAngle:(360.0 * 0.25) * M_PI / 180.0 clockwise:NO];
//	[path addLineToPoint:CGPointMake(CGRectGetMidX(contentRect), CGRectGetMidY(contentRect))];
	
	return path;
}

@end
