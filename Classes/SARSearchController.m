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

#import "SARSearchController.h"

#import "SASearchBar+Private.h"
#import "SASearchDisplayPopoverContentViewController.h"

#import "WikipediaPicker.h"

NSString* const SASearchControllerTitleMatchingEnabledDefaultsKey = @"SARTitleMatchingEnabled";

@interface SARSearchController()<UITextFieldDelegate, UIPopoverControllerDelegate>

@property(nonatomic, strong) SASearchBar* searchBar;
@property(nonatomic, weak) UIViewController* containerViewController;

@property(nonatomic, strong) UIView* overlayView;
@property(nonatomic, strong) ARKSearchTableViewController* searchTableViewController;
@property(nonatomic, readwrite, strong) UIPopoverController* contentPopoverController;

@property(nonatomic) UIViewAnimationCurve preferredAnimationCurve;
@property(nonatomic) NSTimeInterval preferredAnimationDuration;

@property(nonatomic) CGRect keyboardFrame;

@property(nonatomic, strong) WIKMediaWiki* mediaWiki;

@end

@implementation SARSearchController

@dynamic searchText;

#pragma mark - Construction & Destruction

- (id)initWithSearchBar:(SASearchBar*)searchBar containerViewController:(UIViewController*)containerViewController {
	if((self = [super init])) {
		self.preferredAnimationCurve = UIViewAnimationCurveEaseInOut;
		self.preferredAnimationDuration = 0.25;

		self.keyboardFrame = CGRectZero;

		self.searchBar = searchBar;
		[self initSearchBarObservers];
		
		self.containerViewController = containerViewController;
		[self addObserver:self forKeyPath:@"containerViewController.view.frame" options:0 context:NULL];

		[self initKeyboardObservers];
		[self initStatusBarObservers];

		self.titleMatchingEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:SASearchControllerTitleMatchingEnabledDefaultsKey];
	}

	return self;
}

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"containerViewController.view.frame" context:NULL];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - SASearchController

- (void)setDelegate:(id<SASearchControllerDelegate>)delegate {
	_delegate = delegate;
	self.searchTableViewController.delegate = delegate;
}

- (void)setActive:(BOOL)active {
	[self setActive:active animated:NO completion:nil];
}

- (void)setActive:(BOOL)active animated:(BOOL)animated completion:(void (^)(void))completion {
	if(self.active == active) { return; }

	[self initOverlayViewIfNeeded];

	if(active) {
		[self initSearchTableViewControllerIfNeeded];
		[self updateSearchBar];
	}

	[self willTransitionToState:active];

	id privateCompletion = ^() {
		[self didTransitionToState:active];
		if(completion) { completion(); }
	};

	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self setPopoverStyleActive:active animated:animated completion:privateCompletion];
	} else {
		[self setEmbeddedStyleActive:active animated:animated completion:privateCompletion];
	}
}

- (NSString*)searchText {
	return self.searchTableViewController.searchText;
}

- (void)setSearchText:(NSString*)searchText {
	if([[self searchText] isEqualToString:searchText]) { return; }

	self.searchTableViewController.searchText = searchText;
	self.searchBar.searchText = searchText;
}

- (void)setTitleMatchingEnabled:(BOOL)titleMatchingEnabled {
	if(self.titleMatchingEnabled == titleMatchingEnabled) { return; }

	_titleMatchingEnabled = titleMatchingEnabled;
	self.searchTableViewController.titleMatchingEnabled = titleMatchingEnabled;

	[[NSUserDefaults standardUserDefaults] setBool:titleMatchingEnabled forKey:SASearchControllerTitleMatchingEnabledDefaultsKey];
}

- (void)setMediaWikiLanguageCode:(NSString*)mediaWikiLanguageCode {
	if([mediaWikiLanguageCode isEqualToString:[self mediaWikiLanguageCode]]) { return; }

	_mediaWikiLanguageCode = [mediaWikiLanguageCode copy];
	self.mediaWiki = [WIKMediaWiki mediaWikiForWikipediaSubdomain:mediaWikiLanguageCode];

	[self updateSearchBar];
	[self updateSearchTableViewController];
}

