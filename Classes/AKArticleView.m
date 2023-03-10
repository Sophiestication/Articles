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
#import "AKArticleView+Archiving.h"
#import "AKArticleView+Searching.h"
#import "AKArticleView+Printing.h"
#import "AKArticleView+Debug.h"
#import "AKArticleView+Private.h"

#import "AKWebCustomizer.h"
#import "AKWebCustomizer+Private.h"

#import "AKLightboxViewController.h"
#import "AKTabularDataViewController.h"
#import "AKLanguagePicker.h"

#import "AKChapterIndexView.h"
#import "AKChapterIndexView+Private.h"

#import "AKArticleOrnamentView.h"
#import "AKShadowView.h"
#import "AKGraphics.h"

#import "AKLockOrientationView.h"
#import "AKLockOrientationView+Private.h"

#import "AKArchive.h"
#import "AKArchive+Private.h"
#import "AKArchiveController.h"

#import "SFNavigationController.h"
#import "SFBezelController.h"

#import "AKResourceURLProtocol.h"
#import "AKImageURLProtocol.h"

#import "AKChapterIndexGestureRecognizer.h"

#import "RESTfulKit.h"
#import "WikipediaAPI.h"

#import "NSArray+Additions.h"
#import "NSURL+Wikipedia.h"
#import "NSString+Additions.h"
#import "UIActionSheet+Additions.h"

#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/MobileCoreServices.h>

@implementation AKArticleView

NSString* const AKArticleViewWillStartNetworkActivityNotification = @"AKArticleViewWillStartNetworkActivityNotification";
NSString* const AKArticleViewDidEndNetworkActivityNotification = @"AKArticleViewDidEndNetworkActivityNotification";

NSString* const AKOpenArticleInNewPageOptionKey = @"AKOpenArticleInNewPageOption";

@dynamic articleURL;
@dynamic articleTitle;

@dynamic canGoBack;
@dynamic canGoForward;

@dynamic contentSize;
@dynamic contentOffset;

@dynamic contentInset;
@dynamic scrollIndicatorInsets;

#pragma mark -
#pragma mark Construction & Destruction

+ (void)initialize {
    if(self == [AKArticleView class]) {
		[NSURLProtocol registerClass:[AKResourceURLProtocol class]];
		// [NSURLProtocol registerClass:[AKImageURLProtocol class]];
    }
}

- (id)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
		[self initIvars];
		[self initContentView];
		[self initWebView];
		[self initChapterIndex];
		[self initOrnamentViews];
		[self initLockOrientationView];
		[self initKeyValueObservers];

		self.contentView.clipsToBounds = YES;
	}

    return self;
}

- (id)initWithCoder:(NSCoder*)coder {
    if((self = [super initWithCoder:coder])) {
		[self initIvars];
		[self initContentView];
		[self initWebView];
		[self initChapterIndex];
		[self initOrnamentViews];
		[self initLockOrientationView];
		[self initKeyValueObservers];

		self.contentView.clipsToBounds = YES;
	}

    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	self.visibleTabularDataViewController = nil;
	self.visibleArchive.delegate = nil;
}

#pragma mark -
#pragma mark AKArticleView

- (BOOL)canGoBack {
	return self.webView.canGoBack;
}

- (BOOL)canGoForward {
	return self.webView.canGoForward;
}

- (NSURL*)articleURL {
	return self.visibleArchive.articleURL;
}

- (NSString*)articleTitle {
	NSString* title = [[self webView]
		stringByEvaluatingJavaScriptFromString:@"document.getElementById('firstHeading').innerText"];
		
//	if(title.length == 0) {
//		title = [[self articleURL] wikipediaTitle];
//	}
		
	return title;
}

- (void)loadArticle:(NSURL*)articleURL animated:(BOOL)animated {
	// ...
	self.possibleArticleURL = articleURL;
	
	// Prevent flashing the chapter index
	[NSObject cancelPreviousPerformRequestsWithTarget:self
		selector:@selector(flashChapterIndex)
		object:nil];
	
	// We better reset the failed property to prevent confusions
	self.failed = NO;

	// ...
	[self resetProgress];

	// Retrieve a new archive for this URL
	AKArchive* archive = [AKArchive
		archiveForArticle:articleURL
		archiveType:AKArchiveTypeCache];
	
	archive.delegate = self;
	
	// Clear the thumbnail cache
	[[self readyMadeThumbnails] removeAllObjects];
	
	// Reload from the web if needed
	[archive loadArchiveIfNeeded];
	
	// Keep this for later
	if(self.visibleArchive != archive) {
		self.visibleArchive.delegate = nil;
		self.visibleArchive = archive;
	}

	// We're now loading
	BOOL loadingArchive = archive.loading;
	BOOL hasValidArticleURL = articleURL != nil;
	
	self.loading = self.loadingDocument = hasValidArticleURL;
	[self setProgressIndicatorShown:[self isLoadingDocument] animated:NO];
	
	if(hasValidArticleURL) {
		// Notify our delegate
		if([[self delegate] respondsToSelector:@selector(articleViewDidStartLoad:)]) {
			[[self delegate] articleViewDidStartLoad:self];
		}
	}
	
	// Start displaying the article if possible
	if(hasValidArticleURL && !loadingArchive) {
		[self loadArchive:archive];
	}
	
	// Show the tutorial if we have no article
//	[self setTutorialShown:!hasValidArticleURL && !self.loadingDocument animated:NO];
	
	// Send out the first progress notification
	[self updateProgress];
}

- (void)reload {
	// Do we have an archive?
	AKArchive* archive = self.archive;
	
	if(archive && !archive.loading) {
		// Clear the thumbnail cache
		[[self readyMadeThumbnails] removeAllObjects];

		// We're now loading
		self.loading = self.loadingDocument = YES;
        self.DOMLoaded = self.webViewLoaded = NO;
		self.failed = NO;
		
		// ...
		[self resetProgress];
		
		// Notify our delegate
		if([[self delegate] respondsToSelector:@selector(articleViewDidStartLoad:)]) {
			[[self delegate] articleViewDidStartLoad:self];
		}
		
		// And transition to the new state if needed
		[self setWebViewShown:NO animated:NO];
		
		// Reload
		[archive reloadArchive];
		
		// Send out the first progress notification
		[self updateProgress];
	}
}

- (void)stopLoading {
	if(self.archive.loading || self.archive.loadingImages) {
		[[self archive] stopLoading];
	}
}

- (UIEdgeInsets)contentInset {
	return _contentInset;
}

- (void)setContentInset:(UIEdgeInsets)contentInset {
	if(!UIEdgeInsetsEqualToEdgeInsets(contentInset, [self contentInset])) {
		_contentInset = contentInset;
		
		self.webCustomizer.scrollView.contentInset = self.contentInset;
		[self setNeedsLayout];
	}
}

- (UIEdgeInsets)scrollIndicatorInsets {
	return _scrollIndicatorInsets;
}

- (void)setScrollIndicatorInsets:(UIEdgeInsets)scrollIndicatorInsets {
	if(!UIEdgeInsetsEqualToEdgeInsets(scrollIndicatorInsets, [self scrollIndicatorInsets])) {
		_scrollIndicatorInsets = scrollIndicatorInsets;
		[self setNeedsLayout];
	}
}

- (void)flashChapterIndex {
	if(!self.failed && self.visibleArchive && !self.loadingDocument) {
		[[[self webCustomizer] scrollView] flashScrollIndicators];
	}
}

- (void)showLanguagePicker {
	AKLanguagePicker* picker = [self languagePicker];
	
	UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:picker];
	[[self parentViewController] presentViewController:navigationController animated:YES completion:nil];
}

- (void)showMetadata {
}

