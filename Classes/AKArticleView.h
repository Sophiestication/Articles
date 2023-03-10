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

#import <UIKit/UIKit.h>

#import <MessageUI/MessageUI.h>

#import "AKArticleViewDelegate.h"
#import "AKWebCustomizerDelegate.h"
#import "AKArchiveDelegate.h"
#import "AKTabularDataViewDelegate.h"
#import "AKLightboxControllerDelegate.h"

@class AKWebCustomizer;
@class AKChapterIndexView;
@class AKLockOrientationView;
@class AKShadowView;
@class SFBezelView;
@class SFPlaceholderView;

extern NSString* const AKArticleViewWillStartNetworkActivityNotification;
extern NSString* const AKArticleViewDidEndNetworkActivityNotification;

extern NSString* const AKOpenArticleInNewPageOptionKey;

@interface AKArticleView : UIView<UIWebViewDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate, AKWebCustomizerDelegate, AKArchiveDelegate, AKTabularDataViewDelegate, AKLightboxControllerDelegate> {
@private
	BOOL _loadingDocument;
	BOOL _loading;
	BOOL _failed;
	BOOL _searching;
	BOOL _needsOrnamentBackgroundLayout;
	
	AKTabularDataViewController* __weak _visibleTabularDataViewController;
	
	UIEdgeInsets _contentInset;
	UIEdgeInsets _scrollIndicatorInsets;
    UIEdgeInsets _searchResultIndicatorInsets;
}

@property(nonatomic, weak) id<AKArticleViewDelegate> delegate;

@property(weak, nonatomic, readonly) NSURL* articleURL;
@property(weak, nonatomic, readonly) NSString* articleTitle;

@property(nonatomic, readonly, getter=canGoBack) BOOL canGoBack;
@property(nonatomic, readonly, getter=canGoForward) BOOL canGoForward;

@property(nonatomic, readonly, getter=isLoadingDocument) BOOL loadingDocument;
@property(nonatomic, readonly, getter=isLoading) BOOL loading;

@property(nonatomic, readonly) CGSize contentSize;

@property(nonatomic) UIEdgeInsets contentInset;
@property(nonatomic) UIEdgeInsets scrollIndicatorInsets;

@property(nonatomic) CGPoint contentOffset;
- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;

- (void)loadArticle:(NSURL*)articleURL animated:(BOOL)animated;

- (void)reload;
- (void)stopLoading;

- (void)flashChapterIndex;

- (void)showLanguagePicker;
- (void)showMetadata;

- (UIImage*)previewImage;

@end