#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
	[self layoutContentViewsIfNeeded];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField*)textField {
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField*)textField {
	[self setActive:YES animated:YES completion:nil];
}

- (BOOL)textFieldShouldEndEditing:(UITextField*)textField {
	return YES;
}

- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string {
	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField*)textField {
	[self searchBarTextDidChange:nil];
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
	if(textField.text.length > 0) {
		[textField resignFirstResponder];
	} else {
		[self deactivate:textField forEvent:nil];
	}

	return YES;
}

#pragma mark - UIPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController*)popoverController {
	[self setActive:NO animated:YES completion:nil];
	return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController*)popoverController {
}

#pragma mark - Searchfield Notifications

- (void)searchBarTextDidChange:(NSNotification*)notification {
	NSString* searchText = self.searchBar.text;

	self.searchBar.searchText = searchText; // workaround
	self.searchTableViewController.searchText = searchText;

	[self layoutContentViews];
}

#pragma mark - Keyboard Notifications

- (void)keyboardWillChangeFrame:(NSNotification*)notification {
	self.preferredAnimationCurve = [[[notification userInfo]
		objectForKey:UIKeyboardAnimationCurveUserInfoKey]
		unsignedIntegerValue];
	self.preferredAnimationDuration = [[[notification userInfo]
		objectForKey:UIKeyboardAnimationDurationUserInfoKey]
		doubleValue];
}

- (void)keyboardDidChangeFrame:(NSNotification*)notification {
}

- (void)keyboardWillShow:(NSNotification*)notification {
}

- (void)keyboardDidShow:(NSNotification*)notification {
	self.keyboardFrame = [[[notification userInfo]
		objectForKey:UIKeyboardFrameEndUserInfoKey]
		CGRectValue];
	[self layoutContentViews];
}

- (void)keyboardWillHide:(NSNotification*)notification {
}

- (void)keyboardDidHide:(NSNotification*)notification {
	self.keyboardFrame = CGRectZero;
	[self layoutContentViews];
}

#pragma mark - Application Notifications

- (void)applicationDidChangeStatusBarOrientation:(NSNotification*)notification {
	[self layoutContentViewsIfNeeded];
}

#pragma mark - Private

- (void)initOverlayViewIfNeeded {
	if(self.overlayView) { return; }
	if(UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone) { return; }

	UIView* containerView = self.containerViewController.view;
	UIControl* overlayView = [[UIControl alloc] initWithFrame:[containerView bounds]];
		
	overlayView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
	overlayView.alpha = 0.0;
	overlayView.opaque = NO;

	overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;

	[overlayView
		addTarget:self
		action:@selector(deactivate:forEvent:)
		forControlEvents:UIControlEventTouchDown];

	[overlayView setIsAccessibilityElement:NO];
		
	self.overlayView = overlayView;
}

- (void)initSearchTableViewControllerIfNeeded {
	if(self.searchTableViewController) { return; }

	ARKSearchTableViewController* searchTableViewController;

	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		SASearchDisplayPopoverContentViewController* popoverContentViewController = [[SASearchDisplayPopoverContentViewController alloc] init];
		searchTableViewController = popoverContentViewController;

		[popoverContentViewController view]; // Make sure the scope bar and callout button are loaded

		[[popoverContentViewController scopeBar]
			addTarget:self
			action:@selector(searchScopeDidChange:forEvent:)
			forControlEvents:UIControlEventValueChanged];
		[[popoverContentViewController calloutButton]
			addTarget:self
			action:@selector(calloutButtonTapped:forEvent:)
			forControlEvents:UIControlEventTouchUpInside];
	} else {
		searchTableViewController = [[ARKSearchTableViewController alloc] init];
	}

	searchTableViewController.delegate = self.delegate;

	self.searchTableViewController = searchTableViewController;
	[self updateSearchTableViewController];
	[self updateSearchBar];
}

