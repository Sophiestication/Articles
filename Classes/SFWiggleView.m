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

#import "SFWiggleView.h"
#import "SFWiggleView+Private.h"

@implementation SFWiggleView

@synthesize contentView = _contentView;
@dynamic wiggling;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithContentView:(UIView*)contentView {
	if((self = [super initWithFrame:[contentView bounds]])) {
		self.clipsToBounds = NO;
		
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
		
		self.userInteractionEnabled = NO;
		
		self.contentView = contentView;
		[self addSubview:contentView];
	}

    return self;
}

- (void)dealloc {
	self.wiggling = NO; // stop the wiggle animation

}

#pragma mark -
#pragma mark SFWiggleView

- (BOOL)isWiggling {
	return _wiggling;
}

- (void)setWiggling:(BOOL)wiggling {
	if(self.wiggling != wiggling) {
		_wiggling = wiggling;
		
		if(wiggling) {
			[self wiggle:nil];
		} else {
			self.contentView.transform = CGAffineTransformIdentity;
		}
	}
}

#pragma mark -
#pragma mark UIView

- (CGSize)sizeThatFits:(CGSize)size {
	return [[self contentView] sizeThatFits:size];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect contentRect = self.bounds;
	self.contentView.center = CGPointMake(
		CGRectGetMidX(contentRect),
		CGRectGetMidY(contentRect));
}

- (void)removeFromSuperview {
	self.wiggling = NO;
	[super removeFromSuperview];
}

#pragma mark -
#pragma mark Private

- (void)wiggle:(id)sender {
	if(![self isWiggling]) { return; }
	
	id animations = ^() {
		if(self.hidden) { return; }
		if(!self.wiggling) { return; }
		
		_alternating = !_alternating;
		CGFloat rotation = 4.0;

		if(_alternating) {
			rotation = -rotation;
		}
		
		CGAffineTransform rotationTransform = CGAffineTransformMakeRotation((M_PI / 180.0) * rotation);
		self.contentView.transform = rotationTransform;
	};
	
	id completion = ^(BOOL finished) {
		[self wiggle:self];
	};
	
	[UIView
		animateWithDuration:0.1
		delay:0.0
		options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState
		animations:animations
		completion:completion];
}

@end
