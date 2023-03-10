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

#import "ArticleViewController.h"
#import "ArticleViewController+Private.h"

#import "BrowserViewController.h"
#import "BookmarkPickerController.h"
#import "BookmarkDetailViewController.h"
#import "WikipediaPicker.h"

#import "SAArticleStackDocumentView.h"

#import "SFDocumentSearchBar+Private.h"

#import "SFBezelController.h"

#import "SASearchBar.h"
#import "SASearchBar+Private.h"

#import "SAArticleStack.h"
#import "SAArticle.h"
#import "SAArticle+Additions.h"
#import "SABookmark.h"

#import "NSArray+Additions.h"
#import "NSString+Additions.h"
#import "NSURL+Wikipedia.h"
#import "UIBarButtonItem+Additions.h"

#import "AKLanguagePicker.h"

#import "AKArticleView+Searching.h"
#import "AKArticleView+Printing.h"
#import "AKArticleView+Private.h"

#import "AKChapterIndexView.h"

#import "SFNavigationController.h"
#import "SFSpellingSuggestionTableViewCell.h"
#import "SFSummaryTableViewCell.h"
#import "SFLoadingTableViewCell.h"

#import "SFNetworkActivity.h"

#import "SAReadLaterDropAnimation.h"

#import "SAReadLaterActivity.h"
#import "SABookmarkActivity.h"
#import "SUIGiftActivity.h"

#import "ARKHTMLMarkupFormatter.h"

#import "Articles.h"

#import "SFDocumentSearchField.h"
#import "SFBarButtonItem.h"
#import "SFNavigationController.h"
#import "UIActionSheet+Additions.h"
#import "UIButton+Graphite.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <QuartzCore/QuartzCore.h>

@implementation ArticleViewController

@dynamic defaultToolbarItems;
@dynamic customizableToolbarItems;
@dynamic documentPickerToolbarItems;

#pragma mark - Construction & Destruction

+ (id)viewController {
	return [[self alloc] initWithNibName:nil bundle:nil];
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		_networkActivity = NO;
		self.hidesBottomBarWhenPushed = YES;
	}

    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark ArticleViewController

- (void)loadArticle:(NSURL*)articleURL {
	[self loadArticle:articleURL animated:YES];
}

- (void)loadArticle:(NSURL*)articleURL animated:(BOOL)animated {
	// Now check if we have a articleURL
	if(!articleURL) {
		[[self articleView] loadArticle:nil animated:animated];
		[self updateButtonItems];

		return;
	}
	
	[[self articleView] setTutorialShown:NO animated:animated];
	
	if(articleURL && [[[[self articleView] visibleArchive] articleURL] isEqual:articleURL]) {
		return;
	}
	
	// Make a new article object for this URL
	SAArticle* article = [SAArticle articleForURL:articleURL inContext:[self managedObjectContext]];
	
	// Notify our stack controller about this new URL
	[[self articleStackController] navigateToArticle:article];
	
	// Make a new URL request for this URL
	[[self articleView] loadArticle:articleURL animated:animated];
	
	// Update our toolbar and search display controller
	[self updateButtonItems];
    
    if(!self.openURLContext) {
		[self setSearchControllerShown:NO animated:YES];
	}

	_searchBarPinned = YES;
	[self layoutSubviewsAnimated:animated];
}

- (void)openFromURL:(NSURL*)URL options:(NSDictionary*)options {
	self.openURLContext = options;
    
    NSString* languageCode = [options objectForKey:@"language"];
    if(languageCode && (id)languageCode != [NSNull null]) {
		[self setLanguageCodeForSearching:languageCode];
    }

    self.searchController.searchText = [options objectForKey:@"search"];
    
    NSString* scopeText = [options objectForKey:@"scope"];

    if(SFEqualCaseInsensitiveStrings(scopeText, @"contents") || SFEqualCaseInsensitiveStrings(scopeText, @"content")) {
    	self.searchController.titleMatchingEnabled = NO;
    } else if(SFEqualCaseInsensitiveStrings(scopeText, @"title")) {
    	self.searchController.titleMatchingEnabled = YES;
    }

	[self setSearchControllerShown:YES animated:YES];
}

- (IBAction)back:(id)sender {
	_didNavigateBack = YES;
	
	// Navigate back
	SAArticleStackItem* stackItem = [[self articleStackController] navigateBack];
	
	if(stackItem) {
		NSURL* articleURL = [NSURL URLWithString:[[stackItem article] articleURL]];
		[[self articleView] loadArticle:articleURL animated:YES];
	}
}

- (IBAction)forward:(id)sender {
	_didNavigateBack = NO;
	
	// Navigate forward
	SAArticleStackItem* stackItem = [[self articleStackController] navigateForward];
	
	if(stackItem) {
		NSURL* articleURL = [NSURL URLWithString:[[stackItem article] articleURL]];
		[[self articleView] loadArticle:articleURL animated:YES];
	}
}

- (IBAction)showActivityPicker:(id)sender {
	// dismiss the current activity picker if needed
	if(self.activitiesPopoverController && [[self activitiesPopoverController] isPopoverVisible]) {
		[[self activitiesPopoverController] dismissPopoverAnimated:YES];
		self.activitiesPopoverController = nil;
		return;
	}

	// article url
	NSURL* articleURL = [[self articleView] articleURL];

	// print formatter
	UIPrintInfo* printInfo = [UIPrintInfo printInfo];
	
	printInfo.outputType = UIPrintInfoOutputGeneral;
	printInfo.jobName = self.articleView.articleTitle;
	printInfo.duplex = UIPrintInfoDuplexLongEdge;
 
    UIViewPrintFormatter* formatter = [[[self articleView] webView] viewPrintFormatter];
	
	// custom activities
	SABookmarkActivity* bookmarkActivity = [[SABookmarkActivity alloc] init];
	bookmarkActivity.activityViewControllerBlock = ^(NSURL* URL) {
		return [self bookmarkDetailsViewControllerForURL:URL];
	};

	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		bookmarkActivity.activityBlock = ^(NSURL* URL) {
			[self presentBookmarkDetailsViewControllerForURL:URL sender:nil animated:YES];
		};
	}

	SAReadLaterActivity* readLaterActivity = [[SAReadLaterActivity alloc] init];
	readLaterActivity.action = ^() {
		[self readLater:nil];
	};

	SUIGiftActivity* giftActivity = [[SUIGiftActivity alloc] initWithApplicationIdentifier:@"364881979"];

	// prepare the activity view controller
	NSArray* items = @[ articleURL, formatter ];
	NSArray* activities = @[ bookmarkActivity, readLaterActivity, giftActivity ];

	UIActivityViewController* viewController = [[UIActivityViewController alloc]
		initWithActivityItems:items
		applicationActivities:activities];
		
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self dismissAllPopoverControllerExcept:nil animated:YES];
		
		UIPopoverController* activitiesPopoverController = [[UIPopoverController alloc] initWithContentViewController:viewController];
		self.activitiesPopoverController = activitiesPopoverController;
		
		[activitiesPopoverController
			presentPopoverFromBarButtonItem:[self addBookmarkButtonItem]
			permittedArrowDirections:UIPopoverArrowDirectionAny
			animated:YES];
	} else {
		[self presentViewController:viewController animated:YES completion:nil];
	}
}

- (void)readLater:(id)sender {
	SAArticle* article = [[[[self articleStackController] selectedStack] selectedItem] article];
	NSString* title = [article title];
    	
	NSDictionary* options = title.length > 0 ?
		@{ @"text": title } : nil;
	[article readLater:options];
}

- (void)copyArticleURL:(id)sender {
	NSURL* articleURL = self.articleView.articleURL;
	if(!articleURL) { return; }
	
	NSArray* pasteboardItems = @[
		@{ (NSString*)kUTTypeUTF8PlainText:[articleURL absoluteString] } ];
	[[UIPasteboard generalPasteboard] setItems:pasteboardItems];
}

- (IBAction)addBookmark:(id)sender {
	NSURL* articleURL = self.articleView.articleURL;
	[self presentBookmarkDetailsViewControllerForURL:articleURL sender:sender animated:YES];
}

- (void)presentBookmarkDetailsViewControllerForURL:(NSURL*)URL sender:(id)sender animated:(BOOL)animated {
	UIViewController* viewController = [self bookmarkDetailsViewControllerForURL:URL];
	UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];

	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self dismissAllPopoverControllerExcept:nil animated:animated];

//		UIPopoverController* popoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
//		[popoverController presentPopoverFromBarButtonItem:[self bookmarksButtonItem] permittedArrowDirections:UIPopoverArrowDirectionAny animated:animated];
//
//		self.bookmarksPopoverController = popoverController;

		[self presentViewController:navigationController animated:YES completion:nil];
	} else {
		[self presentViewController:navigationController animated:YES completion:nil];
	}
}

- (UIViewController*)bookmarkDetailsViewControllerForURL:(NSURL*)articleURL {
	SAArticle* article = [SAArticle
		articleForURL:articleURL
		inContext:[self managedObjectContext]];
	if(!article) { return nil; }
	
	SABookmark* bookmark = [NSEntityDescription
		insertNewObjectForEntityForName:@"Bookmark"
		inManagedObjectContext:[self managedObjectContext]];
	
	bookmark.title = [articleURL wikipediaTitle];
	bookmark.article = article;
	bookmark.creationDate = [NSDate date];
	bookmark.sortOrder = [NSNumber numberWithInteger:NSIntegerMax];
	
	BookmarkDetailViewController* viewController = [BookmarkDetailViewController viewController];
	
	viewController.bookmark = bookmark; // TODO

	return viewController;
}

- (IBAction)showBookmarks:(id)sender {
	if([[self bookmarksPopoverController] isPopoverVisible]) {
		[[self bookmarksPopoverController] dismissPopoverAnimated:YES];
		// self.bookmarksPopoverController = nil;

		return;
	}
    
    if(self.bookmarksPopoverController) {
    	[self dismissAllPopoverControllerExcept:[self bookmarksPopoverController] animated:YES];

        [[self bookmarksPopoverController]
        	presentPopoverFromBarButtonItem:[self bookmarksButtonItem]
            permittedArrowDirections:UIPopoverArrowDirectionAny
            animated:YES];
    
    	return;
    }
	
	BookmarkPickerController* bookmarkController = [[BookmarkPickerController alloc] initWithSupergroup:nil managedObjectContext:[self managedObjectContext]];
	
	bookmarkController.delegate = self;
	
	UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:bookmarkController];
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		navigationController.toolbarHidden = YES;
		
		UIPopoverController* popoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
		
		popoverController.delegate = self,
		self.bookmarksPopoverController = popoverController;
		
		[self dismissAllPopoverControllerExcept:popoverController animated:YES];
		[popoverController presentPopoverFromBarButtonItem:[self bookmarksButtonItem] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];

		[bookmarkController restoreFromUserDefaults];
	} else {
		navigationController.toolbarHidden = NO;

		[self presentViewController:navigationController animated:YES completion:nil];
	
		[bookmarkController restoreFromUserDefaults];
	}
}

- (IBAction)showArticleStacks:(id)sender {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self setSearchControllerShown:NO animated:YES];
		[self dismissAllPopoverControllerExcept:nil animated:YES];
	}

	[self showDocumentPicker];
}

