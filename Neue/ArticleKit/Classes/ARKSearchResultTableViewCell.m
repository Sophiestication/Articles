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

#import "ARKSearchResultTableViewCell.h"

#import <QuartzCore/QuartzCore.h>

@interface ARKSearchResultTableViewCell()

@property(nonatomic, strong, readwrite) ARKTableViewCellLabel* summaryTextLabel;
@property(nonatomic, strong, readwrite) ARKImagePreviewView* imagePreviewView;

@end

@implementation ARKSearchResultTableViewCell

#pragma mark - Construction & Destruction

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier {
    if((self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier])) {
		self.imagePreviewShown = YES;

		[self initTextLabel];
		[self initSummaryTextLabel];
		[self initImagePreviewView];
    }

    return self;
}

#pragma mark - ARKSearchResultTableViewCell

+ (CGFloat)preferredHeight { return 110.0; }

- (void)setImagePreviewShown:(BOOL)imagePreviewShown {
	if(self.imagePreviewShown == imagePreviewShown) { return; }
	
	_imagePreviewShown = imagePreviewShown;
	[self setNeedsLayout];
}

#pragma mark - UITableViewCell

- (void)prepareForReuse {
	[super prepareForReuse];
	
	self.imagePreviewShown = YES;

	self.imagePreviewView.image = nil;
	self.imagePreviewView.errorIndicatorShown = NO;
	self.imagePreviewView.progressIndicatorShown = NO;

	self.summaryTextLabel.attributedText = nil;
}

- (void)layoutSubviews {
	[super layoutSubviews];

	CGFloat const padding = 10.0;
	CGRect contentRect = self.contentView.bounds;

	CGFloat const maxContentWidth = 400.0;

	if(CGRectGetWidth(contentRect) > maxContentWidth) {
		contentRect.origin.x = ceil(CGRectGetMidX(contentRect) - maxContentWidth * 0.5);
		contentRect.size.width = maxContentWidth;
	}

	CGRect textContentRect = contentRect;
	textContentRect.origin.x += padding;
	textContentRect.origin.y += padding;
	textContentRect.size.width -= 80.0 + padding + 4.0;
	textContentRect.size.height -= padding;

	CGRect imageRect = CGRectMake(
		CGRectGetMaxX(textContentRect) + 3.0,
		CGRectGetMinY(textContentRect) - 1.0,
		76.0,
		76.0);
		
	if(!self.imagePreviewShown) {
		textContentRect.size.width += 74.0;
	}

	CGRect textLabelRect = self.textLabel.frame;
	textLabelRect.origin = textContentRect.origin;
	textLabelRect.size.width = CGRectGetWidth(textContentRect);

	CGFloat const paragraphSpacing = 2.0;

	CGRect summaryTextLabelRect = CGRectMake(
		CGRectGetMinX(textLabelRect),
		CGRectGetMaxY(textLabelRect) + paragraphSpacing,
		CGRectGetWidth(textContentRect),
		round(CGRectGetHeight(textContentRect) - CGRectGetMaxY(textLabelRect) - paragraphSpacing));

	CGSize summaryTextLabelSize = [[self summaryTextLabel]
		sizeThatFits:summaryTextLabelRect.size];
	summaryTextLabelRect.size.height = ceil(MIN(summaryTextLabelSize.height, CGRectGetHeight(summaryTextLabelRect)));

	self.summaryTextLabel.backgroundColor = self.textLabel.backgroundColor;

	self.imagePreviewView.frame = imageRect;
	self.textLabel.frame = textLabelRect;
	self.summaryTextLabel.frame = summaryTextLabelRect;
	
	self.imagePreviewView.hidden = !self.imagePreviewShown;

//	self.imagePreviewView.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.7];
//	self.summaryTextLabel.backgroundColor = [[UIColor orangeColor] colorWithAlphaComponent:0.7];
//	self.textLabel.backgroundColor = [[UIColor yellowColor] colorWithAlphaComponent:0.7];
}

#pragma mark - Private

- (void)initTextLabel {
	UILabel* textLabel = self.textLabel;

	if(![[UIFont class] respondsToSelector:@selector(preferredFontForTextStyle:)]) {
		textLabel.font = [UIFont boldSystemFontOfSize:16.0];	
	}

	textLabel.adjustsLetterSpacingToFitWidth = YES;
}

- (void)initSummaryTextLabel {
	ARKTableViewCellLabel* label = [[ARKTableViewCellLabel alloc] initWithFrame:CGRectZero];

	self.summaryTextLabel = label;
	[[self contentView] addSubview:label];
}

- (void)initImagePreviewView {
	ARKImagePreviewView* imagePreviewView = [[ARKImagePreviewView alloc] initWithFrame:CGRectZero];

	self.imagePreviewView = imagePreviewView;
	[[self contentView] addSubview:imagePreviewView];
}

@end