- (void)initSearchBarObservers {
	SASearchBar* searchBar = self.searchBar;

	searchBar.searchField.delegate = self;

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(searchBarTextDidChange:)
		name:UITextFieldTextDidChangeNotification
		object:[searchBar searchField]];

	[[searchBar accessoryView]
		addTarget:self
		action:@selector(accessoryControlTapped:forEvent:)
		forControlEvents:UIControlEventTouchUpInside];

	if(UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone) { return; }

	// iPhone only
	[[searchBar scopeBar]
		addTarget:self
		action:@selector(searchScopeDidChange:forEvent:)
		forControlEvents:UIControlEventValueChanged];
	[[searchBar scopeBar]
		addTarget:self
		action:@selector(calloutButtonTapped:forEvent:)
		forControlEvents:SAScopeBarEventTouchUpInsideCalloutButton];	
	[[searchBar calloutButton]
		addTarget:self
		action:@selector(calloutButtonTapped:forEvent:)
		forControlEvents:UIControlEventTouchUpInside];
	[[searchBar cancelButton]
		addTarget:self
		action:@selector(deactivate:forEvent:)
		forControlEvents:UIControlEventTouchUpInside];
}

- (void)initKeyboardObservers {
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(keyboardWillChangeFrame:)
		name:UIKeyboardWillChangeFrameNotification
		object:nil];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(keyboardDidChangeFrame:)
		name:UIKeyboardDidChangeFrameNotification
		object:nil];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(keyboardWillShow:)
		name:UIKeyboardWillShowNotification
		object:nil];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(keyboardDidShow:)
		name:UIKeyboardDidShowNotification
		object:nil];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(keyboardWillHide:)
		name:UIKeyboardWillHideNotification
		object:nil];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(keyboardDidHide:)
		name:UIKeyboardDidHideNotification
		object:nil];
}

- (void)initStatusBarObservers {
	if(UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone) { return; }

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(applicationDidChangeStatusBarOrientation:)
		name:UIApplicationDidChangeStatusBarOrientationNotification
		object:nil];
}

#pragma mark -

- (void)setEmbeddedStyleActive:(BOOL)active animated:(BOOL)animated completion:(void (^)(void))completion {
	void (^containmentCompletion)(void) = [self presentOrDismissSearchTableViewControllerForStateIfNeeded:active animated:animated];

	[self layoutContentViews];
	_active = active;

	id animations = ^() {
		SASearchBar* searchBar = self.searchBar;

		if(active) {
			[[searchBar searchField] becomeFirstResponder];
		} else {
			[[searchBar searchField] endEditing:YES];
		}

		[searchBar setActive:active animated:animated];
		[self layoutContentViews];
	};

	id privateCompletion = ^(BOOL finished) {
		if(!finished) { return; }
		if(containmentCompletion) { containmentCompletion(); }
		if(completion) { completion(); }
	};

	if(!animated) {
		if(containmentCompletion) { containmentCompletion(); }
		if(completion) { completion(); }

		return;
	}

	NSTimeInterval duration = self.preferredAnimationDuration;
	UIViewAnimationOptions options = [self animationOptionsFromAnimationCurve:[self preferredAnimationCurve]];

	[UIView
		animateWithDuration:duration
		delay:0.0
		options:UIViewAnimationOptionBeginFromCurrentState|options
		animations:animations
		completion:privateCompletion];
}

- (UIViewAnimationOptions)animationOptionsFromAnimationCurve:(UIViewAnimationCurve)animationCurve {
	if(animationCurve == UIViewAnimationCurveEaseInOut) { return UIViewAnimationOptionCurveEaseInOut; }
	if(animationCurve == UIViewAnimationCurveEaseIn) { return UIViewAnimationOptionCurveEaseIn; }
	if(animationCurve == UIViewAnimationCurveEaseOut) { return UIViewAnimationOptionCurveEaseOut; }
	return UIViewAnimationOptionCurveLinear;
}

#pragma mark -

