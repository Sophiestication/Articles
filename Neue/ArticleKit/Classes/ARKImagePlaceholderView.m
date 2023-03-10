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

#import "ARKImagePlaceholderView.h"

#import "SUIProgressIndicatorView.h"

#import "ARKImagePlaceholderRenderer.h"

#import "NSCache+Images.h"
#import "UIColor+HEX.h"
#import "UIImage+PDF.h"
#import "UIImage+Styles.h"

@interface ARKImagePlaceholderView()

@property(nonatomic, strong) UIImageView* backgroundView;

@property(nonatomic, strong) UIColor* progressIndicatorColor;
@property(nonatomic, strong) UIColor* progressIndicatorBackgroundColor;
@property(nonatomic, strong) SUIProgressIndicatorView* progressIndicatorView;
@property(nonatomic, strong) UIImageView* errorIndicatorView;

@end

@implementation ARKImagePlaceholderView

#pragma mark - Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
		[self initIvars];
		[self initBackgroundView];
		[self initErrorIndicatorViewIfNeeded];
//		[self initProgressIndicatorView];
		[self highlightDidChange];
    }

    return self;
}

#pragma - ARKImagePlaceholderView

- (void)setHighlighted:(BOOL)highlighted {
	if(self.highlighted == highlighted) { return; }

	_highlighted = highlighted;
	[self highlightDidChange];
}

- (void)setErrorIndicatorShown:(BOOL)errorIndicatorShown {
	if(self.errorIndicatorShown == errorIndicatorShown) { return; }
	
	_errorIndicatorShown = errorIndicatorShown;
	[self setNeedsLayout];
}

#pragma - UIView

- (void)layoutSubviews {
	if(self.errorIndicatorShown) { [self initErrorIndicatorViewIfNeeded]; }
	
	[super layoutSubviews];

	CGRect contentRect = self.bounds;

	CGRect progressIndicatorViewRect = CGRectMake(0.0, 0.0, 17.0, 17.0);
	progressIndicatorViewRect.origin = CGPointMake(
		round(CGRectGetMidX(contentRect) - CGRectGetWidth(progressIndicatorViewRect) * 0.5),
		round(CGRectGetMidY(contentRect) - CGRectGetHeight(progressIndicatorViewRect) * 0.5));
	self.progressIndicatorView.frame = progressIndicatorViewRect;

	self.backgroundView.frame = contentRect;
	[self updateBackgroundViewForContentSize:contentRect.size];
	
	CGSize errorIndicatorViewSize = [[self errorIndicatorView]
		sizeThatFits:contentRect.size];
	CGRect errorIndicatorViewRect = CGRectMake(
		CGRectGetMidX(contentRect) - errorIndicatorViewSize.width * 0.5,
		CGRectGetMidY(contentRect) - errorIndicatorViewSize.height * 0.5,
		errorIndicatorViewSize.width,
		errorIndicatorViewSize.height);
	self.errorIndicatorView.frame = CGRectIntegral(errorIndicatorViewRect);
	
	self.errorIndicatorView.alpha = self.errorIndicatorShown ? 1.0 : 0.0;
	self.progressIndicatorView.alpha = self.errorIndicatorShown ? 0.0 : 1.0;
}

#pragma mark - Private

- (void)initIvars {
	self.userInteractionEnabled = NO;
	
	self.progressIndicatorColor = [UIColor colorWithWhite:0.68 alpha:1.000];
	self.progressIndicatorBackgroundColor = [ARKImagePlaceholderRenderer preferredFillColor];
}

- (void)initBackgroundView {
	UIImageView* backgroundView = [[UIImageView alloc] initWithImage:nil];

	self.backgroundView.highlighted = self.highlighted;

	self.backgroundView = backgroundView;
	[self addSubview:backgroundView];
}

- (void)initProgressIndicatorView {
	SUIProgressIndicatorView* progressIndicatorView = [[SUIProgressIndicatorView alloc] initWithFrame:CGRectZero];
	
	progressIndicatorView.tintColor = self.progressIndicatorColor;

	self.progressIndicatorView = progressIndicatorView;
	[self insertSubview:progressIndicatorView aboveSubview:[self backgroundView]];
}

- (void)initErrorIndicatorViewIfNeeded {
	if(self.errorIndicatorView) { return; }

	UIImageView* errorIndicatorView = [[UIImageView alloc] initWithImage:nil highlightedImage:nil];
	
	self.errorIndicatorView = errorIndicatorView;
	[self updateErrorIndicatorView];

	[self addSubview:errorIndicatorView];
}

