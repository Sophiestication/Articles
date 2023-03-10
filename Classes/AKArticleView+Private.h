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

#import "AKArticleView.h"

#import "AKWebCustomizer.h"
#import "AKWebCustomizer+Private.h"

@class AKChapterIndexView;
@class AKLanguagePicker;

@interface AKArticleView()

@property(nonatomic, readwrite) BOOL webViewLoaded;
@property(nonatomic, readwrite) BOOL DOMLoaded;

@property(nonatomic, readwrite) BOOL loadingDocument;
@property(nonatomic, readwrite) BOOL loading;
@property(nonatomic) BOOL failed;

@property(nonatomic, strong) NSURL* possibleArticleURL;

@property(nonatomic, strong) NSError* visibleError;

@property(nonatomic) float progress;
@property(nonatomic) float archiveProgress;
@property(nonatomic) float webViewProgress;

@property(nonatomic, strong) UIView* contentView;

@property(nonatomic, strong) UIWebView* webView;
@property(nonatomic, strong) AKWebCustomizer* webCustomizer;
@property(nonatomic, strong) SFPlaceholderView* statusView;
@property(nonatomic, strong) AKChapterIndexView* chapterIndex;
@property(nonatomic, strong) AKLockOrientationView* lockOrientationView;

@property(nonatomic, strong) UIImageView* tutorialView;
@property(nonatomic, strong) UIScrollView* placeholderScrollView;

@property(nonatomic, readwrite, strong) UIView* topOrnamentView;
@property(nonatomic, readwrite, strong) UIView* bottomOrnamentView;
@property(nonatomic, readwrite, strong) UIView* leftOrnamentView;
@property(nonatomic, readwrite, strong) UIView* rightOrnamentView;
@property(nonatomic, readwrite, strong) AKShadowView* topOrnamentShadowView;
@property(nonatomic, readwrite, strong) AKShadowView* bottomOrnamentShadowView;
@property(nonatomic, readwrite, strong) AKShadowView* leftOrnamentShadowView;
@property(nonatomic, readwrite, strong) AKShadowView* rightOrnamentShadowView;
@property(nonatomic, readwrite, strong) AKShadowView* navigationBarShadowView;
@property(nonatomic, readwrite, strong) UIImageView* documentFooterView;

@property(nonatomic, strong) NSArray* documentFontSizes;
@property(nonatomic, strong) NSString* documentFontSize;

@property(nonatomic, strong) AKArchive* visibleArchive;
@property(nonatomic, copy) NSURL* visibleArticleURL;

@property(nonatomic, strong) NSMutableArray* readyMadeThumbnails;

@property(nonatomic, weak) AKTabularDataViewController* visibleTabularDataViewController;

+ (void)postNetworkActivityWillStartNotification;
+ (void)postNetworkActivityDidEndNotification;

- (void)initIvars;
- (void)initContentView;
- (void)initWebView;
- (void)initChapterIndex;
- (void)initStatusViewIfNeeded;
- (void)initPlaceholderScrollViewIfNeeded;
- (void)initOrnamentViews;
- (void)initLockOrientationView;
- (void)initKeyValueObservers;

- (void)layoutContentViews;
- (void)layoutScrollIndicators;
- (void)layoutChapterIndex;
- (void)layoutOrnamentViews;
- (void)layoutOrnamentBackground;
- (void)layoutLockOrientationView;

- (BOOL)webView:(UIWebView*)webView shouldHandleArticleURL:(NSURL*)URL options:(NSDictionary*)options;
- (BOOL)webCustomizer:(AKWebCustomizer*)webCustomizer shouldHandleEventWithURL:(NSURL*)URL;

- (void)webCustomizer:(AKWebCustomizer*)webCustomizer shouldPresentImageForURL:(NSURL*)URL options:(NSDictionary*)options;
- (void)webCustomizer:(AKWebCustomizer*)webCustomizer shouldPresentTableForURL:(NSURL*)URL options:(NSDictionary*)options;

- (void)updateProgress;
- (void)resetProgress;

- (void)setProgressIndicatorShown:(BOOL)progressIndicatorShown animated:(BOOL)animated;
- (void)showError:(NSError*)error animated:(BOOL)animated;
- (void)setTutorialShown:(BOOL)tutorialShown animated:(BOOL)animated;
- (void)setTutorialShown:(BOOL)tutorialShown animated:(BOOL)animated bounce:(BOOL)bounce;
- (void)setWebViewShown:(BOOL)webViewShown animated:(BOOL)animated;

- (void)showThumbnail:(NSDictionary*)thumbnail;
- (NSString*)showThumbnailJavascript:(NSDictionary*)thumbnail;

- (void)showLightboxWithOptions:(NSDictionary*)options;

- (UIViewController*)parentViewController;

- (void)increaseFontSize;
- (void)decreaseFontSize;

- (AKLanguagePicker*)languagePicker;

- (void)resetWebView;

@end
