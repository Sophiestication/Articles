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

#import "AKChapterIndexBackgroundView.h"

#import "AKChapterIndexView.h"
#import "AKChapterIndexView+Private.h"

#import "AKArticleView.h"
#import "AKArticleView+Private.h"

#import "NSArray+Additions.h"

#import <QuartzCore/QuartzCore.h>

@implementation AKChapterIndexBackgroundView

@synthesize chapterIndexView = _chapterIndexView;

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
		self.userInteractionEnabled = NO;
		self.contentMode = UIViewContentModeRedraw;
		self.clipsToBounds = NO;
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
		self.clipsToBounds = NO;
	}

    return self;
}

- (void)dealloc {
	self.chapterIndexView = nil;
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGRect bounds = self.bounds;
	
	// Use some white shadow
//	CGContextSetShadowWithColor(
//		context,
//		CGSizeZero,
//		1.0,
//		[[UIColor whiteColor] CGColor]);

	// Draw the chapter index background
	CGRect backgroundRect = bounds;
	CGRect clipRect = CGRectInset(backgroundRect, 0.0, 0.0);
	
	// Clip to the chapter index path
	CGFloat const radius = 2.5;
	
	CGContextBeginPath(context);

	CGContextMoveToPoint(context, CGRectGetMinX(clipRect), CGRectGetMinY(clipRect) + radius);
	CGContextAddLineToPoint(context, CGRectGetMinX(clipRect), CGRectGetMinY(clipRect) + CGRectGetHeight(clipRect) - radius);
	CGContextAddArc(context, CGRectGetMinX(clipRect) + radius, CGRectGetMinY(clipRect) + CGRectGetHeight(clipRect) - radius, radius, M_PI / 4.0, M_PI / 2.0, 1.0);
	CGContextAddLineToPoint(context, CGRectGetMinX(clipRect) + CGRectGetWidth(clipRect) - radius, CGRectGetMinY(clipRect) + CGRectGetHeight(clipRect));
	CGContextAddArc(context, CGRectGetMinX(clipRect) + CGRectGetWidth(clipRect) - radius, CGRectGetMinY(clipRect) + CGRectGetHeight(clipRect) - radius, radius, M_PI / 2.0, 0.0, 1.0);
	CGContextAddLineToPoint(context, CGRectGetMinX(clipRect) + CGRectGetWidth(clipRect), CGRectGetMinY(clipRect) + radius);
	CGContextAddArc(context, CGRectGetMinX(clipRect) + CGRectGetWidth(clipRect) - radius, CGRectGetMinY(clipRect) + radius, radius, 0.0, -M_PI / 2.0, 1.0);
	CGContextAddLineToPoint(context, CGRectGetMinX(clipRect) + radius, CGRectGetMinY(clipRect));
	CGContextAddArc(context, CGRectGetMinX(clipRect) + radius, CGRectGetMinY(clipRect) + radius, radius, -M_PI / 2.0, M_PI, 1.0);
	
	CGContextClosePath(context);
	
	[[[UIColor blackColor] colorWithAlphaComponent:0.5] setFill];
	CGContextFillPath(context);

	// ...
	CGFloat contentHeight = self.chapterIndexView.contentHeight;
	CGFloat previousOffset = 0.0;
	
	CGFloat const minOffset = AKChapterIndexMinChapterHeight;
	
	CGSize separatorImageSize = CGSizeMake(CGRectGetWidth(backgroundRect), 1.0);
	
	NSArray* chapterInfo = self.chapterIndexView.chapterIndexMetadata;
	
	for(NSDictionary* chapter in chapterInfo) {
		NSNumber* chapterOffset = [chapter objectForKey:AKChapterIndexOffsetKey];
		
		CGFloat scaleFactor = [chapterOffset doubleValue] / MAX(contentHeight, 1.0);
		
//		scaleFactor = MIN(scaleFactor, 1.0);
//		scaleFactor = MAX(scaleFactor, 0.0);
	
		CGFloat offset = CGRectGetHeight(backgroundRect) * scaleFactor;
	
		if(offset <= 0.0) {
			continue;
		}
		
//		if(chapter == chapterInfo.firstObject) {
//			continue;
//		}

		if((offset - previousOffset) <= minOffset) {
			continue;
		}
		
		if((CGRectGetMaxY(backgroundRect) - offset) <= minOffset) {
			continue;
		}
		
		CGRect separatorRect = CGRectMake(
			CGRectGetMinX(backgroundRect),
			ceil(offset - separatorImageSize.height * 0.5),
			CGRectGetWidth(backgroundRect),
			separatorImageSize.height);
		
		[[UIColor clearColor] set];
		UIRectFill(separatorRect);
		
		//[[[UIColor blackColor] colorWithAlphaComponent:0.33] set];
		//UIRectFill(separatorRect);
		
		previousOffset = offset;
	}
}

@end
