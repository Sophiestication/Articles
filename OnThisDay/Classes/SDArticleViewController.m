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

#import "SDArticleViewController.h"
#import "SDArticleViewController+Private.h"

#import "SDBrowserViewController.h"

#import "NSArray+Additions.h"
#import "NSURL+Additions.h"
#import "SFToolbar.h"
#import "UIActionSheet+Additions.h"
#import "UILabel+Graphite.h"
#import "UIButton+Graphite.h"

#import "AKShadowView.h"

#import "AKLanguagePicker.h"

#import "AKArticleView+Printing.h"
#import "AKArticleView+Private.h"

#import <MobileCoreServices/MobileCoreServices.h>

@implementation SDArticleViewController

#pragma mark - Construction & Destruction

+ (id)viewController {
	return [[self alloc] initWithNibName:@"SDArticleViewController" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		self.history = [NSMutableArray array];
		self.selectedHistoryItemIndex = 0;
		self.shouldDisplayBanner = NO;
	}

    return self;
}

#pragma mark - SDArticleViewController

- (IBAction)done:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)navigateBack:(id)sender {
	if(![self canGoBack]) {
		return;
	}
	
	NSDictionary* historyItem = [[self history] objectAtIndex:[self selectedHistoryItemIndex] - 1];
	
//	self.articleView.preferredContentOffset = [[historyItem objectForKey:@"offset"] CGPointValue];
	
	self.selectedHistoryItemIndex -= 1;
	
	NSURL* articleURL = [historyItem objectForKey:@"URL"];
	
//	self.articleView.webViewWentBack = YES;
	[[self articleView] loadArticle:articleURL animated:YES];
}

- (IBAction)navigateForward:(id)sender {
	if(![self canGoForward]) {
		return;
	}
	
	NSDictionary* historyItem = [[self history] objectAtIndex:[self selectedHistoryItemIndex] + 1];
	
//	self.articleView.preferredContentOffset = [[historyItem objectForKey:@"offset"] CGPointValue];
	
	self.selectedHistoryItemIndex += 1;
	
	NSURL* articleURL = [historyItem objectForKey:@"URL"];
	
//	self.articleView.webViewWentBack = NO;
	[[self articleView] loadArticle:articleURL animated:YES];
}

- (IBAction)reload:(id)sender {
	[[self articleView] reload];
}

- (IBAction)stop:(id)sender {
	[[self articleView] stopLoading];
}

- (IBAction)openSafari:(id)sender {
	NSURL* URL = self.articleView.articleURL;
	[[UIApplication sharedApplication] openURL:URL];
}

- (IBAction)openArticles:(id)sender {
	NSURL* URL = self.articleView.articleURL;
	
	if(![URL isArticlesURL]) {
		NSString* articlesURLString = [NSString stringWithFormat:@"x-articles:%@", [URL resourceSpecifier]];
		URL = [NSURL URLWithString:articlesURLString];
	}
	
	[[UIApplication sharedApplication] openURL:URL];
}

- (IBAction)showActionSheet:(id)sender {
	UIActionSheet* sheet = [[UIActionSheet alloc]
		initWithTitle:nil
		delegate:nil
		cancelButtonTitle:nil
		destructiveButtonTitle:nil
		otherButtonTitles:nil];
	
	BOOL articlesIsInstalled =  [[UIApplication sharedApplication]
		canOpenURL:[NSURL URLWithString:@"x-articles://available"]];
	
	if(articlesIsInstalled) {
		[sheet addButtonWithTitle:NSLocalizedString(@"OPENARTICLES_ACTION_TITLE", @"") block:^{
			[self openArticles:sender];
		}];
	} else {
		[sheet addButtonWithTitle:NSLocalizedString(@"OPENSAFARI_ACTION_TITLE", @"") block:^{
			[self openSafari:sender];
		}];
	}
	
	[sheet addButtonWithTitle:NSLocalizedString(@"SHEETBUTTON_CLIPBOARD_COPY", @"") block:^{
		NSURL* articleURL = [[self articleView] articleURL];
	
		NSArray* pasteboardItems = [NSArray arrayWithObjects:
			[NSDictionary dictionaryWithObject:articleURL forKey:(id)kUTTypeURL],
			[NSDictionary dictionaryWithObject:[[articleURL absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:(id)kUTTypeUTF8PlainText],
			nil];
		[[UIPasteboard generalPasteboard] setItems:pasteboardItems];
	}];
	
	if([AKArticleView isPrintingAvailable]) {
		[sheet addButtonWithTitle:NSLocalizedString(@"SHEETBUTTON_PRINT", @"") block:^{
			[[self articleView] print:[self actionsButtonItem]];
		}];
	}
	
	[sheet setCancelButtonWithTitle:NSLocalizedString(@"SHEETBUTTON_CANCEL", @"") block:^{
	}];
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		[sheet showInView:[self view]];
	} else {
		[sheet showFromBarButtonItem:[self actionsButtonItem] animated:YES];
	}
}

- (IBAction)showTableOfContents:(id)sender {
	AKLanguagePicker* picker = [[self articleView] languagePicker];
	
	picker.pickerMode = AKLanguagePickerModeTOC;
	picker.allowsModeSelection = NO;
	
	UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:picker];
	[self presentViewController:navigationController animated:YES completion:nil];
}

