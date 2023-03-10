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

#import "AKLightboxView.h"

@interface AKLightboxView()

@property(nonatomic, strong) UIScrollView* scrollView;
@property(nonatomic, strong) UIImageView* imageView;
@property(nonatomic, strong) UINavigationBar* navigationBar;
@property(nonatomic, strong) UIToolbar* toolbar;
@property(nonatomic, strong) UILabel* captionLabel;
@property(nonatomic, strong) AKLightboxProgressView* progressView;
@property(nonatomic) CGRect statusBarFrame;

@property(nonatomic) BOOL barsHidden;
- (void)setBarsHidden:(BOOL)barsHidden animated:(BOOL)animated;

@property(nonatomic, strong) NSDictionary* imageProperties;

@property(nonatomic) CGSize imageSize;
@property(nonatomic) CGSize previewSize;

- (void)initIvars;
- (void)initNavigationBar;
- (void)initToolbar;
- (void)initCaptionLabel;
- (void)initScrollView;
- (void)initImageView;
- (void)initProgressIndicator;
- (void)initGestureRecognizers;

- (void)layoutImageView;

- (void)loadImageWithURL:(NSURL*)imageURL;
- (void)loadAnimatedImage:(CGImageSourceRef)imageSource;
- (void)loadRegularImage:(CGImageSourceRef)imageSource;

- (NSArray*)imagesForSource:(CGImageSourceRef)imageSource;

- (void)updatePreviewImageIfNeeded;
- (void)updateScrollViewContentSize;

- (CGFloat)preferredZoomScale;
- (CGRect)zoomRectForScale:(CGFloat)scale withCenter:(CGPoint)center;

@end