- (IBAction)findInDocument:(id)sender {
	if(_searchingDocument && sender == self.documentSearchButtonItem.customView) {
		[self cancelFindInDocument:sender]; return;
	}

	_searchingDocument = YES;
	
	if(!self.documentSearchBar) {
		CGRect documentSearchBarRect = [[self toolbar] frame];
		documentSearchBarRect = CGRectOffset(documentSearchBarRect, 0.0, CGRectGetHeight(documentSearchBarRect));
		
		if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			documentSearchBarRect.origin.y = CGRectGetHeight([[self view] bounds]);
		}
		
		SFDocumentSearchBar* documentSearchBar = [[SFDocumentSearchBar alloc] initWithFrame:documentSearchBarRect];
		
		documentSearchBar.delegate = self;
		
		[[self view] insertSubview:documentSearchBar belowSubview:[self toolbar]];
		self.documentSearchBar = documentSearchBar;
	}
	
	self.articleView.searching = YES;

	if(sender != self.articleView) {
		[[self documentSearchBar] becomeFirstResponder];
	}
	
	[self dismissAllPopoverControllerExcept:(id)[self documentSearchBar] animated:YES];
	[self layoutSubviewsAnimated:YES];
}

- (IBAction)cancelFindInDocument:(id)sender {
	_searchingDocument = NO;
	self.articleView.searching = NO;
	
	if(!self.documentSearchBar) { return; }
	
	if(_keyboardVisible) {
		[[self documentSearchBar] endEditing:YES];
	} else {
		[self layoutSubviewsAnimated:YES];
	}
}

- (IBAction)customizeToolbar:(id)sender {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { return; }
	if(self.toolbarCustomizationController) { return; }
	if(_pickingDocument) { return; }
	
	if([sender isKindOfClass:[UILongPressGestureRecognizer class]]) {
		UILongPressGestureRecognizer* gestureRecognizer = sender;
		
		if(gestureRecognizer.state != UIGestureRecognizerStateBegan) {
			return; // do nothing
		}
	}

	SFToolbarCustomizationController* toolbarCustomizationController =
		[[SFToolbarCustomizationController alloc] initWithToolbar:[self toolbar]];
	
	toolbarCustomizationController.delegate = self;
	
	self.toolbarCustomizationController = toolbarCustomizationController;
	
	NSArray* toolbarItems = [NSArray arrayWithObjects:
		[self backButtonItem],
		[self forwardButtonItem],
		[self addBookmarkButtonItem],
		[self bookmarksButtonItem],
		[self showTabsButtonItem],
		[self chaptersButtonItem],
		[self localizationsButtonItem],
		[self documentSearchButtonItem],
		nil];
	
	[toolbarCustomizationController
		beginCustomizingItems:toolbarItems
		fromRect:CGRectZero
		inView:nil
		animated:YES];
}

- (IBAction)showLocalizationPicker:(id)sender {
	if(self.localizationsController) {
		[[self localizationsController] dismissPopoverAnimated:YES];
		self.localizationsController = nil;
		return;
	}
	
	AKLanguagePicker* picker = [[self articleView] languagePicker];
	
	picker.pickerMode = AKLanguagePickerModeDefault;
	picker.allowsModeSelection = NO;

	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		picker.delegate = self;
		
		UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:picker];
		
		UIPopoverController* popoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
		
		popoverController.delegate = self;
		self.localizationsController = popoverController;
		
		[self dismissAllPopoverControllerExcept:popoverController animated:YES];
		[popoverController presentPopoverFromBarButtonItem:[self localizationsButtonItem] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	} else {
		UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:picker];
		[self presentViewController:navigationController animated:YES completion:nil];
	}
}

- (IBAction)showChapterPicker:(id)sender {
	if(self.chaptersPopoverController) {
		[[self chaptersPopoverController] dismissPopoverAnimated:YES];
		self.chaptersPopoverController = nil;
		return;
	}
	
	AKLanguagePicker* picker = [[self articleView] languagePicker];
	
	picker.pickerMode = AKLanguagePickerModeTOC;
	picker.allowsModeSelection = NO;
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		picker.delegate = self;
		
		UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:picker];
		
		UIPopoverController* popoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
		
		popoverController.delegate = self;
		self.chaptersPopoverController = popoverController;
		
		[self dismissAllPopoverControllerExcept:popoverController animated:YES];
		[popoverController presentPopoverFromBarButtonItem:[self chaptersButtonItem] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	} else {
		UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:picker];
		[self presentViewController:navigationController animated:YES completion:nil];
	}
}

#pragma mark -
#pragma mark SFDocumentSearchBarDelegate

- (void)documentSearchBarSearchButtonTapped:(SFDocumentSearchBar*)searchBar {
	if(self.documentSearchBar != searchBar) { return; }

	NSString* searchText = searchBar.text;
	NSInteger numberOfSearchResults = [[self articleView] searchWithText:searchText];
	
	if(numberOfSearchResults > 0) {
		[searchBar resignFirstResponder];
		[searchBar setBarMode:SFDocumentSearchBarModeNavigation animated:YES];
	} else {
		[[SFBezelController sharedBezelController]
			presentBezelWithText:NSLocalizedString(@"NOSEARCHRESULTS_BEZEL_TITLE", @"")
			image:[UIImage imageNamed:@"documentSearchBezelImage.png"]];
	}
}

- (void)documentSearchBarCancelButtonTapped:(SFDocumentSearchBar*)searchBar {
	if(self.documentSearchBar == searchBar) {
		[self cancelFindInDocument:searchBar];
	}
}

- (void)documentSearchBarPrevButtonTapped:(SFDocumentSearchBar*)searchBar {
	if(self.documentSearchBar == searchBar) {
		[[self articleView] findPrevious];
	}
}

- (void)documentSearchBarNextButtonTapped:(SFDocumentSearchBar*)searchBar {
	if(self.documentSearchBar == searchBar) {
		[[self articleView] findNext];
	}
}

- (void)documentSearchBar:(SFDocumentSearchBar*)searchBar textDidChange:(NSString*)text {
	if(text.length == 0) {
		[[self articleView] searchWithText:@""];
		[searchBar setBarMode:SFDocumentSearchBarModeDefault animated:YES];
	}
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
		// TODO Display some feedback bezel
		if(!_loadingDocument && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
			[self loadArticle:[[self wikipedia] randomArticleURL]];
		}

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

- (void)loadView {
	[super loadView];
	
	_launching = YES;
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self loadViewForiPad];
	} else {
		self.view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
		self.view.backgroundColor = [UIColor whiteColor];
		
		// Init the article view
		AKArticleView* articleView = [[AKArticleView alloc] initWithFrame:[[self view] bounds]];
		
		articleView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleTopMargin;
		articleView.alpha = 0.0; // initially hidden
		
		[[self view] addSubview:articleView];
		self.articleView = articleView;
		
		// Init the search bar
		SASearchBar* searchBar = [[SASearchBar alloc] initWithFrame:[[self view] bounds]];
		
		[searchBar sizeToFit];
		searchBar.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleWidth;
		
		[[searchBar pickerButton] addTarget:articleView action:@selector(showLanguagePicker) forControlEvents:UIControlEventTouchUpInside];
		[[searchBar searchButton] addTarget:self action:@selector(findInDocument:) forControlEvents:UIControlEventTouchUpInside];
		
		[[self view] insertSubview:searchBar aboveSubview:articleView];
		self.searchBar = searchBar;
		
		// Init the toolbar
		SFToolbar* toolbar = [[SFToolbar alloc] initWithFrame:CGRectZero];
		
		[toolbar sizeToFit];
		toolbar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleWidth;
		
		[[self view] insertSubview:toolbar aboveSubview:articleView];
		self.toolbar = toolbar;
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(applicationDidChangeStatusBarFrame:)
		name:UIApplicationDidChangeStatusBarFrameNotification
		object:nil];
	
	// Setup custom menu items
	NSArray* customMenuItems = [NSArray arrayWithObjects:
		[[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"FIND_MENUITEM", @"") action:@selector(find:)],
		nil];
	[[UIMenuController sharedMenuController]
		setMenuItems:customMenuItems];
	
	// ...
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
		
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(lightboxWillShow:)
		name:AKLightboxWillShowNotification
		object:nil];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(lightboxWillHide:)
		name:AKLightboxWillHideNotification
		object:nil];

	_keyboardRect = CGRectZero;
		
	// Init the search display controller
	SARSearchController* searchController = [[SARSearchController alloc]
		initWithSearchBar:[self searchBar]
		containerViewController:self];

	searchController.delegate = self;

	self.searchController = searchController;

	// Determine the search scopes
	NSString* mediaWikiLanguageCode = [[NSUserDefaults standardUserDefaults]
		stringForKey:@"SASelectedScopeLanguageCode"];
	
	if(mediaWikiLanguageCode.length <= 0) {
		mediaWikiLanguageCode = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];

		if(![@[ @"en", @"de", @"fr", @"ru" ] containsObject:mediaWikiLanguageCode]) {
			mediaWikiLanguageCode = @"en";
		}
	}

	searchController.mediaWikiLanguageCode = mediaWikiLanguageCode;

	// searchController.scopeCalloutButtonTitle = [WikipediaPicker displayNameForLanguageCode:selectedScopeLanguageCode];
	// self.searchBar.scopeCalloutButtonTitle = [WikipediaPicker displayNameForLanguageCode:selectedScopeLanguageCode];
	
	// Create a new article stack controller
	SAArticleStackController* articleStackController = [[SAArticleStackController alloc] init];
	
	articleStackController.managedObjectContext = self.managedObjectContext;
	[articleStackController refresh];
	
	articleStackController.articleView = self.articleView;
	
	self.articleStackController = articleStackController;
	
	// Init the search bar
	self.searchBar.placeholder = NSLocalizedString(@"SEARCHBAR_PLACEHOLDER_TITLE", @"");

	// Setup our toolbar items
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self loadButtonItemsForiPad];
	} else {
		self.backButtonItem = [[SFBarButtonItem alloc] initWithBarButtonAppItem:SFBarButtonAppItemNavigateBack target:self action:@selector(back:)];
		self.backButtonItem.itemIdentifier = @"backButtonItem";
		
		self.forwardButtonItem = [[SFBarButtonItem alloc] initWithBarButtonAppItem:SFBarButtonAppItemNavigateForward target:self action:@selector(forward:)];
		self.forwardButtonItem.itemIdentifier = @"forwardButtonItem";
		
		self.addBookmarkButtonItem = [[SFBarButtonItem alloc] initWithBarButtonAppItem:SFBarButtonAppItemAction target:self action:@selector(showActivityPicker:)];
		self.addBookmarkButtonItem.itemIdentifier = @"addBookmarkButtonItem";
		
		self.bookmarksButtonItem = [[SFBarButtonItem alloc] initWithBarButtonAppItem:SFBarButtonAppItemBookmarks target:self action:@selector(showBookmarks:)];
		self.bookmarksButtonItem.itemIdentifier = @"bookmarksButtonItem";
		
		self.showTabsButtonItem = [[SFBarButtonItem alloc] initWithBarButtonAppItem:SFBarButtonAppItemTabs target:self action:@selector(showArticleStacks:)];
		self.showTabsButtonItem.itemIdentifier = @"showTabsButtonItem";
		
		// Also setup the optional items
		self.localizationsButtonItem = [[SFBarButtonItem alloc] initWithBarButtonAppItem:SFBarButtonAppItemLocalizations target:self action:@selector(showLocalizationPicker:)];
		self.localizationsButtonItem.itemIdentifier = @"localizationsButtonItem";
		
		self.chaptersButtonItem = [[SFBarButtonItem alloc] initWithBarButtonAppItem:SFBarButtonAppItemChapters target:self action:@selector(showChapterPicker:)];
		self.chaptersButtonItem.itemIdentifier = @"chaptersButtonItem";
		
		self.documentSearchButtonItem = [[SFBarButtonItem alloc] initWithBarButtonAppItem:SFBarButtonAppItemSearch target:self action:@selector(findInDocument:)];
		self.documentSearchButtonItem.itemIdentifier = @"documentSearchButtonItem";
	
		// And setup the document picker toolbar items
		self.addNewDocumentButtonItem = [[SFBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BARBUTTON_ITEM_NEW_PAGE", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(addDocument:)];
		self.documentPickerDoneButtonItem = [[SFBarButtonItem alloc] initWithBarButtonAppItem:SFBarButtonAppItemDone target:self action:@selector(donePickingDocument:)];
	}
	
	[self updateButtonItems];
	[self restoreToolbarItemsIfNeededAnimated:YES];
	
	// [self setToolbarItems:[self defaultToolbarItems] animated:YES];
	
	// Add a gesture recognizer to enable toolbar customization
	UILongPressGestureRecognizer* customizingGestureRecognizer = [[UILongPressGestureRecognizer alloc]
		initWithTarget:self action:@selector(customizeToolbar:)];
	
	customizingGestureRecognizer.minimumPressDuration = 1.0;
	
	[[self toolbar] addGestureRecognizer:customizingGestureRecognizer];
	
	
	// ...
	self.articleView.delegate = self;
	
	// Setup the wikipedia backend
	self.wikipedia = [[WikipediaAPI alloc] init];
	
	// Update the article view edge insets
	[self updateArticleViewEdgeInsets];
	[self setContentOffsetIfNeeded:CGPointMake(0.0, -self.articleView.contentInset.top)];
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self updateiPadForInterfaceOrientation:[self interfaceOrientation]];
	}

