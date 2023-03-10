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

#import "SFBadgeAccessoryView.h"
#import "SFBadgeAccessoryView+Private.h"

#import "NSString+Additions.h"
#import "UIColor+Additions.h"

@implementation SFBadgeAccessoryView

@dynamic text;
@dynamic otherText;
@dynamic badgeColor;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
		[self initIvars];
	}

    return self;
}

- (id)initWithCoder:(NSCoder*)coder {
    if((self = [super initWithCoder:coder])) {
		[self initIvars];
	}

    return self;
}

- (void)dealloc {
	self.text = nil;
	self.otherText = nil;
	self.badgeColor = nil;
	
}

#pragma mark -
#pragma mark SFBadgeAccessoryView

- (NSString*)text {
	return _text;
}

- (void)setText:(NSString*)text {
	if(!SFEqualStrings(text, [self text])) {
		_text = [text copy];
		
		[self setNeedsDisplay];
	}
}

- (NSString*)otherText {
	return _otherText;
}

- (void)setOtherText:(NSString*)otherText {
	if(!SFEqualStrings(otherText, [self otherText])) {
		_otherText = [otherText copy];
		
		[self setNeedsDisplay];
	}
}

- (UIColor*)badgeColor {
	return _badgeColor;
}

- (void)setBadgeColor:(UIColor*)badgeColor {
	if(badgeColor != [self badgeColor]) {
		_badgeColor = badgeColor;
		
		[self setNeedsDisplay];
	}
}

- (SFControlSize)controlSize {
	return _controlSize;
}

- (void)setControlSize:(SFControlSize)controlSize {
	if(controlSize != _controlSize) {
		_controlSize = controlSize;

		[self setNeedsDisplay];
	}
}

#pragma mark -
#pragma mark UIView

- (void)setHighlighted:(BOOL)highlighted {
	if(highlighted != [self isHighlighted]) {
		[super setHighlighted:highlighted];
		[self setNeedsDisplay];
	}
}

