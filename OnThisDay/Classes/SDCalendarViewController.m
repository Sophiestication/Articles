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

#import "SDCalendarViewController.h"
#import "SDCalendarViewController+Private.h"

#import "SDCalendarNavigationButton.h"
#import "SDCalendarTitleView.h"

#import "SDDayPickerViewController.h"
#import "SDDayPickerViewController+Private.h"

#import "SDArticleViewController.h"
#import "SDBrowserViewController.h"

#import "SFNetworkReachability.h"

#import "SDWikipediaEventImporter.h"

#import "SDDay.h"
#import "SDDay+Additions.h"
#import "SDEventGroup.h"
#import "SDEvent.h"

#import "WikipediaAPI.h"

#import "NSArray+Additions.h"
#import "NSLocale+Additions.h"
#import "NSString+Additions.h"

@implementation SDCalendarViewController

#pragma mark -
#pragma mark Construction & Destruction

+ (id)viewController {
	return [[self alloc] initWithNibName:nil bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		self.progressIndicatorShown = NO;
	}
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - SDCalendarViewController

- (IBAction)back:(id)sender {
	// Determine the previous date
	NSCalendar* gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	
	NSDateComponents* dayBackComponent = [[NSDateComponents alloc] init];
	
	[dayBackComponent setDay:-1];
	
	NSDate* newDate = [gregorian dateByAddingComponents:dayBackComponent
		toDate:[self selectedDate]
		options:0];
	
	[self showDay:newDate];
}

- (IBAction)forward:(id)sender {
	// Determine the previous date
	NSCalendar* gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	
	NSDateComponents* dayForwardComponent = [[NSDateComponents alloc] init];
	
	[dayForwardComponent setDay:1];
	
	NSDate* newDate = [gregorian dateByAddingComponents:dayForwardComponent
		toDate:[self selectedDate]
		options:0];
	
	[self showDay:newDate];
}

- (IBAction)showDay:(NSDate*)day {
	NSComparisonResult result = [day compare:[self selectedDate]];
	if(result == NSOrderedSame) { return; }
	
	// NSLog(@"%@ < %@", [day earlierDate:[self selectedDate]], [day laterDate:[self selectedDate]]);

	// Make it so!
	[self updateContentOffsetForCurrentDay];
	
	// Scroll to top
	self.webCustomizer.scrollView.contentOffset = CGPointZero;
	
	// Transition to the new date
	UIViewAnimationOptions transition = result == NSOrderedAscending ?
		UIViewAnimationOptionTransitionCurlDown :
		UIViewAnimationOptionTransitionCurlUp;

	transition |= UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionBeginFromCurrentState;
	
	id animations = ^() {
		// Clear the calendar
		[self clearCalendarContents];
		[self hideMessageView];
	
		// Select the new date
		[self selectDate:day];
	};

	id completion = ^(BOOL finished) {
		if(!finished) { return; }

		self.transitioningToNewDay = NO;
		[self updateContentViewAfterEventImportIfNeeded];
	};

	self.transitioningToNewDay = YES;
	[UIView transitionWithView:[self view] duration:0.75 options:transition animations:animations completion:completion];
}

- (IBAction)showToday:(id)sender {
	NSDate* today = [self todayDate];
	[self showDay:today];
}

- (IBAction)showDayPicker:(id)sender {
	[self updateContentOffsetForCurrentDay];

	SDDayPickerViewController* viewController = [SDDayPickerViewController viewController];
	viewController.selectedDay = self.selectedDate;
	[self presentViewController:viewController animated:YES completion:nil];
}

- (IBAction)showArticle:(id)sender {
}

- (IBAction)reload:(id)sender {
	NSDate* date = [self selectedDate];
	
	// Check if we're already importing
	if([self isImportingEventsForDate:date]) {
		return;
	}

	// Did we import before? Delete the events if so.
	SDDay* day = [self dayForDate:date];
	
	if(day) {
		[[self managedObjectContext] deleteObject:day];
	}
	
	[self clearCalendarContents];
	[self hideMessageView];
	[self fadeInCalendarContents];
	
	// Import now
	[self setProgressIndicatorShown:YES animated:YES];
	[self selectDate:date];
}

- (IBAction)copy:(id)sender	{
	NSString* text = [NSString stringWithFormat:NSLocalizedString(@"SHARE_EVENT_FORMATSTRING", nil),
    	[[self metadataForLongPressGesture] objectForKey:@"year"],
        [[self metadataForLongPressGesture] objectForKey:@"content"]];
        
    [[UIPasteboard generalPasteboard] setString:text];
    [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
}

- (BOOL)progressIndicatorShown {
	return _progressIndicatorShown;
}

- (void)setProgressIndicatorShown:(BOOL)progressIndicatorShown {
	[self setProgressIndicatorShown:progressIndicatorShown animated:NO];
}

- (void)setProgressIndicatorShown:(BOOL)progressIndicatorShown animated:(BOOL)animated {
	if(progressIndicatorShown != self.progressIndicatorShown) {
		if(progressIndicatorShown) {
			[self initProgressIndicatorIfNeeded];
		}

		if(animated) {
			[UIView beginAnimations:@"progressIndicatorShownAnimation" context:NULL];
			
			[UIView setAnimationDelay:1.0];
			[UIView setAnimationDuration:0.3];
		}
		
		_progressIndicatorShown = progressIndicatorShown;
		self.progressIndicator.alpha = progressIndicatorShown ? 1.0 : 0.0;

		if(progressIndicatorShown) {
			[[self progressIndicator] startAnimating];
		} else {
			[[self progressIndicator] stopAnimating];
		}
		
		if(animated) {
			[UIView commitAnimations];
		}
	}
}

- (void)presentArticleViewControllerForURL:(NSURL*)URL animated:(BOOL)animated {
	[self updateContentOffsetForCurrentDay];
		
	SDArticleViewController* viewController = [SDArticleViewController viewController];
	[self presentViewController:viewController animated:animated completion:^() {
		[viewController loadArticle:URL];
	}];
}

#pragma mark -
#pragma mark UIResponder

- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent*)event {
	if(motion == UIEventSubtypeMotionShake) {
		_shaking = YES;
	}
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent*)event {
	if(motion == UIEventSubtypeMotionShake) {
		[self reload:nil];
		_shaking = NO;
	}
}

- (void)motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent*)event {
	if(motion == UIEventSubtypeMotionShake) {
		_shaking = NO;
	}
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];
    
    // ...
    [[NSNotificationCenter defaultCenter]
    	addObserver:self
        selector:@selector(applicationDidChangeUserDefaults:)
        name:NSUserDefaultsDidChangeNotification
        object:nil];
	[[NSNotificationCenter defaultCenter]
    	addObserver:self
        selector:@selector(currentLocaleDidChange:)
        name:NSCurrentLocaleDidChangeNotification
        object:nil];
        
    [[NSNotificationCenter defaultCenter]
    	addObserver:self
        selector:@selector(applicationDidBecomeActive:)
        name:UIApplicationDidBecomeActiveNotification
        object:nil];
	
	// ...
	self.view.clipsToBounds = YES;
	self.view.backgroundColor = [UIColor blackColor];
	
	// Make a new Wikipedia API
	self.wikipediaAPI = [[WikipediaAPI alloc] init];
	self.wikipediaAPI.preferredLanguage = [self preferredLanguageCode];
	
	// And make a new operation queue
	self.operationQueue = [[NSOperationQueue alloc] init];
	
	// Register for network reachability events
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(networkReachabilityDidChange:)
		name:SFNetworkReachabilityDidChangeNotification
		object:nil];

	// Init the overlay view
	BOOL isLongPhone = CGRectGetHeight([[UIScreen mainScreen] bounds]) > 480.0;

	NSString* overlayImageName = isLongPhone ?
		@"calendar-568h" :
		@"calendar";
	UIImageView* overlayView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:overlayImageName]];
	self.overlayView = overlayView;
	[[self view] addSubview:overlayView];

	// Init the navigation bar buttons
	SDCalendarNavigationButton* backButton = [SDCalendarNavigationButton calendarButtonWithStyle:SDCalendarButtonStyleDayNavigateBack];

	backButton.frame = [[self backButton] frame];
	backButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin;
	
	[backButton addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];

	self.backButton = backButton;
	[[self view] insertSubview:backButton aboveSubview:overlayView];
	
	SDCalendarNavigationButton* forwardButton = [SDCalendarNavigationButton calendarButtonWithStyle:SDCalendarButtonStyleDayNavigateForward];
	
	forwardButton.frame = [[self forwardButton] frame];
	forwardButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin;
    
	[forwardButton addTarget:self action:@selector(forward:) forControlEvents:UIControlEventTouchUpInside];

	self.forwardButton = forwardButton;
	[[self view] insertSubview:forwardButton aboveSubview:overlayView];

	// Init the title view
	SDCalendarTitleView* titleView = [[SDCalendarTitleView alloc] initWithFrame:CGRectZero];
	self.titleView = titleView;
	[[self view] insertSubview:titleView aboveSubview:overlayView];

	// Load our web view
	UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectZero];

	webView.allowsInlineMediaPlayback = NO;

	if([webView respondsToSelector:@selector(setSuppressesIncrementalRendering:)]) {
		webView.suppressesIncrementalRendering = YES;
	}

	webView.scalesPageToFit = NO;

	webView.scrollView.delegate = self;
	webView.scrollView.scrollsToTop = YES;

	webView.delegate = self;

	self.webView = webView;
	[[self view] insertSubview:webView belowSubview:overlayView];

	NSString* defaultHTMLPath = [[NSBundle mainBundle]
		pathForResource:@"calendar"
		ofType:@"html"];
	NSURLRequest* request = [NSURLRequest
		requestWithURL:[NSURL fileURLWithPath:defaultHTMLPath]];
	[[self webView] loadRequest:request];
	
	self.webView.backgroundColor = [UIColor colorWithRed:0.260 green:0.138 blue:0.098 alpha:1.000];

	UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeCustom];

	[infoButton setImage:[UIImage imageNamed:@"info"] forState:UIControlStateNormal];
	infoButton.showsTouchWhenHighlighted = YES;

	[infoButton addTarget:self action:@selector(showDayPicker:) forControlEvents:UIControlEventTouchUpInside];

	self.infoButton = infoButton;
	[[self view] insertSubview:infoButton aboveSubview:overlayView];

	// ..
	AKWebCustomizer* webCustomizer = [[AKWebCustomizer alloc] initWithWebView:[self webView] delegate:self];
	webCustomizer.documentShadowsShown = YES;
	self.webCustomizer = webCustomizer;

	// Make a new transition view
	NSString* defaultImageName = isLongPhone ?
		@"Default-568h@2x" :
		@"Default";
	NSString* defaultImagePath = [[NSBundle mainBundle] pathForResource:defaultImageName ofType:@"png"];
	UIImage* defaultImage = [UIImage imageWithContentsOfFile:defaultImagePath];
	
	UIImageView* transitionView = [[UIImageView alloc] initWithImage:defaultImage];
	
	CGRect transitionViewRect = self.view.bounds;

	CGFloat statusBarHeight = CGRectGetHeight([[UIApplication sharedApplication] statusBarFrame]);
	transitionViewRect.size.height += statusBarHeight;
	transitionViewRect = CGRectOffset(transitionViewRect, 0.0, -statusBarHeight);

	transitionView.frame = transitionViewRect;

	[[self view] addSubview:transitionView];
	[[self view] bringSubviewToFront:transitionView];

	self.transitionView = transitionView;
	
	// ...