//	[self setLanguageCodeForSearching:selectedScopeLanguageCode];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];

	[[self navigationController] setNavigationBarHidden:YES animated:animated];

	[[self searchBar] layoutIfNeeded];
	[[self articleView] layoutIfNeeded];
	[[self toolbar] layoutIfNeeded];
	
	// ...
	[self updateButtonItems];
	[self updateSearchBarAnimated:NO];
	
	[self layoutSubviewsAnimated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	_launching = NO;
	
	// Restore the previous dispaly state from user defaults
	// Load the previous session
	if(!self.articleView.articleURL) {
		SAArticleStack* stack = self.articleStackController.selectedStack;
		SAArticleStackItem* stackItem = stack.selectedItem;
		
		if(stack && stackItem) {
			[self loadWithStackItem:stackItem inStack:stack animated:YES];
		}
	}
	
	[self layoutSubviewsAnimated:YES];

	// Make this controller first responder
	[self becomeFirstResponderIfNeeded];
	
	if(animated) {
		[[self articleView] flashChapterIndex];
	}

/*	// For the default image
	[self loadArticle:nil];
	// self.articleView.hidden = YES;
	self.toolbarItems = [NSArray array];
	self.searchBar.prompt = @"";
	self.searchBar.placeholder = @"";
	self.searchBar.promptLabel.hidden = YES;
	self.searchBar.searchButtonShown = NO;
	self.searchBar.pickerButtonShown = NO;
	[[self articleView] setTutorialShown:NO animated:NO]; */
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	[self storeContentOffset];
	[[self articleStackController] save];
	
	// ...
	[self resignFirstResponder];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
    
    if(!_launching || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self layoutSubviews]; // for call-in statusbar
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if(_shaking) { return [self interfaceOrientation] == toInterfaceOrientation; }
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { return YES; }
	if([[self toolbarCustomizationController] isCustomizing]) { return [self interfaceOrientation] == toInterfaceOrientation; }
	
	NSNumber* preferredInterfaceOrientation = [[NSUserDefaults standardUserDefaults] objectForKey:@"AKPreferredInterfaceOrientation"];
	if(preferredInterfaceOrientation) {
		return [preferredInterfaceOrientation integerValue] == toInterfaceOrientation;
	}

	return YES;
}

- (BOOL)shouldAutorotate {
	if(_shaking) { return NO; }
	if([[self toolbarCustomizationController] isCustomizing]) { return NO; }

	return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration { 
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self updateiPadForInterfaceOrientation:toInterfaceOrientation];
	}

	[self updateButtonItems];
	[self layoutSubviewsAnimated:YES];
}

- (NSArray*)toolbarItems {
	return self.toolbar.items;
}

- (void)setToolbarItems:(NSArray*)items {
	[self setToolbarItems:items animated:NO];
}

- (void)setToolbarItems:(NSArray*)toolbarItems animated:(BOOL)animated {
	[[self toolbar] setItems:toolbarItems animated:animated];
}

- (UIView*)rotatingFooterView {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { return nil; }
	if(self.searchController.active) { return nil; }
    
    UIView* footerView = [super rotatingFooterView];
	
	if(!footerView) {
		footerView = self.documentSearchBar ?
			(id)self.documentSearchBar :
			(id)self.toolbar;
	}
	
	return footerView;
}

#pragma mark - AKArticleViewDelegate

- (void)articleView:(AKArticleView*)articleView needsParentViewController:(UIViewController**)viewController {
	*viewController = self;
}

- (BOOL)articleView:(AKArticleView*)articleView shouldStartLoadArticle:(NSURL*)articleURL options:(NSDictionary*)options {
	// Retrieve the article object for the current URL
	if([[articleURL absoluteString] length] > 0) {
		// NSLog(@"Will start loading %@", articleURL);
		
		BOOL loadInNewPage = [[options objectForKey:AKOpenArticleInNewPageOptionKey] boolValue];
		
		if(loadInNewPage) {
			[self showDocumentPicker];
			
			SAArticleStack* stack = [[self articleStackController] navigateToArticleURLInNewPageIfNeeded:articleURL];
			SAArticleStackDocument* selectedDocument = nil;
			
			for(SAArticleStackDocument* document in self.documentPicker.documents) {
				if(document.articleStack == stack) {
					selectedDocument = document;
				}
			}
			
			if(!selectedDocument) {
				selectedDocument = [[SAArticleStackDocument alloc] initWithArticleStack:stack];
			}
			
			[self performSelector:@selector(addNewDocumentAnimated:)
				withObject:selectedDocument
				afterDelay:SFDocumentPickerMaximizeAnimationDuration + 0.125];
			
			return NO;
		}
		
		SAArticle* article = [SAArticle
			articleForURL:articleURL
			inContext:[self managedObjectContext]];

		// Mark this new article in our stack controller
		[[self articleStackController] navigateToArticle:article];
		
		// Update the toolbar buttons right away
		[self updateButtonItems];
	}
	
	return YES;
}

- (void)articleView:(AKArticleView*)articleView shouldLoadExternalResource:(NSURL*)resourceURL {
	if(!resourceURL) { return; }

	BrowserViewController* viewController = [BrowserViewController viewController];
		
	NSURLRequest* newRequest = [NSURLRequest requestWithURL:resourceURL];
	[[viewController webView] loadRequest:newRequest];
			
	UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
	
	UIViewController* parentViewController = (id)articleView.visibleTabularDataViewController;
	if(!parentViewController) { parentViewController = self; }
	
	[parentViewController presentViewController:navigationController animated:YES completion:nil];
}

- (void)articleViewDidStartLoad:(AKArticleView*)articleView {
	_loadingDocument = YES;
	_shouldRestoreContentOffset = YES;
	_searchBarPinned = YES;
	
	[self dismissAllPopoverControllerExcept:nil animated:YES];
	[self cancelFindInDocument:articleView];
	
	self.searchBar.progress = articleView.progress;
	
	// experimental transitions
	if(articleView.visibleArchive) {
		[[self articleView] resetWebView];
		
        id animations = ^() {
    		[self updateButtonItems];
			[self updateSearchBarAnimated:YES];
			[self layoutSubviewsAnimated:YES];
        };
        
		[UIView transitionWithView:[self articleView]
			duration:0.3
			options:UIViewAnimationOptionTransitionCrossDissolve|UIViewAnimationOptionBeginFromCurrentState
			animations:animations
			completion:nil];
	} else {
    	[self updateButtonItems];
		[self updateSearchBarAnimated:YES];
		[self layoutSubviewsAnimated:YES];
    }
	
	_didNavigateBack = NO;
}

- (void)articleView:(AKArticleView*)articleView didProgressLoad:(float)loadProgress {
	self.searchBar.progress = MIN(loadProgress, 0.85);
}

- (void)articleViewDidFinishLoadingDocument:(AKArticleView*)articleView {
	// Updates the selected article URL in case we had a redirect
	[[self articleStackController] didNavigateToArticleURL:[articleView articleURL]];
    self.articleStackController.selectedStack.selectedItem.article.title = [articleView articleTitle];

    // Revert back to the previous content offset
	[self restoreContentOffsetIfNeeded];

	_loadingDocument = NO;
    
    [self updateButtonItems];
    [self updateHistory];
	
    id animations = ^() {
		[self layoutSubviewsAnimated:YES];
    };
    
	[UIView transitionWithView:[self articleView]
		duration:0.3
		options:UIViewAnimationOptionTransitionCrossDissolve|UIViewAnimationOptionBeginFromCurrentState
		animations:animations
		completion:nil];
	
	// Make this controller first responder
	[self becomeFirstResponderIfNeeded];
}

- (void)articleViewDidFinishLoad:(AKArticleView*)articleView {
	// Make this controller first responder
	[self becomeFirstResponderIfNeeded];

	_searchBarPinned = NO;
	[self updateSearchBarAnimated:YES];
	[self layoutSubviewsAnimated:YES];
    
    // Revert back to the previous content offset
	[self restoreContentOffsetIfNeeded];

/*
	// for default image
	self.searchBar.searchButtonShown = NO;
	self.searchBar.pickerButtonShown = NO;
	self.searchBar.accessoryType = SASearchBarAccessoryTypeNone;
	[[self articleView] setTutorialShown:NO animated:NO];
*/
}

- (void)articleView:(AKArticleView*)articleView didFailLoadWithError:(NSError*)error {
	// Make this controller first responder
	[self becomeFirstResponderIfNeeded];
	
	[self updateButtonItems];
	[self updateSearchBarAnimated:YES];
	
	[self layoutSubviewsAnimated:YES];
}

- (void)articleView:(AKArticleView*)articleView didHighlightSearchResultAtIndex:(NSInteger)resultIndex numberOfResults:(NSInteger)numberOfResults {
	if(!self.documentSearchBar) { return; }
	
	[[self documentSearchBar] setCurrentResultIndex:resultIndex numberOfResults:numberOfResults];
}

- (void)articleView:(AKArticleView*)articleView shouldFindInDocumentWithText:(NSString*)text {
	[self findInDocument:articleView];

	self.documentSearchBar.text = text;

	[self documentSearchBarSearchButtonTapped:[self documentSearchBar]];
//	[self becomeFirstResponder];
}

- (void)articleView:(AKArticleView*)articleView shouldReadLaterWithOptions:(NSDictionary*)options {
	NSURL* URL = [options objectForKey:@"URL"];
	SAArticle* article = [SAArticle articleForURL:URL inContext:[self managedObjectContext]];
	
	if(article.title.length == 0) {
		article.title = [URL wikipediaTitle];
	}
	
	NSMutableDictionary* dropAnimationOptions = [NSMutableDictionary dictionary];
	
	UIViewController* infoSheetViewController = (id)[articleView visibleTabularDataViewController];
	UIViewController* parentViewController = infoSheetViewController ?
		infoSheetViewController :
		self;

	[dropAnimationOptions setObject:parentViewController forKey:@"viewController"];
	
	if(!infoSheetViewController &&
	   [[self toolbarItems] containsObject:[self bookmarksButtonItem]]) {
		[dropAnimationOptions setObject:[[self bookmarksButtonItem] customView] forKey:@"destinationView"];
	}
	
	[dropAnimationOptions setObject:[options objectForKey:@"rects"] forKey:@"rects"];
	[dropAnimationOptions setObject:[options objectForKey:@"sourceView"] forKey:@"sourceView"];
	
	UIEdgeInsets contentEdgeInsets = UIEdgeInsetsZero;
	
	if(infoSheetViewController) {
		contentEdgeInsets.top = 44.0;
	} else {
		if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
			contentEdgeInsets.bottom = 44.0;
		}
	}
	
	[dropAnimationOptions setObject:[NSValue valueWithUIEdgeInsets:contentEdgeInsets] forKey:@"contentEdgeInsets"];

	[SAReadLaterDropAnimation dropWithOptions:dropAnimationOptions];
	
	[article readLater:options];
	
	AKArchive* archive = [AKArchive archiveForArticle:URL archiveType:AKArchiveTypeAny];
	[archive loadArchiveIfNeeded];
}

