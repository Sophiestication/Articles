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

#import "AKTabularDataViewController.h"
#import "AKTabularDataViewController+Private.h"

#import "AKArticleView.h"
#import "AKArticleView+Private.h"

#import "AKArchive.h"
#import "AKArchive+Private.h"

#import "AKWebCustomizer.h"

#import "NSURL+Wikipedia.h"
#import "UIButton+Graphite.h"
#import "UILabel+Graphite.h"
#import "UINavigationController+Additions.h"

@implementation AKTabularDataViewController

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
//		self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		self.modalPresentationStyle = UIModalPresentationFormSheet;
		self.hidesBottomBarWhenPushed = YES;
	}

    return self;
}

- (void)dealloc {
	self.webCustomizer.delegate = nil;
	self.delegate = nil;
}

#pragma mark -
#pragma mark UIViewController

- (void)back:(id)sender {
	[[self navigationController] popViewControllerAnimated:YES];
}

- (void)done:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark UIViewController

- (void)loadView {
	// Graphite Style
	UILabel* titleLabel = [UILabel graphiteNavigationBarLabelWithText:@""];
	self.navigationItem.titleView = titleLabel;

	if(self.navigationController.rootViewController == self) {
//		if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
			UIButton* doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
			[doneButton addTarget:self action:@selector(done:) forControlEvents:UIControlEventTouchUpInside];
			self.doneButtonItem = [[UIBarButtonItem alloc] initWithCustomView:doneButton];
//		} else {
//			UIBarButtonItem* doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
//			self.doneButtonItem = doneButtonItem;
//		}
	} else {
		UIButton* backButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[backButton addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
		self.backButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
	}
	
	// ...
	AKTabularDataContainerView* view = [[AKTabularDataContainerView alloc] initWithFrame:CGRectZero];
	
	view.viewController = self;
	
	self.view = view;
	
	// ...
	UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectZero];
	
	webView.backgroundColor = [UIColor whiteColor]; // [UIColor colorWithRed:0.647 green:0.675 blue:0.710 alpha:1.000];
	webView.opaque = YES;

	webView.scalesPageToFit = NO;
	webView.dataDetectorTypes = UIDataDetectorTypeNone;
	
	webView.delegate = self;

	self.webView = webView;
	[view addSubview:webView];
	
	AKWebCustomizer* webCustomizer = [[AKWebCustomizer alloc] initWithWebView:webView delegate:self];
	self.webCustomizer = webCustomizer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
    NSString* titleString = [[self options] objectForKey:@"caption"];
    if(titleString.length <= 0) {
		titleString = [[[self options] objectForKey:@"articleView"] articleTitle];
    }
    
    self.title = titleString;
	
	UILabel* titleLabel = (id)self.navigationItem.titleView;
	
    if(titleLabel) {
        titleLabel.text = self.title;
        [titleLabel sizeToFit];
	}
    
    self.navigationItem.leftBarButtonItem = self.backButtonItem;
	self.navigationItem.rightBarButtonItem = self.doneButtonItem;
	
	[self loadTabularData];
}

