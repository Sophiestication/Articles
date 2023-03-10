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

#import "SFBarButtonItemWell.h"
#import "SFBarButtonItemWell+Private.h"

#import "SFWiggleView.h"
#import "SFBarButtonItem+Private.h"

@implementation SFBarButtonItemWell

@synthesize buttonItem = _buttonItem;
@synthesize textLabel = _textLabel;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithBarButtonItem:(SFBarButtonItem*)buttonItem {
	if((self = [super initWithFrame:CGRectZero])) {
		self.buttonItem = buttonItem;
		
		[self initIvars];
		[self initTextLabel];
		
		self.textLabel.text = buttonItem.title;
	}
	
	return self;
}


#pragma mark -
#pragma mark SFBarButtonItemWell

- (CGRect)contentViewRect {
	static CGFloat const wellSize = 50.0;
	
	CGRect contentRect = CGRectMake(
		floorf(CGRectGetMidX(self.bounds) - wellSize * 0.5),
		10.0,
		wellSize,
		wellSize);

	return contentRect;
}

#pragma mark -
#pragma mark UIView

- (CGSize)sizeThatFits:(CGSize)size {
	return CGSizeMake(50.0, 50.0);
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect contentRect = self.bounds;
	contentRect = CGRectInset(contentRect, 5.0, 0.0);
	
	CGSize textLabelSize = [[self textLabel]
		sizeThatFits:contentRect.size];
	
	CGRect textLabelRect = CGRectMake(
		floorf(CGRectGetMidX(contentRect) - textLabelSize.width * 0.5),
		floorf(CGRectGetMaxY(contentRect) - textLabelSize.height - 2.0),
		floorf(textLabelSize.width),
		floorf(textLabelSize.height));
	self.textLabel.frame = textLabelRect;
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	
	static CGFloat const cornerRadius = 7.0;
	
	static CGFloat const lineWidth = 0.5;

	CGRect contentRect = [self contentViewRect];
	contentRect = CGRectInset(contentRect, lineWidth, lineWidth);
	
	UIBezierPath* path = [UIBezierPath
		bezierPathWithRoundedRect:contentRect
		cornerRadius:cornerRadius];
	
	[[UIColor colorWithRed:0.950 green:0.955 blue:0.966 alpha:1.000] setFill];
	[[UIColor colorWithRed:0.443 green:0.461 blue:0.491 alpha:0.8] setStroke];
		
	path.lineWidth = lineWidth;

	CGFloat dashPattern[2] = { 4, 3 };
	[path setLineDash:dashPattern count:2 phase:0.0];
	
	[path fill];
	[path stroke];
}

#pragma mark -
#pragma mark Private

- (void)initIvars {
	self.opaque = NO;
	self.backgroundColor = [UIColor clearColor];
		
	self.contentMode = UIViewContentModeRedraw;
	
	self.clipsToBounds = NO;
}

- (void)initTextLabel {
	UILabel* textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	
	textLabel.opaque = NO;
	textLabel.backgroundColor = [UIColor clearColor];
	
	textLabel.textColor = [UIColor colorWithRed:0.455 green:0.514 blue:0.608 alpha:1.000];
	textLabel.font = [UIFont boldSystemFontOfSize:11.0];
	
	textLabel.textAlignment = NSTextAlignmentCenter;
	
	self.textLabel = textLabel;
	[self addSubview:textLabel];
}

@end
