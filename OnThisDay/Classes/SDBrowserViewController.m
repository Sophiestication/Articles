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

#import "SDBrowserViewController.h"

#import "NSArray+Additions.h"

@implementation SDBrowserViewController

@dynamic webView;
@synthesize navigationTitleView = _navigationTitleView;
@synthesize titleLabel = _titleLabel;
@synthesize detailLabel = _detailLabel;
@synthesize doneButtonItem = _doneButtonItem;
@synthesize backButtonItem = _backButtonItem;
@synthesize forwardButtonItem = _forwardButtonItem;
@synthesize openSafariButtonItem = _openSafariButtonItem;
@synthesize reloadButtonItem = _reloadButtonItem;
@synthesize stopButtonItem = _stopButtonItem;
@synthesize actionButtonItem = _actionButtonItem;

#pragma mark -
#pragma mark Construction & Destruction

+ (id)viewController {
	return [[self alloc] initWithNibName:@"SDBrowserViewController" bundle:nil];
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    if(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		self.hidesBottomBarWhenPushed = NO;
	}

    return self;
}

- (void)dealloc {
	self.actionButtonItem = nil;
	self.doneButtonItem = nil;
	self.backButtonItem = nil;
	self.forwardButtonItem = nil;
	self.openSafariButtonItem = nil;
	self.reloadButtonItem = nil;
	self.stopButtonItem = nil;
	self.navigationTitleView = nil;
	self.titleLabel = nil;
	self.detailLabel = nil;
}

#pragma mark -
#pragma mark BrowserViewController

- (UIWebView*)webView {
	return (id)self.view;
}

- (IBAction)done:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)openSafari:(id)sender {
	NSURL* URL = [[[self webView] request] URL];
	[[UIApplication sharedApplication] openURL:URL];
}

- (IBAction)print:(id)sender {
	UIPrintInteractionController* controller = [UIPrintInteractionController sharedPrintController];

	UIPrintInfo* printInfo = [UIPrintInfo printInfo];
	printInfo.outputType = UIPrintInfoOutputGeneral;
	printInfo.jobName = self.titleLabel.text;
	printInfo.duplex = UIPrintInfoDuplexLongEdge;
    
	controller.printInfo = printInfo;
    controller.showsPageRange = YES;
 
    UIViewPrintFormatter* formatter = [[self webView] viewPrintFormatter];
    formatter.startPage = 0;
    controller.printFormatter = formatter;
	
	id completionHandler = ^(UIPrintInteractionController* printController, BOOL completed, NSError* error) {
		if(!completed && error){
            NSLog(@"Could not print document due to error in domain %@ with error code %u", [error domain], [error code]);
        }
    };
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		[controller presentAnimated:YES completionHandler:completionHandler];
	} else {
		[controller presentFromBarButtonItem:[self actionButtonItem] animated:YES completionHandler:completionHandler];
	}
}

- (IBAction)showActionSheet:(id)sender {
	BOOL canPrint =
		[UIPrintInteractionController class] &&
		[UIPrintInteractionController isPrintingAvailable];
	
	UIActionSheet* actionSheet = [[UIActionSheet alloc]
		initWithTitle:nil
		delegate:self
		cancelButtonTitle:NSLocalizedString(@"UIBarButtonSystemItemCancel", @"")
		destructiveButtonTitle:nil
		otherButtonTitles:
			NSLocalizedString(@"OPENSAFARI_ACTION_TITLE", @""),
			canPrint ? NSLocalizedString(@"SHEETBUTTON_PRINT", @"") : nil,
			nil];
	[actionSheet showFromToolbar:[[self navigationController] toolbar]];
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	// Setup our toolbar
	self.toolbarItems = [NSArray arrayWithObjects:
		self.backButtonItem,
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
		self.forwardButtonItem,
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
		self.reloadButtonItem,
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
		self.actionButtonItem,
		nil];
	self.navigationController.toolbarHidden = NO;
	
//	self.navigationItem.titleView = self.navigationTitleView;
	self.navigationItem.rightBarButtonItem = self.doneButtonItem;
	
	[self updateTitleLabels];
	[self updateButtonItems];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	
	self.actionButtonItem = nil;
	self.doneButtonItem = nil;
	self.backButtonItem = nil;
	self.forwardButtonItem = nil;
	self.openSafariButtonItem = nil;
	self.reloadButtonItem = nil;
	self.stopButtonItem = nil;
	self.navigationTitleView = nil;
	self.titleLabel = nil;
	self.detailLabel = nil;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	// Display the navigation bar
	self.navigationController.navigationBarHidden = NO;
	
	// ...
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
	return YES;
}

- (void)webViewDidStartLoad:(UIWebView*)webView {
	[self updateTitleLabels];
	[self updateButtonItems];
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)webViewDidFinishLoad:(UIWebView*)webView {
	[self updateTitleLabels];
	[self updateButtonItems];
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error {
	[self updateTitleLabels];
	[self updateButtonItems];
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	
	// Report errors if we didn't cancelled
	if(error.code != NSURLErrorCancelled) {
		UIAlertView* alert = [[UIAlertView alloc]
			initWithTitle:nil
			message:[error localizedDescription]
			delegate:nil
			cancelButtonTitle:nil
			otherButtonTitles:@"OK", nil];
		[alert show];
	}
}

#pragma mark -
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(buttonIndex == actionSheet.firstOtherButtonIndex) {
		[self openSafari:actionSheet];
	}
	
	BOOL canPrint =
		[UIPrintInteractionController class] &&
		[UIPrintInteractionController isPrintingAvailable];

	if(canPrint && buttonIndex == actionSheet.firstOtherButtonIndex + 1) {
		[self print:actionSheet];
	}
}

#pragma mark -
#pragma mark Private

- (void)updateTitleLabels {
	NSString* title = [[self webView] stringByEvaluatingJavaScriptFromString:@"document.title"];

	if(title.length <= 0) {
		title = NSLocalizedString(@"LOADING_MORE_LABEL", @"");
	}
	
	self.title = self.titleLabel.text = title;
	self.detailLabel.text = [[[[self webView] request] URL] relativeString];
}

- (void)updateButtonItems {
	self.backButtonItem.enabled = self.webView.canGoBack;
	self.forwardButtonItem.enabled = self.webView.canGoForward;
	
	self.actionButtonItem.enabled =
	self.reloadButtonItem.enabled =
	self.stopButtonItem.enabled = self.webView.request != nil;
	
	if(self.webView.loading) {
		self.toolbarItems = [[self toolbarItems]
			arrayByReplacingObject:[self reloadButtonItem]
			withObject:[self stopButtonItem]];
	} else {
		self.toolbarItems = [[self toolbarItems]
			arrayByReplacingObject:[self stopButtonItem]
			withObject:[self reloadButtonItem]];
	}
		
}

@end