- (void)viewDidUnload {
	[super viewDidUnload];

	self.webView = nil;
	self.backButtonItem = nil;
	self.doneButtonItem = nil;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[[self navigationController] setNavigationBarHidden:NO animated:NO];
	[[self navigationController] setToolbarHidden:YES animated:animated];
	
	[self updateDoneButtonItemForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
	
	if([[self delegate] respondsToSelector:@selector(tabularDataViewControllerWillAppear:)]) {
		[[self delegate] tabularDataViewControllerWillAppear:self];
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[[[self webCustomizer] scrollView] flashScrollIndicators];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	
	if([[self delegate] respondsToSelector:@selector(tabularDataViewControllerDidDisappear:)]) {
		[[self delegate] tabularDataViewControllerDidDisappear:self];
	}

	[[self navigationController] setNavigationBarHidden:YES animated:animated];
	[[self navigationController] setToolbarHidden:NO animated:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	AKArticleView* articleView = [[self options] objectForKey:@"articleView"];
	UIViewController* parentViewController = [articleView parentViewController];
	
	if(parentViewController && [parentViewController respondsToSelector:@selector(shouldAutorotateToInterfaceOrientation:)]) {
		return [parentViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
	}

	return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
	[self updateDoneButtonItemForOrientation:toInterfaceOrientation];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark AKWebCustomizerDelegate

- (UIView*)webCustomizer:(AKWebCustomizer*)webCustomizer viewForGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer {
	return [self view];
}

- (void)webCustomizer:(AKWebCustomizer*)webCustomizer shouldPresentURL:(NSURL*)URL options:(NSDictionary*)options {
	AKArticleView* articleView = [[self options] objectForKey:@"articleView"];
	[articleView webCustomizer:webCustomizer shouldPresentURL:URL options:options];
}

- (void)webCustomizer:(AKWebCustomizer*)webCustomizer shouldPresentSheetForURL:(NSURL*)URL options:(NSDictionary*)options {
	AKArticleView* articleView = [[self options] objectForKey:@"articleView"];
	[articleView webCustomizer:webCustomizer shouldPresentSheetForURL:URL options:options];
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
	NSURL* URL = [request URL];
	
	if([[URL scheme] isEqualToString:@"x-articlekit-internal"]) {
		AKArticleView* articleView = [[self options] objectForKey:@"articleView"];
		return [articleView webCustomizer:[self webCustomizer] shouldHandleEventWithURL:URL];
	}
	
	if([URL isFileURL]) {
		return YES;
	} else if([URL isWikipediaFileURL]) {
    	return NO;
    } else if([URL isWikipediaURL]) {
		AKArticleView* articleView = [[self options] objectForKey:@"articleView"];
		[articleView webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
	} else {
		if([[URL absoluteString] hasPrefix:@"about:"]) {
			return NO;
		}
		
		// Tell the delegate to load this external resource
		AKArticleView* articleView = [[self options] objectForKey:@"articleView"];
		
		if([[articleView delegate] respondsToSelector:@selector(articleView:shouldLoadExternalResource:)]) {
			[[articleView delegate] articleView:articleView shouldLoadExternalResource:URL];
		}
		
		return NO;
	}
	
	// We're done
	[self performSelector:@selector(done:)
		withObject:nil
		afterDelay:0.0];

	return NO;
}

- (void)webViewDidFinishLoad:(UIWebView*)webView {
	[self loadImagesIfNeeded];
}

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error {
	[self loadImagesIfNeeded];
}

#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
}

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView*)scrollView {
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView*)scrollView {
	return YES;
}

- (void)scrollViewDidScrollToTop:(UIScrollView*)scrollView {
}


#pragma mark -
#pragma mark Private

- (void)loadTabularData {
	AKArchive* archive = [[self options] objectForKey:@"archive"];

	NSString* markup = [[self options] objectForKey:@"markup"];
	NSString* HTMLString = [NSString stringWithFormat:
		@"<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"\n"
		@"\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n"
		@"<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">\n"
		@"<head>\n"
			@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"/>\n"
			@"<meta name=\"viewport\" content=\"user-scalable=no, width=device-width, initial-scale = 1.0\">\n"
			@"<link rel=\"stylesheet\" type=\"text/css\" href=\"x-articlekit-resource://articlekit.css\">\n"
			@"<link rel=\"stylesheet\" type=\"text/css\" href=\"x-articlekit-resource://table.css\">\n"
			@"<script type=\"text/javascript\" src=\"x-articlekit-resource://articlekit.js\"></script>\n"
		@"</head>\n"
		@"<body class=\"articlekit-tablesheet\">\n"
		@"%@\n"
		@"</body>\n"
		@"</html>",
	markup];
	
	[[self webView] loadHTMLString:HTMLString baseURL:[archive archiveURL]];
}

- (void)loadImagesIfNeeded {
	AKArchive* archive = [[self options] objectForKey:@"archive"];
	AKArticleView* articleView = [[self options] objectForKey:@"articleView"];
	
	for(NSDictionary* imageInfo in archive.images) {
		NSString* javascript = [articleView showThumbnailJavascript:imageInfo];
		[[self webView] stringByEvaluatingJavaScriptFromString:javascript];
	}
}

- (void)updateDoneButtonItemForOrientation:(UIInterfaceOrientation)orientation {
	// ...
	UIButton* doneButton = (id)self.navigationItem.rightBarButtonItem.customView;
	
	if(doneButton) {
		[doneButton
			setGraphiteStyle:UIBarButtonItemStyleDone
			miniBar:UIInterfaceOrientationIsLandscape(orientation)
			systemItem:UIBarButtonSystemItemDone];
	}
	
	// ...
	UIButton* backButton = (id)self.navigationItem.leftBarButtonItem.customView;
	
	if(backButton) {
		[backButton setGraphiteBackStyle:UIInterfaceOrientationIsLandscape(orientation)];
	}
	
	// ...
	UILabel* titleLabel = (id)self.navigationItem.titleView;
	
	if(titleLabel) {
		titleLabel.font = UIInterfaceOrientationIsPortrait(orientation) ?
			[UIFont boldSystemFontOfSize:19.0] :
			[UIFont boldSystemFontOfSize:16.0];
		[titleLabel sizeToFit];
	}
}

@end

#pragma mark -
#pragma mark AKTabularDataContainerView

@implementation AKTabularDataContainerView

@synthesize viewController = _viewController;

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event {
	UIView* view = [super hitTest:point withEvent:event];
	
	view = [[[self viewController] webCustomizer] hitTest:point withEvent:event targetView:view inView:self];
	
	return view;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	self.viewController.webView.frame = self.bounds;
}

@end