- (void)setPopoverStyleActive:(BOOL)active animated:(BOOL)animated completion:(void (^)(void))completion {
	[self initSearchTableViewControllerIfNeeded];
	ARKSearchTableViewController* searchTableViewController = self.searchTableViewController;

	UIPopoverController* contentPopoverController = self.contentPopoverController;

	if(!contentPopoverController) {
		UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:searchTableViewController];
		contentPopoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
		self.contentPopoverController = contentPopoverController;
	}

	_active = active;

	SASearchBar* searchBar = self.searchBar;

	if(active) {
		contentPopoverController.passthroughViews = @[ searchBar ];
		contentPopoverController.delegate = self;

		[contentPopoverController presentPopoverFromRect:[searchBar bounds] inView:searchBar permittedArrowDirections:UIPopoverArrowDirectionAny animated:animated];

		[[searchBar searchField] becomeFirstResponder];
	} else {
		[contentPopoverController dismissPopoverAnimated:animated];
		[[searchBar searchField] endEditing:YES];
	}

	[searchBar setActive:active animated:animated];

	// call completion directly even when animating
	// since there are no completion on UIPopover available
	if(completion) { completion(); }
}

#pragma mark -

- (void)layoutContentViewsIfNeeded {
	[self layoutContentViews];
}

- (void)layoutContentViews {
	BOOL active = self.active;

	UIView* containerView = self.containerViewController.view;
	CGRect containerViewRect = containerView.bounds;

	SASearchBar* searchBar = self.searchBar;

	UIView* overlayView = self.overlayView;

	overlayView.alpha = active ? 1.0 : 0.0;
	overlayView.hidden = [self hasSearchText];

	overlayView.frame = containerViewRect;

	[containerView insertSubview:overlayView belowSubview:searchBar];

	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		CGRect searchBarRect = searchBar.frame;
	
		CGSize searchBarSize = [searchBar sizeThatFits:containerViewRect.size];
		searchBarRect.size = searchBarSize;
		searchBar.frame = searchBarRect;

		searchBar.clipsToBounds = !active;
	}

	[self layoutSearchTableView];
}

- (void)layoutSearchTableView {
	if(!self.searchTableViewController) { return; }
	if(![[self searchTableViewController] isViewLoaded]) { return; }
	if(UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone) { return; }

	UITableView* searchTableView = self.searchTableViewController.tableView;
	UIView* containerView = self.containerViewController.view;

	CGRect searchTableViewRect = containerView.bounds;
	searchTableView.frame = searchTableViewRect;

	if(self.active) {
		CGRect searchBarRect = self.searchBar.frame;
		CGFloat topInset = CGRectGetHeight(searchBarRect);

		CGRect keyboardFrame = self.keyboardFrame;
		CGFloat bottomInset = MAX(CGRectGetHeight(keyboardFrame), 0.0);

		UIEdgeInsets insets = UIEdgeInsetsMake(topInset, 0.0, bottomInset, 0.0);
		searchTableView.contentInset = insets;
		searchTableView.scrollIndicatorInsets = insets;
	}

	[containerView insertSubview:searchTableView aboveSubview:[self overlayView]];

	searchTableView.alpha = self.active ? 1.0 : 0.0;
	searchTableView.hidden = ![self hasSearchText];
}

#pragma mark -

- (void)willTransitionToState:(BOOL)active {
	if(active) {
		if([[self delegate] respondsToSelector:@selector(searchControllerWillBeginSearch:)]) {
			[[self delegate] searchControllerWillBeginSearch:self];
		}
	} else {
		if([[self delegate] respondsToSelector:@selector(searchControllerWillEndSearch:)]) {
			[[self delegate] searchControllerWillEndSearch:self];
		}
	}
}

- (void)didTransitionToState:(BOOL)active {
	if(active) {
		if([[self delegate] respondsToSelector:@selector(searchControllerDidBeginSearch:)]) {
			[[self delegate] searchControllerDidBeginSearch:self];
		}
	} else {
		if([[self delegate] respondsToSelector:@selector(searchControllerDidEndSearch:)]) {
			[[self delegate] searchControllerDidEndSearch:self];
		}
	}
}

#pragma mark -

