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

#import "BrowserViewController.h"
#import "BrowserViewController+Private.h"

#import "NSArray+Additions.h"
#import "UIBarButtonItem+Additions.h"
#import "SFNetworkActivity.h"

@implementation BrowserViewController

@dynamic webView;
@synthesize doneButtonItem = _doneButtonItem;
@synthesize backButtonItem = _backButtonItem;
@synthesize forwardButtonItem = _forwardButtonItem;
@synthesize openSafariButtonItem = _openSafariButtonItem;
@synthesize reloadButtonItem = _reloadButtonItem;
@synthesize stopButtonItem = _stopButtonItem;
@synthesize actionButtonItem = _actionButtonItem;
@synthesize customToolbar = _customToolbar;
@synthesize visibleActionSheet = _visibleActionSheet;
@synthesize visiblePrintInteractionController = _visiblePrintInteractionController;

#pragma mark - Construction & Destruction

+ (id)viewController {
	return [[self alloc] initWithNibName:nil bundle:nil];
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		self.hidesBottomBarWhenPushed = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
	}

    return self;
}

- (void)dealloc {
	self.webView.delegate = nil;

	
	

}

#pragma mark - BrowserViewController

- (UIWebView*)webView {
	return (id)self.view;
}

- (IBAction)done:(id)sender {
    [[self webView] stopLoading];
	self.webView.delegate = nil;
    
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)openSafari:(id)sender {
	NSURL* URL = [[[self webView] request] URL];
	[[UIApplication sharedApplication] openURL:URL];
}

- (IBAction)print:(id)sender {
	if(self.visiblePrintInteractionController) {
		[[self visiblePrintInteractionController] dismissAnimated:YES];
		self.visiblePrintInteractionController = nil;
		
		return;
	}
	
	if(self.visibleActionSheet) {
		[[self visibleActionSheet]
			dismissWithClickedButtonIndex:[[self visibleActionSheet] cancelButtonIndex]
			animated:YES];
		self.visibleActionSheet = nil;
	}
	
	UIPrintInteractionController* controller = [UIPrintInteractionController sharedPrintController];

	controller.delegate = self;

	UIPrintInfo* printInfo = [UIPrintInfo printInfo];
	printInfo.outputType = UIPrintInfoOutputGeneral;
	printInfo.jobName = self.title;
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
	
	self.visiblePrintInteractionController = controller;
}

- (IBAction)showActionSheet:(id)sender {
	if(self.visiblePrintInteractionController) {
		[[self visiblePrintInteractionController] dismissAnimated:YES];
		self.visiblePrintInteractionController = nil;
		
		return;
	}
	
	if(self.visibleActionSheet) {
		[[self visibleActionSheet]
			dismissWithClickedButtonIndex:[[self visibleActionSheet] cancelButtonIndex]
			animated:YES];
		self.visibleActionSheet = nil;
		
		return;
	}
	
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
			
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[actionSheet showFromBarButtonItem:[self actionButtonItem] animated:YES];
	} else {
		[actionSheet showFromToolbar:[[self navigationController] toolbar]];
	}
	
	self.visibleActionSheet = actionSheet;
}

- (void)showActivityPicker:(id)sender {
	// dismiss the current activity picker if needed
	if(self.activitiesPopoverController && [[self activitiesPopoverController] isPopoverVisible]) {
		[[self activitiesPopoverController] dismissPopoverAnimated:YES];
		self.activitiesPopoverController = nil;
		return;
	}

	// article URL
	NSURL* URL = [[[self webView] request] URL];
	
	// print formatter
	UIViewPrintFormatter* formatter = [[self webView] viewPrintFormatter];

	NSArray* items = @[ URL, formatter ];

	UIActivityViewController* viewController = [[UIActivityViewController alloc]
		initWithActivityItems:items
		applicationActivities:nil];
		
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UIPopoverController* activitiesPopoverController = [[UIPopoverController alloc] initWithContentViewController:viewController];
		activitiesPopoverController.delegate = self;
		self.activitiesPopoverController = activitiesPopoverController;
		
		[activitiesPopoverController
			presentPopoverFromBarButtonItem:[self actionButtonItem]
			permittedArrowDirections:UIPopoverArrowDirectionAny
			animated:YES];
	} else {
		[self presentViewController:viewController animated:YES completion:nil];
	}
}