- (IBAction)openArticlesWebsite:(id)sender {
	NSURL* URL = [NSURL URLWithString:@"http://itunes.apple.com/app/id317065689?mt=8"];
	[[UIApplication sharedApplication] openURL:URL];
}

- (void)loadArticle:(NSURL*)articleURL {
	[self navigateToArticle:articleURL];
	[[self articleView] loadArticle:articleURL animated:NO];
}

#pragma mark - UIView

- (void)viewDidLoad {
    [super viewDidLoad];
	
	// ...
	self.articleView.delegate = self;
	
	// ...
	UILabel* titleLabel = [UILabel graphiteNavigationBarLabelWithText:@"Articles"];
	titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
	self.navigationItem.titleView = titleLabel;

	// ...
	UIButton* doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[doneButton addTarget:self action:@selector(done:) forControlEvents:UIControlEventTouchUpInside];
	[doneButton setGraphiteStyle:UIBarButtonItemStyleDone miniBar:NO systemItem:UIBarButtonSystemItemDone];
	
	self.doneButtonItem = [[UIBarButtonItem alloc] initWithCustomView:doneButton];
	
	self.navigationItem.rightBarButtonItem = self.doneButtonItem;
	
	// ...
	UIButton* navigateBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[navigateBackButton addTarget:self action:@selector(navigateBack:) forControlEvents:UIControlEventTouchUpInside];
	[navigateBackButton setImage:[UIImage imageNamed:@"navigateBack.png"] forState:UIControlStateNormal];
	[navigateBackButton setGraphiteStyle:UIBarButtonItemStylePlain miniBar:NO];
	
	self.navigateBackButtonItem = [[UIBarButtonItem alloc] initWithCustomView:navigateBackButton];
	
	// ...
	UIButton* navigateForwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[navigateForwardButton addTarget:self action:@selector(navigateForward:) forControlEvents:UIControlEventTouchUpInside];
	[navigateForwardButton setImage:[UIImage imageNamed:@"navigateForward.png"] forState:UIControlStateNormal];
	[navigateForwardButton setGraphiteStyle:UIBarButtonItemStylePlain miniBar:NO];
	
	self.navigateForwardButtonItem = [[UIBarButtonItem alloc] initWithCustomView:navigateForwardButton];
	
	// ...
	UIButton* reloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[reloadButton addTarget:self action:@selector(reload:) forControlEvents:UIControlEventTouchUpInside];
	[reloadButton setImage:[UIImage imageNamed:@"reload.png"] forState:UIControlStateNormal];
	[reloadButton setGraphiteStyle:UIBarButtonItemStylePlain miniBar:NO];
	
	self.reloadButtonItem = [[UIBarButtonItem alloc] initWithCustomView:reloadButton];
	
	// ...
	UIButton* stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[stopButton addTarget:self action:@selector(stop:) forControlEvents:UIControlEventTouchUpInside];
	[stopButton setImage:[UIImage imageNamed:@"stop.png"] forState:UIControlStateNormal];
	[stopButton setGraphiteStyle:UIBarButtonItemStylePlain miniBar:NO];
	
	self.stopButtonItem = [[UIBarButtonItem alloc] initWithCustomView:stopButton];
	
	// ...
	UIButton* actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[actionButton addTarget:self action:@selector(showActionSheet:) forControlEvents:UIControlEventTouchUpInside];
	[actionButton setImage:[UIImage imageNamed:@"addBookmark.png"] forState:UIControlStateNormal];
	[actionButton setGraphiteStyle:UIBarButtonItemStylePlain miniBar:NO];
	
	self.actionsButtonItem = [[UIBarButtonItem alloc] initWithCustomView:actionButton];
	
	// ...
	UIButton* contentsButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[contentsButton addTarget:self action:@selector(showTableOfContents:) forControlEvents:UIControlEventTouchUpInside];
	[contentsButton setImage:[UIImage imageNamed:@"TOCButtonItem.png"] forState:UIControlStateNormal];
	[contentsButton setGraphiteStyle:UIBarButtonItemStylePlain miniBar:NO];
	
	self.contentsButtonItem = [[UIBarButtonItem alloc] initWithCustomView:contentsButton];
	
	// ...
	self.toolbar.items = [NSArray arrayWithObjects:
		self.navigateBackButtonItem,
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL],
		self.navigateForwardButtonItem,
//		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL],
//		self.reloadButtonItem,
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL],
		self.contentsButtonItem,
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL],
		self.actionsButtonItem,
		nil];
	
	// ...
	self.navigationBar.items = [NSArray arrayWithObject:[self navigationItem]];


