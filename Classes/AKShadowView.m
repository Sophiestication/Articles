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

#import "AKShadowView.h"

@implementation AKShadowView

@synthesize offset = _offset;
@synthesize blur = _blur;
@synthesize shadowColor = _shadowColor;
@dynamic shadowEdge;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
		self.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
		
		self.blur = 10.0;
		self.offset = CGSizeZero;
	}

    return self;
}


#pragma mark -
#pragma mark AKShadowView

- (AKShadowViewEdge)shadowEdge {
	return _shadowEdge;
}

- (void)setShadowEdge:(AKShadowViewEdge)shadowEdge {
	if(shadowEdge != self.shadowEdge) {
		_shadowEdge = shadowEdge;
		[self setNeedsDisplay];
	}
}

#pragma mark -
#pragma mark UIView

- (CGSize)sizeThatFits:(CGSize)size {
	return CGSizeMake(16.0, 16.0);
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	
	CGContextSetShadowWithColor(
		UIGraphicsGetCurrentContext(),
		[self offset],
		[self blur],
		[[self shadowColor] CGColor]);
	
	CGRect bounds = self.bounds;
	
	CGSize contentSize = [self sizeThatFits:bounds.size];
	CGRect contentRect;
	
	switch(self.shadowEdge) {
		case AKShadowViewEdgeTop: {
			contentRect = CGRectMake(
				CGRectGetMinX(bounds),
				CGRectGetMinY(bounds) + contentSize.height,
				CGRectGetWidth(bounds),
				contentSize.height);
		} break;
		
		case AKShadowViewEdgeRight: {
			contentRect = CGRectMake(
				CGRectGetMinX(bounds) - contentSize.width,
				CGRectGetMinY(bounds),
				contentSize.width,
				CGRectGetHeight(bounds));
		} break;
		
		case AKShadowViewEdgeBottom: {
			contentRect = CGRectMake(
				CGRectGetMinX(bounds),
				CGRectGetMinY(bounds) - contentSize.height,
				CGRectGetWidth(bounds),
				contentSize.height);
		} break;
		
		case AKShadowViewEdgeLeft: {
			contentRect = CGRectMake(
				contentSize.width,
				CGRectGetMinY(bounds),
				contentSize.width,
				CGRectGetHeight(bounds));
		} break;
	}
	
	[[UIColor whiteColor] set];
	UIRectFill(contentRect);
}

@end