- (CGSize)sizeThatFits:(CGSize)size {
	if(self.text.length <= 0) {
		return CGSizeZero;
	}
	
	if(size.width <= 0) {
		size.width = CGFLOAT_MAX;
	}
	
	UIFont* textFont = [self font];
	
	CGFloat const margin = self.controlSize == SFRegularControlSize ?
		10.0 :
		6.0;
	CGFloat textWidth = MAX(size.width - margin * 2.0, 0.0);
	
	CGSize textSize = [[self text]
		sizeWithFont:textFont
		forWidth:textWidth
		lineBreakMode:NSLineBreakByTruncatingMiddle];
		
	CGFloat const minimumHeight = self.controlSize == SFRegularControlSize ?
		21.0 :
		19.0;

	textSize.height = MIN(textSize.height, minimumHeight); // restrain to a minimum height
	textSize.width += margin * 2.0; // add some margins to the left and right
	
	if(self.otherText.length > 0) {
		CGSize otherTextSize = [[self otherText]
			sizeWithFont:textFont
			forWidth:textWidth
			lineBreakMode:NSLineBreakByTruncatingMiddle];
			
		textSize.width += otherTextSize.width + margin + 1.0; // 1px for the separator line
	}
	
	return textSize;
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	
	// Draw the badge
	CGRect bounds = self.bounds;
	CGRect badgeRect = bounds;
   
	CGFloat const cornerRadius = 10.0;
   
	CGContextRef context = UIGraphicsGetCurrentContext();

	// TODO Cache this bezier path for better performance
	CGContextBeginPath(context); {
		CGContextMoveToPoint(context, CGRectGetMinX(badgeRect) + cornerRadius, CGRectGetMinY(badgeRect));
		CGContextAddArc(context, CGRectGetMaxX(badgeRect) - cornerRadius, CGRectGetMinY(badgeRect) + cornerRadius, cornerRadius, 3.0 * M_PI / 2.0, 0.0, 0.0);
		CGContextAddArc(context, CGRectGetMaxX(badgeRect) - cornerRadius, CGRectGetMaxY(badgeRect) - cornerRadius, cornerRadius, 0.0, M_PI / 2.0, 0.0);
		CGContextAddArc(context, CGRectGetMinX(badgeRect) + cornerRadius, CGRectGetMaxY(badgeRect) - cornerRadius, cornerRadius, M_PI / 2.0, M_PI, 0.0);
		CGContextAddArc(context, CGRectGetMinX(badgeRect) + cornerRadius, CGRectGetMinY(badgeRect) + cornerRadius, cornerRadius, M_PI, 3.0 * M_PI / 2.0, 0.0);
	} CGContextClosePath(context);
   
	UIColor* badgeColor = [self badgeColorForControlState:[self state]];
	[badgeColor setFill];
	
	CGContextFillPath(context);
	
	// Use the clear blend mode to cut out the text from our badge
	if(self.highlighted) {
		CGContextSetBlendMode(context, kCGBlendModeClear);
	}

	// Now draw the text label
	UIColor* textColor = self.highlighted ?
		[UIColor clearColor] :
		[UIColor whiteColor];
	[textColor set];
	
	CGRect textRect = badgeRect;
	
	UIFont* textFont = [self font];
	CGSize textSize = [[self text]
		sizeWithFont:textFont
		forWidth:CGRectGetWidth(textRect)
		lineBreakMode:NSLineBreakByTruncatingMiddle];
	
	CGPoint textOrigin = CGPointMake(
		floorf(CGRectGetMidX(textRect) - textSize.width * 0.5),
		(CGRectGetMidY(textRect) - textSize.height * 0.5));
		
	if(self.otherText.length > 0) {
		CGSize otherTextSize = [[self otherText]
			sizeWithFont:textFont
			forWidth:CGRectGetWidth(textRect)
			lineBreakMode:NSLineBreakByTruncatingMiddle];
		
		CGFloat const separatorWidth = 1.0;
		
		CGFloat const margin = self.controlSize == SFRegularControlSize ?
			10.0 :
			6.0;
		textOrigin.x = CGRectGetMinX(textRect) + margin;
		
		CGPoint otherTextOrigin = CGPointMake(
			CGRectGetMaxX(textRect) - otherTextSize.width - margin + separatorWidth,
			(CGRectGetMidY(textRect) - otherTextSize.height * 0.5));
		
		CGRect separatorRect = CGRectMake(
			floorf(otherTextOrigin.x - (margin * 0.5) - separatorWidth * 0.5) - 1.0,
			CGRectGetMinY(textRect),
			separatorWidth,
			CGRectGetHeight(textRect));
		[[UIColor clearColor] set];
		UIRectFill(separatorRect);
		
		[textColor set];
		
		[[self otherText]
			drawAtPoint:otherTextOrigin
			forWidth:otherTextSize.width
			withFont:textFont
			minFontSize:0.0
			actualFontSize:NULL
			lineBreakMode:NSLineBreakByTruncatingMiddle
			baselineAdjustment:UIBaselineAdjustmentAlignCenters];
	}
	
	[[self text]
		drawAtPoint:textOrigin
		forWidth:textSize.width
		withFont:textFont
		minFontSize:0.0
		actualFontSize:NULL
		lineBreakMode:NSLineBreakByTruncatingMiddle
		baselineAdjustment:UIBaselineAdjustmentAlignCenters];
}

#pragma mark -
#pragma mark Private

- (void)initIvars {
	self.userInteractionEnabled = NO;
	self.contentMode = UIViewContentModeRedraw;
	
	self.controlSize = SFRegularControlSize;
	
	// We usually draw opaque and on a white background
	self.backgroundColor = [UIColor whiteColor];
	self.opaque = YES;
}

- (UIColor*)badgeColorForControlState:(UIControlState)controlState {
	// We always draw a white badge when highlighted
	if(controlState & UIControlStateHighlighted) {
		return [UIColor whiteColor];
	}
	
	// Now check if we have a custom badge color
	if(self.badgeColor) {
		return self.badgeColor;
	}
	
//	// Try to determine the color by the application's bar style
//	UIStatusBarStyle statusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
//
//	if(statusBarStyle == UIStatusBarStyleDefault) {
		return [UIColor colorWithRed:(140.0 / 0xff) green:(153.0 / 0xff) blue:(180.0 / 0xff) alpha:1.0];
//		// return [UIColor otherTableViewCellTextColor];
//	}
//
//	// Draw using a ugly fuckly gray tint
//	return [UIColor grayColor];
}

- (UIFont*)font {
	UIFont* font = self.controlSize == SFRegularControlSize ?
		[UIFont boldSystemFontOfSize:15.0] :
		[UIFont boldSystemFontOfSize:15.0];
	
	return font;
}

@end