//	[[self backButton] setHidden:YES];
//	[[self forwardButton] setHidden:YES];
//	self.titleView.hidden = YES;
//	self.infoButton.hidden = YES;
}

- (void)viewDidUnload {
	self.webView = nil;
	self.infoButton = nil;
	self.titleView = nil;
	self.backButton = nil;
	self.forwardButton = nil;
	self.progressIndicator = nil;
	self.overlayView = nil;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	[self setProgressIndicatorShown:NO animated:animated];
	// [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	// Make sure to store the content offset
	[self updateContentOffsetForCurrentDay];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return !_shaking && UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];

	CGRect contentRect = self.view.bounds;

	CGFloat const webViewHeight = 81.0;
	self.webView.frame = CGRectMake(
		0.0, webViewHeight,
		CGRectGetWidth(contentRect), (CGRectGetHeight(contentRect) - webViewHeight) + 420.0);

	self.backButton.frame = CGRectMake(
		16.0, 47.0,
		61.0, 30.0);
	self.forwardButton.frame = CGRectMake(
		243.0, 47.0,
		61.0, 30.0);

	self.titleView.frame = CGRectMake(
		80.0, 47.0,
		160.0, 30.0);

	self.infoButton.frame = CGRectMake(
		276.0, CGRectGetHeight(contentRect) - 48.0,
		50.0, 50.0);
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
	NSURL* URL = request.URL;

	if([[URL scheme] isEqualToString:@"file"]) {
		return YES;
	}

	if([[URL scheme] isEqualToString:@"x-onthisday-internal"]) {
		NSString* action = [URL host];
		
		if([action isEqualToString:@"loadMore"]) {
			NSInteger groupID = [[URL query] integerValue];
			[self loadMoreForGroupWithID:groupID];
		}
	}
	
	if([URL isWikipediaURL]) {
		[self presentArticleViewControllerForURL:URL animated:YES];
	}
	
	return NO;
}