#pragma mark - SARSearchController

- (void)presentWikipediaPicker:(id)sender {
	WikipediaPicker* picker = [WikipediaPicker viewController];
	
	picker.delegate = self;
	picker.selectedWikipedia = self.searchController.mediaWikiLanguageCode;

	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UINavigationController* navigationController = (UINavigationController*)[[[self searchController] contentPopoverController] contentViewController];
		[navigationController pushViewController:picker animated:YES];
	} else {
		UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:picker];
		[self presentViewController:navigationController animated:YES completion:nil];
	}
}

- (void)reload:(id)sender {
	self.articleStackController.selectedStack.selectedItem.contentOffset = nil;
	[[self articleView] reload];
}

- (void)stopLoading:(id)sender {
	[[self articleView] stopLoading];
}

#pragma mark - SARSearchControllerDelegate

- (void)searchControllerWillBeginSearch:(SARSearchController*)searchController {
	[self dismissAllPopoverControllerExcept:[searchController contentPopoverController] animated:YES];

	self.articleView.webView.scrollView.scrollsToTop = NO;

//	_contentOffsetBeforeSearch = self.articleView.contentOffset;
	[self layoutSubviewsAnimated:YES];
}

- (void)searchControllerDidBeginSearch:(SARSearchController*)searchController {
}

- (void)searchControllerWillEndSearch:(SARSearchController*)searchController {
	self.openURLContext = nil; // always nil out for now

	self.articleView.webView.scrollView.scrollsToTop = YES;
	
	[self layoutSubviewsAnimated:YES];
//	[[self articleView] setContentOffset:_contentOffsetBeforeSearch animated:YES];
	
	[self becomeFirstResponder];
}

- (void)searchControllerDidEndSearch:(SARSearchController*)searchController {
}

#pragma mark - ARKSearchTableViewControllerDelegate

- (void)searchTableViewController:(ARKSearchTableViewController*)viewController didSelectPage:(WIKPage*)page {
	NSURL* URL = page.URL.value;
	[self loadArticle:URL animated:YES];

	[[self searchController] setActive:NO animated:YES completion:nil];
}

- (BOOL)searchTableViewController:(ARKSearchTableViewController*)viewController shouldPresentActivityViewControllerForPage:(WIKPage*)page {
	NSURL* URL = [[page URL] value];
	NSString* searchText = viewController.searchText;
	
	// Bookmark
	SABookmarkActivity* bookmarkActivity = [[SABookmarkActivity alloc] init];
	bookmarkActivity.activityViewControllerBlock = ^(NSURL* URL) {
		return [self bookmarkDetailsViewControllerForURL:URL];
	};

	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		bookmarkActivity.activityBlock = ^(NSURL* URL) {
			[self presentBookmarkDetailsViewControllerForURL:URL sender:nil animated:YES];
		};
	}

	// Read Later
	SAReadLaterActivity* readLaterActivity = [[SAReadLaterActivity alloc] init];
	readLaterActivity.action = ^() {
		[self addPageToReadLaterListIfNeeded:page forSearchText:searchText];
	};

	// prepare the activity view controller
	NSArray* items = @[ URL ];
	NSArray* activities = @[ bookmarkActivity, readLaterActivity ];

	UIActivityViewController* activityViewController = [[UIActivityViewController alloc]
		initWithActivityItems:items
		applicationActivities:activities];

	if(self.searchController.contentPopoverController) {
		UINavigationController* navigationController = (UINavigationController*)self.searchController.contentPopoverController.contentViewController;
		[navigationController presentViewController:activityViewController animated:YES completion:nil];
	} else {
		[viewController presentViewController:activityViewController animated:YES completion:nil];
	}

	return NO;
}

- (void)addPageToReadLaterListIfNeeded:(WIKPage*)page forSearchText:(NSString*)searchText {
	NSURL* URL = [[page URL] value];

	ARKHTMLMarkupFormatter* formatter = [[ARKHTMLMarkupFormatter alloc] init];

	NSString* title = [formatter stringFromString:[[page title] value] error:nil];
	NSString* summary = [formatter stringFromString:[[page summary] value] error:nil];

	SAArticle* article = [SAArticle articleForURL:URL inContext:[self managedObjectContext]];

	NSMutableDictionary* options = [NSMutableDictionary dictionaryWithCapacity:2];

	NSStringCompareOptions searchOptions = NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch;

	NSRange range = [summary rangeOfString:searchText options:searchOptions];
	if(range.length == 0) { range = [summary rangeOfString:title options:searchOptions]; }

	if(range.length > 0) {
		options[@"targetTextRange"] = [NSValue valueWithRange:range];
		options[@"text"] = summary;
	} else if(summary.length > 0) {
		options[@"text"] = summary;
	} else {
		options[@"text"] = title;
	}

	[article readLater:options];
}

#pragma mark - SFDocumentPickerViewDelegate

- (CGRect)documentPickerView:(SFDocumentPickerView*)documentPicker needsMaximizedRectForDocument:(id<SFDocument>)document {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return self.backgroundPagesView.frame;
	}
	
	CGRect maximizedDocumentRect = self.articleView.frame;
	
//	maximizedDocumentRect = UIEdgeInsetsInsetRect(maximizedDocumentRect, self.articleView.contentInset);
	
	maximizedDocumentRect.size.height -= self.articleView.contentInset.bottom;
	
	CGFloat contentOffset = self.articleView.contentOffset.y;
	CGFloat headerViewHeight = 0.0; //self.articleView.contentInset.top;
	
	if(contentOffset < headerViewHeight) {
		contentOffset -= headerViewHeight;
		maximizedDocumentRect = CGRectOffset(maximizedDocumentRect, 0.0, -contentOffset);
	}
	
	CGSize contentSize = [[[[[self articleStackController] selectedStack] selectedItem] contentSize] CGSizeValue];
	
	if(!self.articleView.archive || contentSize.height <= CGRectGetHeight(maximizedDocumentRect)) {
		maximizedDocumentRect.origin.y = headerViewHeight;
	}
	
	BOOL hasArticle = self.articleView.visibleArchive != nil;
	
	if(self.articleView.loadingDocument) {
		maximizedDocumentRect.origin.y = 0.0;
	}
	
	if(!hasArticle) {
		CGFloat searchBarHeight = CGRectGetHeight(self.searchBar.frame);
		
		maximizedDocumentRect.origin.y += searchBarHeight;
		maximizedDocumentRect.size.height -= searchBarHeight;
	}
	
	maximizedDocumentRect = [documentPicker convertRect:maximizedDocumentRect fromView:[self articleView]];

	return maximizedDocumentRect;
}

- (BOOL)documentPickerView:(SFDocumentPickerView*)documentPicker shouldFinishPickingDocument:(id<SFDocument>)document {
	// Load the selected document
	SAArticleStack* articleStack = [(SAArticleStackDocument*)document articleStack];
	
	self.articleStackController.selectedStack = articleStack;
	[self loadWithStackItem:[articleStack selectedItem] inStack:articleStack animated:NO];
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[UIView beginAnimations:@"hideDocumentPickerBarButtons" context:NULL]; {
			[UIView setAnimationDuration:SFDocumentPickerMaximizeAnimationDuration];
		
			self.addNewDocumentButtonItem.customView.alpha = 0.0;
			self.documentPickerDoneButtonItem.customView.alpha = 0.0;
		} [UIView commitAnimations];
	}
	
	return YES;
}

- (void)documentPickerView:(SFDocumentPickerView*)documentPicker willFinishPickingDocument:(id<SFDocument>)document {
	_pickingDocument = NO;
	
	// Update our toolbar
	[self restoreToolbarItemsIfNeededAnimated:YES];
	[self updateButtonItems];
	
	[self updateSearchBarAnimated:NO];
	
	[self layoutSubviewsAnimated:NO];
}

- (void)documentPickerView:(SFDocumentPickerView*)documentPicker didFinishPickingDocument:(id<SFDocument>)document {
	// [[[self articleView] layer] removeAllAnimations]; // TODO find out about the extra transition
	self.articleView.hidden = NO;
	
	[self hideDocumentPicker];
}

- (BOOL)documentPickerView:(SFDocumentPickerView*)documentPicker shouldCommitEditingStyle:(SFDocumentPickerViewEditingStyle)editingStyle forDocument:(id<SFDocument>)document {
	if(editingStyle == SFDocumentPickerViewEditingStyleDelete) {
		// Make a new stack if we're deleted the last one
		if(self.articleStackController.stacks.count == 1) {
			SAArticleStack* newArticleStack = [[self articleStackController] addNewArticleStack];
			SAArticleStackDocument* newDocument = [[SAArticleStackDocument alloc] initWithArticleStack:newArticleStack];
			[documentPicker addDocument:newDocument animated:YES];
		}
	}
	
	return YES;
}

- (void)documentPickerView:(SFDocumentPickerView*)documentPicker commitEditingStyle:(SFDocumentPickerViewEditingStyle)editingStyle forDocument:(id<SFDocument>)document {
	if(editingStyle == SFDocumentPickerViewEditingStyleDelete) {
		// Delete this stack
		SAArticleStack* articleStack = [(SAArticleStackDocument*)document articleStack];
		[[self articleStackController] deleteArticleStack:articleStack];
	}
	
	if(editingStyle == SFDocumentPickerViewEditingStyleInsert) {
		// Dissmiss after a short delay
		[self performSelector:@selector(donePickingDocument:)
			withObject:self
			afterDelay:0.0];
	}
	
	[self updateButtonItems];
}

- (SFDocumentView*)documentPickerView:(SFDocumentPickerView*)documentPickerView viewForDocument:(id<SFDocument>)document {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		SFDocumentView* documentView = [documentPickerView dequeueReusableDocumentViewWithIdentifier:@"stack"];
		
		if(!documentView) {
			documentView = [[SAArticleStackDocumentView alloc] initWithDocument:document reuseIdentifier:@"stack"];
		}
		
		documentView.image = [document imageForSize:CGSizeZero];
		
		return documentView;
	}

	return nil;
}

#pragma mark - SFToolbarCustomizationDelegate

- (void)toolbarCustomizationControllerWillHide:(SFToolbarCustomizationController*)customizationController {
	[self updateButtonItems];
	[self updateSearchBarAnimated:NO];
}

- (void)toolbarCustomizationControllerDidHide:(SFToolbarCustomizationController*)customizationController {
	self.toolbarCustomizationController = nil;
	[self storeToolbarItems];

	[self becomeFirstResponderIfNeeded];
}

#pragma mark - WikipediaPickerDelegate

- (void)setLanguageCodeForSearching:(NSString*)languageCode {
	if(languageCode.length == 0) { return; }

	self.searchController.mediaWikiLanguageCode = languageCode;
	self.wikipedia.preferredLanguage = languageCode;

	[[NSUserDefaults standardUserDefaults] setObject:languageCode forKey:@"SASelectedScopeLanguageCode"];
}

