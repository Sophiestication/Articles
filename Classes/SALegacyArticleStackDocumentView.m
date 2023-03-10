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

#import "SALegacyArticleStackDocumentView.h"

@implementation SALegacyArticleStackDocumentView

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithDocument:(id<SFDocument>)document reuseIdentifier:(NSString*)reuseIdentifier {
    if((self = [super initWithDocument:document reuseIdentifier:reuseIdentifier])) {
	}

    return self;
}


#pragma mark -
#pragma mark UIView

- (void)drawRect:(CGRect)rect {
	[[UIColor clearColor] set];
	UIRectFill(rect);
	
	CGRect contentRect = [self contentRectForBounds:[self bounds]];
	CGRect imageRect = [self imageRectForContentRect:contentRect];
	
	// Render the content image
	UIImage* contentImage = self.image;
	
	if(contentImage) {
		[contentImage drawInRect:imageRect];
	} else {
		BOOL landscape = CGRectGetWidth(imageRect) > CGRectGetHeight(imageRect);
		imageRect = CGRectInset(imageRect, landscape ? 8.0 : 3.0, 0.0);
		
		UIImage* pagesImage = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ?
			[UIImage imageNamed:@"backgroundPagesPortrait.png"] :
			[UIImage imageNamed:@"backgroundPagesLandscape.png"];
		[pagesImage drawInRect:imageRect];
		
		UIImage* pagesContentImage = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ?
			[UIImage imageNamed:@"backgroundContentPagePortrait.png"] :
			[UIImage imageNamed:@"backgroundContentPageLandscape.png"];
		[pagesContentImage drawInRect:imageRect];
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if(UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
		self.closeButton.frame = CGRectOffset(self.closeButton.frame, 15.0, 6.0);
	} else {
		self.closeButton.frame = CGRectOffset(self.closeButton.frame, 23.0, 5.0);
	}
}

#pragma mark -
#pragma mark SFDocumentView

- (CGRect)contentRectForBounds:(CGRect)bounds {
	return bounds;
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect {
	return contentRect;
}

@end
