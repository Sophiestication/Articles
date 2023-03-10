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

#import "AKWebCustomizer+Scrolling.h"
#import "AKWebCustomizer+Gestures.h"
#import "AKWebCustomizer+Private.h"

@implementation AKWebCustomizer(Scrolling)

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView*)scrollView {
	if([[self delegate] respondsToSelector:_cmd]) {
		return [[self delegate] scrollViewShouldScrollToTop:scrollView];
	}
	
	return YES;
}

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
	[[self delegate] scrollViewDidScroll:scrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView {
	[[self delegate] scrollViewWillBeginDragging:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(BOOL)decelerate {
	[[self delegate] scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView*)scrollView {
	[[self delegate] scrollViewDidEndScrollingAnimation:scrollView];
}

- (void)scrollViewDidScrollToTop:(UIScrollView*)scrollView {
	[[self delegate] scrollViewDidScrollToTop:scrollView];
}

@end
