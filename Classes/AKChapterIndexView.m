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

#import "AKChapterIndexView.h"
#import "AKChapterIndexView+Private.h"

#import "AKArticleView.h"
#import "AKArticleView+Searching.h"
#import "AKArticleView+Private.h"

#import "AKChapterIndexBackgroundView.h"

#import "NSArray+Additions.h"
#import "NSString+Additions.h"

#import "JSONKit.h"

@implementation AKChapterIndexView

NSString* const AKChapterIndexIdentifierKey = @"id";
NSString* const AKChapterIndexTagNameKey = @"tag";
NSString* const AKChapterIndexOffsetKey = @"offset";
CGFloat const AKChapterIndexMinChapterHeight = 8.0;

@synthesize articleView = _articleView;
@synthesize chapterIndexMetadata = _chapterIndexMetadata;
@synthesize contentHeight = _contentHeight;
@synthesize backgroundView = _backgroundView;

#pragma mark -
#pragma mark Contruction & Destruction

- (id)initWithFrame:(CGRect)frame {
	if(self = [super initWithFrame:frame]) {
		_previousLocation = CGPointZero;
		
		self.active = NO;
		
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
		
		[self initBackgroundView];
		
		self.userInteractionEnabled = NO;
	}
	
	return self;
}


#pragma mark -
#pragma mark AKChapterIndexView

- (BOOL)isActive {
	return _active;
}

- (void)setActive:(BOOL)active {
	[self setActive:active animated:NO];
}