- (void (^)(void))presentOrDismissSearchTableViewControllerForStateIfNeeded:(BOOL)active animated:(BOOL)animated {
	if(UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone) { return nil; }

	BOOL shouldPresentViewController = active;
	if(shouldPresentViewController) { [self initSearchTableViewControllerIfNeeded]; }

	ARKSearchTableViewController* searchTableViewController = self.searchTableViewController;
	UIView* searchTableView = self.searchTableViewController.view;

	UIViewController* containerViewController = self.containerViewController;
	UIView* containerView = self.containerViewController.view;

	if(shouldPresentViewController && searchTableViewController.parentViewController != containerViewController) { // present
		[containerViewController addChildViewController:searchTableViewController];

		[searchTableViewController beginAppearanceTransition:YES animated:animated];
		[containerView insertSubview:searchTableView aboveSubview:[self overlayView]];

		return ^() {
			[searchTableViewController didMoveToParentViewController:containerViewController];
			[searchTableViewController endAppearanceTransition];
		};
	}

	if(!shouldPresentViewController && searchTableViewController.parentViewController == containerViewController) { // dismiss
		[searchTableViewController willMoveToParentViewController:nil];
		[searchTableViewController beginAppearanceTransition:NO animated:animated];

		return ^() {
			if([searchTableViewController isViewLoaded]) { [[searchTableViewController view] removeFromSuperview]; }
			[searchTableViewController removeFromParentViewController];
			[searchTableViewController endAppearanceTransition];
		};
	}

	return nil;
}

- (BOOL)hasSearchText {
	NSString* searchText = self.searchTableViewController.searchText;
	searchText = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	return searchText.length > 0;
}

#pragma mark -

- (void)updateSearchTableViewController {
	ARKSearchTableViewController* searchTableViewController = self.searchTableViewController;
	if(!searchTableViewController) { return; }

	searchTableViewController.mediaWikis = self.mediaWiki ? @[ self.mediaWiki ] : nil;
	searchTableViewController.titleMatchingEnabled = self.titleMatchingEnabled;
	searchTableViewController.searchText = self.searchBar.text;

	searchTableViewController.tableView.scrollsToTop = YES;
}

- (void)updateSearchBar {
	SASearchBar* searchBar = self.searchBar;

	NSString* calloutButtonTitle = [WikipediaPicker displayNameForLanguageCode:[self mediaWikiLanguageCode]];
	searchBar.scopeCalloutButtonTitle = calloutButtonTitle;

	NSUInteger selectedSegmentIndex = self.titleMatchingEnabled ? 0 : 1;
	[[searchBar scopeBar] setSelectedSegmentIndex:selectedSegmentIndex];

	// a workaround
	if([[self searchTableViewController] isKindOfClass:[SASearchDisplayPopoverContentViewController class]]) {
		SASearchDisplayPopoverContentViewController* searchTableViewController = (SASearchDisplayPopoverContentViewController*)self.searchTableViewController;
		searchTableViewController.calloutButtonTitle = calloutButtonTitle;
		searchTableViewController.selectedScopeBarItemIndex = selectedSegmentIndex;
	}
}

- (void)deactivate:(id)sender forEvent:(UIEvent*)event {
	[self setActive:NO animated:YES completion:nil];
}

- (void)searchScopeDidChange:(id)sender forEvent:(UIEvent*)event {
	BOOL titleMatchingEnabled = self.searchBar.selectedScopeButtonIndex == 0;

	// a workaround
	if([[self searchTableViewController] isKindOfClass:[SASearchDisplayPopoverContentViewController class]]) {
		titleMatchingEnabled = [(UISegmentedControl*)sender selectedSegmentIndex] == 0;
	}

	self.titleMatchingEnabled = titleMatchingEnabled;
}

- (void)calloutButtonTapped:(id)sender forEvent:(UIEvent*)event {
	[[UIApplication sharedApplication] sendAction:@selector(presentWikipediaPicker:) to:[self containerViewController] from:sender forEvent:event];
}

- (void)accessoryControlTapped:(id)sender forEvent:(UIEvent*)event {
	SASearchBarAccessoryType accessoryType = self.searchBar.accessoryType;

	SEL action = NULL;
	if(accessoryType == SASearchBarAccessoryTypeReload) { action = @selector(reload:); }
	if(accessoryType == SASearchBarAccessoryTypeStop) { action = @selector(stopLoading:); }

	if(action) {
		[[UIApplication sharedApplication] sendAction:action to:[self containerViewController] from:sender forEvent:event];
	}
}

@end