- (UIImage*)previewImage {
	if(!self.articleURL || self.webView.hidden) {
		return nil;
	}
	
	if(self.loadingDocument || self.failed) {
		return nil;
	}
	
	// ...
	[[self parentViewController] becomeFirstResponder];
	
	UIScrollView* scrollView = self.webCustomizer.scrollView;
	
	BOOL verticalScrollIndicatorShown = scrollView.showsVerticalScrollIndicator;
	BOOL horizontalScrollIndicatorShown = scrollView.showsHorizontalScrollIndicator;

	scrollView.showsVerticalScrollIndicator = scrollView.showsHorizontalScrollIndicator = NO;

	// Scale down the image to save memory
	UIImage* previewImage = nil;
	static CGFloat const scale = 1.0; // Don't scale because of landscape mode
	
	CGSize previewImageSize = self.webView.bounds.size;

	previewImageSize.width *= scale;
	previewImageSize.height *= scale;
	
	if(UIGraphicsBeginImageContextWithOptions) {
		UIGraphicsBeginImageContextWithOptions(previewImageSize, YES, 0.0);
	} else {
		 UIGraphicsBeginImageContext(previewImageSize);
	} {
		CGContextRef context = UIGraphicsGetCurrentContext();
		
		[[UIColor whiteColor] set];
		UIRectFill(CGContextGetClipBoundingBox(context));
		
		CGPoint contentOffset = self.contentOffset;

		if(contentOffset.y < 0.0) {
			self.contentOffset = CGPointMake(contentOffset.x, 0.0);
		}
		
		CGContextScaleCTM(context, scale, scale);

		[[[self webView] layer] renderInContext:context];
		self.contentOffset = contentOffset;
		
		previewImage = UIGraphicsGetImageFromCurrentImageContext();
	} UIGraphicsEndImageContext();
	
	scrollView.showsVerticalScrollIndicator = verticalScrollIndicatorShown;
	scrollView.showsHorizontalScrollIndicator = horizontalScrollIndicatorShown;
	
	return previewImage;
}

- (CGSize)contentSize {
	return self.webCustomizer.scrollView.contentSize;
}

- (CGPoint)contentOffset {
	return self.webCustomizer.scrollView.contentOffset;
}

- (void)setContentOffset:(CGPoint)contentOffset {
	[self setContentOffset:contentOffset animated:NO];
}

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated {
	[[[self webCustomizer] scrollView] setContentOffset:contentOffset animated:animated];
}

/*
- (void)share:(id)sender {
	NSString* selectedHTML = [[self webView] stringByEvaluatingJavaScriptFromString:@"articleKitDocumentController.getSelectedHTML()"];

	NSString* CSS = [NSString stringWithContentsOfURL:
		[NSURL URLWithString:@"x-articlekit-resource://share.css"]
		encoding:NSUTF8StringEncoding
		error:nil];
	
	selectedHTML = [NSString stringWithFormat:@"<style type=\"text/css\">%@</style>%@",
		CSS,
		selectedHTML];
	
	MFMailComposeViewController* viewController = [[[MFMailComposeViewController alloc] init] autorelease];
	
	[viewController setSubject:[self articleTitle]];
	[viewController setMessageBody:selectedHTML isHTML:YES];
	
//	viewController.mailComposeDelegate = self;

	[[self parentViewController] presentModalViewController:viewController animated:YES];
}
*/

#pragma mark -
#pragma mark UIResponder

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	if(@selector(find:) == action) {
		return [self canPerformFindAction:action withSender:sender];
	}
	
	return [super canPerformAction:action withSender:sender];
}

#pragma mark -
#pragma mark UIView

- (void)setFrame:(CGRect)frame {
	if(!CGRectEqualToRect(frame, [self frame])) {
		_needsOrnamentBackgroundLayout = YES;
		[super setFrame:frame];
	}
}

- (void)willMoveToSuperview:(UIView*)newSuperview {
	[super willMoveToSuperview:newSuperview];
	
	// Add the chapter index to our superview to make sure it floats over other
	// accessory views which are no subviews of AKArticleView.
	[newSuperview addSubview:[self chapterIndex]];
	[newSuperview bringSubviewToFront:[self chapterIndex]];
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event {
	if(self.statusView && !self.statusView.hidden) {
		return self.statusView;
	}
	
	UIView* view = [super hitTest:point withEvent:event];
	
	if(view == self) {
		view = self.webCustomizer.scrollView;
	}
	
	view = [[self webCustomizer] hitTest:point withEvent:event targetView:view inView:self];

	return view;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if(_needsOrnamentBackgroundLayout) {
		[self layoutOrnamentBackground];
	}

	[self layoutChapterIndex];
	[self layoutContentViews];
	[self layoutOrnamentViews];
	[self layoutLockOrientationView];
	[self layoutScrollIndicators];
}

- (void)layoutContentViews {
//	CGRect webViewRect = UIEdgeInsetsInsetRect(
//		self.bounds,
//		self.contentEdgeInsets);

	CGRect webViewRect = self.bounds;
	self.webView.frame = webViewRect;
	
	CGRect statusViewRect = webViewRect;
	
	if(self.contentInset.top > 0) {
		CGFloat statusViewOffset = 60.0;
		statusViewRect.origin.y += statusViewOffset;
		statusViewRect.size.height -= statusViewOffset;
	}
	
	if(self.contentInset.bottom > 0) {
		statusViewRect.size.height -= self.contentInset.bottom;
	}
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		statusViewRect = CGRectOffset(statusViewRect, 0.0, -60.0);
	}
	
	if(self.placeholderScrollView) {
		self.placeholderScrollView.frame = webViewRect;
	}
	
	self.statusView.frame = statusViewRect;
	
	if(self.tutorialView) {
		CGFloat offset = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ?
        	72.0 :
            10.0;
        
        CGSize tutorialViewSize = self.tutorialView.image.size;
		self.tutorialView.frame = CGRectMake(
			round(CGRectGetMaxX(statusViewRect) - tutorialViewSize.width),
			CGRectGetMinY(statusViewRect) + offset,
			tutorialViewSize.width,
			tutorialViewSize.height);
        self.tutorialView.alpha = 1.0;
			
		self.statusView.hidden = YES;
	}
	
	self.placeholderScrollView.hidden = !self.webView.hidden;
}

- (void)layoutScrollIndicators {
	UIScrollView* scrollView = self.webCustomizer.scrollView;
	
	if(scrollView) {
		UIEdgeInsets scrollIndicatorInsets = self.scrollIndicatorInsets;
			
		if(self.searching) {
			scrollIndicatorInsets.bottom += 15.0;
		} else {
			if(CGRectGetHeight(self.bottomOrnamentView.frame) > scrollIndicatorInsets.bottom) {
				scrollIndicatorInsets.bottom = CGRectGetHeight(self.bottomOrnamentView.frame);
			}
		}
		
		[scrollView setScrollIndicatorInsets:scrollIndicatorInsets];
	}
}

- (void)layoutLockOrientationView {
	if(self.contentOffset.y < 0.0) {
		CGRect bounds = self.bounds;

		CGRect lockOrientationViewRect = CGRectMake(
			CGRectGetMinX(bounds), CGRectGetMinY(bounds) - self.contentInset.top,
			CGRectGetWidth(bounds), abs(self.contentOffset.y));
		self.lockOrientationView.frame = lockOrientationViewRect;
	
		self.lockOrientationView.hidden = NO;
		
		// [[self lockOrientationView] layoutIfNeeded];
		[[self lockOrientationView] updateForContentSize:lockOrientationViewRect.size animated:YES];
	} else {
		self.lockOrientationView.hidden = YES;
	}
}

- (void)layoutChapterIndex {
	AKChapterIndexView* chapterIndexView = self.chapterIndex;
	
	CGRect contentRect = self.bounds;
	contentRect = [self convertRect:contentRect toView:[chapterIndexView superview]];
	
	CGSize chapterIndexSize = [chapterIndexView
		sizeThatFits:contentRect.size];
	
	CGRect chapterIndexRect = CGRectMake(
		CGRectGetMaxX(contentRect) - chapterIndexSize.width,
		CGRectGetMinY(contentRect),
		chapterIndexSize.width,
		CGRectGetHeight(contentRect) - self.contentInset.bottom);

	chapterIndexView.frame = chapterIndexRect;
	
	if(chapterIndexView.active) {
		[[chapterIndexView superview] bringSubviewToFront:chapterIndexView];
	}
}