/*	
	// ...
	BOOL articlesIsInstalled =  [[UIApplication sharedApplication]
		canOpenURL:[NSURL URLWithString:@"x-articles://available"]];
	
	if(!articlesIsInstalled && NSClassFromString(@"ADBannerView")) {
		ADBannerView* bannerView = [[[ADBannerView alloc] initWithFrame:CGRectZero] autorelease];
		
		// Are we on iOS 4.0 or 4.2?
		bannerView.requiredContentSizeIdentifiers = [NSSet setWithObjects:
			[UIPrintInteractionController class] ? ADBannerContentSizeIdentifierPortrait : ADBannerContentSizeIdentifier320x50,
			nil];
		bannerView.delegate = self;
		
		bannerView.backgroundColor = [UIColor whiteColor];
		
		self.bannerView = bannerView;
		[[self view] insertSubview:bannerView aboveSubview:[self articleView]];
		
		self.shouldDisplayBanner = bannerView.bannerLoaded;
		[self layoutBannerViewAnimated:NO];
	} else {
		self.bannerView = nil;
	}
*/

	if([[self toolbar] respondsToSelector:@selector(setShadowImage:forToolbarPosition:)]) {
		[[self toolbar] setShadowImage:
			[UIImage imageNamed:@"whitespace"]
			forToolbarPosition:UIToolbarPositionBottom];
	}

	// ...
	[self updateTitle];
	[self updateToolbarItems];
	[self updateContentInsets];
}

- (void)viewDidUnload {
	[super viewDidUnload];

	self.articleView = nil;
	
	self.navigationBar = nil;
	self.titleLabel = nil;

	self.toolbar = nil;
	self.doneButtonItem = nil;
	self.navigateBackButtonItem = nil;
	self.navigateForwardButtonItem = nil;
	self.reloadButtonItem = nil;
	self.stopButtonItem = nil;
	self.actionsButtonItem = nil;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView {
}

- (void)scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(BOOL)decelerate {
}

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
	[self updateContentInsets];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView*)scrollView {
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView*)scrollView {
	return YES;
}

- (void)scrollViewDidScrollToTop:(UIScrollView*)scrollView {
}

#pragma mark - AKArticleViewDelegate

- (void)articleViewDidStartLoad:(AKArticleView*)articleView {
//	[self layoutSubviewsAnimated:YES];

	[self updateTitle];
	[self updateToolbarItems];
    
    [[[self activityIndicatorView] superview] bringSubviewToFront:[self activityIndicatorView]];
    [[self activityIndicatorView] startAnimating];
    
    id animations = ^() {
    	articleView.hidden = YES;
        self.activityIndicatorView.alpha = 1.0;
    };
    [UIView
    	transitionWithView:articleView
    	duration:0.3
        options:UIViewAnimationOptionTransitionCrossDissolve|UIViewAnimationOptionShowHideTransitionViews|UIViewAnimationOptionBeginFromCurrentState
        animations:animations
        completion:nil];
}

- (BOOL)articleView:(AKArticleView*)articleView shouldStartLoadArticle:(NSURL*)articleURL options:(NSDictionary*)options {
	[self navigateToArticle:articleURL];
	
	return YES;
}

