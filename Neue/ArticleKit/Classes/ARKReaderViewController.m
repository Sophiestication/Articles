//
//  ARKReaderViewController.m
//  Articles
//
//  Created by Sophia Teutschler on 23.12.11.
//  Copyright (c) 2011 Sophiestication Software. All rights reserved.
//

#import "ARKReaderViewController.h"

#import "ARKWebViewController.h"

#import "ARKManagedObjectStoreController.h"

#import "ARKHistoryController.h"
#import "ARKHistoryItem+Additions.h"

#import "UIColor+Tint.h"
#import "UIImage+Additions.h"

@interface ARKReaderViewController()<SUIPiledViewDataSource, SUIPiledViewDelegate, ARKWebViewControllerDelegate>

@property(nonatomic, strong) NSMutableSet* reuseableWebViewControllers;

@property(nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property(nonatomic, strong) ARKHistoryController* historyController;

@property(nonatomic, copy) NSURL* articleURLScheduledForLoading;

@end

@implementation ARKReaderViewController

#pragma mark - Construction & Destruction

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		self.reuseableWebViewControllers = [NSMutableSet setWithCapacity:2];

		self.delegate = self;
		self.dataSource = self;

		self.hidesBottomBarWhenPushed = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
	}

    return self;
}

#pragma mark - ARKArticleViewController

- (void)loadArticle:(NSURL*)articleURL animated:(BOOL)animated {
	if(!self.managedObjectContext) {
		self.articleURLScheduledForLoading = articleURL;
		return;
	}

	ARKHistoryItem* selectedHistoryItem = self.historyController.selectedHistoryItem;
	ARKHistoryItem* newSelectedHistoryItem = [[self historyController] navigateToURL:articleURL];

	if(selectedHistoryItem == newSelectedHistoryItem) { return; }

	NSInteger selectedItemIndex = [[newSelectedHistoryItem index] integerValue];
	[self setSelectedItemIndex:selectedItemIndex animated:animated completion:nil];
}

#pragma mark - UIViewController

- (void)loadView {
    [super loadView];

	[ARKManagedObjectStoreController requestManagedObjectContextOfType:ARKManagedObjectStoreTypeHistory completion:^(NSManagedObjectContext* managedObjectContext, NSError* error) {
		self.managedObjectContext = managedObjectContext; // TODO Add error handling
		[self initHistoryControllerIfNeeded];

		ARKHistoryItem* selectedHistoryItem = self.historyController.selectedHistoryItem;

		NSURL* articleURLScheduledForLoading = self.articleURLScheduledForLoading;

		if(selectedHistoryItem && !articleURLScheduledForLoading) {
			[self setSelectedItemIndex:[[selectedHistoryItem index] integerValue] animated:YES completion:nil];
		} else {
			NSURL* URL = articleURLScheduledForLoading ?
				articleURLScheduledForLoading :
				[NSURL URLWithString:@"http://en.wikipedia.org/wiki/Art_Deco"];
			[self loadArticle:URL animated:YES];
		}

		self.articleURLScheduledForLoading = nil;

		[self loadButtonItemsAnimated:YES];
	}];
}

#pragma mark - ARKWebViewControllerDelegate

- (void)webViewController:(ARKWebViewController*)webViewController shouldLoadArticleWithURL:(NSURL*)URL {
	[self loadArticle:URL animated:YES];
}

#pragma mark - SUIPiledViewDataSource

- (NSUInteger)numberOfItemsInPiledViewController:(SUIPiledViewController*)piledViewController {
	return self.historyController.numberOfHistoryItems;
}

- (UIViewController*)piledViewController:(SUIPiledViewController*)piledViewController viewControllerForItemAtIndex:(NSInteger)index {
	ARKHistoryItem* historyItem = [[self historyController] historyItemAtIndex:index];
	if(!historyItem) { return nil; }

	ARKWebViewController* viewController = [self dequeueReuseableWebViewControllerForHistoryItem:historyItem];
	return viewController;
}

#pragma mark - SUIPiledViewDelegate

- (void)piledViewController:(SUIPiledViewController*)piledViewController willPresentViewController:(ARKWebViewController*)viewController forItemAtIndex:(NSInteger)index {
	[viewController loadArticleIfNeeded];
	[self updateContentInsetsForWebViewController:viewController];
}

- (void)piledViewController:(SUIPiledViewController*)piledViewController didDismissViewController:(UIViewController*)viewController forItemAtIndex:(NSInteger)index {
	[[self reuseableWebViewControllers] addObject:viewController];
}

- (void)piledViewController:(SUIPiledViewController*)piledViewController didSelectViewController:(UIViewController*)viewController forItemAtIndex:(NSInteger)index {
	[self setUserInteractionEnabled:NO forViewController:[self selectedViewController]];
	[[self historyController] navigateToItemAtIndex:index];
	[self setUserInteractionEnabled:YES forViewController:viewController];
}

#pragma mark - Private

