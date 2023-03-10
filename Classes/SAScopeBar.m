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

#import "SAScopeBar.h"

#import "UIButton+Graphite.h"
#import "UILabel+Graphite.h"

@implementation SAScopeBar

#pragma mark - Construction & Destruction

- (id)initWithCoder:(NSCoder*)coder {
    if(self = [super initWithCoder:coder]) {
		[self setBackgroundImage:[UIImage imageNamed:@"miniScopeBarBackground.png"] forState:UIControlStateNormal];
		[self setBackgroundImage:[UIImage imageNamed:@"miniScopeBarBackgroundHighlighted.png"] forState:UIControlStateHighlighted];
		
		self.contentEdgeInsets = UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0);
		
		[self setImage:[UIImage imageNamed:@"scopeBarDisclosureIndicator.png"] forState:UIControlStateNormal];
		[self setImage:[UIImage imageNamed:@"scopeBarDisclosureIndicatorHighlighted.png"] forState:UIControlStateHighlighted];
		
		self.imageView.contentMode = UIViewContentModeCenter;

		[self setTitle:@"Russian" forState:UIControlStateNormal];

		[self setTitleShadowColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5] forState:UIControlStateNormal];
		[self setTitleShadowColor:[[UIColor blackColor] colorWithAlphaComponent:1.0 / 3.0] forState:UIControlStateHighlighted];
		
		self.titleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
		// self.reversesTitleShadowWhenHighlighted = YES;

		[self setTitleColor:[UIColor colorWithRed:69.0 / 256.0 green:90.0 / 256.0 blue:119.0 / 256.0 alpha:1.0] forState:UIControlStateNormal];
		[self setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
	
		self.titleLabel.font = [UIFont boldSystemFontOfSize:13.5];
		self.titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
	}

    return self;
}

#pragma mark - UIButton

- (CGRect)backgroundRectForBounds:(CGRect)bounds {
	return [super backgroundRectForBounds:bounds];
}

- (CGRect)contentRectForBounds:(CGRect)bounds {
	return [super contentRectForBounds:bounds];
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect {
	CGRect titleRect = [super titleRectForContentRect:contentRect];
	
	titleRect.origin.x = CGRectGetMinX(contentRect);
	
	return titleRect;
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect {
	CGRect imageRect = [super imageRectForContentRect:contentRect];
	
	imageRect.origin.x = CGRectGetMaxX(contentRect) - CGRectGetWidth(imageRect);
	
	return imageRect;
}

#pragma mark - UIView

- (void)layoutSubviews {
	[super layoutSubviews];

	// custom shadow offset handling on iOS 6
	self.titleLabel.shadowOffset = self.highlighted ?
		CGSizeMake(0.0, -1.0) :
		CGSizeMake(0.0, 1.0);
}

@end
