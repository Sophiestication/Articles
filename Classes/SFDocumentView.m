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

#import "SFDocumentView.h"
#import "SFDocumentView+Private.h"

#import "SFDocument.h"
#import "SFDocumentPickerView.h"

@implementation SFDocumentView

@synthesize document = _document;
@synthesize reuseIdentifier = _reuseIdentifier;

@synthesize closeButton = _closeButton;
@dynamic image;
@dynamic showsCloseButton;

@synthesize documentPickerView = _documentPickerView;

#pragma mark -
#pragma mark Construction & Reuse & Destruction

- (id)initWithDocument:(id<SFDocument>)document reuseIdentifier:(NSString*)reuseIdentifier {
    if(self = [super initWithFrame:CGRectZero]) {
		[self initIvars];
		[self initSubviews];
		
		self.document = document;
		self.reuseIdentifier = reuseIdentifier;
	}

    return self;
}

- (void)prepareForReuse {
	self.document = nil;
	
//	self.image = nil;
	
	self.alpha = 1.0;
	self.showsCloseButton = NO;
	
	self.documentPickerView = nil;
	
//	[self setNeedsDisplay];
}

- (void)dealloc {
	self.documentPickerView = nil;
	

	self.image = nil;

}

#pragma mark -
#pragma mark SFDocumentView

- (UIImage*)image {
	return _image;
}

- (void)setImage:(UIImage*)image {
	if(_image != image) {
		_image = image;
		
		[self setNeedsDisplay];
	}
}

- (BOOL)showsCloseButton {
	return self.closeButton.alpha > 0.0;
}

- (void)setShowsCloseButton:(BOOL)showsCloseButton {
	[self setShowsCloseButton:showsCloseButton animated:NO];
}

- (void)setShowsCloseButton:(BOOL)showsCloseButton animated:(BOOL)animated {
	if(animated) {
		[UIView beginAnimations:@"showsCloseButtonAnimation" context:NULL];
		
		[UIView setAnimationBeginsFromCurrentState:YES];
	}
	
	self.closeButton.alpha = showsCloseButton ? 1.0 : 0.0;
	
	if(animated) {
		[UIView commitAnimations];
	}
}

#pragma mark -
#pragma mark UIView

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event {
	if(self.showsCloseButton) {
		CGRect closeButtonRect = [self convertRect:[[self closeButton] bounds] fromView:[self closeButton]];
	
		if(CGRectContainsPoint(closeButtonRect, point)) {
			return self.closeButton;
		}
	}
	
	UIView* view = [super hitTest:point withEvent:event];
	return view;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect contentRect = [self contentRectForBounds:[self bounds]];
	
	CGSize closeButtonSize = CGSizeMake(50.0, 50.0);
	CGRect closeButtonRect = CGRectMake(
		floorf(CGRectGetMinX(contentRect) - closeButtonSize.width * 0.5),
		floorf(CGRectGetMinY(contentRect) - closeButtonSize.height * 0.5),
		closeButtonSize.width,
		closeButtonSize.height);
	self.closeButton.frame = closeButtonRect;
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	
	// Retrieve the image rect
	CGRect contentRect = [self contentRectForBounds:[self bounds]];
	
	// Draw with a shadow
	CGSize shadowOffset = CGSizeMake(0.0, 2.5);

	CGContextSetShadow(UIGraphicsGetCurrentContext(), shadowOffset, 4.0);
	
	// Now the white content
	[[UIColor whiteColor] set];
	UIRectFill(contentRect);
	
	// Render the content image
	UIImage* image = self.image;
	
	if(image) {
		CGContextSetShadowWithColor(UIGraphicsGetCurrentContext(), CGSizeZero, 0.0, NULL);
		
		CGRect imageRect = [self imageRectForContentRect:contentRect];
		[self drawImage:image inRect:imageRect contentMode:UIViewContentModeScaleAspectFit];
	}
}

#pragma mark -
#pragma mark Private

- (void)initIvars {
	self.clipsToBounds = NO;

	self.opaque = NO;
	self.backgroundColor = [UIColor clearColor];
	
	self.contentMode = UIViewContentModeRedraw;
}

- (void)initSubviews {
	// Init the close button
	UIButton* closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	
	[closeButton setImage:[UIImage imageNamed:@"stackCloseButton.png"] forState:UIControlStateNormal];
	[closeButton setImage:[UIImage imageNamed:@"stackCloseButtonHighlighted.png"] forState:UIControlStateHighlighted];
	
	[closeButton
		addTarget:self
		action:@selector(documentShouldClose:)
		forControlEvents:UIControlEventTouchUpInside];
	
	[closeButton sizeToFit];
	
	[self addSubview:closeButton];
	self.closeButton = closeButton;

	self.showsCloseButton = NO;
}

- (void)documentShouldClose:(id)sender {
	[[self documentPickerView] removeDocument:[self document] animated:YES];
}

- (void)drawImage:(UIImage*)image inRect:(CGRect)rect contentMode:(UIViewContentMode)contentMode {
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGContextSaveGState(context); {
	
	CGFloat scaleX = CGRectGetWidth(rect) / image.size.width;
	CGFloat scaleY; // = CGRectGetHeight(rect) / image.size.height;
	
	scaleY = scaleX;
	
	CGSize sourceImageSize = self.image.size;
	CGSize imageSize = CGSizeMake(
		sourceImageSize.width * scaleX,
		sourceImageSize.height * scaleY);
	imageSize.width = ceil(imageSize.width);
	imageSize.height = ceil(imageSize.height);
		
	CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
	
	UIRectClip(rect);

	CGRect imageRect = CGRectMake(
		CGRectGetMinX(rect), // ceilf(CGRectGetMidX(rect) - imageSize.width * 0.5),
		CGRectGetMinY(rect), // floorf(CGRectGetMidY(rect) - imageSize.height * 0.5),
		imageSize.width,
		imageSize.height);
	[image drawInRect:imageRect];
	
	} CGContextRestoreGState(context);
}

- (CGRect)contentRectForBounds:(CGRect)bounds {
	return CGRectInset(bounds, 10.0, 10.0);
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect {
	return contentRect;
}

@end
