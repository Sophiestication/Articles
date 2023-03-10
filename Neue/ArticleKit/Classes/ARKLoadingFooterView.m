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

#import "ARKLoadingFooterView.h"

#import "NSCache+Images.h"
#import "UIImage+PDF.h"
#import "UIImage+Styles.h"

@interface ARKLoadingFooterView()

@property(nonatomic, readwrite) UIActivityIndicatorView* activityIndicatorView;
@property(nonatomic, strong) UIImageView* errorIndicatorView;

@end

@implementation ARKLoadingFooterView

#pragma mark - Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
		self.backgroundView.hidden = YES; // = [[UIView alloc] initWithFrame:CGRectZero];
		[self initActivityIndicatorView];
    }

    return self;
}

#pragma mark - ARKLoadingFooterView

+ (CGFloat)preferredHeight {
	return 44.0;
}

- (void)setLoadingFooterViewStyle:(ARKLoadingFooterViewStyle)loadingFooterViewStyle {
	[self setLoadingFooterViewStyle:loadingFooterViewStyle animated:NO];
}

- (void)setLoadingFooterViewStyle:(ARKLoadingFooterViewStyle)loadingFooterViewStyle animated:(BOOL)animated {
	if(loadingFooterViewStyle == self.loadingFooterViewStyle) { return; }
	
	if(loadingFooterViewStyle == ARKLoadingFooterViewStyleFailure) {
		[self initErrorIndicatorViewIfNeeded];
	}
	
	_loadingFooterViewStyle = loadingFooterViewStyle;
	[self setNeedsLayout];
	
	if(animated) {
		[UIView
			animateWithDuration:0.3
			delay:0.0
			options:UIViewAnimationOptionBeginFromCurrentState
			animations:^() { [self layoutIfNeeded]; }
			completion:nil];
	}
}

#pragma mark - UIView

- (CGSize)sizeThatFits:(CGSize)size {
	return CGSizeMake(size.width, [[self class] preferredHeight]);
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect contentRect = self.bounds;
	
	CGSize errorIndicatorViewSize = self.errorIndicatorView.image.size;
	CGRect errorIndicatorViewRect = CGRectMake(
		round(CGRectGetMidX(contentRect) - errorIndicatorViewSize.width * 0.5),
		round(CGRectGetMidY(contentRect) - errorIndicatorViewSize.height * 0.5),
		errorIndicatorViewSize.width,
		errorIndicatorViewSize.height);
	self.errorIndicatorView.frame = errorIndicatorViewRect;
	
	CGRect activityIndicatorViewRect = self.activityIndicatorView.frame;
	activityIndicatorViewRect = CGRectMake(
		round(CGRectGetMidX(contentRect) - CGRectGetWidth(activityIndicatorViewRect) * 0.5),
		round(CGRectGetMidY(contentRect) - CGRectGetHeight(activityIndicatorViewRect) * 0.5),
		CGRectGetWidth(activityIndicatorViewRect),
		CGRectGetHeight(activityIndicatorViewRect));
	self.activityIndicatorView.frame = activityIndicatorViewRect;
	
	BOOL errorIndicatorShown = self.loadingFooterViewStyle == ARKLoadingFooterViewStyleFailure;
	self.errorIndicatorView.alpha = errorIndicatorShown ? 1.0 : 0.0;
	self.activityIndicatorView.alpha = errorIndicatorShown ? 0.0 : 1.0;
}

#pragma mark - Private

- (void)initActivityIndicatorView {
	UIActivityIndicatorView* activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	
	activityIndicator.hidesWhenStopped = YES;
	
	self.activityIndicatorView = activityIndicator;
	[[self contentView] addSubview:activityIndicator];
}


- (void)initErrorIndicatorViewIfNeeded {
	if(self.errorIndicatorView) { return; }
	
	CGSize size = CGSizeMake(20.0, 18.0);
	UIImage* image = [UIImage PDFImageNamed:@"warning-indicator-template" size:size scale:0.0];

	NSDictionary* styles = @{
		SUIImageStyleFillColor: [UIColor grayColor] };
	UIImage* styledImage = [image imageByApplyingStyles:styles];

	UIImageView* errorIndicatorView = [[UIImageView alloc] initWithImage:styledImage highlightedImage:nil];
	
	self.errorIndicatorView = errorIndicatorView;
	[self addSubview:errorIndicatorView];
}

@end
