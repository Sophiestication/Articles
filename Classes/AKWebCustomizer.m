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

#import "AKWebCustomizer.h"
#import "AKWebCustomizer+Gestures.h"
#import "AKWebCustomizer+Scrolling.h"
#import "AKWebCustomizer+Private.h"

#import <objc/runtime.h>
#import <objc/objc.h>

@implementation AKWebCustomizer

@synthesize delegate = _delegate;
@synthesize webView = _webView;
@synthesize scrollView = _scrollView;
@synthesize documentView = _documentView;
@dynamic documentShadowsShown;

@synthesize approximateElementInvocation = _approximateElementInvocation;

@synthesize chapterIndexGestureRecognizer = _chapterIndexGestureRecognizer;
@synthesize pinchGestureRecognizer = _pinchGestureRecognizer;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithWebView:(UIWebView*)webView delegate:(id<AKWebCustomizerDelegate>)delegate {
	if((self = [super init])) {
		self.webView = webView;
		self.delegate = delegate;
		
		[self initScrollView];
		[self initDocumentView];
		[self initGestureRecognizers];
	}
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.delegate = nil;
}

#pragma mark -
#pragma mark AKWebCustomizer

- (BOOL)documentShadowsShown {
	return _documentShadowsShown;
}

- (void)setDocumentShadowsShown:(BOOL)documentShadowsShown {
	if(documentShadowsShown != self.documentShadowsShown) {
		_documentShadowsShown = documentShadowsShown;
		
		for(UIView* subview in self.scrollView.subviews) {
			if([subview isKindOfClass:[UIImageView class]]) {
				subview.hidden = !documentShadowsShown;
			}
		}
	}
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event targetView:(UIView*)targetView inView:(UIView*)containerView {
	return targetView;
}

#pragma mark -
#pragma mark Private

- (void)initScrollView {
	self.scrollView = self.webView.scrollView;
    self.scrollView.delegate = self;
}

- (void)initDocumentView {
	_documentShadowsShown = NO;
	
	for(UIView* subview in self.scrollView.subviews) {
		if([subview isKindOfClass:[UIImageView class]]) {
			subview.hidden = YES;
		} else {
			self.documentView = subview;
		}
	}
}

@end
