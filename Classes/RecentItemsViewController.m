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

#import "RecentItemsViewController.h"
#import "RecentItemsViewController+Private.h"

#import "SAArticle.h"

#import "Articles.h"

#import "NSArray+Additions.h"
#import "NSURL+Wikipedia.h"
#import "UINavigationController+Additions.h"

#import <MobileCoreServices/MobileCoreServices.h>

@implementation RecentItemsViewController

@synthesize doneButtonItem = _doneButtonItem;
@synthesize clearButtonItem = _clearButtonItem;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize searchResultsController = _searchResultsController;
@synthesize groupDateFormatter = _groupDateFormatter;
@synthesize userDefaults = _userDefaults;

#pragma mark -
#pragma mark Construction & Destruction

+ (id)viewController {
	return [[self alloc] initWithNibName:@"RecentItemsViewController" bundle:nil]; 
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
	if(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		self.contentSizeForViewInPopover = CGSizeMake(320.0, 480.0);
		self.title = NSLocalizedString(@"UITabBarSystemItemHistory", @"");
        
    	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        	self.hidesBottomBarWhenPushed = YES;
        }
        
        [[NSNotificationCenter defaultCenter]
    		addObserver:self
        	selector:@selector(applicationSignificantTimeChange:)
        	name:UIApplicationSignificantTimeChangeNotification
        	object:nil];
	}
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter]
    	removeObserver:self
        name:UIApplicationSignificantTimeChangeNotification
        object:nil];
    

	
	self.fetchedResultsController.delegate = nil;
	
	self.searchResultsController.delegate = nil;
	


}

#pragma mark -
#pragma mark RecentItemsViewController

- (IBAction)done:(id)sender {
	self.fetchedResultsController.delegate = nil;
	
	// We also call done through our root view controller to
	// ensure proper user defaults updates
	[(id)[[self navigationController] rootViewController] done:sender];
}

- (IBAction)clear:(id)sender {
	// open an action sheet
	UIActionSheet* actionSheet = [[UIActionSheet alloc]
		initWithTitle:nil
		delegate:self
		cancelButtonTitle:NSLocalizedString(@"SHEETBUTTON_CANCEL", @"")
		destructiveButtonTitle:NSLocalizedString(@"SHEETBUTTON_CLEARALL_RECENTITEMS", @"")
		otherButtonTitles:nil];
	
	actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
	
	[actionSheet showInView:[[self navigationController] view]];
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.clearButtonItem.title = NSLocalizedString(@"BARBUTTON_ITEM_CLEAR", @"");
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.navigationItem.rightBarButtonItem = self.clearButtonItem;
	} else {
		self.navigationItem.rightBarButtonItem = self.doneButtonItem;
	
		self.toolbarItems = [NSArray arrayWithObjects:
			[self clearButtonItem],
			nil];
	}
	
	self.tableView.alwaysBounceVertical = YES;

	// Init the group date formatter
	[self initGroupDateFormatter];
	
	// Init the fetched results controller
	[self initFetchedResultsControllerIfNeeded];
	
	// Display the placeholder if needed
	[self updateContentViewAnimated:NO];
}

- (void)viewDidUnload {
	[super viewDidUnload];

	self.groupDateFormatter = nil;

	self.fetchedResultsController.delegate = nil;
	self.fetchedResultsController = nil;
	
	self.searchResultsController.delegate = nil;
	self.searchResultsController = nil;
	
	self.doneButtonItem = nil;
	self.clearButtonItem = nil;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	// Retrieve the content offset from user defaults if needed
	NSString* contentOffsetString = [[self userDefaults] objectForKey:@"contentOffset"];
	
	if(contentOffsetString.length > 0) {
		self.tableView.contentOffset = CGPointFromString(contentOffsetString);
	} else {
		CGFloat searchBarHeight = CGRectGetHeight([[[self searchDisplayController] searchBar] frame]);
		self.tableView.contentOffset = CGPointMake(0.0, searchBarHeight);
	}
	
	// Now the last used search text
	NSString* searchText = [[self userDefaults] objectForKey:@"searchText"];
	
	if(searchText.length > 0) {
		[[self searchDisplayController] setActive:YES animated:animated];
		[[[self searchDisplayController] searchBar] becomeFirstResponder];
		self.searchDisplayController.searchBar.text = searchText;
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if(self.navigationController.parentViewController) {
		return [[[self navigationController] parentViewController] shouldAutorotateToInterfaceOrientation:interfaceOrientation];
	}
	
	return YES;
}

#pragma mark -
#pragma mark SFTableViewController

- (void)placeholderView:(SFPlaceholderView*)placeholderView willAppearAnimated:(BOOL)animated {
	placeholderView.imageView.image = [UIImage imageNamed:@"recentItemsPlaceholder.png"];
	placeholderView.textLabel.text = NSLocalizedString(@"RECENTITEMS_PLACEHOLDER_TITLE", @"");
	placeholderView.detailTextLabel.text = NSLocalizedString(@"RECENTITEMS_PLACEHOLDER_DESCRIPTION", @"");
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    NSFetchedResultsController* controller = tableView == self.tableView ?
		self.fetchedResultsController :
		self.searchResultsController;
	
	NSInteger numberOfSections = [[controller sections] count];
	return numberOfSections;
}
 
- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	 NSFetchedResultsController* controller = tableView == self.tableView ?
		self.fetchedResultsController :
		self.searchResultsController;
	
	id <NSFetchedResultsSectionInfo> sectionInfo = [[controller sections] objectAtIndex:section];
	
	return [sectionInfo numberOfObjects];
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
	NSFetchedResultsController* controller = tableView == self.tableView ?
		self.fetchedResultsController :
		self.searchResultsController;
	
	SAArticle* article = [controller objectAtIndexPath:
		[NSIndexPath indexPathForRow:0 inSection:section]];
	
	return [[self groupDateFormatter] stringFromDate:[article lastUsedDay]];
}
 
- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	static NSString* const recentItemIdentifier = @"recentItem";
		
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:recentItemIdentifier];
		
	if(!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:recentItemIdentifier];
	}
	
	NSFetchedResultsController* controller = tableView == self.tableView ?
		self.fetchedResultsController :
		self.searchResultsController;
	SAArticle* article = [controller objectAtIndexPath:indexPath];
		
	cell.textLabel.text = article.title;
	cell.imageView.image = [UIImage imageNamed:@"bookmark.png"];
		
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
	return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	NSFetchedResultsController* controller = tableView == self.tableView ?
		self.fetchedResultsController :
		self.searchResultsController;
	
	SAArticle* article = [controller objectAtIndexPath:indexPath];
		
	NSURL* articleURL = [NSURL URLWithString:[article articleURL]];
	[[Articles self] openArticleURL:articleURL];
		
	[self done:nil];
}

- (BOOL)tableView:(UITableView*)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath*)indexPath {
	return YES;
}

- (BOOL)tableView:(UITableView*)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath*)indexPath withSender:(id)sender {
	if(action == @selector(copy:)) {
		return YES;
	}
	
	return NO;
}

- (void)tableView:(UITableView*)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath*)indexPath withSender:(id)sender {
	if(action == @selector(copy:)) {
		NSFetchedResultsController* controller = tableView == self.tableView ?
			self.fetchedResultsController :
			self.searchResultsController;
	
		SAArticle* article = [controller objectAtIndexPath:indexPath];
		
		NSString* articleURLString = [article articleURL];
		if(articleURLString <= 0) { return; }
		
		NSURL* articleURL = [NSURL URLWithString:articleURLString];
		if(!articleURL) { return; }
		
		articleURL = [articleURL wikipediaURLByFixingScheme];
		if(!articleURL) { return; }
		
		NSArray* pasteboardItems = [NSArray arrayWithObjects:
			[NSDictionary dictionaryWithObject:articleURL forKey:(id)kUTTypeURL],
			[NSDictionary dictionaryWithObject:[articleURL absoluteString] forKey:(id)kUTTypeUTF8PlainText],
			nil];
		[[UIPasteboard generalPasteboard] setItems:pasteboardItems];
	}
}

#pragma mark -
#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController*)controller {
	[[self tableView] beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController*)controller {
	[[self tableView] endUpdates];
}

#pragma mark -
#pragma mark UISearchDisplayDelegate

- (BOOL)searchDisplayController:(UISearchDisplayController*)controller shouldReloadTableForSearchString:(NSString*)searchString {
	if(searchString.length == 0) {
		self.searchResultsController = nil;
		return YES;
	}
	
	[self initSearchResultsControllerIfNeeded];
	
//	if(searchString.length == 1) {
//		searchString = [NSString stringWithFormat:@"%@*", searchString];
//	} else {
		searchString = [NSString stringWithFormat:@"*%@*", searchString];
//	}
	
	NSPredicate* newPredicate = [self newRecentItemsPredicateForSearchText:searchString];
	self.searchResultsController.fetchRequest.predicate = newPredicate;
	
	NSError* error = nil;
		
	if(![[self searchResultsController] performFetch:&error]) {
		NSLog(@"%@", error);
	}
	
	return YES;
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController*)controller {
	self.searchResultsController.delegate = nil;
	self.searchResultsController = nil;
}