- (void)wikipediaPickerController:(WikipediaPicker*)picker didFinishPickingLanguageCode:(NSString*)languageCode {
	[self setLanguageCodeForSearching:languageCode];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView {
	if(self.articleView.webCustomizer.scrollView == scrollView) {
		_shouldRestoreContentOffset = NO;
	} else {
		if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
			[[[self searchBar] searchField] endEditing:NO];
			[[[self documentSearchBar] searchField] endEditing:NO];
		}
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(BOOL)decelerate {
}

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
//	NSLog(@"%@", NSStringFromCGPoint([scrollView contentOffset]));
	
    if(self.articleView.webCustomizer.scrollView == scrollView) {
		[self updateArticleViewEdgeInsets];
		
		BOOL animated = _animatingSubviewLayout; //!scrollView.tracking && !scrollView.decelerating;
		[self layoutSubviewsAnimated:animated];
	}
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView*)scrollView {
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView*)scrollView {
	[[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
	return YES;
}

- (void)scrollViewDidScrollToTop:(UIScrollView*)scrollView {
}

#pragma mark - UIKeyboard Notifications

- (void)keyboardWillShow:(NSNotification*)notification {
	NSDictionary* userInfo = [notification userInfo];
	
	_keyboardRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	
	UIViewAnimationCurve animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
	double animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

	[UIView
		animateWithDuration:animationDuration
		delay:0.0
		options:animationCurve|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction
		animations:^{ [self layoutSubviewsAnimated:YES]; }
		completion:nil];
}

- (void)keyboardDidShow:(NSNotification*)notification {
	_keyboardVisible = YES;
}

- (void)keyboardWillHide:(NSNotification*)notification {
	NSDictionary* userInfo = [notification userInfo];
	
	_keyboardRect = CGRectZero;
	
	UIViewAnimationCurve animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
	double animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

	[UIView
		animateWithDuration:animationDuration
		delay:0.0
		options:animationCurve|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction
		animations:^{ [self layoutSubviewsAnimated:YES]; }
		completion:nil];
}

- (void)keyboardDidHide:(NSNotification*)notification {
	_keyboardVisible = NO;
}

#pragma mark - AKLightbox Notifications

- (void)lightboxWillShow:(NSNotification*)notification {
	if(!CGRectIntersectsRect(self.searchBar.frame, self.view.bounds)) {
		self.searchBar.hidden = YES;
	}
}

- (void)lightboxWillHide:(NSNotification*)notification {
	self.searchBar.hidden = NO;
}

#pragma mark - Private

- (void)applicationDidChangeStatusBarFrame:(NSNotification*)notification {
//	[self layoutSubviews];
}

- (NSArray*)defaultToolbarItems {
	NSArray* toolbarItems = [NSArray arrayWithObjects:
		self.backButtonItem,
		[UIBarButtonItem flexibleSpaceSystemItem],
		self.forwardButtonItem,
		[UIBarButtonItem flexibleSpaceSystemItem],
		self.addBookmarkButtonItem,
		[UIBarButtonItem flexibleSpaceSystemItem],
		self.bookmarksButtonItem,
		[UIBarButtonItem flexibleSpaceSystemItem],
		self.showTabsButtonItem,
		nil];
	return toolbarItems;
}

- (NSArray*)customizableToolbarItems {
	NSArray* toolbarItems = [NSArray arrayWithObjects:
		self.backButtonItem,
		self.forwardButtonItem,
		self.addBookmarkButtonItem,
		self.bookmarksButtonItem,
		self.localizationsButtonItem,
		self.chaptersButtonItem,
		self.documentSearchButtonItem,
		self.showTabsButtonItem,
		nil];
	return toolbarItems;
}

- (NSArray*)documentPickerToolbarItems {
	NSArray* toolbarItems = [NSArray arrayWithObjects:
		[UIBarButtonItem fixedSpaceSystemItem],
		self.addNewDocumentButtonItem,
		[UIBarButtonItem flexibleSpaceSystemItem],
		self.documentPickerDoneButtonItem,
		[UIBarButtonItem fixedSpaceSystemItem],
		nil];
	return toolbarItems;
}

- (void)updateButtonItems {
	self.backButtonItem.enabled = [[self articleStackController] canNavigateBack];
	self.forwardButtonItem.enabled = [[self articleStackController] canNavigateForward];
	
	self.addBookmarkButtonItem.enabled =
	self.documentSearchButtonItem.enabled = 
	self.chaptersButtonItem.enabled = 
	self.localizationsButtonItem.enabled = 
		self.articleView.articleURL != nil && !self.articleView.visibleError;
	
	self.showTabsButtonItem.tag = self.articleStackController.stacks.count;
	
	self.addNewDocumentButtonItem.enabled = self.articleStackController.stacks.count < 9;
}

- (void)updateSearchBarAnimated:(BOOL)animated {
	// Update the picker button in our searchbar
	NSArray* toolbarItems = self.toolbarItems;
	
	self.searchBar.pickerButtonShown =
		!self.articleView.loadingDocument &&
		!self.articleView.failed &&
		self.articleView.articleURL &&
		!([toolbarItems containsObject:[self chaptersButtonItem]] && [toolbarItems containsObject:[self localizationsButtonItem]]);
	
	self.searchBar.searchButtonShown =
		![toolbarItems containsObject:[self documentSearchButtonItem]];

	// ...
	if(self.articleStackController.selectedStack.selectedItem && !self.articleView.failed) {
		NSString* title = self.articleStackController.selectedStack.selectedItem.article.title;
		
		if(title.length > 0) {
			[[self searchBar] setPrompt:title animated:animated];
		} else {
			title = [[[self articleView] articleURL] wikipediaTitle];
			
			if(title.length > 0) {
				[[self searchBar] setPrompt:title animated:animated];
			} else {
				[[self searchBar] setPrompt:NSLocalizedString(@"LOADING_MORE_LABEL", @"") animated:animated];
			}
		}
		
		if(self.articleView.loading) {
			[[self searchBar] setAccessoryType:SASearchBarAccessoryTypeStop animated:animated];
		} else {
			[[self searchBar] setAccessoryType:SASearchBarAccessoryTypeReload animated:animated];
		}
	} else {
		[[self searchBar] setPrompt:NSLocalizedString(@"UNTITLED_NAVIGATIONITEM_TITLE", @"") animated:animated];
		[[self searchBar] setAccessoryType:SASearchBarAccessoryTypeNone animated:animated];
	}
}

- (void)updateHistory {
	NSURL* articleURL = self.articleView.articleURL;
	SAArticle* article = [SAArticle
		articleForURL:articleURL
		inContext:[self managedObjectContext]];
	
	[article updateLastUsedDate];
	
	if(article.title.length == 0) {
		article.title = self.articleView.articleTitle;
	}
	
//	[[self managedObjectContext] save:nil];
}

- (void)updateArticleViewEdgeInsets {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self updateiPadArticleViewEdgeInsets]; return;
	}
	
	CGFloat topInset = 0.0;
	CGFloat topScrollIndicatorInset = 0.0;
	
	if(!_searchingDocument) {
		CGSize searchBarSize = [[self searchBar]
			sizeThatFits:[[self view] bounds].size];
		topInset = searchBarSize.height;
		
		topScrollIndicatorInset = CGRectGetMaxY([[self searchBar] frame]);
	} else {
		CGPoint contentOffset = self.articleView.contentOffset;
		
		if(contentOffset.y < 0.0) {
			topScrollIndicatorInset = -contentOffset.y;
		}
	}
	
	CGFloat bottomInset = CGRectGetHeight([[self toolbar] bounds]);
	
	self.articleView.contentInset = UIEdgeInsetsMake(topInset, 0.0, bottomInset, 0.0);
	self.articleView.scrollIndicatorInsets = UIEdgeInsetsMake(topScrollIndicatorInset, 0.0, bottomInset, 0.0);
}

- (void)becomeFirstResponderIfNeeded {
	if(!self.searchController.active) {
		[self becomeFirstResponder];
	}
}

- (void)setSearchControllerShown:(BOOL)searchControllerShown animated:(BOOL)animated {
	[[self searchController] setActive:searchControllerShown animated:animated completion:nil];
}

- (void)layoutSubviewsAnimated:(BOOL)animated {
	_layoutSubviewsAnimated = animated;
	
	if(animated) {
		id animationBlock = ^{
			[self layoutSubviews];
			_animatingSubviewLayout = YES;
		};
		
		id completionBlock = ^(BOOL finished) {
			_animatingSubviewLayout = NO;
			
			if(!_searchingDocument && self.documentSearchBar) {
				[[self documentSearchBar] removeFromSuperview];
				self.documentSearchBar = nil;
			}
		};
		
		[UIView
			animateWithDuration:0.3
			delay:0.0
			options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState/*|UIViewAnimationOptionAllowUserInteraction*/
			animations:animationBlock
			completion:completionBlock];
	} else {
		[self layoutSubviews];
	}
}

- (void)layoutSubviews {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self layoutForiPad];
		
		return;
	}

//	if(!_layoutSubviewsAnimated) {
//		NSLog(@"non animated layout");
//	}
//
//	NSLog(@"loading: %i, pinned: %i, animated: %i, animating: %i", _loadingDocument, _searchBarPinned, _layoutSubviewsAnimated, _animatingSubviewLayout);
	
	_layoutSubviewsAnimated = NO;
	
	CGRect contentRect = self.view.bounds;
	
//	if(self.navigationController) {
//		contentRect = self.navigationController.view.bounds;
//		contentRect.size.height -= CGRectGetHeight([[UIApplication sharedApplication] statusBarFrame]);
//	}

	CGSize searchBarSize = [[self searchBar]
		sizeThatFits:contentRect.size];
	CGRect searchBarRect = CGRectMake(
		CGRectGetMinX(contentRect), CGRectGetMinY(contentRect),
		CGRectGetWidth(contentRect), searchBarSize.height);
	
	CGSize toolbarSize = [[self toolbar]
		sizeThatFits:contentRect.size];
	CGRect toolbarRect = CGRectMake(
		CGRectGetMinX(contentRect), CGRectGetHeight(contentRect) - toolbarSize.height,
		CGRectGetWidth(contentRect), toolbarSize.height);
	
	if(self.documentPicker) {
		self.documentPicker.frame = CGRectMake(
			CGRectGetMinX(contentRect),
			CGRectGetMinY(contentRect),
			CGRectGetWidth(contentRect),
			CGRectGetHeight(contentRect) - toolbarSize.height);
	}
	
	BOOL hasArticle = self.articleView.visibleArchive != nil;
	
	if(!self.searchController.active && !_loadingDocument && hasArticle && !_launching) {
		CGFloat contentOffset = self.articleView.contentOffset.y;
		contentOffset = -contentOffset - searchBarSize.height;
		
		if(contentOffset < -searchBarSize.height) {
			contentOffset = -searchBarSize.height;
		}
		
		searchBarRect = CGRectOffset(searchBarRect, 0.0, contentOffset);
        
        if(_searchBarPinned) {
        	searchBarRect.origin.y = MAX(CGRectGetMinY(searchBarRect), CGRectGetMinY(contentRect));
        }
	}
	
	if(_pickingDocument || _searchingDocument) {
		searchBarRect.origin.y = CGRectGetMinY(contentRect) - searchBarSize.height;
	}
	