- (void)layoutOrnamentViews {
	static const CGFloat webViewPadding = 0.0;

	CGRect bounds = self.bounds;
	
	CGPoint contentOffset = self.contentOffset;
	CGSize contentSize = self.contentSize;

	// Layout the left ornament view
	CGRect leftOrnamentViewRect = CGRectMake(
		CGRectGetMinX(bounds),
		CGRectGetMinY(bounds),
		MAX(CGRectGetMinX(bounds) - contentOffset.x, 0.0),
		MAX(CGRectGetHeight(bounds), 0.0));
	self.leftOrnamentView.frame = leftOrnamentViewRect;
	
	// Layout the left ornament shadow view
	CGSize leftOrnamentShadowViewSize = [[self leftOrnamentShadowView]
		sizeThatFits:leftOrnamentViewRect.size];
	CGRect leftOrnamentShadowViewRect = CGRectMake(
		CGRectGetMaxX(leftOrnamentViewRect) - leftOrnamentShadowViewSize.width,
		MAX(-contentOffset.y, 0.0),
		leftOrnamentShadowViewSize.width,
		CGRectGetHeight(leftOrnamentViewRect));
	self.leftOrnamentShadowView.frame = leftOrnamentShadowViewRect;

	// Layout the right ornament view
	CGFloat rightOrnamentWidth = MAX(contentOffset.x - ((contentSize.width - webViewPadding * 2.0) - CGRectGetWidth(bounds)), 0.0);
	
	if(rightOrnamentWidth >= CGRectGetWidth(bounds)) {
		rightOrnamentWidth = 0.0;
	}
	
	CGRect rightOrnamentViewRect = CGRectMake(
		CGRectGetMaxX(bounds) - rightOrnamentWidth,
		CGRectGetMinY(bounds),
		rightOrnamentWidth,
		MAX(CGRectGetHeight(bounds), 0.0));
	self.rightOrnamentView.frame = rightOrnamentViewRect;
	
	// Layout the right ornament shadow view
	CGSize rightOrnamentShadowViewSize = [[self rightOrnamentShadowView]
		sizeThatFits:rightOrnamentViewRect.size];
	CGRect rightOrnamentShadowViewRect = CGRectMake(
		0.0,
		MAX(-contentOffset.y, 0.0),
		rightOrnamentShadowViewSize.width,
		CGRectGetHeight(rightOrnamentViewRect));
	self.rightOrnamentShadowView.frame = rightOrnamentShadowViewRect;
	
	// Layout the top ornament view
	CGRect topOrnamentViewRect = CGRectMake(
		CGRectGetMinX(bounds) + MAX(-contentOffset.x, 0.0),
		CGRectGetMinY(bounds) - self.contentInset.top,
		MAX(CGRectGetWidth(bounds), 0.0),
		MAX(-contentOffset.y, 0.0));
	self.topOrnamentView.frame = topOrnamentViewRect;
	
	CGSize topOrnamentShadowViewSize = [[self topOrnamentShadowView]
		sizeThatFits:topOrnamentViewRect.size];
	CGRect topOrnamentShadowViewRect = CGRectMake(
		0.0,
		CGRectGetHeight(topOrnamentViewRect) - topOrnamentShadowViewSize.height,
		CGRectGetWidth(topOrnamentViewRect) - CGRectGetWidth(rightOrnamentViewRect),
		topOrnamentShadowViewSize.height);
	self.topOrnamentShadowView.frame = topOrnamentShadowViewRect;
	
	// Layout the bottom ornament view
	CGFloat bottomOrnamentViewHeight = MAX((contentOffset.y + CGRectGetHeight(bounds)) - (contentSize.height - webViewPadding), 0.0);

	if(bottomOrnamentViewHeight >= CGRectGetHeight(bounds)) {
		bottomOrnamentViewHeight = 0.0;
	}

	CGRect bottomOrnamentViewRect = CGRectMake(
		CGRectGetMinX(topOrnamentViewRect),
		CGRectGetMaxY(bounds) - bottomOrnamentViewHeight,
		CGRectGetWidth(topOrnamentViewRect),
		bottomOrnamentViewHeight);
	self.bottomOrnamentView.frame = bottomOrnamentViewRect;
	
	CGSize bottomOrnamentShadowViewSize = [[self bottomOrnamentShadowView]
		sizeThatFits:bottomOrnamentViewRect.size];
	CGRect bottomOrnamentShadowViewRect = CGRectMake(
		0.0,
		CGRectGetHeight(bottomOrnamentViewRect) - bottomOrnamentShadowViewSize.height - self.contentInset.bottom,
		CGRectGetWidth(bottomOrnamentViewRect) - CGRectGetWidth(rightOrnamentViewRect),
		bottomOrnamentShadowViewSize.height);
	self.bottomOrnamentShadowView.frame = bottomOrnamentShadowViewRect;

	CGSize documentFooterSize = self.documentFooterView.image.size;
	CGRect documentFooterRect = CGRectMake(
		0.0, 0.0,
		CGRectGetWidth(bottomOrnamentViewRect), documentFooterSize.height);
	self.documentFooterView.frame = documentFooterRect;
    
    // Layout the navigation bar shadow view
    if(self.navigationBarShadowView) {
		CGSize navigationBarShadowViewSize = [[self navigationBarShadowView]
			sizeThatFits:bounds.size];
		CGRect navigationBarOrnamentShadowViewRect = CGRectMake(
			0.0, 0.0,
			CGRectGetWidth(topOrnamentViewRect), navigationBarShadowViewSize.height);
		self.navigationBarShadowView.frame = navigationBarOrnamentShadowViewRect;
	}

	// ...
	leftOrnamentShadowViewRect.origin.y -= CGRectGetHeight(bottomOrnamentViewRect);
	self.leftOrnamentShadowView.frame = leftOrnamentShadowViewRect;
	
	// ...
	self.bottomOrnamentView.hidden = self.searching;
}

- (void)layoutOrnamentBackground {
	self.topOrnamentView.backgroundColor =
	self.bottomOrnamentView.backgroundColor =
	self.leftOrnamentView.backgroundColor = 
	self.rightOrnamentView.backgroundColor =
		AKOrnamentBackgroundColorWithHeight(CGRectGetHeight(self.bounds));
	
	_needsOrnamentBackgroundLayout = NO;
}

#pragma mark -
#pragma mark AKWebCustomizerDelegate

- (UIView*)webCustomizer:(AKWebCustomizer*)webCustomizer viewForGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer {
	return self;
}

- (void)webCustomizer:(AKWebCustomizer*)webCustomizer shouldPresentURL:(NSURL*)URL options:(NSDictionary*)options {
	NSString* type = [options objectForKey:@"type"];
	
	if(SFEqualStrings(type, @"regular") || SFEqualStrings(type, @"external")) {
		NSURLRequest* request = [NSURLRequest requestWithURL:URL];
		[self webView:[webCustomizer webView] shouldStartLoadWithRequest:request navigationType:UIWebViewNavigationTypeLinkClicked];
	} else if(SFEqualStrings(type, @"image")) {
		[self webCustomizer:webCustomizer shouldPresentImageForURL:URL options:options];
	} else if(SFEqualStrings(type, @"table-cell")) {
		[self webCustomizer:webCustomizer shouldPresentTableForURL:URL options:options];
	}
	
	if([self visibleTabularDataViewController] && SFEqualStrings(type, @"regular")) {
		[[self visibleTabularDataViewController] done:self];
	}
}	