- (void)updateBackgroundViewForContentSize:(CGSize)contentSize {
	if(CGSizeEqualToSize(contentSize, self.backgroundView.image.size)) { return; }

	CGSize imageSize = contentSize;
	NSCache* cache = [NSCache sharedImageCache];

	NSString* imageIdentifier = [self backgroundImageIdentifierForSize:imageSize highlighted:NO];
	UIImage* image = [cache objectForKey:imageIdentifier];

	NSString* highlightedImageIdentifier = [self backgroundImageIdentifierForSize:imageSize highlighted:YES];
	UIImage* highlightedImage = [cache objectForKey:highlightedImageIdentifier];

	if(!image || !highlightedImage) {
		ARKImagePlaceholderRenderer* renderer = [[ARKImagePlaceholderRenderer alloc] initWithContentSize:imageSize];
		
		image = [renderer renderedImage];
		[cache setImage:image forKey:imageIdentifier];

		// highlight
		renderer.strokeColor = [UIColor whiteColor];
		renderer.fillColor = [UIColor colorWithWhite:1.0 alpha:1.0 / 3.0];
		
		highlightedImage = [renderer renderedImage];
		[cache setImage:highlightedImage forKey:highlightedImageIdentifier];
	}

	self.backgroundView.image = image;
	self.backgroundView.highlightedImage = highlightedImage;
}

- (NSString*)backgroundImageIdentifierForSize:(CGSize)size highlighted:(BOOL)highlighted {
	NSString* identifier = [NSString stringWithFormat:@"imageplaceholder-%0.2f-%0.2f", size.width, size.height];
	if(highlighted) { identifier = [identifier stringByAppendingString:@"-highlighted"]; }

	return identifier;
}

- (void)updateErrorIndicatorView {
	if(!self.errorIndicatorView) { return; }

	CGSize indicatorSize = CGSizeMake(20.0, 18.0); // TODO?
	NSCache* cache = [NSCache sharedImageCache];

	UIColor* color = [ARKImagePlaceholderRenderer preferredStrokeColor];

	NSString* imageIdentifier = [self errorIndicatorImageIdentifierForSize:indicatorSize color:color];
	UIImage* image = [cache objectForKey:imageIdentifier];

	if(!image) {
		image = [self errorIndicatorImageForColor:color size:indicatorSize];
		[cache setImage:image forKey:imageIdentifier];
	}

	color = [UIColor whiteColor];
	imageIdentifier = [self errorIndicatorImageIdentifierForSize:indicatorSize color:color];
	UIImage* highlightedImage = [cache objectForKey:imageIdentifier];

	if(!highlightedImage) {
		highlightedImage = [self errorIndicatorImageForColor:color size:indicatorSize];
		[cache setImage:highlightedImage forKey:imageIdentifier];
	}

	self.errorIndicatorView.image = image;
	self.errorIndicatorView.highlightedImage = highlightedImage;
}

- (NSString*)errorIndicatorImageIdentifierForSize:(CGSize)size color:(UIColor*)color {
	NSString* identifier = [NSString stringWithFormat:@"imageplaceholder-%0.2f-%0.2f", size.width, size.height];
	if(color) { identifier = [identifier stringByAppendingFormat:@"-%@", [color hexadecimalString]]; }

	return identifier;
}

- (UIImage*)errorIndicatorImageForColor:(UIColor*)tintColor size:(CGSize)size {
	UIImage* image = [UIImage PDFImageNamed:@"warning-indicator-template" size:size scale:0.0];

	NSDictionary* styles = @{
		SUIImageStyleFillColor: tintColor };
	UIImage* styledImage = [image imageByApplyingStyles:styles];

	return styledImage;
}

- (void)highlightDidChange {
	SUIProgressIndicatorView* progressIndicatorView = self.progressIndicatorView;

	if(self.highlighted) {
		progressIndicatorView.tintColor = [UIColor whiteColor];
		progressIndicatorView.opaque = NO;
		progressIndicatorView.backgroundColor = [UIColor clearColor];
	} else {
		progressIndicatorView.tintColor = self.progressIndicatorColor;
		progressIndicatorView.opaque = YES;
		progressIndicatorView.backgroundColor = self.progressIndicatorBackgroundColor;
	}
}

@end