//	self.searchBar.hidden = !CGRectIntersectsRect(contentRect, searchBarRect);
	self.searchBar.frame = searchBarRect;
	
	// Layout when in search mode
	if(self.documentSearchBar) {
		self.documentSearchBar.controlSize = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ?
			SFRegularControlSize :
			SFMiniControlSize;
	
		CGSize documentSearchBarSize = [[self documentSearchBar]
			sizeThatFits:contentRect.size];
		CGRect documentSearchBarRect = CGRectMake(
			CGRectGetMinX(contentRect),
			CGRectGetMaxY(contentRect) - documentSearchBarSize.height,
			documentSearchBarSize.width,
			documentSearchBarSize.height);
			
		if(!CGRectEqualToRect(_keyboardRect, CGRectZero)) {
			CGRect keyboardRect = [[self view] convertRect:_keyboardRect fromView:nil];
			documentSearchBarRect.origin.y = CGRectGetMinY(keyboardRect) - CGRectGetHeight(documentSearchBarRect);
		} else if(!_searchingDocument) {
			documentSearchBarRect = CGRectOffset(documentSearchBarRect, 0.0, CGRectGetHeight(documentSearchBarRect));
		}
		
		self.documentSearchBar.frame = documentSearchBarRect;
	}
	
	if(_searchingDocument) {
		toolbarRect = CGRectOffset(toolbarRect, 0.0, CGRectGetHeight(toolbarRect));
	}
	
	self.articleView.alpha = _launching && !hasArticle ? 0.0 : 1.0;
	self.articleView.hidden = (_loadingDocument || _launching) && !self.articleView.visibleError;

//	self.articleView.alpha = self.articleView.loadingDocument || _launching ?
//		0.0 :
//		1.0;
	
	[[self articleView] setTutorialShown:!hasArticle animated:NO];
	
	self.articleView.frame = contentRect;
	self.toolbar.frame = toolbarRect;
	
//	self.searchBar.alpha = 0.25;
//	self.toolbar.alpha = 0.25;

	[self updateArticleViewEdgeInsets];
}

#pragma mark -

- (void)showDocumentPicker {
	// Cancel flashing the chapter index
	[[[self articleView] chapterIndex] setActive:NO];
	[NSObject cancelPreviousPerformRequestsWithTarget:[self articleView]
		selector:@selector(flashChapterIndex)
		object:nil];
	
	// First update the stack item image
	UIImage* image = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 
		[[self articleView] previewImage] : 
		[self documentPreviewImage];
	SAArticleStackItem* stackItem = self.articleStackController.selectedStack.selectedItem;
	
	SAArticleStackItemImage* stackItemImage = stackItem.image;
	
	NSInteger currentRasterBuild = 2; // change raster build on new stack image styles/files
	
	if([[stackItemImage rasterBuild] integerValue] < currentRasterBuild) { // Seems to be an outdated raster
		stackItemImage = nil;
	}
	
	if(stackItemImage.interfaceIdiom && (UIUserInterfaceIdiom)[[stackItemImage interfaceIdiom] integerValue] != UI_USER_INTERFACE_IDIOM()) {
		stackItemImage = nil;
	}
	
	if(!stackItemImage) {
		stackItemImage = [NSEntityDescription
			insertNewObjectForEntityForName:@"ArticleStackItemImage"
			inManagedObjectContext:[self managedObjectContext]];
		
		stackItemImage.interfaceIdiom = [NSNumber numberWithInteger:UI_USER_INTERFACE_IDIOM()];
		stackItemImage.interfaceOrientation	= [NSNumber numberWithInteger:[self interfaceOrientation]];
		
		stackItemImage.rasterBuild = [NSNumber numberWithInteger:currentRasterBuild];
		
		stackItemImage.stackItem = stackItem;
	}
	
	stackItemImage.image = image;
	
	// Store the content offset in order to restore it later on again
	stackItem.contentOffset = [NSValue valueWithCGPoint:[[self articleView] contentOffset]];
	stackItem.contentSize = [NSValue valueWithCGSize:[[self articleView] contentSize]];
	
	// Make a new picker view if needed
	SFDocumentPickerView* documentPicker = self.documentPicker;
	
	if(!documentPicker) {
		documentPicker = [[SFDocumentPickerView alloc] initWithFrame:CGRectZero];
		self.documentPicker = documentPicker;
	}
	
	documentPicker.delegate = self;
	
	// Make document objects for each article stack
	NSMutableArray* documents = [NSMutableArray array];
	SAArticleStackDocument* selectedDocument = nil;
	
	for(SAArticleStack* articleStack in self.articleStackController.stacks) {
		SAArticleStackDocument* document = [[SAArticleStackDocument alloc] initWithArticleStack:articleStack];
		
		if(articleStack == self.articleStackController.selectedStack) {
			selectedDocument = document;
		}
		
		[documents addObject:document];
	}
	
	documentPicker.documents = documents;
	[documentPicker setSelectedDocument:selectedDocument];
	
	// ...
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UIButton* newDocumentButton = (id)self.addNewDocumentButtonItem.customView;
		[[self backgroundView] addSubview:newDocumentButton];
		[newDocumentButton sizeToFit];
		
		UIButton* documentPickerDoneButton = (id)self.documentPickerDoneButtonItem.customView;
		[[self backgroundView] addSubview:documentPickerDoneButton];
	}
	
	// Update the toolbar
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		[self setToolbarItems:[self documentPickerToolbarItems] animated:YES];
	} else {
		[documentPicker addSubview:[[self addNewDocumentButtonItem] customView]];
		self.addNewDocumentButtonItem.customView.alpha = 0.0;
		
		[documentPicker addSubview:[[self documentPickerDoneButtonItem] customView]];
		self.documentPickerDoneButtonItem.customView.alpha = 0.0;
	}
	
	[self updateButtonItems];

	// Insert the picker in our view hierarchy
	[self layoutSubviews];
	[[self view] insertSubview:documentPicker aboveSubview:[self articleView]];
	
	_pickingDocument = YES;
	
	[[self documentPicker] present:self];
	[self layoutSubviewsAnimated:YES];
	
	self.articleView.hidden = YES;
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.addNewDocumentButtonItem.customView.alpha = 0.0;
		self.documentPickerDoneButtonItem.customView.alpha = 0.0;
		
		[UIView beginAnimations:@"showDocumentPickerBarButtons" context:NULL]; {
			[UIView setAnimationDuration:SFDocumentPickerMaximizeAnimationDuration];
		
			self.addNewDocumentButtonItem.customView.alpha = 1.0;
			self.documentPickerDoneButtonItem.customView.alpha = 1.0;
		} [UIView commitAnimations];
	}
}

- (void)hideDocumentPicker {
	// We fade in if the article view currently displays a error message
	if(!self.articleView.archive || self.articleView.failed) {
		CATransition* transition = [CATransition animation];
	
		transition.type = kCATransitionFade;
		transition.duration = 0.05;
		
		if(!self.articleView.archive || self.articleView.failed) {
			transition.duration = 1.0 / 3.0;
		}
		
		transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
	
		CALayer* layer = self.view.layer;
		[layer addAnimation:transition forKey:@"showArticleViewTransition"];
	}
	
	// We no longer need the document picker
	[[self documentPicker] removeFromSuperview];
	self.documentPicker = nil;
	
	// We also flash the chapter index to indicate the article contents
	[[self articleView]
		performSelector:@selector(flashChapterIndex)
		withObject:nil
		afterDelay:0.125];
	
	// ...
	self.articleView.hidden = NO;
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[[[self addNewDocumentButtonItem] customView] removeFromSuperview];
		[[[self documentPickerDoneButtonItem] customView] removeFromSuperview];
	}
}

- (void)addDocument:(id)sender {
	SAArticleStack* articleStack = [[self articleStackController] addNewArticleStack];
	SAArticleStackDocument* document = [[SAArticleStackDocument alloc] initWithArticleStack:articleStack];
	
	[[self documentPicker] addDocument:document animated:YES];
}

- (void)donePickingDocument:(id)sender {
	[[self documentPicker] dismiss:sender];
}

- (void)loadWithStackItem:(SAArticleStackItem*)stackItem inStack:(SAArticleStack*)stack animated:(BOOL)animated {
	self.articleStackController.selectedStack = stack;
	
	// Update the stacks search text
	NSString* articleURLString = stackItem.article.articleURL;
	
	if(articleURLString.length > 0) {
		NSURL* articleURL = [NSURL URLWithString:articleURLString];
		
		// Equal articles?
		if([[[self articleView] articleURL] isEqual:articleURL]) {
			return;
		}
        
       [self loadArticle:articleURL animated:animated];
	} else {
    	[[self articleView] resetWebView];
		[self loadArticle:nil animated:animated];
	}
}

- (void)addNewDocumentAnimated:(id)document {
	[[self documentPicker] addDocument:document animated:YES];
}

#pragma mark -

- (void)storeContentOffset {
	CGPoint contentOffset = self.articleView.contentOffset;
	self.articleStackController.selectedStack.selectedItem.contentOffset = [NSValue valueWithCGPoint:contentOffset];
}

- (void)restoreContentOffsetIfNeeded {
	if(self.searchController.active) { return; }
    
    NSValue* contentOffsetValue = self.articleStackController.selectedStack.selectedItem.contentOffset;
	CGPoint contentOffset;
	
	if(contentOffsetValue) {
		contentOffset = [contentOffsetValue CGPointValue];
		contentOffset.y = MAX(contentOffset.y, 0.0);
	} else {
		NSString* fragment = [[[self articleView] articleURL] fragment];
		
		if(fragment.length > 0) {
			NSString* javascript = [NSString stringWithFormat:
				@"document.getElementById('%@').getBoundingClientRect().top", fragment];
			NSString* offsetString = [[[self articleView] webView]
				stringByEvaluatingJavaScriptFromString:javascript];
			
			contentOffset = CGPointMake(0.0, [offsetString floatValue]);
		} else {
			contentOffset = CGPointMake(
				0.0,
				0.0); // -self.articleView.contentInset.top);
		}
	}

	[self setContentOffsetIfNeeded:contentOffset];
}

- (void)setContentOffsetIfNeeded:(CGPoint)contentOffset {
	if(_shouldRestoreContentOffset) {
		BOOL animated = NO; // contentOffset.y < 0.0;
		[[self articleView] setContentOffset:contentOffset animated:animated];
	}
}

#pragma mark -

- (void)storeToolbarItems {
	NSMutableArray* toolbarItemIdentifiers = [NSMutableArray array];
	
	for(SFBarButtonItem* buttonItem in self.toolbarItems) {
		if(![buttonItem isKindOfClass:[SFBarButtonItem class]]) { continue; }
		if(!buttonItem.itemIdentifier) { continue; }
		
		[toolbarItemIdentifiers addObject:[buttonItem itemIdentifier]];
	}

	[[NSUserDefaults standardUserDefaults] setObject:toolbarItemIdentifiers forKey:@"SAArticleViewToolbarItems"];
}

- (void)restoreToolbarItemsIfNeededAnimated:(BOOL)animated {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self restoreiPadToolbarItemsIfNeeded]; return;
	}
	
	NSArray* toolbarItemIdentifiers = [[NSUserDefaults standardUserDefaults] arrayForKey:@"SAArticleViewToolbarItems"];
	
	if(toolbarItemIdentifiers.count == 0) {
		[self setToolbarItems:[self defaultToolbarItems] animated:animated];
		return;
	}
	
	NSArray* customizableToolbarItems = self.customizableToolbarItems;
	NSMutableArray* storedToolbarItems = [NSMutableArray array];
	
	for(NSString* itemIdentifier in toolbarItemIdentifiers) {
		for(SFBarButtonItem* buttonItem in customizableToolbarItems) {
			if([[buttonItem itemIdentifier] isEqualToString:itemIdentifier]) {
				[storedToolbarItems addObject:buttonItem];
				break;
			}
		}
	}
	
	NSMutableArray* toolbarItems = [NSMutableArray array];
	
	if(storedToolbarItems.count == 1) {
		[toolbarItems addObject:[UIBarButtonItem flexibleSpaceSystemItem]];
		[toolbarItems addObject:[storedToolbarItems lastObject]];
		[toolbarItems addObject:[UIBarButtonItem flexibleSpaceSystemItem]];
	} else {
		for(UIBarButtonItem* buttonItem in storedToolbarItems) {
			[toolbarItems addObject:buttonItem];
			   
			if(buttonItem != storedToolbarItems.lastObject) {
				[toolbarItems addObject:[UIBarButtonItem flexibleSpaceSystemItem]];
			}
		}
	}
	
	[self setToolbarItems:toolbarItems animated:animated];
}