- (void)webCustomizer:(AKWebCustomizer*)webCustomizer shouldPresentSheetForURL:(NSURL*)URL options:(NSDictionary*)options {
	NSString* type = [options objectForKey:@"type"];
	
	// Special case for table cells
	if(SFEqualStrings(type, @"table-cell")) {
		[self webCustomizer:webCustomizer shouldPresentTableForURL:URL options:options];
		return;
	}
	
	// ...
	UIViewController* parentViewController = self.visibleTabularDataViewController ?
		self.visibleTabularDataViewController :
		[self parentViewController];
	UIView* parentView = parentViewController ?
		[parentViewController view] :
		[webCustomizer webView];
		
	NSMutableDictionary* newOptions = [NSMutableDictionary dictionaryWithDictionary:options];
	[newOptions setObject:webCustomizer forKey:@"webCustomizer"];
	options = newOptions;

	NSString* URLString = [[URL absoluteString]
		stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

	UIActionSheet* sheet = [[UIActionSheet alloc]
		initWithTitle:URLString
		delegate:nil
		cancelButtonTitle:nil
		destructiveButtonTitle:nil
		otherButtonTitles:nil];
	
	if(SFEqualStrings(type, @"regular")) {
		[sheet addButtonWithTitle:NSLocalizedString(@"SHEETBUTTON_OPEN", @"") block:^{
			if([self visibleTabularDataViewController]) {
				[[self visibleTabularDataViewController] done:self];
			}
			
			[self webView:[webCustomizer webView] shouldHandleArticleURL:URL options:nil];
		}];
		
#ifndef CONFIGURATION_ARTICLEKIT
        [sheet addButtonWithTitle:NSLocalizedString(@"SHEETBUTTON_OPEN_NEWPAGE", @"") block:^{
            if([self visibleTabularDataViewController]) {
                [[self visibleTabularDataViewController] done:self];
            }
			
            NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
                (id)kCFBooleanTrue, AKOpenArticleInNewPageOptionKey,
                nil];
            [self webView:[webCustomizer webView] shouldHandleArticleURL:URL options:options];
        }];
#endif
		
		BOOL respondsToReadLater = [[self delegate] respondsToSelector:
			@selector(articleView:shouldReadLaterWithOptions:)];
			
		if(respondsToReadLater) {
			[sheet addButtonWithTitle:NSLocalizedString(@"SHEETBUTTON_READLATER", @"") block:^{
				NSMutableDictionary* readLaterOptions = [NSMutableDictionary dictionary];

				NSDictionary* readLaterInfo = [options objectForKey:@"readLater"];
				
				NSArray* rectStrings = [readLaterInfo objectForKey:@"rects"];
				NSMutableArray* rects = [NSMutableArray arrayWithCapacity:[rectStrings count]];
				
				for(NSString* rectString in rectStrings) {
					CGRect rect = CGRectFromString(rectString);
					rect = [[webCustomizer documentView] convertRect:rect toView:nil];
					
					[rects addObject:[NSValue valueWithCGRect:rect]];
				}
				
				[readLaterOptions setObject:rects forKey:@"rects"];
				
				UIView* sourceView = [webCustomizer webView];
				[readLaterOptions setObject:sourceView forKey:@"sourceView"];
				
				NSString* text = [[readLaterInfo objectForKey:@"text"]
					stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
				[readLaterOptions setObject:text forKey:@"text"];
				
				NSRange targetTextRange = NSRangeFromString([readLaterInfo objectForKey:@"targetTextRange"]);
				[readLaterOptions setObject:[NSValue valueWithRange:targetTextRange] forKey:@"targetTextRange"];
				
				[readLaterOptions setObject:URL forKey:@"URL"];
				[readLaterOptions setObject:[self articleURL] forKey:@"fromURL"];
				
				[[self delegate]
					articleView:self
					shouldReadLaterWithOptions:readLaterOptions];
			}];
		}
		
		[sheet addButtonWithTitle:NSLocalizedString(@"SHEETBUTTON_CLIPBOARD_COPY", @"") block:^{
			NSArray* pasteboardItems = [NSArray arrayWithObjects:
				[NSDictionary dictionaryWithObject:URL forKey:(id)kUTTypeURL],
				[NSDictionary dictionaryWithObject:URLString forKey:(id)kUTTypeUTF8PlainText],
				nil];
			[[UIPasteboard generalPasteboard] setItems:pasteboardItems];
		}];
	}
	
	if(SFEqualStrings(type, @"external")) {
		[sheet addButtonWithTitle:NSLocalizedString(@"SHEETBUTTON_OPEN", @"") block:^{
			NSURLRequest* request = [NSURLRequest requestWithURL:URL];
			[self webView:[webCustomizer webView] shouldStartLoadWithRequest:request navigationType:UIWebViewNavigationTypeLinkClicked];
		}];
		
		[sheet addButtonWithTitle:NSLocalizedString(@"OPENSAFARI_ACTION_TITLE", @"") block:^{
			[[UIApplication sharedApplication] openURL:URL];
		}];
		
		[sheet addButtonWithTitle:NSLocalizedString(@"SHEETBUTTON_CLIPBOARD_COPY", @"") block:^{
			NSArray* pasteboardItems = [NSArray arrayWithObjects:
				[NSDictionary dictionaryWithObject:URL forKey:(id)kUTTypeURL],
				[NSDictionary dictionaryWithObject:URLString forKey:(id)kUTTypeUTF8PlainText],
				nil];
			[[UIPasteboard generalPasteboard] setItems:pasteboardItems];
		}];
	}
	
	if(SFEqualStrings(type, @"image")) {
		[sheet addButtonWithTitle:NSLocalizedString(@"SHEETBUTTON_QUICKLOOK", @"") block:^{
			[self webCustomizer:webCustomizer shouldPresentURL:URL options:options];
		}];
		
		[sheet addButtonWithTitle:NSLocalizedString(@"SHEETBUTTON_SAVE_IMAGE", @"") block:^{
			NSString* imageID = [options objectForKey:@"id"];
			NSData* imageData = [[self visibleArchive] imageDataForID:imageID];
			
			UIImage* image = [[UIImage alloc] initWithData:imageData];
			
			UIImageWriteToSavedPhotosAlbum(image, self, NULL, NULL);

		}];
		
		[sheet addButtonWithTitle:NSLocalizedString(@"SHEETBUTTON_CLIPBOARD_COPY", @"") block:^{
			NSString* imageID = [options objectForKey:@"id"];
			NSData* imageData = [[self visibleArchive] imageDataForID:imageID];
			
			NSArray* pasteboardItems = [NSArray arrayWithObjects:
				[NSDictionary dictionaryWithObject:URL forKey:(id)kUTTypeURL],
//				[NSDictionary dictionaryWithObject:URLString forKey:(id)kUTTypeUTF8PlainText],
				[NSDictionary dictionaryWithObject:imageData forKey:(id)kUTTypeImage],
				nil];
			[[UIPasteboard generalPasteboard] setItems:pasteboardItems];
		}];
	}
	
	[sheet setCancelButtonWithTitle:NSLocalizedString(@"SHEETBUTTON_CANCEL", @"") block:^{
	}];

	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		CGRect targetRect = [[options objectForKey:@"targetRect"] CGRectValue];
		[sheet showFromRect:targetRect inView:[webCustomizer webView] animated:YES];
	} else {
		[sheet showInView:parentView];
	}
}

#pragma mark -
#pragma mark AKArchiveDelegate

- (void)archive:(AKArchive*)articleArchive didProgress:(float)progress {
	if(self.visibleArchive == articleArchive && (articleArchive.loading || articleArchive.loadingImages)) {
		self.archiveProgress = progress;
		[self updateProgress];
	}
}

- (void)archive:(AKArchive*)articleArchive didLoadArticle:(NSURL*)localArticleURL {
	if(self.visibleArchive == articleArchive) {
		[self loadArchive:articleArchive];
	}
}

- (void)archive:(AKArchive*)articleArchive didLoadImage:(NSDictionary*)image {
    if(self.visibleArchive == articleArchive) {
		// Are we still loading the document
		if(self.webViewLoaded && self.DOMLoaded) {
			// Show the thumbnail
            [self showThumbnail:image];
		} else {
			// Make a new array for ready made thumbnails
			if(!self.readyMadeThumbnails) {
				self.readyMadeThumbnails = [NSMutableArray array];
			}
			
			// Keep this thumbnail for later
			[[self readyMadeThumbnails] addObject:image];
		}
	}
}

- (void)archiveDidFinishLoading:(AKArchive*)articleArchive {
	if(self.visibleArchive == articleArchive) {
		/*// Flash the chapter index if we loaded before
		if(self.loading) {
			[self performSelector:@selector(flashChapterIndex)
				withObject:nil
				afterDelay:0.15];
			
			// Send the final finish method
			if([[self delegate] respondsToSelector:@selector(articleViewDidFinishLoad:)]) {
				[(id)[self delegate]
					performSelector:@selector(articleViewDidFinishLoad:)
					withObject:self
					afterDelay:0.0];
			}
		}*/
		
        self.loading = NO;
		
		[[self chapterIndex] setNeedsUpdate];
		[self updateProgress];
        
        [[self delegate] articleViewDidFinishLoad:self];
	}
}

- (void)archive:(AKArchive*)articleArchive didFailLoadWithError:(NSError*)error {
	if(self.visibleArchive == articleArchive) {
		[self webView:[self webView] didFailLoadWithError:error];
	}
}

#pragma mark -
#pragma mark AKTabularDataViewDelegate

- (void)tabularDataViewControllerWillAppear:(AKTabularDataViewController*)viewController {
	self.visibleTabularDataViewController = viewController;
}

- (void)tabularDataViewControllerDidDisappear:(AKTabularDataViewController*)viewController {
	self.visibleTabularDataViewController = nil;
	[self layoutScrollIndicators];
}

#pragma mark -
#pragma mark AKLightboxControllerDelegate

#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView {
	[[self delegate] scrollViewWillBeginDragging:scrollView];
	[[self chapterIndex] setActive:NO];

	CGRect lockOrientationViewRect = self.lockOrientationView.bounds;
	[[self lockOrientationView] updateForContentSize:lockOrientationViewRect.size animated:NO];
}

