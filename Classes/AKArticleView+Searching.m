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

#import "AKArticleView+Searching.h"
#import "AKArticleView+Private.h"

@implementation AKArticleView(Searching)

@dynamic searching;
@dynamic searchResultIndicatorInsets;

- (void)find:(id)sender {
	if([[self delegate] respondsToSelector:@selector(articleView:shouldFindInDocumentWithText:)]) {
		NSString* selectedText = [[self webView] stringByEvaluatingJavaScriptFromString:@"articleKitDocumentController.getSelectedText()"];
		selectedText = [selectedText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
//		[[self webView] stringByEvaluatingJavaScriptFromString:@"window.getSelection().removeAllRanges();"];
		[[self parentViewController] becomeFirstResponder];
		
		[[self delegate] articleView:self shouldFindInDocumentWithText:selectedText];
	}
}

- (BOOL)isSearching {
	return _searching;
}

- (void)setSearching:(BOOL)searching {
	if(searching != self.searching) {
		_searching = searching;
		
		NSString* javascript = [NSString stringWithFormat:@"documentSearchController.setActive(%@);",
			searching ? @"true" : @"false"];
		[[self webView] stringByEvaluatingJavaScriptFromString:javascript];
	}
}

- (UIEdgeInsets)searchResultIndicatorInsets {
	return _searchResultIndicatorInsets;
}

- (void)setSearchResultIndicatorInsets:(UIEdgeInsets)searchResultIndicatorInsets {
	if(UIEdgeInsetsEqualToEdgeInsets(searchResultIndicatorInsets, [self searchResultIndicatorInsets])) { return; }
	
	
	_searchResultIndicatorInsets = searchResultIndicatorInsets;
	NSString* javascript = [NSString stringWithFormat:@"documentSearchController.setSearchResultIndicatorInsets({ top: %0.1f, left: %0.1f, bottom: %0.1f, right: %0.1f});",
		searchResultIndicatorInsets.top, searchResultIndicatorInsets.left, searchResultIndicatorInsets.bottom, searchResultIndicatorInsets.right];
	[[self webView] stringByEvaluatingJavaScriptFromString:javascript];
}

- (NSInteger)searchWithText:(NSString*)text {
	self.searching = YES;
	
	// TODO
	[[self webView] stringByEvaluatingJavaScriptFromString:@"documentSearchController.cancel();"];
	
	text = [text stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
	NSInteger resultCount = [[[self webView] stringByEvaluatingJavaScriptFromString:
		[NSString stringWithFormat:@"documentSearchController.find('%@');", text]]
		integerValue];
	
	return resultCount;
}

- (BOOL)findNext {
	NSString* javascript = @"documentSearchController.findNext();";
	[[self webView] stringByEvaluatingJavaScriptFromString:javascript];
	
	return YES;
}

- (BOOL)findPrevious {
	NSString* javascript = @"documentSearchController.findPrevious();";
	[[self webView] stringByEvaluatingJavaScriptFromString:javascript];
	
	return YES;
}

- (BOOL)canPerformFindAction:(SEL)action withSender:(id)sender {
	if([[self delegate] respondsToSelector:@selector(articleView:shouldFindInDocumentWithText:)]) {
		NSString* selectedText = [[self webView] stringByEvaluatingJavaScriptFromString:@"articleKitDocumentController.getSelectedText()"];
		selectedText = [selectedText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		__block BOOL maximumWordCountExceeded = NO;
		__block NSInteger wordIndex = 0;
		
		id wordEnumeratorBlock = ^(NSString* substring, NSRange substringRange, NSRange enclosingRange, BOOL* stop) {
			++wordIndex;
			
			if(wordIndex > 3) {
				*stop = YES;
				maximumWordCountExceeded = YES;
			}
		};
		
		[selectedText
			enumerateSubstringsInRange:NSMakeRange(0, [selectedText length])
			options:NSStringEnumerationByWords|NSStringEnumerationLocalized|NSStringEnumerationSubstringNotRequired
			usingBlock:wordEnumeratorBlock];
	
		if(wordIndex > 0) {
			return !maximumWordCountExceeded;
		}
	}
	
	return NO;
}

@end
