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

#import "AKLightboxViewController.h"
#import "AKLightboxViewController+Private.h"

#import "AKLightboxView.h"
#import "AKLightboxView+Private.h"

#import "AKLightboxOverlayView.h"
#import "AKLightboxProgressView.h"

#import "SFDownloadOperation.h"

#import "UIImage+Additions.h"

#import <MobileCoreServices/MobileCoreServices.h>

@implementation AKLightboxViewController

NSString* const AKLightboxWillShowNotification = @"AKLightboxWillShowNotification";
NSString* const AKLightboxWillHideNotification = @"AKLightboxWillHideNotification";

@dynamic lightboxView;

#pragma mark - Construction & Destruction

+ (AKLightboxViewController*)viewController {
	return [[self alloc] initWithNibName:nil bundle:nil];
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		self.wantsFullScreenLayout = YES;
//		self.modalTransitionStyle = UIModalTransitionStylePartialCurl;
		self.modalPresentationStyle = UIModalPresentationFullScreen;
	}

    return self;
}

- (void)dealloc {
	self.downloadOperation.delegate = nil;
	self.delegate = nil;
}

#pragma mark - AKLightboxViewController

- (void)presentPreviewInViewController:(UIViewController*)parentViewController withOptions:(NSDictionary*)options animated:(BOOL)animated {
	self.options = options;
	_previousStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:AKLightboxWillShowNotification object:self];
	
	UIView* parentView = parentViewController.view;
	UIWindow* window = parentView.window;
	
	CGRect rect = window.bounds;
	
	CGRect previewRect = [[options objectForKey:@"rect"] CGRectValue];
	previewRect = [[self view] convertRect:previewRect fromView:nil];
	
	CGRect visiblePreviewRect = [[options objectForKey:@"visibleRect"] CGRectValue];
	visiblePreviewRect = [[self view] convertRect:visiblePreviewRect fromView:nil];
	
//	NSLog(@"%@, %@, %@", NSStringFromCGRect(previewRect), NSStringFromCGRect(visiblePreviewRect), NSStringFromCGRect(rect));
	
	CGAffineTransform windowTransform = window.transform;
	
	CGRect overlayRect = rect;
	AKLightboxOverlayView* transitionOverlayView = [[AKLightboxOverlayView alloc] initWithFrame:overlayRect];
	
	transitionOverlayView.alpha = 0.0;
	transitionOverlayView.photoFrame = visiblePreviewRect;
	
	[window addSubview:transitionOverlayView];
	
	id animationBlock = ^{
		[[UIApplication sharedApplication]
			setStatusBarHidden:YES
			withAnimation:animated ? UIStatusBarAnimationFade : UIStatusBarAnimationNone];
		
		if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
			[[UIApplication sharedApplication]
				setStatusBarStyle:UIStatusBarStyleBlackTranslucent
				animated:animated];
		}

		CGAffineTransform transform = windowTransform;
		
		CGFloat scaleX = CGRectGetWidth(rect) / CGRectGetWidth(previewRect);
		CGFloat scaleY = CGRectGetHeight(rect) / CGRectGetHeight(previewRect);
			
		CGFloat scale = MIN(scaleX, scaleY);

		transform = CGAffineTransformScale(transform, scale, scale);
		
		CGFloat offsetX = CGRectGetMidX(rect) - CGRectGetMidX(previewRect);
		CGFloat offsetY = CGRectGetMidY(rect) - CGRectGetMidY(previewRect);
		
		transform = CGAffineTransformTranslate(transform, offsetX, offsetY);
		
		window.transform = transform;
		
		transitionOverlayView.alpha = 1.0;
	};
	
	id completionBlock = ^(BOOL finished) {
		if(!finished) { return; }

		[transitionOverlayView removeFromSuperview];
		self.transitionOverlayView = nil;
		
		window.transform = windowTransform;
		
		[parentViewController presentViewController:self animated:NO completion:nil];
	};
	
	NSTimeInterval duration = animated ?
		0.3 :
		0.0;
	
	[UIView animateWithDuration:duration
		delay:0.0
		options:/*UIViewAnimationOptionRepeat|UIViewAnimationOptionAutoreverse|*/UIViewAnimationOptionCurveEaseInOut
		animations:animationBlock
		completion:completionBlock];
}

