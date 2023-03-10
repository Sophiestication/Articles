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

#import "SFLoadingTableViewCell.h"

@implementation SFLoadingTableViewCell

@synthesize activityIndicatorView = _activityIndicatorView;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if(self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
		// ...
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		
		// Init the text label
		self.textLabel.text = NSLocalizedString(@"LOADING_MORE_LABEL", @"");
		
		self.textLabel.font = [UIFont systemFontOfSize:18.0];
		self.textLabel.textColor = [UIColor grayColor];
		
		// Init the progress view
		UIActivityIndicatorView* activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		
		[[self contentView] addSubview:activityIndicatorView];
		self.activityIndicatorView = activityIndicatorView;
	}

    return self;
}


#pragma mark -
#pragma mark UIView

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect contentRect = self.contentView.bounds;
	CGFloat const margin = 10.0;
	
	CGSize activityIndicatorSize = [[self activityIndicatorView] sizeThatFits:contentRect.size];
	CGSize textLabelSize = [[self textLabel] sizeThatFits:contentRect.size];
	
	CGSize contentSize = CGSizeMake(
		activityIndicatorSize.width + margin + textLabelSize.width,
		MAX(activityIndicatorSize.height, textLabelSize.height));
		
	CGPoint contentOrigin = CGPointMake(
		floorf(CGRectGetMidX(contentRect) - contentSize.width * 0.5),
		floorf(CGRectGetMidY(contentRect) - contentSize.height * 0.5));
		
	CGRect activityIndicatorRect = CGRectMake(
		contentOrigin.x,
		floorf(CGRectGetMidY(contentRect) - activityIndicatorSize.height * 0.5),
		activityIndicatorSize.width,
		activityIndicatorSize.height);
	self.activityIndicatorView.frame = activityIndicatorRect;
	
	CGRect textLabelRect = CGRectMake(
		CGRectGetMaxX(activityIndicatorRect) + margin,
		floorf(CGRectGetMidY(contentRect) - textLabelSize.height * 0.5),
		textLabelSize.width,
		textLabelSize.height);
	self.textLabel.frame = textLabelRect;
}

@end