#pragma mark - iPad only

@synthesize backgroundView = _backgroundView;
@synthesize backgroundPagesView = _backgroundPagesView;
@synthesize backgroundPagesToolbarHeaderView = _backgroundPagesToolbarHeaderView;
@synthesize backgroundPagesHeaderView = _backgroundPagesHeaderView;
@synthesize backgroundPagesLeftBorderView = _backgroundPagesLeftBorderView;
@synthesize backgroundPagesRightBorderView = _backgroundPagesRightBorderView;
@synthesize backgroundPagesFooterView = _backgroundPagesFooterView;
@synthesize actionSheet = _actionSheet;
@synthesize bookmarksPopoverController = _bookmarksPopoverController;
@synthesize localizationsController = _localizationsController;
@synthesize chaptersPopoverController = _chaptersPopoverController;
@synthesize searchbarButtonItem = _searchbarButtonItem;

- (void)loadViewForiPad {
	// wooden background view
	UIImageView* backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
	self.backgroundView = backgroundView;
	[[self view] addSubview:backgroundView];

	// paper stack view
	UIView* backgroundPagesView = [[UIView alloc] initWithFrame:[[self view] bounds]];
	
    self.backgroundPagesView = backgroundPagesView;
	[[self view] insertSubview:backgroundPagesView aboveSubview:backgroundView];
	
	// init the article view
	AKArticleView* articleView = [[AKArticleView alloc] initWithFrame:[[self view] bounds]];
		
//	articleView.alpha = 0.0; // initially hidden
	
	UIColor* linenColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"linen.png"]];
	articleView.webCustomizer.scrollView.backgroundColor = linenColor;
	
	[backgroundPagesView addSubview:articleView];
	self.articleView = articleView;
	
	// toolbar header
	UIImage* toolbarHeaderImage = [[UIImage imageNamed:@"paperStackToolbar.png"]
		stretchableImageWithLeftCapWidth:16.0 topCapHeight:0];
	UIImageView* backgroundPagesToolbarHeaderView = [[UIImageView alloc] initWithImage:toolbarHeaderImage];
	
	self.backgroundPagesToolbarHeaderView = backgroundPagesToolbarHeaderView;
	[backgroundPagesView insertSubview:backgroundPagesToolbarHeaderView aboveSubview:articleView];
	
	// paper footer
	UIImage* footerImage = [[UIImage imageNamed:@"paperStackFooter.png"]
		stretchableImageWithLeftCapWidth:16.0 topCapHeight:0];
	UIImageView* backgroundPagesFooterView = [[UIImageView alloc] initWithImage:footerImage];
	
	self.backgroundPagesFooterView = backgroundPagesFooterView;
	[backgroundPagesView insertSubview:backgroundPagesFooterView aboveSubview:articleView];
	
	// left page border
	UIImage* leftPageBorderImage = [[UIImage imageNamed:@"paperStackLeft.png"]
		stretchableImageWithLeftCapWidth:0.0 topCapHeight:8.0];
	UIImageView* backgroundPagesLeftBorderView = [[UIImageView alloc] initWithImage:leftPageBorderImage];
	
	self.backgroundPagesLeftBorderView = backgroundPagesLeftBorderView;
	[backgroundPagesView insertSubview:backgroundPagesLeftBorderView aboveSubview:articleView];
	
	// right page border
	UIImage* rightPageBorderImage = [UIImage
		imageWithCGImage:[leftPageBorderImage CGImage]
		scale:[leftPageBorderImage scale]
		orientation:UIImageOrientationUpMirrored];
	UIImageView* backgroundPagesRightBorderView = [[UIImageView alloc] initWithImage:rightPageBorderImage];
	
	self.backgroundPagesRightBorderView = backgroundPagesRightBorderView;
	[backgroundPagesView insertSubview:backgroundPagesRightBorderView aboveSubview:articleView];
	
	// init the toolbar
	UIToolbar* toolbar = [[UIToolbar alloc] initWithFrame:CGRectZero];
	
	[toolbar setBackgroundImage:[UIImage imageNamed:@"whitespace.png"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];

	[toolbar sizeToFit];
	toolbar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleWidth;
		
	[[backgroundPagesToolbarHeaderView superview] insertSubview:toolbar aboveSubview:backgroundPagesToolbarHeaderView];
	self.toolbar = (id)toolbar;

	// search bar
	CGRect searchBarRect = CGRectMake(0.0, 0.0, 364.0, 32.0);
	SASearchBar* searchBar = [[SASearchBar alloc] initWithFrame:searchBarRect];
		
	[searchBar sizeToFit];
	self.searchBar = searchBar;
	
	// …
	[[self articleView] initPlaceholderScrollViewIfNeeded];
	self.articleView.placeholderScrollView.backgroundColor = [UIColor colorWithPatternImage:
		[UIImage imageNamed:@"linen.png"]];
	
//	self.backgroundPagesLeftBorderView.hidden = self.backgroundPagesRightBorderView.hidden = self.backgroundPagesToolbarHeaderView.hidden = self.backgroundPagesFooterView.hidden = self.backgroundView.hidden = YES;
}

- (void)loadButtonItemsForiPad {
	self.backButtonItem = (id)[self iPadButtonItemWithIdentifier:@"navigateBack" borderType:UIViewContentModeLeft action:@selector(back:)];
	self.forwardButtonItem = (id)[self iPadButtonItemWithIdentifier:@"navigateForward" borderType:UIViewContentModeRight action:@selector(forward:)];
	
	self.showTabsButtonItem = (id)[self iPadButtonItemWithIdentifier:@"navigationTab" borderType:0 action:@selector(showArticleStacks:)];
	
	self.bookmarksButtonItem = (id)[self iPadButtonItemWithIdentifier:@"bookmarks" borderType:UIViewContentModeLeft action:@selector(showBookmarks:)];
	
	SEL actionButtonItemAction = [UIActivityViewController class] ?
		@selector(showActivityPicker:) :
		@selector(showActionSheet:);
	self.addBookmarkButtonItem = (id)[self iPadButtonItemWithIdentifier:@"addBookmark" borderType:UIViewContentModeRight action:actionButtonItemAction];
	
	self.documentSearchButtonItem = (id)[self iPadButtonItemWithIdentifier:@"search" borderType:UIViewContentModeLeft action:@selector(findInDocument:)];
	
	self.localizationsButtonItem = (id)[self iPadButtonItemWithIdentifier:@"languagesButtonItem" borderType:UIViewContentModeLeft action:@selector(showLocalizationPicker:)];
	self.chaptersButtonItem = (id)[self iPadButtonItemWithIdentifier:@"TOCButtonItem" borderType:UIViewContentModeRight action:@selector(showChapterPicker:)];
	
	self.searchbarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[self searchBar]];
	
	self.toolbarItems = [NSArray arrayWithObjects:
		self.backButtonItem,
		self.forwardButtonItem,
		[self iPadSeparatorButtonItem],
		self.showTabsButtonItem,
		[self iPadSeparatorButtonItem],
		self.bookmarksButtonItem,
		self.addBookmarkButtonItem,
		self.searchbarButtonItem,
		self.documentSearchButtonItem,
		self.localizationsButtonItem,
		self.chaptersButtonItem,
		nil];
		
	UIButton* newDocumentButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[newDocumentButton setTitle:NSLocalizedString(@"BARBUTTON_ITEM_NEW_PAGE", @"") forState:UIControlStateNormal];
	[newDocumentButton addTarget:self action:@selector(addDocument:) forControlEvents:UIControlEventTouchUpInside];
	
	[self setWoodenStyle:newDocumentButton barStyle:UIBarButtonItemStyleBordered];
	
	self.addNewDocumentButtonItem = [[UIBarButtonItem alloc] initWithCustomView:newDocumentButton];
	
	UIButton* doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[doneButton addTarget:self action:@selector(donePickingDocument:) forControlEvents:UIControlEventTouchUpInside];
	
	NSString* doneButtonTitle = NSLocalizedString(@"UIBarButtonSystemItemDone", @"");
	[doneButton setTitle:doneButtonTitle forState:UIControlStateNormal];

	[self setWoodenStyle:doneButton barStyle:UIBarButtonItemStyleDone];

	self.documentPickerDoneButtonItem = [[UIBarButtonItem alloc] initWithCustomView:doneButton];
}

- (void)layoutForiPad {
	CGRect contentRect = self.backgroundPagesView.superview.bounds;

	CGRect backgroundPagesRect = contentRect;
	self.backgroundPagesView.frame = backgroundPagesRect;
    
	self.backgroundPagesToolbarHeaderView.frame = CGRectMake(
		0.0,
		3.0,
		CGRectGetWidth(contentRect),
		self.backgroundPagesToolbarHeaderView.image.size.height);
		
	self.backgroundPagesFooterView.frame = CGRectMake(
		0.0,
		CGRectGetMaxY(contentRect) - self.backgroundPagesFooterView.image.size.height,
		CGRectGetWidth(contentRect),
		self.backgroundPagesFooterView.image.size.height);

	self.backgroundPagesLeftBorderView.frame = CGRectMake(
		2.0,
		CGRectGetMaxY(self.backgroundPagesToolbarHeaderView.frame),
		self.backgroundPagesLeftBorderView.image.size.width,
		CGRectGetMinY(self.backgroundPagesFooterView.frame) - CGRectGetMaxY(self.backgroundPagesToolbarHeaderView.frame));
	self.backgroundPagesRightBorderView.frame = CGRectMake(
		CGRectGetWidth(contentRect) - 6.0,
		CGRectGetMaxY(self.backgroundPagesToolbarHeaderView.frame),
		self.backgroundPagesRightBorderView.image.size.width,
		CGRectGetMinY(self.backgroundPagesFooterView.frame) - CGRectGetMaxY(self.backgroundPagesToolbarHeaderView.frame));
	
    [self layoutArticleView];
	
	CGRect toolbarRect = CGRectMake(
		CGRectGetMinX(self.backgroundPagesToolbarHeaderView.frame) + 6.0,
		CGRectGetMinY(self.backgroundPagesToolbarHeaderView.frame) + 3.0,
		CGRectGetWidth(self.backgroundPagesToolbarHeaderView.frame) - 12.0,
		44.0);
	self.toolbar.frame = toolbarRect;
	
    if(self.documentPicker) {
		self.documentPicker.frame = contentRect;
	}
	
	self.backgroundPagesView.hidden = self.documentPicker != nil;
	
	// ...
	CGRect searchBarRect = self.searchBar.bounds;
	
	if(UIInterfaceOrientationIsPortrait([self interfaceOrientation])) {
		searchBarRect.size.width = 292.0;
	} else {
		searchBarRect.size.width = 548.0;
	}
	
	self.searchBar.bounds = searchBarRect;
	
	// ...
	UIButton* newDocumentButton = (id)self.addNewDocumentButtonItem.customView;
		
	CGRect newDocumentButtonRect = newDocumentButton.frame;
	newDocumentButtonRect.origin.x = CGRectGetMinX(contentRect) + 20.0;
	newDocumentButtonRect.origin.y = CGRectGetMaxY(contentRect) - CGRectGetHeight(newDocumentButtonRect) - 15.0;
		
	newDocumentButton.frame = newDocumentButtonRect;
	[[newDocumentButton superview] bringSubviewToFront:newDocumentButton];
		
	// ...
	UIButton* documentPickerDoneButton = (id)self.documentPickerDoneButtonItem.customView;
		
	CGRect documentPickerDoneButtonRect = documentPickerDoneButton.frame;
	documentPickerDoneButtonRect.origin.x = CGRectGetMaxX(contentRect) - CGRectGetWidth(documentPickerDoneButtonRect) - 20.0;
	documentPickerDoneButtonRect.origin.y = CGRectGetMaxY(contentRect) - CGRectGetHeight(documentPickerDoneButtonRect) - 15.0;
		
	documentPickerDoneButton.frame = documentPickerDoneButtonRect;
	[[documentPickerDoneButton superview] bringSubviewToFront:documentPickerDoneButton];
	
	// document search
	if(self.documentSearchBar) {
		self.documentSearchBar.controlSize = SFRegularControlSize;
	
		CGSize documentSearchBarSize = [[self documentSearchBar]
			sizeThatFits:contentRect.size];
		CGRect documentSearchBarRect = CGRectMake(
			CGRectGetMinX(contentRect),
			CGRectGetMaxY(contentRect) - documentSearchBarSize.height,
			documentSearchBarSize.width,
			documentSearchBarSize.height);

		if(!CGRectEqualToRect(_keyboardRect, CGRectZero)) {
			CGRect keyboardRect = [[self view] convertRect:_keyboardRect fromView:nil];
			documentSearchBarRect.origin.y = CGRectGetMinY(keyboardRect) - CGRectGetHeight(documentSearchBarRect);
		} else if(!_searchingDocument) {
			documentSearchBarRect = CGRectOffset(documentSearchBarRect, 0.0, CGRectGetHeight(documentSearchBarRect));
		}
		
		self.documentSearchBar.frame = documentSearchBarRect;
	}
}