- (void)dismissPreviewAnimated:(BOOL)animated {
	if(self.visiblePrintInteractionController) {
		[[self visiblePrintInteractionController] dismissAnimated:animated];
		self.visiblePrintInteractionController = nil;
	}
	
	if(self.visibleActionSheet) {
		[[self visibleActionSheet]
			dismissWithClickedButtonIndex:[[self visibleActionSheet] cancelButtonIndex]
			animated:animated];
		self.visibleActionSheet = nil;
	}

	if(self.activitiesPopoverController) {
		[[self activitiesPopoverController] dismissPopoverAnimated:YES];
		self.activitiesPopoverController = nil;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:AKLightboxWillHideNotification object:self];
	
	[self dismissViewControllerAnimated:animated completion:nil];
	
	[[UIApplication sharedApplication] setStatusBarStyle:_previousStatusBarStyle animated:animated];
}

- (IBAction)share:(id)sender {
	if([sender isKindOfClass:[UIGestureRecognizer class]]) {
		if([(UIGestureRecognizer*)sender state] != UIGestureRecognizerStateBegan) {
			return;
		}
	}
	
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
		[self isPrintingAvailable] &&
		[UIPrintInteractionController canPrintURL:[[self lightboxView] imageURL]];
	
	UIActionSheet* actionSheet = [[UIActionSheet alloc]
		initWithTitle:nil
		delegate:self
		cancelButtonTitle:NSLocalizedString(@"SHEETBUTTON_CANCEL", @"")
		destructiveButtonTitle:nil
		otherButtonTitles:
			NSLocalizedString(@"SHEETBUTTON_CLIPBOARD_COPY", @""),
			NSLocalizedString(@"SHEETBUTTON_SAVE_IMAGE", @""),
			canPrint ? NSLocalizedString(@"SHEETBUTTON_PRINT", @"") : nil,
			nil];
	
	actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		[actionSheet showInView:[self view]];
	} else {
		if(sender == self.shareButtonItem) {
			[actionSheet showFromBarButtonItem:[self shareButtonItem] animated:YES];
		} else if([sender respondsToSelector:@selector(locationInView:)]) {
			CGPoint targetLocation = [(UIGestureRecognizer*)sender locationInView:[self view]];
			CGFloat targetSize = 44.0;

			CGRect targetRect = CGRectMake(
				floorf(targetLocation.x - targetSize * 0.5),
				floorf(targetLocation.y - targetSize * 0.5),
				targetSize, 
				targetSize);
				
			[actionSheet showFromRect:targetRect inView:[self view] animated:YES];
		}
	}
	
	self.visibleActionSheet = actionSheet;
}

- (void)presentActivityPicker:(id)sender {
	if([sender isKindOfClass:[UIGestureRecognizer class]]) {
		if([(UIGestureRecognizer*)sender state] != UIGestureRecognizerStateBegan) {
			return;
		}
	}

	if(self.activitiesPopoverController && [[self activitiesPopoverController] isPopoverVisible]) {
		[[self activitiesPopoverController] dismissPopoverAnimated:YES];
		self.activitiesPopoverController = nil;
		return;
	}

	NSURL* localImageURL = self.lightboxView.imageURL;
	if(!localImageURL) { return; }

	UIImage* image = [[UIImage alloc] initWithContentsOfFile:[localImageURL path]];

	// prepare the activity view controller
	NSArray* items = @[ image ];

	UIActivityViewController* viewController = [[UIActivityViewController alloc]
		initWithActivityItems:items
		applicationActivities:nil];
		
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UIPopoverController* activitiesPopoverController = [[UIPopoverController alloc] initWithContentViewController:viewController];
		activitiesPopoverController.delegate = self;
		self.activitiesPopoverController = activitiesPopoverController;

		if(sender == self.shareButtonItem) {
			[activitiesPopoverController
				presentPopoverFromBarButtonItem:[self shareButtonItem]
				permittedArrowDirections:UIPopoverArrowDirectionAny
				animated:YES];
		} else if([sender respondsToSelector:@selector(locationInView:)]) {
			CGPoint targetLocation = [(UIGestureRecognizer*)sender locationInView:[self view]];
			CGFloat targetSize = 44.0;

			CGRect targetRect = CGRectMake(
				floorf(targetLocation.x - targetSize * 0.5),
				floorf(targetLocation.y - targetSize * 0.5),
				targetSize, 
				targetSize);
				
			[activitiesPopoverController
				presentPopoverFromRect:targetRect
				inView:[self view]
				permittedArrowDirections:UIPopoverArrowDirectionAny
				animated:YES];
		}
		
		
	} else {
		[self presentViewController:viewController animated:YES completion:nil];
	}

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
	NSURL* imageURL = self.lightboxView.imageURL;
	
	if([UIPrintInteractionController canPrintURL:imageURL]) {
		controller.printingItem = imageURL;
		controller.delegate = self;

		if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
			[controller presentAnimated:YES completionHandler:nil];
		} else {
			[controller presentFromBarButtonItem:[self shareButtonItem] animated:YES completionHandler:nil];
		}
		
		self.visiblePrintInteractionController = controller;
	}
}

