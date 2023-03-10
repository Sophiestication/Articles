//
//  ARKWebViewController.m
//  Articles
//
//  Created by Sophia Teutschler on 23.12.11.
//  Copyright (c) 2011 Sophiestication Software. All rights reserved.
//

#import "ARKWebViewController.h"

#import "ARKHistoryItem.h"

#import "NSString+Additions.h"
#import "NSString+ArticleKit.h"
#import "NSURL+ArticleKit.h"

#import <QuartzCore/QuartzCore.h>

@interface ARKWebViewController()<UIWebViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property(nonatomic, readwrite, retain) UIWebView* webView;
@property(nonatomic, readwrite, retain) UIActivityIndicatorView* loadingView;

@property(nonatomic, getter=isWebViewLoaded) BOOL webViewLoaded;
@property(nonatomic) BOOL articleShouldLoadWhenReady;
@property(nonatomic, getter=isArticleLoaded) BOOL articleLoaded;

@property(nonatomic, getter=isLoadingViewShown) BOOL loadingViewShown;
- (void)setLoadingViewShown:(BOOL)loadingViewShown animated:(BOOL)animated;

@end

@implementation ARKWebViewController

@dynamic scrollView;

#pragma mark - Construction & Destruction

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
	}

    return self;
}

#pragma mark - ARKWebViewController

- (UIScrollView*)scrollView {
	return self.webView.scrollView;
}

- (void)setLoadingViewShown:(BOOL)loadingViewShown {
	[self setLoadingViewShown:loadingViewShown animated:NO];
}

- (void)setLoadingViewShown:(BOOL)loadingViewShown animated:(BOOL)animated {
	if(loadingViewShown == self.loadingViewShown) { return; }
	
	_loadingViewShown = loadingViewShown;
	
	if(loadingViewShown) {
		[self initLoadingViewIfNeeded];
	}
	
	if(loadingViewShown) {
		[[self loadingView] startAnimating];
		[[self view] bringSubviewToFront:[self loadingView]];
	}
	
	id animations = ^() {
		self.loadingView.hidden = NO;
		self.loadingView.alpha = loadingViewShown ? 1.0 : 0.0;
	};
	
	id completion = ^(BOOL finished) {
		if(finished && !loadingViewShown) {
			self.loadingView.hidden = YES;
			[[self loadingView] stopAnimating];
		}
	};
	
	NSTimeInterval duration = animated ? 0.5 : 0.0;

	[UIView animateWithDuration:duration animations:animations completion:completion];
}

- (void)loadArticleIfNeeded {
	if(self.articleLoaded) { return; }
	if(!self.representedURL) { return; }
	
	[self setLoadingViewShown:YES animated:YES];
	
	self.articleShouldLoadWhenReady	= YES;
	
	if(self.webViewLoaded) {
		[self loadArticle:[self representedURL]];
	}
}

- (void)loadArticle:(NSURL*)articleURL {
	if(!articleURL) { return; }

	NSString* articleURLString = [[articleURL absoluteString] stringByReplacingJavascriptCharacters];
	NSString* javascript = [NSString stringWithFormat:@"ArticleKit.loadArticle(\"%@\");", articleURLString];
	
	[[self webView] stringByEvaluatingJavaScriptFromString:javascript];
	
	self.articleLoaded = YES;
}

- (void)prepareForReuse {
	[[self webView] stringByEvaluatingJavaScriptFromString:@"ArticleKit.prepareForReuse();"];

	UIEdgeInsets contentInset = self.scrollView.contentInset;
	self.scrollView.contentOffset = CGPointMake(-contentInset.left, -contentInset.top);
	
	self.webView.hidden = YES;
	[[[self view] layer] removeAllAnimations];

	self.loadingViewShown = NO;

	self.articleLoaded = NO;
	self.articleShouldLoadWhenReady = NO;
}

#pragma mark - NSObject

- (NSString*)description {
	if(!self.representedURL) { return [super description]; }

	return [NSString stringWithFormat:@"%@ {article = %@}",
		[super description],
		[[self representedURL] absoluteString]];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	[self initWebViewIfNeeded];
}

