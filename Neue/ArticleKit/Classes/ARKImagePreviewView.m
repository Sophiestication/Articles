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

#import "ARKImagePreviewView.h"
#import "ARKImagePlaceholderView.h"

@interface ARKImagePreviewView()

@property(nonatomic, strong) UIImageView* imageView;
@property(nonatomic, strong) ARKImagePlaceholderView* imagePlaceholderView;

@end

@implementation ARKImagePreviewView

#pragma mark - Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
		[self initIvars];
		[self initImageView];
		[self initImagePlaceholderView];
		
		[self highlightDidChange];

		self.progressIndicatorShown = YES;
		self.errorIndicatorShown = NO;
    }

    return self;
}

#pragma mark - ARKImagePreviewView

- (void)setHighlighted:(BOOL)highlighted {
	if(self.highlighted == highlighted) { return; }

	_highlighted = highlighted;
	[self highlightDidChange];
}

- (void)setImage:(UIImage*)image {
	[self setImage:image animated:NO];
}

- (void)setImage:(UIImage*)image animated:(BOOL)animated {
	if(image == self.image) { return; }

	_image = image;
	if(image) { self.imageView.image = image; }

	[self setNeedsLayout];
	
	void (^finalize)(void) = ^() {
		self.imageView.image = self.image;
		
		SUIProgressIndicatorStyle style = self.image ?
			SUIProgressIndicatorStyleDeterminate :
			SUIProgressIndicatorStyleActivity;
		self.progressIndicatorView.style = style;
	};

	if(animated) {
		id animations = ^() {
			[self layoutIfNeeded];
		};

		id completion = ^(BOOL finished) {
			if(finished) { finalize(); }
		};

		[UIView
			animateWithDuration:0.3
			delay:0.0
			options:UIViewAnimationOptionBeginFromCurrentState
			animations:animations
			completion:completion];
	} else {
		finalize();
	}
}

#pragma mark - UIView

- (void)layoutSubviews {
	[super layoutSubviews];

	BOOL imageVisible = self.image != nil;
	CGRect contentRect = self.bounds;
	
	ARKImagePlaceholderView* imagePlaceholderView = self.imagePlaceholderView;

	imagePlaceholderView.alpha = imageVisible ? 0.0 : 1.0;

	CGRect imagePlaceholderViewRect = CGRectInset(contentRect, 8.0, 8.0);
	imagePlaceholderView.frame = imagePlaceholderViewRect;

	self.imageView.frame = contentRect;
	self.imageView.alpha = imageVisible ? 1.0 : 0.0;
}

#pragma mark - Private

- (void)initIvars {
	self.userInteractionEnabled = NO;
}

- (void)initImageView {
	UIImageView* imageView = [[UIImageView alloc] initWithImage:nil];

	imageView.contentMode = UIViewContentModeCenter;

	self.imageView = imageView;
	[self addSubview:imageView];
}

- (void)initImagePlaceholderView {
	ARKImagePlaceholderView* imagePlaceholderView = [[ARKImagePlaceholderView alloc] initWithFrame:CGRectZero];

	imagePlaceholderView.alpha = 0.0;
	imagePlaceholderView.progressIndicatorView.style = SUIProgressIndicatorStyleActivity;

	self.imagePlaceholderView = imagePlaceholderView;
	[self addSubview:imagePlaceholderView];
}

- (void)highlightDidChange {
	BOOL highlighted = self.highlighted;

	self.imageView.highlighted = highlighted;
	self.imagePlaceholderView.highlighted = highlighted;
}

@end

#pragma mark - 

@implementation ARKImagePreviewView(ProgressIndicator)

@dynamic progressIndicatorShown;;
@dynamic progressIndicatorView;

- (SUIProgressIndicatorView*)progressIndicatorView {
	return self.imagePlaceholderView.progressIndicatorView;
}

- (BOOL)isProgressIndicatorShown {
	return self.progressIndicatorView.alpha > 0.0;
}

- (void)setProgressIndicatorShown:(BOOL)progressIndicatorShown {
	[self setProgressIndicatorShown:progressIndicatorShown animated:NO delay:0.0];
}

- (void)setProgressIndicatorShown:(BOOL)progressIndicatorShown animated:(BOOL)animated delay:(NSTimeInterval)delay {
	if(progressIndicatorShown == self.progressIndicatorShown) { return; }
	
	BOOL progressIndicatorAlpha = progressIndicatorShown ? 1.0 : 0.0;
	[self setNeedsLayout];

	if(animated) {
		id animations = ^() {
			self.progressIndicatorView.alpha = progressIndicatorAlpha;
			[self layoutIfNeeded];
		};
	
		[UIView
			animateWithDuration:0.3
			delay:delay
			options:UIViewAnimationOptionBeginFromCurrentState
			animations:animations
			completion:nil];
	} else {
		self.progressIndicatorView.alpha = progressIndicatorAlpha;
	}
}

@end

#pragma mark - 

@implementation ARKImagePreviewView(ErrorIndicator)

@dynamic errorIndicatorShown;

- (BOOL)isErrorIndicatorShown {
	return self.imagePlaceholderView.errorIndicatorShown;
}

- (void)setErrorIndicatorShown:(BOOL)errorIndicatorShown {
	[self setErrorIndicatorShown:errorIndicatorShown animated:NO];
}

- (void)setErrorIndicatorShown:(BOOL)errorIndicatorShown animated:(BOOL)animated {
	if(self.errorIndicatorShown == errorIndicatorShown) { return; }
	
	self.imagePlaceholderView.errorIndicatorShown = errorIndicatorShown;
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

@end