- (IBAction)done:(id)sender {
	[self dismissPreviewAnimated:YES];
}

#pragma mark - UIViewController

- (void)loadView {
	AKLightboxView* lightboxView = [[AKLightboxView alloc] initWithFrame:CGRectZero];
	
	lightboxView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
	
	self.view = lightboxView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = [[self options] objectForKey:@"title"];

	SEL shareAction = [UIActivityViewController class] ?
		@selector(presentActivityPicker:) :
		@selector(share:);
	
	// Long press to show menu
	UILongPressGestureRecognizer* longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] init];
	
	[longPressGestureRecognizer addTarget:self action:shareAction];
	
	[[[self lightboxView] scrollView] addGestureRecognizer:longPressGestureRecognizer];
	
	// Share Button Item
	UIBarButtonItem* shareButtonItem = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemAction
		target:self
		action:shareAction];
	self.shareButtonItem = shareButtonItem;
	
	self.navigationItem.leftBarButtonItem = shareButtonItem;
	
	// Done Button Item
	UIBarButtonItem* doneButtonItem = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemDone
		target:self
		action:@selector(done:)];
	self.doneButtonItem = doneButtonItem;
	
	self.navigationItem.rightBarButtonItem = doneButtonItem;
	
	// ...
	self.lightboxView.navigationItem = self.navigationItem;
	
	NSString* captionText = [[[self options] objectForKey:@"caption"]
		stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	self.lightboxView.captionText = captionText;
	
	// Download the highres image if needed
	NSURL* imageURL = [[self options] objectForKey:@"URL"];
	NSURL* localImageURL = [[self options] objectForKey:@"localURL"];

	if(![localImageURL checkResourceIsReachableAndReturnError:nil]) {
		[self downloadImageAtURL:imageURL toURL:localImageURL];
		localImageURL = [[self options] objectForKey:@"previewURL"];
	}
	
	self.lightboxView.imageURL = localImageURL;
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	UIViewController* parentViewController = [self parentViewController];
	
	if(parentViewController && [parentViewController respondsToSelector:@selector(shouldAutorotateToInterfaceOrientation:)]) {
		return [parentViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
	}

	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
	self.lightboxView.interfaceOrientation = toInterfaceOrientation;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UIActionSheetDelegate

- (void)willPresentActionSheet:(UIActionSheet*)actionSheet {
//	if(!self.lightboxView.barsHidden) {
//		[[self lightboxView] setBarsHidden:YES animated:YES];
//	}
}

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(buttonIndex == actionSheet.firstOtherButtonIndex) {
//		NSURL* imageURL = nil;
		NSURL* localImageURL = self.lightboxView.imageURL;
		
		NSData* imageData = [NSData dataWithContentsOfMappedFile:[localImageURL path]];
		
		NSArray* pasteboardItems = [NSArray arrayWithObjects:
//			[NSDictionary dictionaryWithObject:imageURL forKey:(id)kUTTypeURL],
			[NSDictionary dictionaryWithObject:localImageURL forKey:(id)kUTTypeFileURL],
			[NSDictionary dictionaryWithObject:imageData forKey:(id)kUTTypeImage],
			nil];
		[[UIPasteboard generalPasteboard] setItems:pasteboardItems];
	} else if(buttonIndex == actionSheet.firstOtherButtonIndex + 1) {
		NSURL* imageURL = self.lightboxView.imageURL;
		UIImage* image = [[UIImage alloc] initWithContentsOfFile:
			[imageURL path]];
		UIImageWriteToSavedPhotosAlbum(
			image,
			self,
			@selector(image:didFinishSavingWithError:contextInfo:),
			NULL);
	} else if(buttonIndex == actionSheet.firstOtherButtonIndex + 2) {
		[self print:actionSheet];
	}
	
	self.visibleActionSheet = nil;
}

- (void)image:(UIImage*)image didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo {
	if(error) {
		NSLog(@"Error saving image: %@", error);
	}
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController*)popoverController {
	if(self.activitiesPopoverController == popoverController) {
		self.activitiesPopoverController = nil;
	}
}

#pragma mark - UIPrintInteractionControllerDelegate

- (void)printInteractionControllerWillPresentPrinterOptions:(UIPrintInteractionController*)printInteractionController {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { return; }
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (void)printInteractionControllerWillDismissPrinterOptions:(UIPrintInteractionController*)printInteractionController {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { return; }
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
}

- (void)printInteractionControllerDidDismissPrinterOptions:(UIPrintInteractionController*)printInteractionController {
	self.visiblePrintInteractionController = nil;
}

- (void)printInteractionControllerWillStartJob:(UIPrintInteractionController*)printInteractionController {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { return; }
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (void)printInteractionControllerDidFinishJob:(UIPrintInteractionController*)printInteractionController {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { return; }
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
}

#pragma mark - SFDownloadOperationDelegate

- (void)downloadOperation:(SFDownloadOperation*)downloadOperation willDownloadWithRequest:(NSMutableURLRequest*)request {
	self.lightboxView.progressView.style = AKLightboxProgressViewStyleActivity;
	self.lightboxView.progressView.progress = 0.0;
	self.lightboxView.progressView.hidden = NO;
}

- (void)downloadOperation:(SFDownloadOperation*)downloadOperation didReceiveResponse:(NSURLResponse*)response {
	// Cancel the download if we don't support the image type
	if(![UIImage canHandleMIMEType:[downloadOperation contentType]]) {
		[downloadOperation cancel];
	}
}

- (void)downloadOperationDidFinish:(SFDownloadOperation*)downloadOperation {
	self.lightboxView.imageContentType = downloadOperation.contentType;
	self.lightboxView.imageURL = downloadOperation.localURL;
	
	self.downloadOperation = nil;
	
	self.lightboxView.progressView.style = AKLightboxProgressViewStyleDetermined;
	self.lightboxView.progressView.hidden = YES;
}

- (void)downloadOperation:(SFDownloadOperation*)downloadOperation didFailWithError:(NSError*)error {
	if([[downloadOperation remoteURL] isEqual:[[self options] objectForKey:@"URL"]]) {
		NSURL* alternateImageURL = [[self options] objectForKey:@"alternateURL"];
		
		if(alternateImageURL && ![alternateImageURL isEqual:[[self options] objectForKey:@"URL"]]) {
			NSURL* localImageURL = [[self options] objectForKey:@"localURL"];
			[self downloadImageAtURL:alternateImageURL toURL:localImageURL];
			
			return;
		}
	}
	
	self.lightboxView.progressView.style = AKLightboxProgressViewStyleDetermined;
	self.lightboxView.progressView.hidden = YES;

	NSLog(@"Could not download image %@: %@", downloadOperation.remoteURL, error);
	
	self.downloadOperation = nil;
}

- (void)downloadOperation:(SFDownloadOperation*)downloadOperation didProgress:(float)progress {
	self.lightboxView.progressView.style = AKLightboxProgressViewStyleDetermined;
	
	float newProgress = MAX(progress, self.lightboxView.progressView.progress); // make sure we only progress
	newProgress = floorf(newProgress * 10.0) / 10.0;
	newProgress = MIN(newProgress, 0.95); // we cap to 0.95 max for better looks
	self.lightboxView.progressView.progress = newProgress;
}

#pragma mark - Private

- (AKLightboxView*)lightboxView {
	return (id)self.view;
}

- (UIImage*)imageRepresentationForView:(UIView*)view {
	UIImage* imageRepresentation = nil;
	
	if(UIGraphicsBeginImageContextWithOptions) {
		UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, 0.0);
	} else {
		 UIGraphicsBeginImageContext(view.bounds.size);
	} {
		[[view layer] renderInContext:UIGraphicsGetCurrentContext()];
		imageRepresentation = UIGraphicsGetImageFromCurrentImageContext();
	} UIGraphicsEndImageContext();
	
	return imageRepresentation;
}

- (void)downloadImageAtURL:(NSURL*)imageURL toURL:(NSURL*)localImageURL {
	SFDownloadOperation* downloadOperation = [[SFDownloadOperation alloc] init];
	
	downloadOperation.delegate = self;
	
	downloadOperation.remoteURL = imageURL;
	downloadOperation.localURL = localImageURL;
	
	self.downloadOperation = downloadOperation;
	
	[downloadOperation begin];
}

- (BOOL)isPrintingAvailable {
	if([UIPrintInteractionController class]) {
		return [UIPrintInteractionController isPrintingAvailable];
	}
	
	return NO;
}

@end