- (void)initHistoryControllerIfNeeded {
	if(self.historyController) { return; }
	
	NSManagedObjectContext* managedObjectContext = self.managedObjectContext;
		
	ARKHistoryController* historyController = [[ARKHistoryController alloc] initWithIdentifier:@"default" managedObjectContext:managedObjectContext];
	self.historyController = historyController;
}

#pragma mark - Reuseable View Controllers

- (ARKWebViewController*)dequeueReuseableWebViewControllerForHistoryItem:(ARKHistoryItem*)historyItem {
	NSURL* articleURL = historyItem.articleURL;
	ARKWebViewController* webViewController;

	for(ARKWebViewController* reuseableWebViewController in self.reuseableWebViewControllers) {
		if([articleURL isEqual:[reuseableWebViewController representedURL]]) {
			webViewController = reuseableWebViewController;
			break;
		}
	}

	if(!webViewController) {
		webViewController = [[self reuseableWebViewControllers] anyObject];
		[webViewController prepareForReuse];
	}

	if(webViewController) {
		[[self reuseableWebViewControllers] removeObject:webViewController];
	} else {
		webViewController = [[ARKWebViewController alloc] init];
		webViewController.delegate = self;
	}

	webViewController.representedURL = articleURL;
	
	return webViewController;
}

- (void)enqueuReuseableWebViewController:(ARKWebViewController*)webViewController {
	if(!webViewController) { return; }

//	NSLog(@"Enqueue %@", webViewController);
	[[self reuseableWebViewControllers] addObject:webViewController];
}

- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled forViewController:(UIViewController*)viewController {
//	if(![viewController isViewLoaded]) { return; }
//	viewController.view.userInteractionEnabled = userInteractionEnabled;
}

- (void)updateContentInsetsForWebViewController:(ARKWebViewController*)webViewController {
	CGFloat navigationBarHeight = 0.0;

	if(!self.navigationController.navigationBarHidden) {
		navigationBarHeight = CGRectGetHeight(self.navigationController.navigationBar.bounds);
	}

	if(![[UIApplication sharedApplication] isStatusBarHidden]) {
		navigationBarHeight += CGRectGetHeight([[UIApplication sharedApplication] statusBarFrame]);
	}

	CGFloat toolbarHeight = 0.0;

	if(!self.navigationController.toolbarHidden) {
		toolbarHeight = CGRectGetHeight(self.navigationController.toolbar.frame);
	}

	UIScrollView* scrollView = webViewController.scrollView;
	scrollView.contentInset = UIEdgeInsetsMake(navigationBarHeight, 0.0, toolbarHeight, 0.0);
	scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(navigationBarHeight, 0.0, toolbarHeight, 0.0);
}

#pragma mark -

- (void)loadButtonItemsAnimated:(BOOL)animated {
	BOOL shouldUsePadLayout = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;

	UIBarButtonItem* bookmarksButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:nil action:NULL];

	UIBarButtonItem* actionButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:nil action:NULL];

	UIBarButtonItem* localizationsButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:nil action:NULL];

	UIBarButtonItem* tableOfContentsButtonItem = [[UIBarButtonItem alloc]
			initWithImage:[UIImage imageNamed:@"tableofcontents-buttonitem"]
			landscapeImagePhone:nil
			style:UIBarButtonItemStylePlain
			target:nil
			action:nil];

	if(shouldUsePadLayout) {
		UIBarButtonItem* navigateBackButtonItem = [[UIBarButtonItem alloc]
			initWithImage:[UIImage imageNamed:@"navigateback-buttonitem"]
			landscapeImagePhone:nil
			style:UIBarButtonItemStylePlain
			target:nil
			action:nil];
		UIBarButtonItem* navigateForwardButtonItem = [[UIBarButtonItem alloc]
			initWithImage:[UIImage imageNamed:@"navigateforward-buttonitem"]
			landscapeImagePhone:nil
			style:UIBarButtonItemStylePlain
			target:nil
			action:nil];

		[[self navigationItem] setLeftBarButtonItems:@[ navigateBackButtonItem, navigateForwardButtonItem, bookmarksButtonItem, actionButtonItem ] animated:animated];

		UISearchBar* searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
		[[self navigationItem] setTitleView:searchBar];

		[[self navigationItem] setRightBarButtonItems:@[ tableOfContentsButtonItem, localizationsButtonItem ] animated:animated];

//		[[self navigationController] setNavigationBarHidden:NO animated:animated];
	} else {
		UIBarButtonItem* searchButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:nil action:NULL];

		NSArray* buttonItems = @[
			searchButtonItem,
			[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL],
			bookmarksButtonItem,
			[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL],
			actionButtonItem,
			[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL],
			localizationsButtonItem,
			[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL],
			tableOfContentsButtonItem];
		[self setToolbarItems:buttonItems animated:animated];

//		[[self navigationController] setToolbarHidden:NO animated:animated];
	}
}

#pragma mark -

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
	if(motion != UIEventSubtypeMotionShake) { return; }

	UINavigationController* navigationController = self.navigationController;
	[navigationController popToRootViewControllerAnimated:YES];
}

@end