- (void)scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(BOOL)decelerate {
	[[self delegate] scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
	[[self lockOrientationView]
		webView:nil
		didEndScrollingAtOffset:[scrollView contentOffset]];
}

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
	[[self delegate] scrollViewDidScroll:scrollView];
	[self setNeedsLayout];
//	[self layoutIfNeeded]; // Call now for better results
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView*)scrollView {
	[[self delegate] scrollViewDidEndScrollingAnimation:scrollView];
	[self setNeedsLayout];
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView*)scrollView {
	[[self delegate] scrollViewShouldScrollToTop:scrollView];
	[[self chapterIndex] setActive:NO];
	[self layoutScrollIndicators];

	return YES;
}

- (void)scrollViewDidScrollToTop:(UIScrollView*)scrollView {
	[[self delegate] scrollViewDidScrollToTop:scrollView];
	[self setNeedsLayout];
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
	NSURL* URL = [request URL];

	if([[URL scheme] isEqualToString:@"x-articlekit-internal"]) {
		return [self webCustomizer:[self webCustomizer] shouldHandleEventWithURL:URL];
	}
	
	if(![URL isFileURL] && ![URL isWikipediaURL]) {
		if([[URL absoluteString] hasPrefix:@"about:"]) {
			return NO;
		}
        
        // add a scheme if needed
        if(![URL scheme]) {
        	NSString* fixedURLString = [@"http:" stringByAppendingString:[URL resourceSpecifier]];
			URL = [NSURL URLWithString:fixedURLString];
        }
		
		// Tell the delegate to load this external resource
		if([[self delegate] respondsToSelector:@selector(articleView:shouldLoadExternalResource:)]) {
			[[self delegate] articleView:self shouldLoadExternalResource:URL];
		}
		
		return NO;
	}
	
	// Tell the delegate to display the wikipedia file resource if needed
	if(navigationType == UIWebViewNavigationTypeLinkClicked &&
	   [URL isWikipediaFileURL]) {
		return NO; // return [self webView:webView shouldHandleFileResourceURL:URL];
	}
	
	if([URL isWikipediaURL] && navigationType != UIWebViewNavigationTypeOther) {
		return [self webView:webView shouldHandleArticleURL:URL options:nil];
	}
	
	return YES;
}

- (void)webViewDidStartLoad:(UIWebView*)webView {
	// Prevent flashing the chapter index
	[NSObject cancelPreviousPerformRequestsWithTarget:self
		selector:@selector(flashChapterIndex)
		object:nil];
}

- (void)webViewDidFinishLoad:(UIWebView*)webView {
	self.webViewLoaded = YES;
    [self finishWebViewLoadIfNeeded:webView];
}

- (void)finishWebViewLoadIfNeeded:(UIWebView*)webView {
	if(!self.DOMLoaded) { return; }
    if(!self.webViewLoaded) { return; }
    
    // push history state
    NSString* articleURLString = [[self articleURL] absoluteString];
    articleURLString = [articleURLString stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""];
  
	NSString* pushStateJavascript = [NSString stringWithFormat:@"window.history.pushState({}, window.title, \"%@\")", articleURLString];
	[webView stringByEvaluatingJavaScriptFromString:pushStateJavascript];
    
     // adjust the font size
    if(self.documentFontSize) {
    	NSString* javascript = [NSString stringWithFormat:@"addClass(document.body, \"%@\");", [self documentFontSize]];
        [webView stringByEvaluatingJavaScriptFromString:javascript];
    }
    
    // display all remaining thumbnails
	for(NSDictionary* thumbnail in self.readyMadeThumbnails) {
		[self showThumbnail:thumbnail];
	}
	
	[[self readyMadeThumbnails] removeAllObjects];
    
    // and be ready in a sec…
    [self performSelector:@selector(webViewIsReadyToDisplay:) withObject:webView afterDelay:0.3];
}

- (void)webViewIsReadyToDisplay:(UIWebView*)webView {
	// ...
	self.loadingDocument = NO;
	self.failed = NO;

	[[self chapterIndex] setNeedsUpdate];
	
	[self showError:nil animated:YES];
	[self setTutorialShown:NO animated:YES];
	[self setWebViewShown:YES animated:YES];
    
    [[self delegate] articleViewDidFinishLoadingDocument:self];
	
	// Send the final finish method if we're done loading images already
	if(!self.visibleArchive || !self.visibleArchive.loadingImages) {
		self.loading = NO;
		
		// ...
		[self updateProgress];
		
        [[self delegate] articleViewDidFinishLoad:self];
	}
	
	// In case we reset the archive while loading
	if(!self.visibleArchive) {
		return;
	}
	
	if(!self.loading) {
		[self performSelector:@selector(flashChapterIndex)
			withObject:nil
			afterDelay:0.125];
	}
	
//	// DEBUG ONLY
//	[self performSelector:@selector(dumpDocument)
//		withObject:nil
//		afterDelay:5.0];
}

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error {
	self.loading = NO;
	self.loadingDocument = NO;
	self.failed = YES;
    self.DOMLoaded = self.webViewLoaded = YES;

	// Display our error page
	[self showError:error animated:YES];
	[self setWebViewShown:NO animated:YES];
	[self setTutorialShown:NO animated:YES];

	// And tell the delegate what happened
	if([[self delegate] respondsToSelector:@selector(articleView:didFailLoadWithError:)]) {
		[[self delegate] articleView:self didFailLoadWithError:error];
	}
}

#pragma mark -
#pragma mark Private

+ (void)postNetworkActivityWillStartNotification {
	[[NSNotificationCenter defaultCenter]
		postNotificationName:AKArticleViewWillStartNetworkActivityNotification
		object:nil
		userInfo:nil];
}

+ (void)postNetworkActivityDidEndNotification {
	[[NSNotificationCenter defaultCenter]
		postNotificationName:AKArticleViewDidEndNetworkActivityNotification
		object:nil
		userInfo:nil];
}

- (void)initIvars {
	self.autoresizesSubviews = YES;
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		self.backgroundColor = [UIColor whiteColor];
		self.opaque = YES;
	} else {
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
	}
	
	self.clipsToBounds = YES;

	self.loadingDocument = NO;
	self.loading = NO;
	self.failed = NO;
	
	self.progress = 1.0;
	self.webViewProgress = 1.0;
	self.archiveProgress = 1.0;
	
	_searching = NO;

	self.contentInset = UIEdgeInsetsZero;
	self.scrollIndicatorInsets = UIEdgeInsetsZero;
	
	self.documentFontSizes = [NSArray arrayWithObjects:
		@"xx-small",
		@"x-small",
		@"small",
		@"medium",
		@"large", // default
		@"x-large",
		@"xx-large",
		nil];
	self.documentFontSize = [[NSUserDefaults standardUserDefaults]
		objectForKey:@"AKDocumentFontSize"];
		
	if(!self.documentFontSize || ![[self documentFontSize] isKindOfClass:[NSString class]]) {
		self.documentFontSize = @"large";
		
		[[NSUserDefaults standardUserDefaults]
			setObject:[self documentFontSize] forKey:@"AKDocumentFontSize"];
	}

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(applicationWillChangeStatusBarFrame:)
		name:UIApplicationWillChangeStatusBarFrameNotification
		object:nil];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(applicationDidChangeStatusBarFrame:)
		name:UIApplicationDidChangeStatusBarFrameNotification
		object:nil];
}

- (void)initContentView {
	UIView* contentView = [[UIView alloc] initWithFrame:[self bounds]];
	
    contentView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    
	contentView.backgroundColor = self.backgroundColor;
	contentView.opaque = self.opaque;
	
	self.contentView = contentView;
	[self addSubview:contentView];
}

- (void)initWebView {
	UIWebView* webView = [[UIWebView alloc] initWithFrame:[self bounds]];
	
	webView.hidden = YES;
	webView.delegate = self;
	
	webView.scalesPageToFit = NO;
	webView.dataDetectorTypes = UIDataDetectorTypeNone;
	
	webView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;

	webView.opaque = self.opaque;
	webView.backgroundColor = self.backgroundColor;

	if([webView respondsToSelector:@selector(setSuppressesIncrementalRendering:)]) {
		webView.suppressesIncrementalRendering = YES;
	}

	[[self contentView] addSubview:webView];
	self.webView = webView;
	
	AKWebCustomizer* webCustomizer = [[AKWebCustomizer alloc] initWithWebView:webView delegate:self];
	
	[[webCustomizer chapterIndexGestureRecognizer]
		addTarget:self
		action:@selector(didRecognizeChapterIndexGesture:)];

	[[webCustomizer pinchGestureRecognizer]
		addTarget:self
		action:@selector(didRecognizePinchGesture:)];

	self.webCustomizer = webCustomizer;
}

