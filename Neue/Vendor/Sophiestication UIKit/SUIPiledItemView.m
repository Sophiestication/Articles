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

#import "SUIPiledItemView.h"

#import <QuartzCore/QuartzCore.h>

@implementation SUIPiledItemView

#pragma mark - Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
		self.backgroundColor = [UIColor whiteColor];
		self.clipsToBounds = NO;

		self.layer.shadowColor = [[UIColor blackColor] CGColor];
    }

    return self;
}

#pragma mark - SUIPileDecorationView

- (void)setContentView:(UIView*)contentView {
	if(_contentView == contentView) { return; }

	[_contentView removeFromSuperview];
	_contentView = contentView;
	[self addSubview:contentView];

	[self setNeedsLayout];
}

- (void)setTransitionProgress:(CGFloat)transitionProgress {
	if(self.transitionProgress == transitionProgress) { return; }

	_transitionProgress = MIN(MAX(transitionProgress, 0.0), 1.0);
	[self setNeedsLayout];
}

- (void)prepareForReuse {
	// TODO
}

#pragma mark - UIView

- (void)willRemoveSubview:(UIView*)subview {
	[super willRemoveSubview:subview];

	if(subview == self.contentView) {
		_contentView = nil;
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];

	if(!CGSizeEqualToSize(self.contentView.frame.size, self.bounds.size)) {
		self.contentView.frame = self.bounds;
	}

	[self layoutContentShadowIfNeeded];
}

- (void)layoutContentShadowIfNeeded {
	CALayer* layer = self.layer;

	CGFloat transitionProgress = self.transitionProgress;

	CGFloat shadowRadius = 10.0;
	layer.shadowRadius = shadowRadius * transitionProgress;

	CGFloat shadowOpacity = 0.75;
	layer.shadowOpacity = shadowOpacity * transitionProgress;

	// update the shadow path if needed
	CGRect shadowRect = CGRectNull;
	CGRect contentRect = layer.bounds;

	CGPathIsRect([layer shadowPath], &shadowRect);

	if(!CGRectEqualToRect(shadowRect,contentRect)) {
		layer.shadowPath = [[UIBezierPath bezierPathWithRect:contentRect] CGPath];
	}
}

#pragma mark - Private

@end
