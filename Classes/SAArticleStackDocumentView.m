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

#import "SAArticleStackDocumentView.h"
#import "SAArticleStackDocumentView+Private.h"

#import "SFDocumentView+Private.h"

@implementation SAArticleStackDocumentView

#pragma mark - Construction & Destruction

- (id)initWithDocument:(id<SFDocument>)document reuseIdentifier:(NSString*)reuseIdentifier {
    if((self = [super initWithDocument:document reuseIdentifier:reuseIdentifier])) {
	}

    return self;
}

#pragma mark - UIView

- (void)drawRect:(CGRect)rect {
	// Retrieve the image rect
	CGRect contentRect = [self contentRectForBounds:[self bounds]];
	
	if(self.image) {
		//[self drawImage:[self image] inRect:contentRect contentMode:UIViewContentModeScaleAspectFit];
		[[self image] drawInRect:contentRect];
		return;
	}
	
	// …
	BOOL portraitOrientation = CGRectGetWidth([self bounds]) <= CGRectGetHeight([self bounds]);
    CGSize pageSize = portraitOrientation ?
        CGSizeMake(768.0, 1004.0) :
        CGSizeMake(1004.0, 768.0);
	
	UIImage* image = nil;
	
	UIGraphicsBeginImageContextWithOptions(pageSize, NO, [[[self window] screen] scale]); {
		
		CGRect imageRect = CGRectMake(0.0, 0.0, pageSize.width, pageSize.height);
		[self drawInContext:UIGraphicsGetCurrentContext() rect:imageRect];
		
		image = UIGraphicsGetImageFromCurrentImageContext();
		
	} UIGraphicsEndImageContext();
	
	[image drawInRect:contentRect];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if(UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
		self.closeButton.frame = CGRectOffset(self.closeButton.frame, 6.0, 3.0);
	} else {
		self.closeButton.frame = CGRectOffset(self.closeButton.frame, 6.0, 3.0);
	}
}

#pragma mark - SFDocumentView

- (CGRect)contentRectForBounds:(CGRect)bounds {
	return bounds;
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect {
	return contentRect;
}

#pragma mark - Private

- (void)drawInContext:(CGContextRef)context rect:(CGRect)rect {
	CGRect contentRect = rect;
	
    UIImage* headerImage = [[UIImage imageNamed:@"paperStackToolbar.png"]
		stretchableImageWithLeftCapWidth:16.0 topCapHeight:0];
	CGRect headerRect = CGRectMake(
		CGRectGetMinX(contentRect),
		CGRectGetMinY(contentRect) + 3.0,
		CGRectGetWidth(contentRect),
		headerImage.size.height);
	
	UIImage* footerImage = [[UIImage imageNamed:@"paperStackFooter.png"]
		stretchableImageWithLeftCapWidth:16.0 topCapHeight:0];
	CGRect footerRect = CGRectMake(
		CGRectGetMinX(contentRect),
		CGRectGetMaxY(contentRect) - footerImage.size.height,
		CGRectGetWidth(contentRect),
		footerImage.size.height);
	
	UIImage* leftBorderImage = [[UIImage imageNamed:@"paperStackLeft.png"]
		stretchableImageWithLeftCapWidth:0.0 topCapHeight:8.0];
	CGRect leftBorderRect = CGRectMake(
		CGRectGetMinX(contentRect) + 2.0,
		CGRectGetMaxY(headerRect),
		leftBorderImage.size.width,
		CGRectGetMinY(footerRect) - CGRectGetMaxY(headerRect));
	
	UIImage* rightBorderImage = [UIImage
		imageWithCGImage:[leftBorderImage CGImage]
		scale:[leftBorderImage scale]
		orientation:UIImageOrientationUpMirrored];
	CGRect rightBorderRect = CGRectMake(
		CGRectGetMaxX(contentRect) - rightBorderImage.size.width - 2.0,
		CGRectGetMaxY(headerRect),
		rightBorderImage.size.width,
		CGRectGetMinY(footerRect) - CGRectGetMaxY(headerRect));
	
	CGRect imageRect = CGRectMake(
		CGRectGetMaxX(leftBorderRect),
		CGRectGetMaxY(headerRect) - 1.0,
		CGRectGetMinX(rightBorderRect) - CGRectGetMaxX(leftBorderRect),
		CGRectGetMinY(footerRect) - CGRectGetMaxY(headerRect) + 6.0);
		
//	if(self.image) {
//		[self drawImage:[self image] inRect:imageRect contentMode:UIViewContentModeScaleAspectFit];
//	}

	UIColor* linenColor = [UIColor colorWithPatternImage:
		[UIImage imageNamed:@"linen"]];
	[linenColor set];
	
	UIRectFill(imageRect);
	
	[headerImage drawInRect:headerRect];
	[footerImage drawInRect:footerRect];
	[leftBorderImage drawInRect:leftBorderRect];
	[rightBorderImage drawInRect:rightBorderRect];
}

@end