- (void)articleViewDidFinishLoadingDocument:(AKArticleView*)articleView {
    id animations = ^() {
    	//[[self activityIndicatorView] stopAnimating];
    	self.activityIndicatorView.alpha = 0.0;
        articleView.hidden = NO;
    };
    
    id completion = ^(BOOL finished) {
    	if(!finished) { return; }
        
        [self updateTitle];
        [self updateToolbarItems];
    };
    
    [UIView
    	transitionWithView:articleView
    	duration:0.5
        options:UIViewAnimationOptionTransitionCrossDissolve|UIViewAnimationOptionShowHideTransitionViews|UIViewAnimationOptionBeginFromCurrentState
        animations:animations
        completion:completion];
}

- (void)articleViewDidFinishLoad:(AKArticleView*)articleView {
	[self updateToolbarItems];
//	[self layoutSubviewsAnimated:YES];
}

- (void)articleView:(AKArticleView*)articleView shouldLoadExternalResource:(NSURL*)resourceURL {
	SDBrowserViewController* viewController = [SDBrowserViewController viewController];
		
	NSURLRequest* newRequest = [NSURLRequest
		requestWithURL:resourceURL
		cachePolicy:NSURLRequestReturnCacheDataElseLoad
		timeoutInterval:60.0];
	[[viewController webView] loadRequest:newRequest];
			
	UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
	
	navigationController.toolbarHidden = NO;
	
	UIViewController* parentViewController = self.presentedViewController;
	if(!parentViewController) { parentViewController = self; }
	
	[parentViewController presentViewController:navigationController animated:YES completion:nil];
}

- (void)articleView:(AKArticleView*)articleView needsParentViewController:(UIViewController**)viewController {
	*viewController = self;
}

#pragma mark - Private

- (void)navigateToArticle:(NSURL*)articleURL {
	NSMutableArray* history = self.history;
	
	NSMutableDictionary* selectedHistoryItem = history.count > self.selectedHistoryItemIndex ?
		[history objectAtIndex:[self selectedHistoryItemIndex]] :
		nil;
		
	if(selectedHistoryItem && [[selectedHistoryItem objectForKey:@"URL"] isEqual:articleURL]) {
		return;
	}
	
	NSValue* preferredContentOffset = [NSValue valueWithCGPoint:[[self articleView] contentOffset]];
	[selectedHistoryItem setObject:preferredContentOffset forKey:@"offset"];
	
	if(selectedHistoryItem != [history lastObject]) {
		[history removeObjectsInRange:NSMakeRange([self selectedHistoryItemIndex] + 1, history.count - self.selectedHistoryItemIndex - 1)];
	}
	
	NSMutableDictionary* historyItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		articleURL, @"URL",
		nil];
	[history addObject:historyItem];
		
	self.selectedHistoryItemIndex = history.count - 1;
	
	[self updateToolbarItems];
}

- (BOOL)canGoBack {
	return self.selectedHistoryItemIndex > 0;
}

- (BOOL)canGoForward {
	return self.selectedHistoryItemIndex < self.history.count - 1;
}

- (void)updateTitle {
	UILabel* titleLabel = (id)self.navigationItem.titleView;
	
	titleLabel.text = self.articleView.loadingDocument ?
		NSLocalizedString(@"LOADING_ARTICLE", @"") :
		self.articleView.articleTitle;
	
	[titleLabel sizeToFit];
}

- (void)updateToolbarItems {
	UIBarButtonItem* newItem = self.articleView.loading ?
		self.stopButtonItem :
		self.reloadButtonItem;
	UIBarButtonItem* itemToReplace = newItem == self.stopButtonItem ?
		self.reloadButtonItem :
		self.stopButtonItem;
		
	NSArray* toolbarItems = self.toolbar.items;
	toolbarItems = [toolbarItems arrayByReplacingObject:itemToReplace withObject:newItem];
	
	self.toolbar.items = toolbarItems;
	
	self.navigateBackButtonItem.enabled = [self canGoBack];
	self.navigateForwardButtonItem.enabled = [self canGoForward];
	
	newItem.enabled = self.articleView.articleURL != nil;
	
    self.contentsButtonItem.enabled = self.articleView.articleURL != nil && !self.articleView.loadingDocument;
    self.actionsButtonItem.enabled = self.articleView.articleURL != nil && !self.articleView.loadingDocument;
	
	[(UIButton*)[[self navigateBackButtonItem] customView] setAlpha:1.0];
	[(UIButton*)[[self navigateForwardButtonItem] customView] setAlpha:1.0];
	[(UIButton*)[newItem customView] setAlpha:1.0];
    [(UIButton*)[[self contentsButtonItem] customView] setAlpha:1.0];
	[(UIButton*)[[self actionsButtonItem] customView] setAlpha:1.0];
}