- (void)initStatusViewIfNeeded {
	if(self.statusView) { return; }
	
	[self initPlaceholderScrollViewIfNeeded];
	
	SFPlaceholderView* statusView = [[SFPlaceholderView alloc] initWithFrame:[self bounds]];
	
	statusView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		statusView.backgroundColor =
		statusView.textLabel.backgroundColor =
		statusView.detailTextLabel.backgroundColor =
		statusView.imageView.backgroundColor = 
			[UIColor clearColor];
		
		statusView.textLabel.textColor =
		statusView.detailTextLabel.textColor =
			[UIColor colorWithWhite:0.200 alpha:1.000];
	} else {
		statusView.opaque = self.opaque;
		statusView.backgroundColor = self.backgroundColor;
	}
	
	statusView.hidden = YES;
	
	self.statusView = statusView;
	[[self placeholderScrollView] addSubview:statusView];
	// [[self contentView] insertSubview:statusView aboveSubview:[self webView]];
}

- (void)initPlaceholderScrollViewIfNeeded {
	if(self.placeholderScrollView) { return; }
	
	UIScrollView* placeholderScrollView = [[UIScrollView alloc] initWithFrame:[self bounds]];
	
	placeholderScrollView.backgroundColor = self.backgroundColor;
	
	placeholderScrollView.alwaysBounceVertical = YES;
	placeholderScrollView.alwaysBounceHorizontal = NO;
	
	placeholderScrollView.showsHorizontalScrollIndicator = placeholderScrollView.showsVerticalScrollIndicator = NO;
	
	self.placeholderScrollView = placeholderScrollView;
	[self insertSubview:placeholderScrollView aboveSubview:[self contentView]];
}

- (void)initChapterIndex {
	AKChapterIndexView* chapterIndex = [[AKChapterIndexView alloc] initWithFrame:CGRectZero];
	
	chapterIndex.userInteractionEnabled = NO;
	chapterIndex.articleView = self;
	chapterIndex.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	
	[self insertSubview:chapterIndex aboveSubview:[self webView]];
	
	self.chapterIndex = chapterIndex;
}

- (void)initOrnamentViews {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { return; }
	
	// Top ornament view
	UIView* topOrnamentView = [[UIView alloc] initWithFrame:CGRectZero];
	
    topOrnamentView.clipsToBounds = YES;
	topOrnamentView.userInteractionEnabled = NO;
	topOrnamentView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
	
	self.topOrnamentView = topOrnamentView;
	[self insertSubview:topOrnamentView aboveSubview:[[self webView] superview]];
	
	AKShadowView* topOrnamentShadowView = [[AKShadowView alloc] initWithFrame:CGRectZero];
	
	topOrnamentShadowView.shadowEdge = AKShadowViewEdgeTop;
	
	self.topOrnamentShadowView = topOrnamentShadowView;
	[topOrnamentView addSubview:topOrnamentShadowView];
	
	// Bottom ornament view
	AKArticleOrnamentView* bottomOrnamentView = [[AKArticleOrnamentView alloc] initWithFrame:CGRectZero];
	
	bottomOrnamentView.clipsToBounds = YES;
	bottomOrnamentView.userInteractionEnabled = NO;
	bottomOrnamentView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
	
	self.bottomOrnamentView = bottomOrnamentView;
	[self insertSubview:bottomOrnamentView aboveSubview:topOrnamentView];
	
	AKShadowView* bottomOrnamentShadowView = [[AKShadowView alloc] initWithFrame:CGRectZero];
	
	bottomOrnamentShadowView.shadowEdge = AKShadowViewEdgeTop;
	
	self.bottomOrnamentShadowView = bottomOrnamentShadowView;
	[bottomOrnamentView addSubview:bottomOrnamentShadowView];
	
	UIImage* documentFooterImage = [[UIImage imageNamed:@"documentFooter.png"]
		stretchableImageWithLeftCapWidth:16.0 topCapHeight:0.0];
	UIImageView* documentFooterView = [[UIImageView alloc] initWithImage:documentFooterImage];
	
	self.documentFooterView = documentFooterView;
	[bottomOrnamentView addSubview:documentFooterView];
	
	// Left ornament view
	UIView* leftOrnamentView = [[UIView alloc] initWithFrame:CGRectZero];
	
	leftOrnamentView.userInteractionEnabled = NO;
	leftOrnamentView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
	
	self.leftOrnamentView = leftOrnamentView;
	[self insertSubview:leftOrnamentView aboveSubview:topOrnamentView];
	
	AKShadowView* leftOrnamentShadowView = [[AKShadowView alloc] initWithFrame:CGRectZero];
	
	leftOrnamentShadowView.shadowEdge = AKShadowViewEdgeLeft;
	
	self.leftOrnamentShadowView = leftOrnamentShadowView;
	[leftOrnamentView addSubview:leftOrnamentShadowView];
	
	// Right ornament view
	UIView* rightOrnamentView = [[UIView alloc] initWithFrame:CGRectZero];
	
	rightOrnamentView.userInteractionEnabled = NO;
	rightOrnamentView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
	
	self.rightOrnamentView = rightOrnamentView;
	[self insertSubview:rightOrnamentView aboveSubview:topOrnamentView];
	
	AKShadowView* rightOrnamentShadowView = [[AKShadowView alloc] initWithFrame:CGRectZero];
	
	rightOrnamentShadowView.shadowEdge = AKShadowViewEdgeRight;
	
	self.rightOrnamentShadowView = rightOrnamentShadowView;
	[rightOrnamentView addSubview:rightOrnamentShadowView];

#ifdef CONFIGURATION_ARTICLEKIT
    // NavigationBar ornament view
	AKShadowView* navigationBarShadowView = [[AKShadowView alloc] initWithFrame:CGRectZero];
	
	navigationBarShadowView.shadowEdge = AKShadowViewEdgeBottom;
	
	self.navigationBarShadowView = navigationBarShadowView;
	[topOrnamentView addSubview:navigationBarShadowView];
#endif
}


- (void)initLockOrientationView {
#ifndef CONFIGURATION_ARTICLEKIT
	
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { return; }
	
	AKLockOrientationView* lockOrientationView = [[AKLockOrientationView alloc] initWithFrame:CGRectZero];
	
	lockOrientationView.articleView = self;
	[self insertSubview:lockOrientationView aboveSubview:[self topOrnamentView]];
	
	self.lockOrientationView = lockOrientationView;
    
#endif
}

- (void)initKeyValueObservers {
}

- (BOOL)webView:(UIWebView*)webView shouldHandleArticleURL:(NSURL*)URL options:(NSDictionary*)options {
	// Ask the delegate if we should load this article
	if([[self delegate] respondsToSelector:@selector(articleView:shouldStartLoadArticle:options:)]) {
		if(![[self delegate] articleView:self shouldStartLoadArticle:URL options:options]) {
			return NO;
		}
	}
		
	// Go for it.
	UIViewController* viewController = [self parentViewController];
	UIViewController* modalViewController = [viewController presentedViewController];
	
	BOOL animated =
		![self visibleTabularDataViewController] &&
		!modalViewController;

	[self loadArticle:URL animated:animated];

	return NO;
}

- (BOOL)webCustomizer:(AKWebCustomizer*)webCustomizer shouldHandleEventWithURL:(NSURL*)URL {
	NSString* action = [URL host];
	
//	NSLog(@"%@", [URL absoluteString]);
	
    if([action isEqualToString:@"documentDidLoad"]) {
    	if(self.webCustomizer == webCustomizer) {
    		self.DOMLoaded = YES;
        	[self finishWebViewLoadIfNeeded:[[self webCustomizer] webView]];
        }
    } else if([action isEqualToString:@"thumbnailDidLoad"]) {
		[[self chapterIndex] setNeedsUpdate];
	} else if([action isEqualToString:@"documentDidHighlightSearchResult"]) {
		if([[self delegate] respondsToSelector:@selector(articleView:didHighlightSearchResultAtIndex:numberOfResults:)]) {
			NSDictionary* parameters = [URL parameters];
			
			[[self delegate]
				articleView:self
				didHighlightSearchResultAtIndex:[[parameters objectForKey:@"index"] integerValue]
				numberOfResults:[[parameters objectForKey:@"resultCount"] integerValue]];
		}
	} else if([action isEqualToString:@"presentItem"]) {
    	NSString* JSONString = [[URL parameters] objectForKey:@"metadata"];
        
        NSDictionary* metadata = [NSJSONSerialization
        	JSONObjectWithData:[JSONString dataUsingEncoding:NSUTF8StringEncoding]
        	options:NSJSONReadingAllowFragments
            error:nil];
            
        if((id)metadata == [NSNull null]) { return NO; }
	
		NSString* targetURLString = [metadata objectForKey:@"URL"];
		NSURL* targetURL = targetURLString ?
			[NSURL URLWithString:targetURLString] :
			nil;

		[self webCustomizer:webCustomizer shouldPresentURL:targetURL options:metadata];
    }
	
	return NO;
}