- (void)layoutArticleView {
	CGFloat topInset = 1.0;

	self.articleView.frame = CGRectMake(
		CGRectGetMaxX(self.backgroundPagesLeftBorderView.frame),
		CGRectGetMaxY(self.backgroundPagesToolbarHeaderView.frame) - topInset,
		CGRectGetMinX(self.backgroundPagesRightBorderView.frame) - CGRectGetMaxX(self.backgroundPagesLeftBorderView.frame),
		CGRectGetMinY(self.backgroundPagesFooterView.frame) - CGRectGetMaxY(self.backgroundPagesToolbarHeaderView.frame) + (topInset + 5.0));
	
	BOOL hasArticle = self.articleView.visibleArchive != nil;
//	self.articleView.webView.alpha = self.articleView.loadingDocument || _launching ?
//		0.0 :
//		1.0;

    self.articleView.webView.hidden = _loadingDocument;

	[[self articleView] setTutorialShown:!hasArticle && !_launching animated:NO];
}

- (void)updateiPadForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
}

- (void)updateiPadArticleViewEdgeInsets {
}

- (void)restoreiPadToolbarItemsIfNeeded {
}

- (UIBarButtonItem*)iPadButtonItemWithIdentifier:(NSString*)itemIdentifier borderType:(UIViewContentMode)borderType action:(SEL)action {
	UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];

	button.showsTouchWhenHighlighted = YES;
	button.contentEdgeInsets = UIEdgeInsetsMake(8.0, 10.0, 6.0, 8.0);

	[button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
	
	UIImage* image = [UIImage imageNamed:itemIdentifier];
	[button setImage:image forState:UIControlStateNormal];
	
	[button sizeToFit];

	UIBarButtonItem* buttonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
	return buttonItem;
}

- (UIBarButtonItem*)iPadSeparatorButtonItem {
	UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];

	button.userInteractionEnabled = NO;

	[button setImage:[UIImage imageNamed:@"toolbarSeparator"] forState:UIControlStateNormal];
	
	[button sizeToFit];
    
    // button.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.33];
	
	UIBarButtonItem* buttonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

	return buttonItem;
}

- (void)setPaperStyle:(UIButton*)button borderType:(UIViewContentMode)borderType {
	UIImage* backgroundImage = nil;
	UIImage* highlightedBackgroundImage = nil;
	
	UIEdgeInsets imageInsets = UIEdgeInsetsMake(2.0, 3.0, 0.0, 0.0);
	
	if(borderType == UIViewContentModeLeft) {
		backgroundImage = [UIImage imageNamed:@"paperButtonLeftBackground.png"];
		highlightedBackgroundImage = [UIImage imageNamed:@"paperButtonLeftBackgroundHighlighted.png"];
	} else if(borderType == UIViewContentModeRight) {
		backgroundImage = [UIImage imageNamed:@"paperButtonRightBackground.png"];
		highlightedBackgroundImage = [UIImage imageNamed:@"paperButtonRightBackgroundHighlighted.png"];
		
		imageInsets.left -= 2.0;
	} else if(borderType == UIViewContentModeCenter) {
		backgroundImage = [UIImage imageNamed:@"paperButtonCenterBackground.png"];
		highlightedBackgroundImage = [UIImage imageNamed:@"paperButtonCenterBackgroundHighlighted.png"];
	}  else {
		backgroundImage = [UIImage imageNamed:@"paperButtonBackground.png"];
		highlightedBackgroundImage = [UIImage imageNamed:@"paperButtonBackgroundHighlighted.png"];
	}
	
	[button setBackgroundImage:backgroundImage forState:UIControlStateNormal];
	[button setBackgroundImage:highlightedBackgroundImage forState:UIControlStateHighlighted];
	
	button.imageEdgeInsets = imageInsets;

	button.adjustsImageWhenHighlighted = NO;
	button.showsTouchWhenHighlighted = NO;
	
	[button sizeToFit];
}

- (void)setWoodenStyle:(UIButton*)button barStyle:(UIBarButtonItemStyle)barStyle {
	UIImage* backgroundImage = nil;
	
	if(barStyle == UIBarButtonItemStyleDone) {
		backgroundImage = [[UIImage imageNamed:@"woodenDocumentPickerDoneButtonBackground.png"]
			stretchableImageWithLeftCapWidth:5.0 topCapHeight:0.0];
	} else {
		backgroundImage = [[UIImage imageNamed:@"woodenDocumentPickerButtonBackground.png"]
			stretchableImageWithLeftCapWidth:5.0 topCapHeight:0.0];
	}

	[button setBackgroundImage:backgroundImage forState:UIControlStateNormal];

	UIImage* highlightedBackgroundImage = [[UIImage imageNamed:@"woodenDocumentPickerButtonBackgroundHighlighted.png"]
		stretchableImageWithLeftCapWidth:5.0 topCapHeight:0.0];
	[button setBackgroundImage:highlightedBackgroundImage forState:UIControlStateHighlighted];
		
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[button setTitleShadowColor:[[UIColor blackColor] colorWithAlphaComponent:0.5] forState:UIControlStateNormal];
		
	button.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
	button.reversesTitleShadowWhenHighlighted = NO;
	button.adjustsImageWhenHighlighted = NO;
	button.showsTouchWhenHighlighted = NO;
		
	button.titleLabel.font = [UIFont systemFontOfSize:16];
	button.contentEdgeInsets = UIEdgeInsetsMake(0.0, 11.0, 0.0, 10.0);
	
	button.opaque = NO;
	button.backgroundColor = [UIColor clearColor];
	
	[button sizeToFit];
}

- (void)dismissAllPopoverControllerExcept:(UIPopoverController*)popoverController animated:(BOOL)animated {
	if(self.bookmarksPopoverController != popoverController) {
		[[self bookmarksPopoverController] dismissPopoverAnimated:animated];
		// self.bookmarksPopoverController = nil;
	}
	
	if(self.localizationsController != popoverController) {
		[[self localizationsController] dismissPopoverAnimated:animated];
		self.localizationsController = nil;
	}
	
	if(self.chaptersPopoverController != popoverController) {
		[[self chaptersPopoverController] dismissPopoverAnimated:animated];
		self.chaptersPopoverController = nil;
	}
	
	if(self.activitiesPopoverController != popoverController) {
		[[self activitiesPopoverController] dismissPopoverAnimated:animated];
		self.activitiesPopoverController = nil;
	}
	
	if(self.searchController.contentPopoverController != popoverController) {
    	if(!self.openURLContext) {
			[self setSearchControllerShown:NO animated:animated];
        }
	}
	
	if(self.actionSheet != (id)popoverController) {
		[[self actionSheet]
			dismissWithClickedButtonIndex:[[self actionSheet] cancelButtonIndex]
			animated:YES];
		self.actionSheet = nil;
	}
	
	if(_searchingDocument && (id)popoverController != self.documentSearchBar) {
		[self cancelFindInDocument:popoverController];
	}
}

- (UIImage*)documentPreviewImage {
	// hide the toolbar
	self.toolbar.hidden = YES;
    
	UIScrollView* scrollView = self.articleView.webCustomizer.scrollView;
	
	scrollView.showsHorizontalScrollIndicator = NO;
	scrollView.showsVerticalScrollIndicator = NO;
	
	// ...
	UIImage* previewImage = nil;
	
	static CGFloat const scale = 1.0;
	
	CGSize previewImageSize = CGSizeMake(
		ceilf(CGRectGetWidth(self.backgroundPagesView.frame) * scale),
		ceilf(CGRectGetHeight(self.backgroundPagesView.frame) * scale));
	
	UIGraphicsBeginImageContext(previewImageSize); {
		CGContextRef context = UIGraphicsGetCurrentContext();
		
		CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
		CGContextScaleCTM(context, scale, scale);
		
		[[[self backgroundPagesView] layer] renderInContext:context];
		
		previewImage = UIGraphicsGetImageFromCurrentImageContext();
	} UIGraphicsEndImageContext();
	
	scrollView.showsHorizontalScrollIndicator = YES;
	scrollView.showsVerticalScrollIndicator = YES;
    
    self.toolbar.hidden = NO;
	
	return previewImage;
}

#pragma mark - UIPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController*)popoverController {
	if(popoverController == self.bookmarksPopoverController) {
		BookmarkPickerController* bookmarkPicker = [[(UINavigationController*)[popoverController contentViewController] viewControllers] firstObject];
		[bookmarkPicker	updateUserDefaults];
	}
	
	return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController*)popoverController {
//	if(popoverController == self.bookmarksPopoverController) { self.bookmarksPopoverController = nil; }
	if(popoverController == self.localizationsController) { self.localizationsController = nil; }
	if(popoverController == self.chaptersPopoverController) { self.chaptersPopoverController = nil; }
}

#pragma mark - BookmarkPickerControllerDelegate

- (void)bookmarkPickerShouldDismiss:(BookmarkPickerController*)bookmarkPicker animated:(BOOL)animated {
	[[self bookmarksPopoverController] dismissPopoverAnimated:animated];
//	self.bookmarksPopoverController = nil;
}

#pragma mark - AKLanguagePickerDelegate

- (BOOL)languagePickerShouldDismiss:(AKLanguagePicker*)picker animated:(BOOL)animated {
	if(self.localizationsController.contentViewController == picker.navigationController) {
		[[self localizationsController] dismissPopoverAnimated:animated];
		self.localizationsController = nil;
	}
	
	if(self.chaptersPopoverController.contentViewController == picker.navigationController) {
		[[self chaptersPopoverController] dismissPopoverAnimated:animated];
		self.chaptersPopoverController = nil;
	}
	
	return YES;
}

@end