- (void)setActive:(BOOL)active animated:(BOOL)animated {
	if(active != self.active) {
		if(animated) {
			[UIView beginAnimations:@"presentChapterIndex" context:NULL];
			
			[UIView setAnimationDuration:0.5];
			[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		}
		
		_active = active;
		[self setNeedsLayout];
	
		if(animated) {
			[self layoutIfNeeded];
			[UIView commitAnimations];
		}
	}
	
	if(active) {
		[NSObject
			cancelPreviousPerformRequestsWithTarget:self
			selector:@selector(hideChapterIndexAnimated)
			object:nil];
	}
}

- (void)flashIndicator {
	if(!self.active) {
		[self setActive:YES animated:YES];
		[self performSelector:@selector(hideChapterIndexAnimated)
			withObject:nil
			afterDelay:1.0];
	}
}

- (void)hideChapterIndexAnimated {
	[self setActive:NO animated:YES];
}

- (void)setNeedsUpdate {
	_needsUpdate = YES;
}

- (void)updateIfNeeded {
	if(_needsUpdate) {
		_previousLocation = CGPointZero;
		[self updateChapterMetadata];
	}
}

#pragma mark -
#pragma mark UIView

- (CGSize)sizeThatFits:(CGSize)size {
	size.width = 44.0;
	return size;
}

- (void)layoutSubviews {
	CGRect bounds = self.bounds;
	
	CGFloat const margin = 3.0;
	CGFloat const backgroundWidth = 5.0;
	
	CGFloat const offset = 7.0;
	
//	CGRect windowRect = self.window.bounds;
//	CGRect viewRect = [self convertRect:bounds toView:nil];
//	
//	BOOL rightAligned = CGRectGetMinX(viewRect) > CGRectGetMidX(windowRect);

	BOOL rightAligned = YES;
	
	CGRect backgroundRect = CGRectMake(
		rightAligned ? CGRectGetMaxX(bounds) - offset : CGRectGetMinX(bounds) + offset,
		margin,
		backgroundWidth,
		CGRectGetHeight(bounds) - margin * 2.0);

	self.backgroundView.frame = backgroundRect;
	self.backgroundView.alpha = self.active ? 1.0 : 0.0;
	
	[self updateIfNeeded];
	
	[[self superview] bringSubviewToFront:self];
}

#pragma mark -
#pragma mark Private

- (void)initBackgroundView {
	AKChapterIndexBackgroundView* backgroundView = [[AKChapterIndexBackgroundView alloc] initWithFrame:CGRectZero];
	
	[(id)backgroundView setChapterIndexView:self];
	[self addSubview:backgroundView];
	
	self.backgroundView = backgroundView;
}

- (void)updateChapterMetadata {
	_needsUpdate = NO;
	
	UIWebView* webView = self.articleView.webView;
	
	if(!webView.request) {
		return;
	}

	CGFloat newContentHeight = self.articleView.contentSize.height;
	
	if(newContentHeight == self.contentHeight) {
		return;
	}
	
	NSString* chapterIndexMetadataString = [webView stringByEvaluatingJavaScriptFromString:
		@"articleKitDocumentController.getChapterIndexMetadata()"];
        
    NSArray* chapterIndexMetadata = [NSJSONSerialization
    	JSONObjectWithData:[chapterIndexMetadataString dataUsingEncoding:NSUTF8StringEncoding]
        options:NSJSONReadingAllowFragments
        error:nil];
    
    self.chapterIndexMetadata = chapterIndexMetadata;
	self.contentHeight = newContentHeight;
	
	[[self backgroundView] setNeedsDisplay];
}

- (BOOL)updateChapteredArticleLocationForTouchLocation:(CGPoint)touchLocation {
	// ...
	CGFloat delta = fabs(touchLocation.y - _previousLocation.y);
	
	if(delta < 10.0) {
		return NO;
	}
	
	_previousLocation = touchLocation;
	
	// ...
	[UIView setAnimationsEnabled:NO];
	
	CGFloat contentHeight =
		self.articleView.contentSize.height -
		CGRectGetHeight(self.articleView.webView.bounds) +
		self.articleView.contentInset.bottom;
	
	const CGFloat topMargin = 5.0;
	
	CGSize viewSize = self.bounds.size;
	
	CGPoint location = touchLocation;
	location.y -= topMargin;
	
	CGFloat offset = location.y / MAX(viewSize.height, 1.0);
	
	offset = MAX(offset, 0.0);
	offset = MIN(offset, 1.0);
	
	// CGFloat scaleFactor = contentHeight / viewSize.height;

	CGPoint newContentOffset = CGPointMake(
		0.0, contentHeight * offset);

	// We simply go continuous if we have a single or no chapter
	if(self.chapterIndexMetadata.count <= 1) {
		self.articleView.contentOffset = newContentOffset;
			
		[UIView setAnimationsEnabled:YES];
			
		return YES;
	}
	
	// Scroll through the document and snap to a chapter if needed
	CGFloat const offsetScaleFactor = contentHeight / MAX(viewSize.height, 1.0);
	CGFloat const snapOffset = offsetScaleFactor * 22.0;
	
	if(newContentOffset.y >= contentHeight) {
		newContentOffset.y = contentHeight;
		self.articleView.contentOffset = newContentOffset;
	} else {
		for(NSDictionary* chapter in self.chapterIndexMetadata) {
			NSNumber* chapterOffset = [chapter objectForKey:AKChapterIndexOffsetKey];
			
			if([chapterOffset floatValue] >= newContentOffset.y || chapter == self.chapterIndexMetadata.lastObject) {
				if(abs([chapterOffset doubleValue] - newContentOffset.y) <= snapOffset) {
					newContentOffset.y = [chapterOffset doubleValue];
				}
				
				NSDictionary* previousChapter = [[self chapterIndexMetadata] objectBeforeObject:chapter];
				NSNumber* previousOffset = [previousChapter objectForKey:AKChapterIndexOffsetKey];
				
				if(abs([previousOffset doubleValue] - newContentOffset.y) <= snapOffset) {
					newContentOffset.y = [previousOffset doubleValue];
				}
				
				newContentOffset.y = MIN(newContentOffset.y, contentHeight);
				self.articleView.contentOffset = newContentOffset;
				
				[UIView setAnimationsEnabled:YES];
				
				return YES;
			}
		}
	}
	
	[UIView setAnimationsEnabled:YES];

	return YES;
}

- (CGRect)chapterIndexRect {
	const CGFloat margin = 5.0;
	CGRect bounds = self.bounds;
	
	CGRect chapterIndexRect = CGRectMake(
		CGRectGetMinX(bounds),
		CGRectGetMinY(bounds) + margin,
		CGRectGetWidth(bounds),
		CGRectGetHeight(bounds) - margin * 2.0);
		
	return chapterIndexRect;
}

@end