- (void)webCustomizer:(AKWebCustomizer*)webCustomizer shouldPresentImageForURL:(NSURL*)URL options:(NSDictionary*)options {
	NSMutableDictionary* imageOptions = [NSMutableDictionary dictionaryWithDictionary:options];

	UIView* containerView = self;
	
	CGRect previewRect = CGRectFromString([options objectForKey:@"rect"]);
	previewRect = [[webCustomizer documentView] convertRect:previewRect toView:nil];

	[imageOptions
		setObject:[NSValue valueWithCGRect:previewRect]
		forKey:@"rect"];
		
	CGRect visiblePreviewRect = previewRect;
	
	CGRect visibleRect = containerView.frame;
	
	if(webCustomizer.webView == self.webView) {
		visibleRect.size.height -= self.scrollIndicatorInsets.bottom;
	} else {
		// TODO Hard coding is not that nice
		visibleRect.origin.y += 44.0;
		visibleRect.size.height -= 44.0;
		
		if(CGRectGetMinY(previewRect) < 0.0) {
			CGFloat statusBarHeight = CGRectGetHeight([[UIApplication sharedApplication] statusBarFrame]);
			
			visibleRect.origin.y += statusBarHeight;
			visibleRect.size.height -= statusBarHeight;
		}
	}
	
	visibleRect = [containerView convertRect:visibleRect toView:nil];
	
	visiblePreviewRect = CGRectIntersection(visibleRect, visiblePreviewRect);

	[imageOptions
		setObject:[NSValue valueWithCGRect:visiblePreviewRect]
		forKey:@"visibleRect"];
		
	CGRect boundingPreviewRect = CGRectFromString([options objectForKey:@"boundingRect"]);
	
	boundingPreviewRect = [[webCustomizer documentView] convertRect:boundingPreviewRect toView:nil];
	
	[imageOptions
		setObject:[NSValue valueWithCGRect:boundingPreviewRect]
		forKey:@"boundingRect"];

	NSString* imageID = [options objectForKey:@"id"];
	NSDictionary* imageInfo = [[self archive] imageInfoForID:imageID];

	NSURL* previewURL = [NSURL URLWithString:imageID
		relativeToURL:[[self archive] archiveURL]];
	[imageOptions setObject:previewURL forKey:@"previewURL"];

	WikipediaAPI* wikipediaAPI = [[WikipediaAPI alloc] init];

	NSURL* wikipediaImageURL = [NSURL URLWithString:[imageInfo objectForKey:@"image"]];
	NSURL* sourceImageURL = [wikipediaAPI
		filePathForResourceURL:wikipediaImageURL
		options:nil];

	UIScreen* screen = self.window.screen;
	
	if(!screen) {
		screen = [UIScreen mainScreen];
	}
	
	CGSize screenSize = screen.bounds.size;
	CGFloat maximumImageSize = MIN(screenSize.width, screenSize.height) * screen.scale * 2.0;

	NSURL* thumbnailURL = [NSURL URLWithString:
		[imageInfo objectForKey:@"thumbnail"]];
	NSURL* imageURL = [wikipediaAPI
		thumbnailURLWithWidth:maximumImageSize
		forURL:thumbnailURL];

	if(!imageURL) {
		imageURL = sourceImageURL;
	}

	[imageOptions setObject:[sourceImageURL wikipediaURLByFixingScheme] forKey:@"alternateURL"];
	[imageOptions setObject:[imageURL wikipediaURLByFixingScheme] forKey:@"URL"];

	NSURL* localImageURL = [NSURL URLWithString:
		[NSString stringWithFormat:@"%@Large", imageID]
		relativeToURL:[[self archive] archiveURL]];
	[imageOptions setObject:localImageURL forKey:@"localURL"];

	[imageOptions setObject:[self archive] forKey:@"archive"];

	[imageOptions setObject:[self articleTitle] forKey:@"title"];

	[self showLightboxWithOptions:imageOptions];
}

- (void)webCustomizer:(AKWebCustomizer*)webCustomizer shouldPresentTableForURL:(NSURL*)URL options:(NSDictionary*)options {
	if(!self.visibleArchive) { return; }
	
	UIViewController* parentViewController = [self parentViewController];
		
	if(parentViewController) {
		AKTabularDataViewController* viewController = [[AKTabularDataViewController alloc] initWithNibName:nil bundle:nil];
		
		NSString* tableID = [options objectForKey:@"id"];
		NSDictionary* tableInfo = [[self visibleArchive] tableInfoForID:tableID];
		
		NSMutableDictionary* tableOptions = [NSMutableDictionary dictionaryWithDictionary:tableInfo];
		
		if([[tableInfo objectForKey:@"caption"] length] <= 0) {
			[tableOptions setObject:[self articleTitle] forKey:@"caption"];
		}
		
		[tableOptions setObject:self forKey:@"articleView"];
		[tableOptions setObject:[self visibleArchive] forKey:@"archive"];
		
		viewController.options = tableOptions;

		viewController.delegate = self;
		
		UINavigationController* navigationController = [[SFNavigationController alloc] initWithRootViewController:viewController];
		[parentViewController presentViewController:navigationController animated:YES completion:nil];
	}
}

- (UIScrollView*)scrollView {
	return [[self webCustomizer] scrollView];
}

- (void)updateProgress {
	float newProgress = 0.0;

	if(self.loading) {
		newProgress =
			self.archiveProgress * 0.75 +
			self.webViewProgress * 0.25;
	} else {
		self.archiveProgress = 1.0;
		self.webViewProgress = 1.0;
		newProgress = 1.0;
	}
	
	newProgress = MIN(newProgress, 1.0);
	newProgress = MAX(newProgress, 0.0);
	
	if(newProgress != self.progress) {
		self.progress = newProgress;
		
		if([[self delegate] respondsToSelector:@selector(articleView:didProgressLoad:)]) {
			[[self delegate] articleView:self didProgressLoad:[self progress]];
		}
	}
}

- (void)resetProgress {
	self.archiveProgress = 0.0;
	self.webViewProgress = 0.5;
	self.progress = 0.0;
}

- (void)setProgressIndicatorShown:(BOOL)progressIndicatorShown animated:(BOOL)animated {
	// TODO
}