#pragma mark -
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(buttonIndex == actionSheet.cancelButtonIndex) {
		return;
	}
	
	NSDate* now = [NSDate date];

	[[NSUserDefaults standardUserDefaults]
		setObject:now
		forKey:@"SARecentItemsStartDate"];

	NSPredicate* predicate = [NSPredicate predicateWithFormat:@"lastUsedDate >= %@", now];
		
	[[[self fetchedResultsController] fetchRequest] setPredicate:predicate];
	[[self fetchedResultsController] performFetch:nil];
	
	self.searchResultsController = nil;
	
	[[self searchDisplayController] setActive:NO animated:NO];
	
	[[self tableView] reloadData];
	[self updateContentViewAnimated:YES];
}

#pragma mark -
#pragma mark Private

- (void)initFetchedResultsControllerIfNeeded {
	if(!self.fetchedResultsController) {
		NSFetchedResultsController* fetchedResultsController = [self newRecentItemsResultController];
		
		self.fetchedResultsController = fetchedResultsController;
		
		NSError* error = nil;
		
		if(![fetchedResultsController performFetch:&error]) {
			NSLog(@"%@", error);
		}
	}
}

- (void)initSearchResultsControllerIfNeeded {
	if(!self.searchResultsController) {
		NSFetchedResultsController* searchResultsController = [self newRecentItemsResultController];
		self.searchResultsController = searchResultsController;
	}
}

- (NSFetchedResultsController*)newRecentItemsResultController {
	NSManagedObjectContext* context = self.managedObjectContext;

	NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
	
	NSEntityDescription* entity = [NSEntityDescription entityForName:@"Article" inManagedObjectContext:context];
	[fetchRequest setEntity:entity];

	NSArray* sortDescriptors = [NSArray arrayWithObjects:
		[[NSSortDescriptor alloc] initWithKey:@"lastUsedDate" ascending:NO],
		nil];
	[fetchRequest setSortDescriptors:sortDescriptors];
	
	NSPredicate* predicate = [self newRecentItemsPredicateForSearchText:nil];
	fetchRequest.predicate = predicate;

	NSFetchedResultsController* fetchedResultsController = [[NSFetchedResultsController alloc]
		initWithFetchRequest:fetchRequest
		managedObjectContext:context
		sectionNameKeyPath:@"lastUsedDay"
		cacheName:nil];
		
	fetchedResultsController.delegate = self;
	
	return fetchedResultsController;
}

- (NSPredicate*)newRecentItemsPredicateForSearchText:(NSString*)searchText {
	NSMutableArray* predicates = [NSMutableArray array];
	
	[predicates addObject:[NSPredicate predicateWithFormat:@"lastUsedDate != nil"]];
	
	NSDate* startDate = [[NSUserDefaults standardUserDefaults]
		objectForKey:@"SARecentItemsStartDate"];
		
	if(startDate) {
		[predicates addObject:[NSPredicate predicateWithFormat:@"lastUsedDate >= %@", startDate]];
	}
	
	if(searchText.length > 0) {
		[predicates addObject:[NSPredicate predicateWithFormat:@"title like[cd] %@", searchText]];
	}
	
	return [[NSCompoundPredicate alloc] initWithType:NSAndPredicateType subpredicates:predicates];
}

- (void)updateContentViewAnimated:(BOOL)animated {
	BOOL showPlaceholderView = self.fetchedResultsController.fetchedObjects.count <= 0;
	
	[self setShowsPlaceholderView:showPlaceholderView animated:animated];
	
	self.clearButtonItem.enabled = !showPlaceholderView;
}

- (void)restoreFromUserDefaults:(NSDictionary*)userDefaults inSelection:(NSArray*)selection {
	self.userDefaults = userDefaults;
}

- (void)initGroupDateFormatter {
	NSDateFormatter* groupDateFormatter = [[NSDateFormatter alloc] init];
	
    [groupDateFormatter setCalendar:[NSCalendar autoupdatingCurrentCalendar]];
	[groupDateFormatter setLocale:[NSLocale autoupdatingCurrentLocale]];
	[groupDateFormatter setTimeStyle:NSDateFormatterNoStyle];
	[groupDateFormatter setDateStyle:NSDateFormatterLongStyle];
	
	[groupDateFormatter setDoesRelativeDateFormatting:YES];
	
	self.groupDateFormatter = groupDateFormatter;
}

- (void)applicationSignificantTimeChange:(NSNotification*)notification {
	[self initGroupDateFormatter];
    [[self tableView] reloadData];
}

@end