#pragma mark - UIViewController

- (NSArray*)toolbarItems {
	return self.customToolbar ?
		self.customToolbar.items :
		[super toolbarItems];
}

- (void)setToolbarItems:(NSArray*)toolbarItems animated:(BOOL)animated	{
	if(self.customToolbar) {
		[[self customToolbar] setItems:toolbarItems animated:animated];
	} else {
		[super setToolbarItems:toolbarItems animated:animated];
	}
}

- (void)loadView {
	UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectZero];
	
	webView.delegate = self;
	
	self.view = webView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.backButtonItem = [[UIBarButtonItem alloc]
		initWithImage:[UIImage imageNamed:@"buttonitem-arrow-left.png"]
		landscapeImagePhone:[UIImage imageNamed:@"buttonitem-arrow-left-landscape.png"]
		style:UIBarButtonItemStylePlain
		target:[self webView]
		action:@selector(goBack)];
	
	self.forwardButtonItem = [[UIBarButtonItem alloc]
		initWithImage:[UIImage imageNamed:@"buttonitem-arrow-right.png"]
		landscapeImagePhone:[UIImage imageNamed:@"buttonitem-arrow-right-landscape.png"]
		style:UIBarButtonItemStylePlain
		target:[self webView]
		action:@selector(goForward)];
		
	self.reloadButtonItem = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
		target:[self webView]
		action:@selector(reload)];
	self.stopButtonItem = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemStop
		target:[self webView]
		action:@selector(reload)];

	SEL action = [UIActivityViewController class] ?
		@selector(showActivityPicker:) :
		@selector(showActionSheet:);
	
	self.actionButtonItem = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemAction
		target:self
		action:action];
		
	self.doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
	
	// Setup our toolbar
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		CGRect toolbarRect = CGRectMake(0.0, 0.0, 180.0, 44.0);
		UIToolbar* customToolbar = [[UIToolbar alloc] initWithFrame:toolbarRect];
		
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:customToolbar];
		
		self.customToolbar = customToolbar;
		
		self.toolbarItems = [NSArray arrayWithObjects:
			self.backButtonItem,
			[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
			self.forwardButtonItem,
			[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
			self.reloadButtonItem,
			[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
			self.actionButtonItem,
			nil];
	} else {
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
	}

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
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		self.navigationController.toolbarHidden = NO;
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
	return YES;
}

- (void)webViewDidStartLoad:(UIWebView*)webView {
	[self updateTitleLabels];
	[self updateButtonItems];
	
//	SFNetworkActivityStarted();
}

- (void)webViewDidFinishLoad:(UIWebView*)webView {
	[self updateTitleLabels];
	[self updateButtonItems];
	
//	SFNetworkActivityStopped();
}

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error {
	[self updateTitleLabels];
	[self updateButtonItems];
	
//	SFNetworkActivityStopped();
	
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

#pragma mark - UIActionSheetDelegate

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
	
	self.visibleActionSheet = nil;
}

#pragma mark - UIPrintInteractionControllerDelegate

- (void)printInteractionControllerDidDismissPrinterOptions:(UIPrintInteractionController*)printInteractionController {
	self.visiblePrintInteractionController = nil;
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController*)popoverController {
	if(popoverController == self.activitiesPopoverController) {
		self.activitiesPopoverController = nil;
	}
}

#pragma mark - Private

- (void)updateTitleLabels {
	NSString* title = [[self webView] stringByEvaluatingJavaScriptFromString:@"document.title"];

	if(title.length <= 0) {
		title = NSLocalizedString(@"LOADING_MORE_LABEL", @"");
	}
	
	self.title = title;
}

- (void)updateButtonItems {
	self.backButtonItem.enabled = self.webView.canGoBack;
	self.forwardButtonItem.enabled = self.webView.canGoForward;
	
	self.reloadButtonItem.enabled =
	self.stopButtonItem.enabled = self.webView.request != nil;

	self.actionButtonItem.enabled = self.webView.request != nil && !self.webView.loading;
	
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