- (void)updateContentInsets {
	CGPoint contentOffset = self.articleView.contentOffset;
	
	self.articleView.scrollIndicatorInsets = UIEdgeInsetsMake(
		contentOffset.y < 0.0 ? -contentOffset.y : 0.0,
		0.0,
		0.0,
		0.0);
	
	self.articleView.contentInset = UIEdgeInsetsMake(
		0.0,
		0.0,
		self.toolbar.hidden ? 0.0 : CGRectGetHeight(self.toolbar.frame),
		0.0);
}

- (void)layoutSubviewsAnimated:(BOOL)animated {
	[UIView
		animateWithDuration:animated ? 0.2 : 0.0
		delay:0.0
		options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionLayoutSubviews
		animations:^{
			[self layoutSubviews];
		}
		completion:^(BOOL finished) {
		}];
}

- (void)layoutSubviews {
	BOOL loading = self.articleView.loadingDocument; // && self.articleView.loading;
	self.articleView.alpha = loading ?
		0.0 :
		1.0;
}

- (void)layoutBannerViewAnimated:(BOOL)animated {
/*
	BOOL shouldDisplayBanner = self.shouldDisplayBanner;
	
	CGSize bannerSize = [ADBannerView sizeFromBannerContentSizeIdentifier:ADBannerContentSizeIdentifier320x50];

	CGRect viewRect = self.view.bounds;
	CGRect navigationBarRect = self.navigationBar.frame;

	CGFloat bannerHeight = shouldDisplayBanner ?
		bannerSize.height : 
		0.0;

	CGRect articleViewRect = CGRectMake(
		CGRectGetMinX(viewRect),
		CGRectGetMaxY(navigationBarRect),
		CGRectGetWidth(viewRect),
		CGRectGetHeight(viewRect) - CGRectGetHeight(navigationBarRect) - bannerHeight);
	
	CGSize toolbarSize = [[self toolbar]
		sizeThatFits:viewRect.size];
	CGRect toolbarRect = CGRectMake(
		CGRectGetMinX(articleViewRect),
		CGRectGetMaxY(articleViewRect) - toolbarSize.height,
		CGRectGetWidth(articleViewRect),
		toolbarSize.height);
		
	CGRect bannerRect = CGRectMake(
		CGRectGetMinX(articleViewRect),
		CGRectGetMaxY(articleViewRect),
		CGRectGetWidth(articleViewRect),
		bannerHeight);
	
	if(animated) {
		if(shouldDisplayBanner) {
			self.bannerView.hidden = NO;
		}
		
		[UIView animateWithDuration:1.0 / 3.0
			delay:0.0
			options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionLayoutSubviews
			animations:^{
				self.articleView.frame = articleViewRect;
				self.toolbar.frame = toolbarRect;
				self.bannerView.frame = bannerRect;
				self.articlesBannerView.frame = bannerRect;
			}
			completion:^(BOOL finished) {
				if(finished) {
					self.bannerView.hidden = !shouldDisplayBanner;
				}
			}];
	} else {
		self.articleView.frame = articleViewRect;
		self.toolbar.frame = toolbarRect;
		self.bannerView.frame = bannerRect;
		self.bannerView.hidden = !shouldDisplayBanner;
	}
*/
}

- (void)initArticlesBannerViewIfNeeded {
/*
	if(self.articlesBannerView) { return; }
	
	UIImageView* bannerView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"articlesAdPortrait.png"]] autorelease];
	
	bannerView.frame = self.bannerView.frame;
	bannerView.userInteractionEnabled = YES;
	
	UITapGestureRecognizer* gestureRecognizer = [[[UITapGestureRecognizer alloc]
		initWithTarget:self
		action:@selector(openArticlesWebsite:)] autorelease];
	[bannerView addGestureRecognizer:gestureRecognizer];
	
	self.articlesBannerView = bannerView;
	[[self view] insertSubview:[self articlesBannerView] aboveSubview:[self bannerView]];
*/
}

@end
