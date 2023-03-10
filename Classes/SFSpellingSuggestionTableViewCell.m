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

#import "SFSpellingSuggestionTableViewCell.h"

@implementation SFSpellingSuggestionTableViewCell

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if(self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier]) {
		self.textLabel.font = [UIFont systemFontOfSize:14.0];
		self.textLabel.textColor = [UIColor lightGrayColor];
		self.textLabel.textAlignment = NSTextAlignmentCenter;
		
		self.detailTextLabel.font = [UIFont boldSystemFontOfSize:16.0];
		self.detailTextLabel.textAlignment = NSTextAlignmentCenter;
	}

    return self;
}


#pragma mark -
#pragma mark UIView

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGFloat const margin = 5.0;
	
	CGRect contentRect = self.contentView.bounds;
	contentRect = CGRectInset(contentRect, margin * 2.0, margin * 2.0);
	
	CGSize textLabelSize = [[self textLabel]
		sizeThatFits:contentRect.size];
	CGSize detailTextLabelSize = [[self detailTextLabel]
		sizeThatFits:contentRect.size];
	
	CGSize contentSize = CGSizeMake(
		CGRectGetWidth(contentRect),
		textLabelSize.height + detailTextLabelSize.height);
	contentSize.height = MIN(contentSize.height, CGRectGetHeight(contentRect));
	
	CGRect newContentRect = CGRectMake(
		CGRectGetMinX(contentRect),
		floorf(CGRectGetMidY(contentRect) - contentSize.height * 0.5) - margin,
		CGRectGetWidth(contentRect),
		contentSize.height);
		
	CGRect textLabelRect = CGRectMake(
		CGRectGetMinX(newContentRect),
		CGRectGetMinY(newContentRect),
		CGRectGetWidth(newContentRect),
		textLabelSize.height);
	self.textLabel.frame = textLabelRect;
	
	CGRect detailTextLabelRect = CGRectMake(
		CGRectGetMinX(newContentRect),
		CGRectGetMaxY(textLabelRect),
		CGRectGetWidth(newContentRect),
		detailTextLabelSize.height);
	self.detailTextLabel.frame = detailTextLabelRect;
}

@end
