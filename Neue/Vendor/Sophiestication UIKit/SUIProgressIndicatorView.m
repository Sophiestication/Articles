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

#import "SUIProgressIndicatorView.h"
#import <QuartzCore/QuartzCore.h>

@interface SUIProgressIndicatorView()

@property(nonatomic) CGFloat rotation;
@property(nonatomic, weak) CADisplayLink* displayLink;

@end

@implementation SUIProgressIndicatorView

#pragma mark - Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
		[self initIvars];
    }

    return self;
}

#pragma mark - SUIProgressIndicatorView

- (void)setStyle:(SUIProgressIndicatorStyle)style {
	if(self.style == style) { return; }

	_style = style;
	[self setNeedsDisplay];
	
	[self updateForStyle:style];
}

- (void)setProgress:(float)progress {
	[self setProgress:progress animated:NO];
}

- (void)setProgress:(float)progress animated:(BOOL)animated {
	if(self.progress == progress) { return; }

	_progress = progress;
	[self setNeedsDisplay];

	// TODO
}

- (void)setTintColor:(UIColor*)tintColor {
	if([[self tintColor] isEqual:tintColor]) { return; }

	_tintColor = [tintColor copy];
	[self setNeedsDisplay];
}

#pragma mark - UIView

- (CGSize)sizeThatFits:(CGSize)size {
	CGFloat extend = MIN(size.width, size.height);
	return CGSizeMake(extend, extend);
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	
	SUIProgressIndicatorStyle style = self.style;

	CGContextRef context = UIGraphicsGetCurrentContext();
	
	[[self backgroundColor] set];
	UIRectFill(rect);

	UIColor* tintColor = self.tintColor;
	if(!tintColor) { tintColor = [UIColor darkTextColor]; } // TODO

	[tintColor setFill];
	[tintColor setStroke];
	
//	UIColor* shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
//	CGSize shadowOffset = CGSizeMake(0.0, 1.0);
//
//	CGContextSetShadowWithColor(context, shadowOffset, 0.75, [shadowColor CGColor]);

	static CGFloat const nativeContentWidth = 32.0;
	static CGFloat const nativeLineWidth = 3.0;
	
	CGRect bounds = self.bounds;
	CGFloat scaleFactor = CGRectGetWidth(bounds) / nativeContentWidth;

	CGFloat lineWidth = nativeLineWidth * scaleFactor;
	lineWidth = roundf(lineWidth * 100.0) / 100.0;
	
	CGRect contentRect = CGRectInset(bounds, lineWidth, lineWidth);

	CGContextSetLineWidth(context, lineWidth);
	
	CGFloat rotation = self.rotation;
	if(style != SUIProgressIndicatorStyleActivity) { rotation = 270.0; }
	
	CGContextTranslateCTM(context, CGRectGetWidth(bounds) * 0.5, CGRectGetWidth(bounds) * 0.5);
	CGContextRotateCTM(context, rotation * M_PI / 180.0);
	CGContextTranslateCTM(context, -CGRectGetWidth(bounds) * 0.5, -CGRectGetWidth(bounds) * 0.5);
	
	CGFloat progress = self.progress;
	if(style == SUIProgressIndicatorStyleActivity) { progress = 0.25; }
	
	// ...
	CGContextBeginPath(context);

	CGContextAddEllipseInRect(context, contentRect);
	CGContextReplacePathWithStrokedPath(context);

	CGContextMoveToPoint(context, CGRectGetMidX(contentRect), CGRectGetMidY(contentRect));

	CGContextAddArc(
		context,
		CGRectGetMidX(contentRect),
		CGRectGetMidY(contentRect),
		CGRectGetWidth(contentRect) / 2.5,
		0.0,
		(360.0 * progress) * M_PI / 180.0,
		0.0);

	CGContextAddLineToPoint(context, CGRectGetMidX(contentRect), CGRectGetMidY(contentRect));

	CGContextClosePath(context);
	
	CGContextFillPath(context);
}

#pragma mark - Private

- (void)initIvars {
	self.opaque = NO;
	self.backgroundColor = [UIColor clearColor];

	self.contentMode = UIViewContentModeRedraw;

	self.progress = 0.0;
	self.rotation = 270.0;
}

- (void)updateForStyle:(SUIProgressIndicatorStyle)style {
	if(style == SUIProgressIndicatorStyleActivity) {
		[self scheduleDisplayLinkIfNeeded];
	} else {
		[self invalidateDisplayLink];
	}
}

- (void)scheduleDisplayLinkIfNeeded {
	if(self.displayLink) { return; }

	CADisplayLink* displayLink = [CADisplayLink
		displayLinkWithTarget:self
		selector:@selector(displayLinkDidUpdate:)];
		
	self.displayLink = displayLink;
	
	NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
	[displayLink addToRunLoop:runLoop forMode:NSRunLoopCommonModes];
	[displayLink addToRunLoop:runLoop forMode:UITrackingRunLoopMode];
}

- (void)invalidateDisplayLink {
	if(!self.displayLink) { return; }
	
	[[self displayLink] invalidate];
	self.displayLink = nil;
}

- (void)displayLinkDidUpdate:(CADisplayLink*)displayLink {
	static CGFloat const maximumRotation = 360.0;
	static NSTimeInterval const duration = 3.0;
	
	NSTimeInterval timeInterval = [displayLink timestamp] / duration;
    
	CGFloat newRotation = maximumRotation * (timeInterval - floor(timeInterval));
	newRotation = round(newRotation * 10.0) / 10.0;
	
	if(self.rotation != newRotation){
		self.rotation = newRotation;
		[self setNeedsDisplay];
	}
	
	// NSLog(@"%f", [displayLink timestamp]);
}

@end
