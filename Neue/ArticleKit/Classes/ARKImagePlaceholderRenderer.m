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

#import "ARKImagePlaceholderRenderer.h"

@interface ARKImagePlaceholderRenderer()

@property(nonatomic) CGSize contentSize;

@property(nonatomic, strong) UIBezierPath* contentPath;
@property(nonatomic, strong) UIBezierPath* borderPath;

@end

@implementation ARKImagePlaceholderRenderer

#pragma mark - Construction & Destruction

- (id)initWithContentSize:(CGSize)contentSize {
	if((self = [super init])) {
		self.contentSize = contentSize;
		[self initBezierPaths];
	}
	
	return self;
}

#pragma mark - ARKImagePlaceholderRenderer

- (UIImage*)renderedImage {
	UIImage* renderedImage = nil;
	
	BOOL opaque = [self shouldRenderBackground];
	
	UIGraphicsBeginImageContextWithOptions([self contentSize], opaque, 0.0); {
		CGContextRef context = UIGraphicsGetCurrentContext();
	
		[self renderInContext:context];

		renderedImage = UIGraphicsGetImageFromCurrentImageContext();
	} UIGraphicsEndImageContext();
	
	return renderedImage;
}

- (void)renderInContext:(CGContextRef)context {
	if([self shouldRenderBackground]) {
		[[self backgroundColor] set];
		UIRectFill(CGContextGetClipBoundingBox(context));
	}
	
	UIColor* fillColor = self.fillColor;
	if(!fillColor) { fillColor = [[self class] preferredFillColor]; }
	
	[fillColor setFill];
	[[self contentPath] fill];
	
	UIColor* strokeColor = self.strokeColor;
	if(!strokeColor) { strokeColor = [[self class] preferredStrokeColor]; }

	[strokeColor setStroke];
	[[self borderPath] stroke];
}

#pragma mark - Private

- (void)initBezierPaths {
	CGSize contentSize = self.contentSize;
	CGRect contentRect = CGRectMake(0.0, 0.0, contentSize.width, contentSize.height);

	UIBezierPath* path = [UIBezierPath bezierPathWithRoundedRect:contentRect cornerRadius:5.0];
	self.contentPath = path;

	contentRect = CGRectInset(contentRect, 0.5, 0.5);
	path = [UIBezierPath bezierPathWithRoundedRect:contentRect cornerRadius:5.0];

	CGFloat pattern[] = { 3.0, 3.0 };
	[path setLineDash:pattern count:2 phase:0.0];

	self.borderPath = path;
}

- (BOOL)shouldRenderBackground {
	return self.backgroundColor != nil &&
		![[self backgroundColor] isEqual:[UIColor clearColor]];
}

@end

@implementation ARKImagePlaceholderRenderer(Colors)

+ (UIColor*)preferredStrokeColor { return [UIColor colorWithWhite:0.788 alpha:1.0]; }
+ (UIColor*)preferredFillColor { return [UIColor colorWithWhite:0.946 alpha:1.0]; }

@end
