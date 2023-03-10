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

#import "SFPlaceholderView.h"
#import "SFPlaceholderView+Private.h"

@implementation SFPlaceholderView

@synthesize imageView = _imageView;
@synthesize textLabel = _textLabel;
@synthesize detailTextLabel = _detailTextLabel;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
		[self initIvars];
		[self initSubviews];
	}

    return self;
}

- (id)initWithCoder:(NSCoder*)coder {
    if(self = [super initWithCoder:coder]) {
		[self initIvars];
		[self initSubviews];
	}

    return self;
}


#pragma mark -
#pragma mark UIView

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGFloat const margin = 5.0;
	
	CGRect bounds = self.bounds;
	bounds = CGRectInset(bounds, margin, margin * 2.0);
	
	CGSize textLabelSize = [[self textLabel]
		sizeThatFits:bounds.size];
	textLabelSize.width = MIN(textLabelSize.width, CGRectGetWidth(bounds));
		
	CGSize detailTextLabelSize = [[self detailTextLabel]
		sizeThatFits:bounds.size];
	detailTextLabelSize.width = MIN(detailTextLabelSize.width, CGRectGetWidth(bounds));
	
	CGSize imageSize = CGSizeMake(
		CGRectGetWidth(bounds),
		CGRectGetHeight(bounds) - textLabelSize.height - detailTextLabelSize.height);
	CGSize imageSizeThatFits = [[self imageView] sizeThatFits:imageSize];
	
	imageSize = CGSizeMake(
		MIN(imageSize.width, imageSizeThatFits.width),
		MIN(imageSize.height, imageSizeThatFits.height));
	
	CGRect imageRect = CGRectMake(
		floorf(CGRectGetMidX(bounds) - imageSize.width * 0.5),
		ceilf(CGRectGetMidY(bounds) - imageSize.height * 0.5 - textLabelSize.height - margin /*- detailTextLabelSize.height*/ ),
		imageSize.width,
		imageSize.height);
	self.imageView.frame = imageRect;
	
//	CGFloat textLabelMargin = CGRectGetWidth(bounds) > CGRectGetHeight(bounds) ?
//		0.0 :
//		margin;
		
	CGRect textLabelRect = CGRectMake(
		floorf(CGRectGetMidX(bounds) - textLabelSize.width * 0.5),
		CGRectGetMaxY(imageRect),
		textLabelSize.width,
		textLabelSize.height);
	self.textLabel.frame = textLabelRect;
	
	CGRect detailTextLabelRect = CGRectMake(
		floorf(CGRectGetMidX(bounds) - detailTextLabelSize.width * 0.5),
		CGRectGetMaxY(textLabelRect) + margin,
		detailTextLabelSize.width,
		detailTextLabelSize.height);
	self.detailTextLabel.frame = detailTextLabelRect;
}

#pragma mark -
#pragma mark Private

- (void)initIvars {
	self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleBottomMargin;
	
	self.opaque = YES;
	self.backgroundColor = [UIColor whiteColor];
}

- (void)initSubviews {
	// Init the image view
	UIImageView* imageView = [[UIImageView alloc] initWithImage:nil];
	
	imageView.opaque = self.opaque;
	imageView.backgroundColor = self.backgroundColor;
	
	imageView.contentMode = UIViewContentModeScaleAspectFit;
	
	[self addSubview:imageView];
	self.imageView = imageView;
	
	// Init the text label
	UILabel* textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	
	textLabel.opaque = self.opaque;
	textLabel.backgroundColor = self.backgroundColor;
	
	UIColor* textColor = [UIColor colorWithRed:0.374 green:0.416 blue:0.480 alpha:1.000];
	textLabel.textColor = textColor;
	
	textLabel.font = [UIFont boldSystemFontOfSize:17.0];
	
	textLabel.textAlignment = NSTextAlignmentCenter;
	
	[self addSubview:textLabel];
	self.textLabel = textLabel;
	
	// Init the detail text label
	UILabel* detailTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	
	detailTextLabel.opaque = self.opaque;
	detailTextLabel.backgroundColor = self.backgroundColor;
	
	detailTextLabel.textColor = textColor;
	detailTextLabel.font = [UIFont boldSystemFontOfSize:13.0];
	
	detailTextLabel.textAlignment = NSTextAlignmentCenter;
	detailTextLabel.numberOfLines = 0;
	detailTextLabel.contentMode = UIViewContentModeTop;
	
	[self addSubview:detailTextLabel];
	self.detailTextLabel = detailTextLabel;
	
//	imageView.backgroundColor = [UIColor orangeColor];
//	textLabel.backgroundColor = [UIColor greenColor];
//	detailTextLabel.backgroundColor = [UIColor redColor];
}

@end