- (void)webViewDidStartLoad:(UIWebView*)webView {
}

- (void)webViewDidFinishLoad:(UIWebView*)webView {
	// ...
	[self updateScrollIndicatorForWebView:webView];
	
	// Select the current date
	NSDate* selectedDate = [[NSUserDefaults standardUserDefaults]
		objectForKey:@"SDSelectedDate"];
	
	if(!selectedDate) {
		selectedDate = [self todayDate];
	}

	[self selectDate:selectedDate];

	[self performSelector:@selector(hideTransitionView)
		withObject:nil
		afterDelay:0.5];
}

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error {
}

#pragma mark -
#pragma mark AKWebCustomizer

- (UIView*)webCustomizer:(AKWebCustomizer*)webCustomizer viewForGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer {
	return [self webView];
}

- (void)webCustomizer:(AKWebCustomizer*)webCustomizer shouldPresentURL:(NSURL*)URL options:(NSDictionary*)options {
}

- (void)webCustomizer:(AKWebCustomizer*)webCustomizer shouldPresentSheetForURL:(NSURL*)URL options:(NSDictionary*)options {
}

- (BOOL)webCustomizer:(AKWebCustomizer*)webCustomizer shouldHandleLongPressGesture:(UILongPressGestureRecognizer*)gestureRecognizer {
	NSDictionary* metadata = [self metadataFromItemForGestureRecognizer:gestureRecognizer];
	if(!metadata) { return YES; }

	if([UIActivityViewController class]) {
		NSArray* activityItems = [self activityItemsForMetadata:metadata];
		UIActivityViewController* viewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];

		[self presentViewController:viewController animated:YES completion:nil];
	} else {
		self.metadataForLongPressGesture = metadata;

		UIMenuController* menuController = [UIMenuController sharedMenuController];
    
		CGPoint targetPoint = [gestureRecognizer locationInView:[self view]];
    	[menuController setTargetRect:CGRectMake(targetPoint.x, targetPoint.y - 10.0, 1.0, 1.0) inView:[self view]];
    
    	[menuController setMenuVisible:YES animated:YES];
    }

    return NO;
}