- (void)showError:(NSError*)error animated:(BOOL)animated {
	self.visibleError = error;
	
	if(error) {
		[self setProgressIndicatorShown:NO animated:NO];
		[self setWebViewShown:NO animated:animated];
	}
	
	BOOL userCancelled =
		error &&
		error.domain == NSURLErrorDomain &&
		error.code == NSURLErrorCancelled;
		
//	BOOL unsupportedURL =
//		error &&
//		error.domain == NSURLErrorDomain &&
//		error.code == NSURLErrorFileDoesNotExist;
	
	if(error && !userCancelled) {
		NSString* text = @"";
		NSString* detailText = @"";
		
		BOOL networkError = NO;

		if([[error domain] isEqualToString:NSURLErrorDomain]) {
			if([error code] == NSURLErrorNotConnectedToInternet) {
				text = NSLocalizedString(@"AKNoNetworkErrorText", @"");
				detailText = NSLocalizedString(@"AKNoNetworkErrorHint", @"");
				networkError = YES;
			}
			
			if([error code] == NSURLErrorFileDoesNotExist || [error code] == NSURLErrorResourceUnavailable) {
				text = NSLocalizedString(@"AKNotFoundErrorText", @"");
				
				NSString* title = [[[[self articleURL] path] lastPathComponent] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
				detailText = [NSString stringWithFormat:NSLocalizedString(@"AKNotFoundErrorHint", @""), title];
			}
		}

		if(text.length == 0) {
			text = NSLocalizedString(@"AKGenericErrorText", @"");
			detailText = NSLocalizedString(@"AKGenericErrorHint", @"");
		}
		
		BOOL animationsEnabled = [UIView areAnimationsEnabled];
		
		[UIView setAnimationsEnabled:NO]; {
		
			[self initStatusViewIfNeeded];
			
			self.statusView.textLabel.text = text;
			self.statusView.detailTextLabel.text = detailText;
			
			UIImage* image = nil;
			
			if(networkError) {
				image = [UIImage imageNamed:@"networkError.png"];
			} else {
				image = [UIImage imageNamed:@"error.png"];
			}
		
			self.statusView.imageView.image = image;
		
			self.statusView.hidden = NO;
			
			[[self statusView] layoutIfNeeded];
			
		} [UIView setAnimationsEnabled:animationsEnabled];
	} else {
		self.statusView.hidden = YES;
	}
}

- (void)setTutorialShown:(BOOL)tutorialShown animated:(BOOL)animated {
	[self setTutorialShown:tutorialShown animated:animated bounce:NO];
}

- (void)setTutorialShown:(BOOL)tutorialShown animated:(BOOL)animated bounce:(BOOL)bounce {
	BOOL animationsEnabled = [UIView areAnimationsEnabled];
	
	[UIView setAnimationsEnabled:NO]; {
	
		if(tutorialShown && !self.tutorialView) {
			UIImage* image = [UIImage imageNamed:@"tapToSearch.png"];
			UIImageView* tutorialView = [[UIImageView alloc] initWithImage:image];
			self.tutorialView = tutorialView;
			
			[self initPlaceholderScrollViewIfNeeded];
			[[self placeholderScrollView] addSubview:tutorialView];
			
			[self setWebViewShown:NO animated:animated];
		} else if(!tutorialShown && self.tutorialView) {
			[[self tutorialView] removeFromSuperview];
			self.tutorialView = nil;
		}
		
		[self setNeedsLayout];
	
	} [UIView setAnimationsEnabled:animationsEnabled];
}

- (void)setWebViewShown:(BOOL)webViewShown animated:(BOOL)animated {
	self.webView.hidden = !webViewShown;
}

- (void)showThumbnail:(NSDictionary*)thumbnail {
	// Update our webview first
	NSString* javascript = [self showThumbnailJavascript:thumbnail];
	[[self webView] stringByEvaluatingJavaScriptFromString:javascript];
	
	// Is the tabular view controller visible?
	if(self.visibleTabularDataViewController) {
		UIWebView* webView = self.visibleTabularDataViewController.webView;
		[webView stringByEvaluatingJavaScriptFromString:javascript];
	}
	
	// Mark our chapter index as updated
	[[self chapterIndex] setNeedsUpdate];
}

- (NSString*)showThumbnailJavascript:(NSDictionary*)thumbnail {
	NSString* thumbnailID = [thumbnail objectForKey:@"id"];
	NSString* javascript = nil;
	
	if([[thumbnail objectForKey:@"hadError"] boolValue]) {
		javascript = [NSString stringWithFormat:@"addClass(document.getElementById('%@'), 'error');",
			thumbnailID];
    } else {
    	NSURL* thumbnailURL = [NSURL URLWithString:thumbnailID relativeToURL:[[self visibleArchive] archiveURL]];
        
        NSString* thumbnailURLString = [thumbnailURL absoluteString];
        thumbnailURLString = [thumbnailURLString stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
        
		javascript = [NSString stringWithFormat:@"articleKitDocumentController.setImagePreview('%@', '%@', '%@');",
			thumbnailID,
            thumbnailURLString,
			[thumbnail objectForKey:@"markup"]];
	}

	return javascript;
}

- (void)showLightboxWithOptions:(NSDictionary*)options {
	AKLightboxViewController* viewController = [AKLightboxViewController viewController];
	
	viewController.delegate = self;
	
	UIViewController* parentViewController = [self visibleTabularDataViewController] ?
		[self visibleTabularDataViewController] :
		[self parentViewController];
	[viewController presentPreviewInViewController:parentViewController withOptions:options animated:YES];
}

- (UIViewController*)parentViewController {
	UIViewController* parentViewController = nil;

	if([[self delegate] respondsToSelector:@selector(articleView:needsParentViewController:)]) {
		[[self delegate] articleView:self needsParentViewController:&parentViewController];
	}
	
	return parentViewController;
}

- (void)increaseFontSize {
	NSInteger fontSizeIndex = [[self documentFontSizes]
		indexOfObject:[self documentFontSize]];
		
	if(fontSizeIndex != NSNotFound && fontSizeIndex + 1 < self.documentFontSizes.count) {
		[[self webView] stringByEvaluatingJavaScriptFromString:
			[NSString stringWithFormat:@"removeClass(document.body, '%@');", [self documentFontSize]]];
		
		NSString* newDocumentFontSize = [[self documentFontSizes]
			objectAtIndex:fontSizeIndex + 1];
		
		[[self webView] stringByEvaluatingJavaScriptFromString:
			[NSString stringWithFormat:@"addClass(document.body, '%@');", newDocumentFontSize]];
		self.documentFontSize = newDocumentFontSize;
		
		[[NSUserDefaults standardUserDefaults]
			setObject:newDocumentFontSize forKey:@"AKDocumentFontSize"];
		
		[[self chapterIndex] setNeedsUpdate];
		
		// ...
		[[SFBezelController sharedBezelController]
			presentBezelWithText:NSLocalizedString(newDocumentFontSize, @"")
			image:[UIImage imageNamed:@"textSizeBezelImage.png"]];
	}
}

- (void)decreaseFontSize {
	NSInteger fontSizeIndex = [[self documentFontSizes]
		indexOfObject:[self documentFontSize]];
		
	if(fontSizeIndex != NSNotFound && fontSizeIndex > 0) {
		[[self webView] stringByEvaluatingJavaScriptFromString:
			[NSString stringWithFormat:@"removeClass(document.body, '%@');", [self documentFontSize]]];
		
		NSString* newDocumentFontSize = [[self documentFontSizes]
			objectAtIndex:fontSizeIndex - 1];
		
		[[self webView] stringByEvaluatingJavaScriptFromString:
			[NSString stringWithFormat:@"addClass(document.body, '%@');", newDocumentFontSize]];
		self.documentFontSize = newDocumentFontSize;
		
		[[NSUserDefaults standardUserDefaults]
			setObject:newDocumentFontSize forKey:@"AKDocumentFontSize"];
		
		[[self chapterIndex] setNeedsUpdate];
		
		// ...
		[[SFBezelController sharedBezelController]
			presentBezelWithText:NSLocalizedString(newDocumentFontSize, @"")
			image:[UIImage imageNamed:@"textSizeBezelImage.png"]];
	}
}

- (void)didRecognizeChapterIndexGesture:(UIGestureRecognizer*)gestureRecognizer {
	if(self.webView.hidden) { return; }
	
	if(gestureRecognizer.state == UIGestureRecognizerStateBegan) {
		[[self chapterIndex] setActive:YES animated:YES];
		self.webView.userInteractionEnabled = NO;
	}
	
	if(gestureRecognizer.state == UIGestureRecognizerStateEnded ||
	   gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
		[[self chapterIndex] setActive:NO animated:YES];
		self.webView.userInteractionEnabled = YES;
	}
	
	if(gestureRecognizer.state == UIGestureRecognizerStateChanged) {
		if(self.chapterIndex.active && [gestureRecognizer numberOfTouches] > 0) {
			CGPoint point = [gestureRecognizer locationOfTouch:0 inView:[self chapterIndex]];

			[[self chapterIndex] updateChapteredArticleLocationForTouchLocation:point];
		}
	}
}

- (void)didRecognizePinchGesture:(UIPinchGestureRecognizer*)gestureRecognizer {
	if(self.webView.hidden) { return; }
	
	if(gestureRecognizer.state == UIGestureRecognizerStateEnded) {
		if(gestureRecognizer.scale <= 0.75) {
			[self decreaseFontSize];
		} else if(gestureRecognizer.scale >= 1.5) {
			[self increaseFontSize];
		}
	}
}

- (AKLanguagePicker*)languagePicker {
	AKLanguagePicker* picker = [AKLanguagePicker viewController];
	
	picker.archive = self.visibleArchive;
	picker.articleView = self;
	
//	picker.modalTransitionStyle = UIModalTransitionStylePartialCurl;
//	picker.modalPresentationStyle = UIModalPresentationFormSheet;

	return picker;
}

- (void)applicationWillChangeStatusBarFrame:(NSNotification*)notification {
}

- (void)applicationDidChangeStatusBarFrame:(NSNotification*)notification {
}

- (void)resetWebView {
	NSString* javascript = @"document.body.outerHTML = '<body></body>'";
	[[self webView] stringByEvaluatingJavaScriptFromString:javascript];
}

@end
