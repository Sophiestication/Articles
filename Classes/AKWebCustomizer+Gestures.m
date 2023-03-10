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

#import "AKWebCustomizer+Gestures.h"
#import "AKWebCustomizer+Private.h"

#import "AKChapterIndexGestureRecognizer.h"

#import "NSString+Additions.h"

#import <UIKit/UIGestureRecognizerSubclass.h>
#import "JSONKit.h"

@implementation AKWebCustomizer(Gestures)

- (void)initGestureRecognizers {
    // custom long press handler for action sheets
	for(UILongPressGestureRecognizer* gestureRecognizer in [[self documentView] gestureRecognizers]) {
		if([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        	if(gestureRecognizer.minimumPressDuration >= 0.5) {
            	[gestureRecognizer addTarget:self action:@selector(didRecognizeLongPressGesture:)];
            }
        }
	}
	
	// Chapter index gesture
	AKChapterIndexGestureRecognizer* chapterIndexGestureRecognizer = [[AKChapterIndexGestureRecognizer alloc]
		initWithTarget:self
		action:@selector(didRecognizeChapterIndexGesture:)];
	
    chapterIndexGestureRecognizer.minimumPressDuration = 0.2;
	chapterIndexGestureRecognizer.delegate = self;
	
	self.chapterIndexGestureRecognizer = chapterIndexGestureRecognizer;
	[self attachGestureRecognizer:chapterIndexGestureRecognizer];
	
	// Pinch gesture
	UIPinchGestureRecognizer* pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc]
		initWithTarget:self
		action:@selector(didRecognizePinchGesture:)];
	
	pinchGestureRecognizer.delegate = self;
	
	self.pinchGestureRecognizer = pinchGestureRecognizer;
	[self attachGestureRecognizer:pinchGestureRecognizer];
}

- (void)didRecognizeLongPressGesture:(UIGestureRecognizer*)gestureRecognizer {
	if(gestureRecognizer.state == UIGestureRecognizerStateBegan) {
		BOOL shouldHandle = YES;

        if([[self delegate] respondsToSelector:@selector(webCustomizer:shouldHandleLongPressGesture:)]) {
        	shouldHandle = [[self delegate] webCustomizer:self shouldHandleLongPressGesture:(UILongPressGestureRecognizer*)gestureRecognizer];
        }
        
        if(shouldHandle) {
        	[self presentActionSheetGestureRecognizer:gestureRecognizer];
        } else {
        	[self cancelAllGestureRecognizers];
        }
	}
}

- (void)didRecognizeChapterIndexGesture:(AKChapterIndexGestureRecognizer*)gestureRecognizer {
}

- (void)didRecognizePinchGesture:(UIPinchGestureRecognizer*)gestureRecognizer {
}

- (void)attachGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer {
	if([[self delegate] respondsToSelector:@selector(webCustomizer:viewForGestureRecognizer:)]) {
		UIView* targetView = [[self delegate] webCustomizer:self viewForGestureRecognizer:gestureRecognizer];
		[targetView addGestureRecognizer:gestureRecognizer];
	}
}

- (CGPoint)webViewLocationWithGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer {
	CGPoint point = [gestureRecognizer locationInView:[self webView]];
	
	if([self approximateElementInvocation]) {
		if(self.scrollView.contentOffset.y < 0.0) {
			point.y += self.scrollView.contentOffset.y;
		}
		
		if(self.approximateElementInvocation) {
			CGPoint* approximatePoint = &point;
			[[self approximateElementInvocation] setArgument:&approximatePoint atIndex:2];
			
			[[self approximateElementInvocation] invokeWithTarget:[self documentView]];
			
			point = *approximatePoint;
		}
	}

	return point;
}

- (void)presentActionSheetGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer {
	CGPoint point = [self webViewLocationWithGestureRecognizer:gestureRecognizer];
	
	NSString* javascript = [NSString stringWithFormat:
		@"articleKitDocumentController.getMetadataForLinkAtPoint(%0.1f, %0.1f);",
		point.x, point.y];
	NSString* JSONString = [[self webView] stringByEvaluatingJavaScriptFromString:javascript];
		
	NSMutableDictionary* metadata = [NSJSONSerialization
        JSONObjectWithData:[JSONString dataUsingEncoding:NSUTF8StringEncoding]
        options:NSJSONReadingAllowFragments|NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves
        error:nil];
	
	if(metadata) {
		NSString* URLString = [metadata objectForKey:@"URL"];
		NSURL* URL = URLString ?
			[NSURL URLWithString:URLString] :
			nil;
			
		CGRect targetRect = CGRectMake(
			point.x, point.y,
			1.0, 1.0);
		[metadata setObject:[NSValue valueWithCGRect:targetRect] forKey:@"targetRect"];
	
		[[self delegate] webCustomizer:self shouldPresentSheetForURL:URL options:metadata];
	}
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer {
	if(self.webView.hidden) { return NO; }
    if(!self.webView.userInteractionEnabled) { return NO; }
	return YES;
}

#pragma mark - Private

- (void)cancelAllGestureRecognizers {
	for(UIGestureRecognizer* otherGestureRecognizer in [[self documentView] gestureRecognizers]) {
        [otherGestureRecognizer setState:UIGestureRecognizerStateCancelled];
    }
}

@end