- (NSArray*)activityItemsForMetadata:(NSDictionary*)metadata {
	NSMutableArray* activityItems = [NSMutableArray arrayWithCapacity:3];

	// NSString* text = [self sharingTextForMetadata:metadata characterLimit:NSIntegerMax];
	//if(text.length > 0) { [activityItems addObject:text]; }

	NSString* text = [self sharingTextForMetadata:metadata characterLimit:140]; // always use the Twitter character limit for now
	if(text.length > 0) { [activityItems addObject:text]; }

    NSString* kind = [metadata objectForKey:@"kind"];
    
    if(SFEqualStrings(kind, SDEventGroupKindBirths) || SFEqualStrings(kind, SDEventGroupKindDeaths)) {
    	NSString* URLString = [[metadata objectForKey:@"links"] firstObject];
        
        if(URLString) {
			NSURL* URL = [NSURL URLWithString:URLString];
			if(URL) { [activityItems addObject:URL]; }
        }
    }
    
	return activityItems;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView {
	[[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
}

- (void)scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(BOOL)decelerate {
}

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
	self.progressIndicator.frame = [self messageViewRect];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView*)scrollView {
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView*)scrollView {
	return YES;
}

- (void)scrollViewDidScrollToTop:(UIScrollView*)scrollView {
}

#pragma mark - SFReachabilityDidChangeNotification

- (void)networkReachabilityDidChange:(NSNotification*)notification {
	// Check if we're only again
	SFNetworkReachability* networkReachability = [notification object];
	
	if(networkReachability.currentReachabilityStatus != SFNetworkStatusNotReachable) {
		BOOL messageShown = [[[self webView]
			stringByEvaluatingJavaScriptFromString:@"messageShown();"]
			boolValue];
			
		if(messageShown) {
			// Try to reload
			[self reload:networkReachability];
		}
	}
}

#pragma mark - SDWikipediaEventImporter

- (void)wikipediaEventImporter:(SDWikipediaEventImporter*)importer didFinishWithEventGroups:(NSArray*)eventGroups {
	NSDate* date = importer.userInfo;
	
	NSString* languageCode = self.wikipediaAPI.preferredLanguage;
	NSURL* wikipediaURL = [importer wikipediaURL];
	
	NSManagedObjectContext* managedObjectContext = self.managedObjectContext;
	
	SDDay* day = [SDDay
		dayForDate:date
		language:languageCode
		wikipediaURL:wikipediaURL
		eventGroups:eventGroups
		managedObjectContext:managedObjectContext];
	
	// Now make the changes persistent
	NSError* error = nil;

	if(![managedObjectContext save:&error]) {
		NSLog(@"%@", error);
	}

	// Display if needed
	if([[self selectedDate] isEqual:date]) {
		self.dayNeedingContentUpdate = day;
		[self updateContentViewAfterEventImportIfNeeded];
	}
}

- (void)wikipediaEventImporter:(SDWikipediaEventImporter*)importer didFailWithError:(NSError*)error {
	NSDate* date = importer.userInfo;
	
	if([[self selectedDate] isEqual:date]) {
		// TODO Oh noes!!!
		if(self.progressIndicatorShown) {
			[self setProgressIndicatorShown:NO animated:YES];
		}

		[self showErrorIfNeeded:error];
		[self fadeInCalendarContents];
	}
}

#pragma mark -
#pragma mark Private

- (void)initProgressIndicatorIfNeeded {
	if(!self.progressIndicator) {
		BOOL animationsEnabled = [UIView areAnimationsEnabled];
		
		[UIView setAnimationsEnabled:NO]; {

			NSInteger numberOfImages = 11;
			NSMutableArray* images = [NSMutableArray arrayWithCapacity:numberOfImages];
			
			for(NSInteger imageIndex=0; imageIndex<numberOfImages; ++imageIndex) {
				UIImage* image = [UIImage imageNamed:
					[NSString stringWithFormat:@"spinner%i.png", imageIndex]];
				[images addObject:image];
			}
			
			UIImageView* progressIndicator = [[UIImageView alloc] initWithImage:nil];
			
			progressIndicator.alpha = 0.0;
			
			progressIndicator.frame = [self messageViewRect];
			progressIndicator.animationImages = images;
			
			progressIndicator.animationDuration = 1.5;
			
			progressIndicator.contentMode = UIViewContentModeScaleAspectFit;
			
			[[self view] insertSubview:progressIndicator belowSubview:[self overlayView]];
			
			self.progressIndicator = progressIndicator;
		
		} [UIView setAnimationsEnabled:animationsEnabled];
	}
}

- (CGRect)messageViewRect {
	CGRect rect = CGRectMake(124.0, 219.0, 72.0, 72.0);
	
	rect = CGRectOffset(rect, 0.0, -self.webCustomizer.scrollView.contentOffset.y);
	
	return rect;
}

- (void)showErrorIfNeeded:(NSError*)error {
	if(error) {
		NSString* javascript = nil;
		
		BOOL isNotConnectedError = error.domain == NSURLErrorDomain &&
			error.code == NSURLErrorNotConnectedToInternet;
		
		if(isNotConnectedError) {
			javascript = [NSString stringWithFormat:@"showNetworkError('%@', '%@')",
				NSLocalizedString(@"NONETWORK_ERROR_TEXT", @""),
				NSLocalizedString(@"NONETWORK_ERROR_HINT", @""),
				nil];
		} else {
			javascript = [NSString stringWithFormat:@"showMessage('%@', '%@')",
				NSLocalizedString(@"GENERIC_ERROR_TEXT", @""),
				NSLocalizedString(@"GENERIC_ERROR_HINT", @""),
				nil];
		}

		[[self webView] stringByEvaluatingJavaScriptFromString:javascript];
	} else {
		[self hideMessageView];
	}
}

- (void)hideMessageView {
	[[self webView] stringByEvaluatingJavaScriptFromString:@"hideMessage();"];
}

- (void)updateContentOffsetForCurrentDay {
	// First store the content offet for the current date
	if(self.selectedDate) {
		CGPoint contentOffset = self.webCustomizer.scrollView.contentOffset;
	
		SDDay* currentDay = [self dayForDate:[self selectedDate]];
		currentDay.contentOffset = [NSNumber numberWithDouble:contentOffset.y];
	}
}

- (void)updateContentViewAfterEventImportIfNeeded {
	if(self.transitioningToNewDay) { return; }
	if(!self.dayNeedingContentUpdate) { return; }

	[self setProgressIndicatorShown:NO animated:YES];

	[self updateWithDay:[self dayNeedingContentUpdate]];
	[self fadeInCalendarContents];

	self.dayNeedingContentUpdate = nil;
}

- (void)selectDate:(NSDate*)date {
	// Store the new date in user defaults
	[[NSUserDefaults standardUserDefaults]
		setObject:date forKey:@"SDSelectedDate"];

	// Update the selected date
	self.selectedDate = date;
	
	// Update the title view
	self.titleView.date = date;
	
	NSCalendar* gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	
	// Update the previous date
	NSDateComponents* dayBackComponent = [[NSDateComponents alloc] init];
	
	[dayBackComponent setDay:-1];
	
	self.previousDate = [gregorian dateByAddingComponents:dayBackComponent
		toDate:date
		options:0];
	
	// Update the next date
	NSDateComponents* dayForwardComponent = [[NSDateComponents alloc] init];
	
	[dayForwardComponent setDay:1];
	
	self.nextDate = [gregorian dateByAddingComponents:dayForwardComponent
		toDate:date
		options:0];
	
	// Update the back/forward buttons
	[[self backButton] setDate:[self previousDate]];
	[[self forwardButton] setDate:[self nextDate]];
	
	// Check if we already imported event data for this day
	SDDay* day = [self dayForDate:date];
	
	if(day) {
		[self updateWithDay:day];
		
		// Update the content offset. Make sure not to animate this change.
		BOOL animationsEnabled = [UIView areAnimationsEnabled];
		
		[UIView setAnimationsEnabled:NO]; {
			
			CGPoint newContentOffset = CGPointMake(0.0, day.contentOffset.floatValue);
			self.webCustomizer.scrollView.contentOffset = newContentOffset;
		
		} [UIView setAnimationsEnabled:animationsEnabled];
	} else {
		[self setProgressIndicatorShown:YES animated:YES];
	
		// First check if a operation for this date is already running
		if([self isImportingEventsForDate:date]) {
			return;
		}
		
		// Load all events for this date
		[self importForDate:date];
	}
}

- (void)updateWithDay:(SDDay*)day {
	// Hide the progress indicator
	[self setProgressIndicatorShown:NO animated:NO];
	
	// Clear the previous content first
//	[self clearCalendarContents];
	
	// Load all groups
	NSArray* groups = day.groups.allObjects;
	groups = [groups sortedArrayUsingDescriptors:[NSArray arrayWithObjects:
		[[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:YES],
		nil]];
    
    // Filter out by user defaults hidden groups
    NSMutableArray* filteredGroups = [NSMutableArray arrayWithCapacity:[groups count]];
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    for(SDEventGroup* eventGroup in groups) {
    	if(SFEqualStrings([eventGroup kind], SDEventGroupKindEvents) && [userDefaults boolForKey:@"SDEventsShown"]) {
        	[filteredGroups addObject:eventGroup];
        }
        
        if(SFEqualStrings([eventGroup kind], SDEventGroupKindBirths) && [userDefaults boolForKey:@"SDBirthsShown"]) {
        	[filteredGroups addObject:eventGroup];
        }
        
        if(SFEqualStrings([eventGroup kind], SDEventGroupKindDeaths) && [userDefaults boolForKey:@"SDDeathsShown"]) {
        	[filteredGroups addObject:eventGroup];
        }
    }
    
    if(filteredGroups.count > 0) {
    	groups = filteredGroups;
    }
    
    // fetch events
	NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
	
	NSEntityDescription* entity = [NSEntityDescription
		entityForName:@"Event"
		inManagedObjectContext:[self managedObjectContext]];
	[fetchRequest setEntity:entity];
    
    BOOL orderAscending = SFEqualStrings([userDefaults stringForKey:@"SDEventSortOrder"], @"ascending");

	[fetchRequest setSortDescriptors:[NSArray arrayWithObjects:
		[[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:orderAscending],
		nil]];
		
	[fetchRequest setFetchOffset:0];
	
	NSMutableString* contentMarkup = [NSMutableString string];
	
	for(SDEventGroup* group in groups) {
			NSString* groupMarkup = [NSString stringWithFormat:
				@"<div id=\\'group-%@\\' class=\\'event-group\\' kind=\\'%@\\'><h2>%@</h2><ul>",
				group.sortOrder,
                group.kind,
				group.title];
			
			NSPredicate* predicate = [NSPredicate
				predicateWithFormat:@"group == %@", group];
			[fetchRequest setPredicate:predicate];
			
			NSInteger fetchOffset = [[group fetchOffset] integerValue];
			
			if(fetchOffset > 0) {
				[fetchRequest setFetchLimit:fetchOffset];
			} else {
				BOOL isLongPhone = CGRectGetHeight([[UIScreen mainScreen] bounds]) > 480.0;
				NSInteger initialLimit = isLongPhone ? 5 : 3;

				NSInteger limit = [groups count] == 1 ?
                	30 :
                    initialLimit;
				[fetchRequest setFetchLimit:limit];
			}
			
			NSError* error = nil;
			NSArray* fetchResults = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
			
			if(error) {
				NSLog(@"%@", error);
			}
			
			for(SDEvent* event in fetchResults) {
				NSString* markup = [self markupForEvent:event];
				groupMarkup = [groupMarkup stringByAppendingString:markup];
			}
			
			// Add the load more element if needed
			if(fetchResults.count != group.events.count) {
				NSString* moreLabel = [NSString stringWithFormat:
					NSLocalizedString(@"LOAD_%@_MORE_LABEL", @""),
					[NSNumber numberWithInteger:group.events.count - fetchResults.count]];
				groupMarkup = [groupMarkup stringByAppendingFormat:
					@"<li class=\\'more\\'><a href=\\'x-onthisday-internal://loadMore?%@\\'>%@</a></li>",
					group.sortOrder,
					moreLabel];
			}
			
			groupMarkup = [groupMarkup stringByAppendingString:@"</ul></div>"];
			[contentMarkup appendString:groupMarkup];
	}
	
	[[self webView] stringByEvaluatingJavaScriptFromString:
		[NSString stringWithFormat:@"document.getElementById('calendar').innerHTML = '%@'", contentMarkup]];
}

- (void)fadeInCalendarContents {
	if(!self.transitionView) {
		CATransition* transition = [CATransition animation];
		transition.duration = 0.4;
		transition.type = kCATransitionFade;
		transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
		[[[self view] layer] addAnimation:transition forKey:@"fadeInCalendarContentsAnimation"];
	}
}

- (void)clearCalendarContents {
	[[self webView] stringByEvaluatingJavaScriptFromString:
		@"document.getElementById('calendar').innerHTML = '';"];
	self.webCustomizer.scrollView.contentOffset = CGPointZero;
}

- (SDDay*)dayForDate:(NSDate*)date {
	NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
	
	NSEntityDescription* entity = [NSEntityDescription
		entityForName:@"Day"
		inManagedObjectContext:[self managedObjectContext]];
	[fetchRequest setEntity:entity];
	
	NSDateComponents* dateComponents = [[NSCalendar currentCalendar]
		components:NSMonthCalendarUnit|NSDayCalendarUnit
		fromDate:date];
	
	NSPredicate* predicate = [NSPredicate
		predicateWithFormat:@"calendarDay == %i && calendarMonth == %i && language == %@",
			[dateComponents day],
			[dateComponents month],
			[[self wikipediaAPI] preferredLanguage]];
	[fetchRequest setPredicate:predicate];
	
	[fetchRequest setFetchLimit:1];
	
	NSError* error = nil;
	NSArray* fetchResults = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
	
	if(error) {
		NSLog(@"%@", error);
	}
	
	return [fetchResults firstObject];
}

- (void)importForDate:(NSDate*)date {
	NSURL* eventURL = [[self wikipediaAPI] eventURLForDate:date];
	
	SDWikipediaEventImporter* importer = [SDWikipediaEventImporter eventImporterForURL:eventURL];
	
	importer.delegate = self;
	importer.userInfo = date;
	
	[[self operationQueue] addOperation:importer];
}

- (BOOL)isImportingEventsForDate:(NSDate*)date {
	for(SDWikipediaEventImporter* importer in self.operationQueue.operations) {
		if([importer isKindOfClass:[SDWikipediaEventImporter class]] && [[importer userInfo] isEqual:date]) {
			return YES;
		}
	}
	
	return NO;
}

- (void)loadMoreForGroupWithID:(NSInteger)groupID {
	// NSLog(@"load more for group %i", groupID);
	
	NSString* javascript = [NSString stringWithFormat:@"getEventCount('%i')", groupID];
	NSInteger numberOfEvents = [[[self webView]
		stringByEvaluatingJavaScriptFromString:javascript]
		integerValue];
		
	SDDay* day = [self dayForDate:[self selectedDate]];
	
	NSArray* groups = day.groups.allObjects;
	groups = [groups sortedArrayUsingDescriptors:[NSArray arrayWithObjects:
		[[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:YES],
		nil]];
		
	NSInteger groupIndex = MAX(groupID - 1, 0);
		
	if(groupIndex >= 0 && groups.count > groupIndex) {
		SDEventGroup* group = [groups objectAtIndex:groupIndex];
		
		NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
	
		NSEntityDescription* entity = [NSEntityDescription
			entityForName:@"Event"
			inManagedObjectContext:[self managedObjectContext]];
		[fetchRequest setEntity:entity];
		
		NSPredicate* predicate = [NSPredicate
			predicateWithFormat:@"group == %@", group];
		[fetchRequest setPredicate:predicate];
        
        BOOL orderAscending = SFEqualStrings([[NSUserDefaults standardUserDefaults] stringForKey:@"SDEventSortOrder"], @"ascending");

		[fetchRequest setSortDescriptors:[NSArray arrayWithObjects:
			[[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:orderAscending],
			nil]];

		[fetchRequest setFetchOffset:numberOfEvents];
		[fetchRequest setFetchLimit:35];
		
		NSArray* events = [[self managedObjectContext] executeFetchRequest:fetchRequest error:nil];
		
		NSString* eventMarkup = @"";
		
		for(SDEvent* event in events) {
			NSString* markup = [self markupForEvent:event];
			eventMarkup = [eventMarkup stringByAppendingString:markup];
		}
		
		javascript = [NSString stringWithFormat:@"addEvent('%i', '%@')", groupID, eventMarkup];
		[[self webView] stringByEvaluatingJavaScriptFromString:javascript];
		
		javascript = [NSString stringWithFormat:@"getEventCount('%i')", groupID];
		NSInteger eventCount = [[[self webView] stringByEvaluatingJavaScriptFromString:javascript] integerValue];
		
		group.fetchOffset = [NSNumber numberWithInteger:eventCount];
		
		// NSLog(@"%i of %i", eventCount, group.events.count);
		
		if(eventCount >= group.events.count) {
			javascript = [NSString stringWithFormat:@"hideMoreElement('%i')", groupID];
			[[self webView] stringByEvaluatingJavaScriptFromString:javascript];
		} else {
			NSString* moreLabel = [NSString stringWithFormat:
				NSLocalizedString(@"LOAD_%@_MORE_LABEL", @""),
				[NSNumber numberWithInteger:group.events.count - eventCount]];
			javascript = [NSString stringWithFormat:@"setMoreElementLabel('%i', '%@')", groupID, moreLabel];
			[[self webView] stringByEvaluatingJavaScriptFromString:javascript];
		}
	}
}

- (NSString*)markupForEvent:(SDEvent*)event {
	NSString* markup = nil;
	
//	if(event.compressedMarkup) {
//		NSData* markupData = [[event compressedMarkup] decompressUsingGZIP];
//		markup = [[[NSString alloc] initWithData:markupData encoding:NSUTF8StringEncoding] autorelease];
//	} else {
		markup = event.markup;
//	}

	markup = [markup stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
	markup = [markup stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	
	return markup;
}

- (void)hideTransitionView {
	// Unhide the webview and remove our transition view
	if(self.transitionView) {
		// Fade in
		CATransition* transition = [CATransition animation];
		transition.duration = 0.4;
		transition.type = kCATransitionFade;
		transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
		[[[self view] layer] addAnimation:transition forKey:@"fadeInAnimation"];
		
		[[self transitionView] removeFromSuperview];
		self.transitionView = nil;
	}
}

- (CGRect)scrollIndicatorRect {
	return CGRectMake(298.0, 2.0, 10.0, 300);
}

- (void)updateScrollIndicatorForWebView:(UIWebView*)webView {
	self.webCustomizer.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(
		2.0,
		0.0,
		498.0,
		10.0);
}

- (NSDate*)todayDate {
	// Retrieve the current date. Make sure it's a leap year to include February 29.
	NSDate* today = [NSDate date];
	NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		
	NSDateComponents* dateComponents = [calendar components:NSDayCalendarUnit|NSMonthCalendarUnit fromDate:today];
		
	[dateComponents setSecond:0];
	[dateComponents setMinute:0];
	[dateComponents setHour:0];
	[dateComponents setYear:2012]; // 2012 is a leap year

	return [calendar dateFromComponents:dateComponents];
}

- (NSString*)preferredLanguageCode {
	NSString* preferredLanguageCode = [[NSUserDefaults standardUserDefaults] stringForKey:@"SDPreferredLanguage"];
    
    if(SFEqualStrings(preferredLanguageCode, @"automatic")) { preferredLanguageCode = [[NSLocale autoupdatingCurrentLocale] preferredLanguageCode]; }
    if(preferredLanguageCode.length <= 0) { preferredLanguageCode = @"en"; } // defaults to english
    
	return preferredLanguageCode;
}

- (void)applicationDidChangeUserDefaults:(NSNotification*)notification {
	BOOL needsReload = NO;
    BOOL needsWebviewReload = NO;
    
    //
    NSArray* displayRelatedUserDefaultKeys = [NSArray arrayWithObjects:
        @"SDEventsShown",
        @"SDBirthsShown",
        @"SDDeathsShown",
        @"SDEventSortOrder",
        nil];
            
    NSDictionary* newDisplayRelatedUserDefaults = [self userDefaultsForKeys:displayRelatedUserDefaultKeys];
    
    if(self.displayRelatedUserDefaults) {
    	needsWebviewReload = ![[self displayRelatedUserDefaults] isEqualToDictionary:newDisplayRelatedUserDefaults];
    }
    
    self.displayRelatedUserDefaults = newDisplayRelatedUserDefaults;
    
    // Preferred Language Change?
    NSString* preferredLanguageCode = [self preferredLanguageCode];
    if(!SFEqualStrings(preferredLanguageCode, [[self wikipediaAPI] preferredLanguage])) {
        self.wikipediaAPI.preferredLanguage = preferredLanguageCode;
        needsReload = YES;
    }
    
    if(needsReload) {
    	[self reload:nil];
        return;
    }
    
    if(needsWebviewReload) {
    	[self selectDate:[self selectedDate]];
    }
}

- (void)currentLocaleDidChange:(NSNotification*)notification {
	[self applicationDidChangeUserDefaults:nil];
}

- (void)applicationDidBecomeActive:(NSNotification*)notification {
	[self updateMenuItems];
}

- (NSDictionary*)userDefaultsForKeys:(NSArray*)keys {
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    for(id key in keys) {
    	id value = [userDefaults objectForKey:key];
        if(value) {
        	[dictionary setObject:value forKey:key];
        }
    }
    
    return dictionary;
}

- (NSDictionary*)metadataFromItemForGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer {
	CGPoint point = [gestureRecognizer locationInView:[self webView]];
    
    NSString* javascript = [NSString stringWithFormat:@"getMetadataFromElementAtPoint(%0.1f, %0.1f)", point.x, point.y];
    
    NSString* metadataString = [[self webView] stringByEvaluatingJavaScriptFromString:javascript];
    if(metadataString.length == 0) { return nil; }
    
    NSError* error = nil;
    
	id metadata = [NSJSONSerialization
    	JSONObjectWithData:[metadataString dataUsingEncoding:NSUTF8StringEncoding]
        options:NSJSONReadingAllowFragments
        error:&error];
    if(error) {
    	NSLog(@"Could not read metadata string: %@", error);
    }
    
	if(![metadata isKindOfClass:[NSDictionary class]]) { return nil; }
     
    metadata = [NSMutableDictionary dictionaryWithDictionary:metadata];
    [metadata setObject:[self selectedDate] forKey:@"date"];

	return metadata;
}

- (void)updateMenuItems {
}

- (NSString*)sharingTextForMetadata:(NSDictionary*)metadata characterLimit:(NSInteger)characterLimit {
	NSBundle* languageBundle = [self preferredLanguageBundle];
    
    NSDate* date = [metadata objectForKey:@"date"];
    NSString* year = [metadata objectForKey:@"year"];
     
    NSString* dateHashTag = nil;
    
    if([date isEqualToDate:[self todayDate]]) {
		dateHashTag = [languageBundle localizedStringForKey:@"ONTHISDAY_HASHTAG" value:@"" table:nil];

        if(year) {
        	dateHashTag = [NSString stringWithFormat:@"%@ %@", dateHashTag, year];
        }
	} else {
    	NSCharacterSet* noneDigitsCharacters = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
        NSRange lettersRange = [year rangeOfCharacterFromSet:noneDigitsCharacters options:0];
        
        BOOL hasNumericYear = lettersRange.location == NSNotFound;
        
        if(hasNumericYear) {
        	NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        
        	NSDateComponents* dateComponents = [calendar components:NSDayCalendarUnit|NSMonthCalendarUnit fromDate:date];
        	dateComponents.year = [year integerValue];
        
    		date = [calendar dateFromComponents:dateComponents];
        }
        
        NSString* languageCode = self.wikipediaAPI.preferredLanguage;
    	NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:languageCode];

        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
		
        [dateFormatter setLocale:locale];
        
        if(hasNumericYear) {
			NSString* dateFormat = [NSDateFormatter dateFormatFromTemplate:@"dd.MM.y" options:0 locale:locale];
        	[dateFormatter setDateFormat:dateFormat];
            
            dateHashTag = [dateFormatter stringFromDate:date];
		} else {
        	NSString* dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MMM d" options:0 locale:locale];
        	[dateFormatter setDateFormat:dateFormat];
        
        	dateHashTag = [NSString stringWithFormat:@"%@ %@", [dateFormatter stringFromDate:date], year];
        }
    }
    
    NSString* text = [NSString stringWithFormat:[languageBundle localizedStringForKey:@"SHARE_EVENT_FORMATSTRING" value:@"" table:nil],
    	dateHashTag, // [metadata objectForKey:@"year"],
        [metadata objectForKey:@"content"]];
    
    NSString* kind = [metadata objectForKey:@"kind"];
    NSString* groupHashTag = nil;
    
    if(SFEqualStrings(kind, SDEventGroupKindBirths)) {
    	groupHashTag = [languageBundle localizedStringForKey:@"BORN_ONTHISDAY_HASHTAG" value:@"" table:nil];
    }
    
    if(SFEqualStrings(kind, SDEventGroupKindDeaths)) {
    	groupHashTag = [languageBundle localizedStringForKey:@"DIED_ONTHISDAY_HASHTAG" value:@"" table:nil];
    }
    
    if(groupHashTag) {
    	if(text.length + groupHashTag.length + 1 <= characterLimit) {
    		text = [[groupHashTag stringByAppendingString:@" "] stringByAppendingString:text];
		}
    }
    
    if(text.length > characterLimit) {
    	text = [[text substringToIndex:characterLimit - 1] stringByAppendingString:@"…"];
    }
    
    return text;
}

- (NSBundle*)preferredLanguageBundle {
	NSString* languageCode = self.wikipediaAPI.preferredLanguage;
	NSString* currentLanguageCode = [[NSLocale autoupdatingCurrentLocale] preferredLanguageCode];
    
    if(SFEqualStrings(languageCode, currentLanguageCode)) {
    	return [NSBundle mainBundle];
    }
    
    NSURL* languageBundleURL = [[NSBundle mainBundle]
    	URLForResource:languageCode
        withExtension:@"lproj"];
    
    NSBundle* languageBundle = [NSBundle bundleWithURL:languageBundleURL];
    
    return languageBundle;
}

@end