- (void)viewDidUnload {
    [super viewDidUnload];
	
	self.webView = nil;
	self.loadingView = nil;
	
	self.webViewLoaded = NO;
	self.articleLoaded = NO;
	self.articleShouldLoadWhenReady = NO;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	
	// resize if needed
	if(!CGSizeEqualToSize(self.view.bounds.size, self.webView.bounds.size)) {
		self.webView.frame = self.view.bounds;
	}
	
	// layout the loading view
	CGRect contentRect = self.view.bounds;
	CGSize loadingViewSize = [[self loadingView]
		sizeThatFits:contentRect.size];
	
	self.loadingView.frame = CGRectMake(
		round(CGRectGetMidX(contentRect) - loadingViewSize.width * 0.5),
		round(CGRectGetMidY(contentRect) - loadingViewSize.height * 0.5),
		loadingViewSize.width,
		loadingViewSize.height);
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
	NSURL* URL = [request URL];
	
	// handle internal actions
	if([URL isArticleKitInternalURL]) {
		NSString* actionString = [URL host];
		
		NSString* argumentsString = [URL query];
		id arguments = nil;
		
		if(argumentsString) {
			argumentsString = [argumentsString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

			arguments = [NSJSONSerialization 
				JSONObjectWithData:[argumentsString dataUsingEncoding:NSUTF8StringEncoding]
				options:NSJSONReadingAllowFragments
				error:nil];
		}
		
		return ![self webView:webView shouldPerformAction:actionString arguments:arguments];
	}
	
	return YES;
}

- (void)webViewDidStartLoad:(UIWebView*)webView{
}

- (void)webViewDidFinishLoad:(UIWebView*)webView {
	self.webViewLoaded = YES;
	
	if(self.articleShouldLoadWhenReady) {
		[self loadArticleIfNeeded];
	}
}

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error {
	NSLog(@"Error loading article web view: %@", error);
}

#pragma mark - Private

- (void)initWebViewIfNeeded {
	if(self.webView) { return; }
	
	// make a new web view
	UIWebView* webView = [[UIWebView alloc] initWithFrame:[[self view] bounds]];
    
	webView.suppressesIncrementalRendering = YES;

	webView.autoresizingMask = self.view.autoresizingMask;
	webView.backgroundColor = self.view.backgroundColor;

	webView.delegate = self;
	webView.scrollView.delegate = self;

	webView.hidden = YES;

	self.webView = webView;

	// hide border shadow images
	for(UIView* subview in webView.scrollView.subviews) {
		if([subview isKindOfClass:[UIImageView class]]) {
			subview.hidden = YES;
		}
	}

	// load the container markup
	NSURL* articleURL = [[NSBundle mainBundle]
		URLForResource:@"articlekit" withExtension:@"html"];
	[webView loadRequest:[NSURLRequest requestWithURL:articleURL]];
	
	[[self view] addSubview:webView];
}

- (void)initLoadingViewIfNeeded {
	if(self.loadingView) { return; }

	UIActivityIndicatorView* loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];

	loadingView.color = [UIColor darkGrayColor];

	[loadingView sizeToFit];
	
	self.loadingView = loadingView;
	[[self view] insertSubview:loadingView aboveSubview:[self webView]];
}

- (BOOL)webView:(UIWebView*)webView shouldPerformAction:(NSString*)action arguments:(id)arguments {
	if(SFEEqualCaseInsensitiveStrings(action, @"loadArticle")) {
		NSURL* articleURL = [NSURL URLWithString:[arguments objectForKey:@"articleURL"]];
		[[self delegate] webViewController:self shouldLoadArticleWithURL:articleURL];
	} else if(SFEEqualStrings(action, @"articleDidFinishLoad")) {
		webView.hidden = NO;
		webView.alpha = 0.0;
		
		id animations = ^() {
			webView.alpha = 1.0;
			
			[self setLoadingViewShown:NO animated:YES];
		};
		
		[UIView animateWithDuration:0.5 delay:0.1 options:0 animations:animations completion:nil];
	}
	
	return YES;
}

@end