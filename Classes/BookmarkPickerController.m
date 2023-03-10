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

#import "BookmarkPickerController.h"
#import "BookmarkPickerController+Private.h"

#import "NearbyItemsViewController.h"

#import "RecentItemsViewController.h"
#import "RecentItemsViewController+Private.h"

#import "ReadLaterViewController.h"
#import "ReadLaterViewController+Private.h"

#import "BookmarkDetailViewController.h"
#import "BookmarkGroupDetailViewController.h"

#import "ArticleViewController.h"

#import "SFBadgedTableViewCell.h"

#import "SABookmarkGroup.h"
#import "SABookmark.h"
#import "SAArticle.h"

#import "AKLanguagePicker.h"

#import "AKArticleView+Archiving.h"
#import "AKArticleView+Private.h"

#import "WikipediaAPI.h"
#import "Articles.h"

#import "NSArray+Additions.h"
#import "NSLocale+Additions.h"
#import "NSString+Additions.h"
#import "NSURL+Wikipedia.h"

#import <MobileCoreServices/MobileCoreServices.h>

@implementation BookmarkPickerController

@synthesize doneButtonItem = _doneButtonItem;
@synthesize addBookmarkGroupButtonItem = _addBookmarkGroupButtonItem;

@synthesize bookmarkItemResultsController = _bookmarkItemResultsController;
@synthesize readLaterCountController = _readLaterCountController;

@synthesize supergroup = _supergroup;
@synthesize managedObjectContext = _managedObjectContext;

@dynamic nearbySectionIndex;
@dynamic recentItemsSectionIndex;
@dynamic featuredItemSectionIndex;
@dynamic randomItemSectionIndex;
@dynamic readLaterItemSectionIndex;
@dynamic languagesItemSectionIndex;
@dynamic tableOfContentsItemSectionIndex;
@dynamic bookmarkItemsSectionIndex;

@dynamic defaultToolbarItems;
@dynamic editingToolbarItems;

@dynamic currrentArticle;

@synthesize userDefaults = _userDefaults;

@synthesize delegate = _delegate;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithSupergroup:(SABookmarkGroup*)supergroup managedObjectContext:(NSManagedObjectContext*)managedObjectContext {
	if(self = [super initWithNibName:@"BookmarkPickerController" bundle:nil]) {
		self.contentSizeForViewInPopover = CGSizeMake(320.0, 480.0);
        
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        	self.hidesBottomBarWhenPushed = YES;
        }
		
		_userDidReorderBookmarkItem = NO;
		
		self.managedObjectContext = managedObjectContext;
		self.supergroup = supergroup;
		
		self.title = NSLocalizedString(@"BOOKMARKS_NAVIGATIONITEM_TITLE", @"");
	
		// We use the supergroups name as title
		if(self.supergroup) {
			self.title = self.supergroup.title;
		}
		
		// Make sure we store to user defaults on quite
		[[NSNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(applicationWillTerminate:)
			name:UIApplicationWillTerminateNotification
			object:nil];
			
//		if(SFIsMultitaskingSupported()) {
			[[NSNotificationCenter defaultCenter]
				addObserver:self
				selector:@selector(applicationWillTerminate:)
				name:UIApplicationDidEnterBackgroundNotification
				object:nil];
//		}
	}
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	self.delegate = nil;

	self.readLaterCountController.delegate = nil;
	self.bookmarkItemResultsController.delegate = nil;
}

#pragma mark -
#pragma mark BookmarkViewController

- (IBAction)done:(id)sender {
	// Save to user defaults
	[self updateUserDefaults];
	
	// We're done
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[[self delegate] bookmarkPickerShouldDismiss:self animated:YES];
	} else {
		[self dismissViewControllerAnimated:YES completion:nil];
	}
}

- (IBAction)addBookmarkGroup:(id)sender {
	NSManagedObjectContext* managedObjectContext = self.managedObjectContext;
	NSEntityDescription* entity = [NSEntityDescription entityForName:@"BookmarkGroup" inManagedObjectContext:managedObjectContext];
	
	SABookmarkGroup* newBookmarkGroup = [[SABookmarkGroup alloc] initWithEntity:entity insertIntoManagedObjectContext:nil];

	NSInteger sortOrder = self.bookmarkItemResultsController.fetchedObjects.count + 1;
	newBookmarkGroup.sortOrder = [NSNumber numberWithInteger:sortOrder];

	BookmarkGroupDetailViewController* viewController = [BookmarkGroupDetailViewController viewController];
	
	viewController.bookmarkGroup = newBookmarkGroup;
	viewController.selectedBookmarkSupergroup = self.supergroup;
	viewController.managedObjectContext = managedObjectContext;
	
	viewController.delegate = self;

	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[[self navigationController] pushViewController:viewController animated:YES];
	} else {
		UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
		[self presentViewController:navigationController animated:YES completion:nil];
	}
}

- (IBAction)showNearbyItems:(id)sender {
	NearbyItemsViewController* viewController = [NearbyItemsViewController viewController];
	
	BOOL animated = ![sender isKindOfClass:[NSUserDefaults class]];
	[[self navigationController] pushViewController:viewController animated:animated];
}

- (IBAction)showRandomArticle:(id)sender {
	[self done:sender];
		
	WikipediaAPI* wikipediaAPI = [[WikipediaAPI alloc] init];
	
	NSString* preferredLanguage = [[NSUserDefaults standardUserDefaults] objectForKey:@"SASelectedScopeLanguageCode"];
	
	if(preferredLanguage.length <= 0) {
		preferredLanguage = [[NSLocale autoupdatingCurrentLocale] preferredLanguageCode];
	}
	
	wikipediaAPI.preferredLanguage = preferredLanguage;
	
	[[Articles self] performSelector:@selector(openArticleURL:)
		withObject:[wikipediaAPI randomArticleURL]
		afterDelay:0.0];
}

#pragma mark -
#pragma mark UIViewController

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	if(self.editing != editing) {
		[super setEditing:editing animated:animated];
		
		if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UIBarButtonItem* leftButtonItem = editing ?
				[self addBookmarkGroupButtonItem] :
				nil;
			[[self navigationItem]
				setLeftBarButtonItem:leftButtonItem
				animated:animated];
		} else {
			// Adjust the top right button item
			UIBarButtonItem* rightButtonItem = editing ? 
				nil :
				self.doneButtonItem;
			[[self navigationItem]
				setRightBarButtonItem:rightButtonItem
				animated:animated];
				
//			// Now adjust the toolbat items
//			NSArray* toolbarItems = editing ?
//				self.editingToolbarItems :
//				self.editingToolbarItems; // We always use editing toolbar items for now
//			[self setToolbarItems:toolbarItems animated:NO];
		}
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];

	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
		initWithImage:[UIImage imageNamed:@"backBarButtonItem.png"]
		style:UIBarButtonItemStyleBordered
		target:nil
		action:NULL];

	self.addBookmarkGroupButtonItem.title = NSLocalizedString(@"NEW_BOOKMARKGROUP_NAVIGATIONITEM_TITLE", @"");
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.navigationItem.rightBarButtonItem = [self editButtonItem];
		self.navigationController.toolbarHidden = YES;
	} else {
		self.navigationItem.rightBarButtonItem = self.doneButtonItem;
		self.toolbarItems = self.editingToolbarItems; // We always use editing toolbar items for now
		self.navigationController.toolbarHidden = NO;
	}
	
	[self initBookmarkItemResultsController];
	
	// Show the placeholder view if needed
	[self updateContentViewAnimated:NO];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	
	self.bookmarkItemResultsController.delegate = nil;
	self.bookmarkItemResultsController = nil;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	BOOL toolbarHidden = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
    [[self navigationController] setToolbarHidden:toolbarHidden animated:animated];

	// Retrieve the content offset from user defaults if needed
	CGPoint contentOffset = CGPointFromString([[self userDefaults] objectForKey:@"contentOffset"]);
	
	if(!CGPointEqualToPoint(contentOffset, CGPointZero)) {
		self.tableView.contentOffset = contentOffset;
	}
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
    if(self.navigationController.parentViewController) {
		return [[[self navigationController] parentViewController] shouldAutorotateToInterfaceOrientation:interfaceOrientation];
	}
	
	return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark SFTableViewController

- (void)placeholderView:(SFPlaceholderView*)placeholderView willAppearAnimated:(BOOL)animated {
	placeholderView.imageView.image = [UIImage imageNamed:@"bookmarksPlaceholder.png"];
	placeholderView.textLabel.text = NSLocalizedString(@"BOOKMARKS_PLACEHOLDER_TITLE", @"");
	placeholderView.detailTextLabel.text = NSLocalizedString(@"BOOKMARKS_PLACEHOLDER_DESCRIPTION", @"");
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
	return 8;
}

- (NSInteger)tableView:(UITableView*)table numberOfRowsInSection:(NSInteger)section {
	if(section == self.nearbySectionIndex) {
		return self.supergroup ? 0 : 1;
	}
	
	if(section == self.recentItemsSectionIndex) {
		return self.supergroup ? 0 : 1;
	}
	
	if(section == self.featuredItemSectionIndex) {
		return self.supergroup ? 0 : 1;
	}
	
	if(section == self.randomItemSectionIndex) {
		return self.supergroup ? 0 : 1;
	}
	
	if(section == self.languagesItemSectionIndex) {
		return YES || self.supergroup || self.currrentArticle == nil ? 0 : 1;
	}
	
	if(section == self.tableOfContentsItemSectionIndex) {
		return YES || self.supergroup || self.currrentArticle == nil ? 0 : 1;
	}
	
	if(section == self.readLaterItemSectionIndex) {
		return self.supergroup ? 0 : 1;
	}

	if(section == self.bookmarkItemsSectionIndex) {
		id<NSFetchedResultsSectionInfo> section = self.bookmarkItemResultsController.sections.firstObject;
		return section.numberOfObjects;
	}
	
	return 0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	if(indexPath.section == self.nearbySectionIndex) {
		static NSString* const nearbyIdentifier = @"nearby";
		
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:nearbyIdentifier];
		
		if(!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nearbyIdentifier];
		}
		
		cell.textLabel.text = NSLocalizedString(@"NEARBYITEMS_NAVIGATIONITEM_TITLE", @"");
		cell.imageView.image = [UIImage imageNamed:@"nearby.png"];
		
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.editingAccessoryType = UITableViewCellAccessoryNone;
		
		cell.shouldIndentWhileEditing = NO;
		
		return cell;
	}
	
	if(indexPath.section == self.recentItemsSectionIndex) {
		static NSString* const recentItemsIdentifier = @"recentItems";
		
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:recentItemsIdentifier];
		
		if(!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:recentItemsIdentifier];
		}
		
		cell.textLabel.text = NSLocalizedString(@"RECENTITEMS_NAVIGATIONITEM_TITLE", @"");
		cell.imageView.image = [UIImage imageNamed:@"recentItems.png"];
		
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.editingAccessoryType = UITableViewCellAccessoryNone;
		
		cell.shouldIndentWhileEditing = NO;
		
		return cell;
	}
	
	if(indexPath.section == self.featuredItemSectionIndex) {
		static NSString* const featuredItemIdentifier = @"featuredItem";
		
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:featuredItemIdentifier];
		
		if(!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:featuredItemIdentifier];
		}
		
		cell.textLabel.text = NSLocalizedString(@"FEATUREDITEM_NAVIGATIONITEM_TITLE", @"");
		cell.imageView.image = [UIImage imageNamed:@"featuredItem.png"];
		
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.editingAccessoryType = UITableViewCellAccessoryNone;
		
		cell.shouldIndentWhileEditing = NO;
		
		return cell;
	}
	
	if(indexPath.section == self.randomItemSectionIndex) {
		static NSString* const featuredItemIdentifier = @"randomItem";
		
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:featuredItemIdentifier];
		
		if(!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:featuredItemIdentifier];
		}
		
		cell.textLabel.text = NSLocalizedString(@"SURPRISEME_NAVIGATIONITEM_TITLE", @"");
		cell.imageView.image = [UIImage imageNamed:@"randomItem.png"];
		
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.editingAccessoryType = UITableViewCellAccessoryNone;
		
		cell.shouldIndentWhileEditing = NO;
		
		return cell;
	}
	
	if(indexPath.section == self.readLaterItemSectionIndex) {
		static NSString* const readLaterItemIdentifier = @"readLater";
		
		SFBadgedTableViewCell* cell = (id)[tableView dequeueReusableCellWithIdentifier:readLaterItemIdentifier];
		
		if(!cell) {
			cell = [[SFBadgedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:readLaterItemIdentifier];
		}
		
		cell.textLabel.text = NSLocalizedString(@"READLATER_NAVIGATIONITEM_TITLE", @"");
		cell.imageView.image = [UIImage imageNamed:@"readLater.png"];
		
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.editingAccessoryType = UITableViewCellAccessoryNone;
		
		cell.shouldIndentWhileEditing = NO;
		
		[self initReadLaterCountControllerIfNeeded];
		NSInteger readLaterCount = self.readLaterCountController.fetchedObjects.count;
		
		cell.badgeAccessoryView.text = readLaterCount > 0 ?
			[NSString stringWithFormat:@"%ld", (long)readLaterCount] :
			nil;
		
		return cell;
	}
	
	if(indexPath.section == self.languagesItemSectionIndex) {
		static NSString* const languagesItemIdentifier = @"languages";
		
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:languagesItemIdentifier];
		
		if(!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:languagesItemIdentifier];
		}
		
		cell.textLabel.text = NSLocalizedString(@"LANGUAGEPICKER_NAVIGATIONITEM_TITLE", @"");
		cell.imageView.image = [UIImage imageNamed:@"bookmark.png"]; // TODO
		
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.editingAccessoryType = UITableViewCellAccessoryNone;
		
		cell.shouldIndentWhileEditing = NO;
		
		return cell;
	}
	
	if(indexPath.section == self.tableOfContentsItemSectionIndex) {
		static NSString* const tableOfContentsItemIdentifier = @"tableOfContents";
		
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:tableOfContentsItemIdentifier];
		
		if(!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableOfContentsItemIdentifier];
		}
		
		cell.textLabel.text = NSLocalizedString(@"CHAPTERPICKER_NAVIGATIONITEM_TITLE", @"");
		cell.imageView.image = [UIImage imageNamed:@"bookmark.png"]; // TODO
		
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.editingAccessoryType = UITableViewCellAccessoryNone;
		
		cell.shouldIndentWhileEditing = NO;
		
		return cell;
	}

	if(indexPath.section == self.bookmarkItemsSectionIndex) {
		static NSString* const bookmarkIdentifier = @"bookmark";
		
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:bookmarkIdentifier];
		
		if(!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:bookmarkIdentifier];
		}
		
		[self configureCell:cell atIndexPath:indexPath];
		
		return cell;
	}
	
	return nil;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
	if(editingStyle == UITableViewCellEditingStyleDelete) {
		if(indexPath.section == self.bookmarkItemsSectionIndex) {
			SABookmarkItem* bookmarkItem = [[[self bookmarkItemResultsController] fetchedObjects] objectAtIndex:[indexPath row]];
			[[bookmarkItem managedObjectContext] deleteObject:bookmarkItem];
		}
	}
}

- (BOOL)tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath*)indexPath {
	return indexPath.section == self.bookmarkItemsSectionIndex;
}

- (void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath*)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath {
	if(destinationIndexPath.section == self.bookmarkItemsSectionIndex) {
		_userDidReorderBookmarkItem = YES;
		
		NSArray* bookmarkGroups = [[self bookmarkItemResultsController] fetchedObjects];
		NSArray* orderedBookmarkGroups = [bookmarkGroups
			arrayByMovingObjectAtIndex:[sourceIndexPath row]
			toIndex:[destinationIndexPath row]];
		
		NSInteger sortOrder = 1;
	
		for(SABookmarkItem* bookmarkItem in orderedBookmarkGroups) {
			if([[bookmarkItem sortOrder] integerValue] != sortOrder) {
				bookmarkItem.sortOrder = [NSNumber numberWithInteger:sortOrder];
			}
			
			++sortOrder;
		}
	}
}

#pragma mark -
#pragma mark UITableViewDelegate

- (NSIndexPath*)tableView:(UITableView*)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath*)sourceIndexPath toProposedIndexPath:(NSIndexPath*)proposedDestinationIndexPath {
	if(sourceIndexPath.section == self.bookmarkItemsSectionIndex) {
		if(sourceIndexPath.section > proposedDestinationIndexPath.section) {
			return [NSIndexPath indexPathForRow:0 inSection:[sourceIndexPath section]];
		}
			
		if(sourceIndexPath.section < proposedDestinationIndexPath.section) {
			NSIndexPath* newIndexPath = [NSIndexPath
				indexPathForRow:MAX([tableView numberOfRowsInSection:[sourceIndexPath section]] - 1, 0)
				inSection:[sourceIndexPath section]];
			return newIndexPath;
		}
		
		return proposedDestinationIndexPath;
	}
	
	if(!sourceIndexPath) {
		return proposedDestinationIndexPath;
	}

	return sourceIndexPath;
}

- (UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
	if(indexPath.section == self.bookmarkItemsSectionIndex) {
		return UITableViewCellEditingStyleDelete;
	}
	
	return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView*)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath*)indexPath {
	if(indexPath.section == self.bookmarkItemsSectionIndex) {
		return YES;
	}
	
	return NO;
}

- (NSIndexPath*)tableView:(UITableView*)tableView willSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	if(tableView.editing &&
	   indexPath.section != self.bookmarkItemsSectionIndex) {
		return nil;
	}
	
	return indexPath;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	if(indexPath.section == self.nearbySectionIndex) {
		self.userDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
			@"nearby", @"section",
			nil];
		[self showNearbyItems:tableView];
	}
	
	if(indexPath.section == self.recentItemsSectionIndex) {
		self.userDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
			@"recentItems", @"section",
			nil];
	
		RecentItemsViewController* viewController = [RecentItemsViewController viewController];
		viewController.managedObjectContext = self.managedObjectContext;
		[[self navigationController] pushViewController:viewController animated:YES];
	}
	
	if(indexPath.section == self.featuredItemSectionIndex) {
		[self done:tableView];
	}
	
	if(indexPath.section == self.randomItemSectionIndex) {
		[self showRandomArticle:tableView];
	}
	
	if(indexPath.section == self.readLaterItemSectionIndex) {
        self.userDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
			@"readLater", @"section",
			nil];
	
		ReadLaterViewController* viewController = [ReadLaterViewController viewController];
		viewController.managedObjectContext = self.managedObjectContext;
		[[self navigationController] pushViewController:viewController animated:YES];
	}
	
	if(indexPath.section == self.languagesItemSectionIndex) {
		self.userDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
			@"languages", @"section",
			nil];
	
		AKLanguagePicker* picker = [[[[Articles self] articleViewController] articleView] languagePicker];
		picker.pickerMode = AKLanguagePickerModeDefault;
		[[self navigationController] pushViewController:picker animated:YES];
	}
	
	if(indexPath.section == self.tableOfContentsItemSectionIndex) {
		self.userDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
			@"tableOfContents", @"section",
			nil];
		
		AKLanguagePicker* picker = [[[[Articles self] articleViewController] articleView] languagePicker];
		picker.pickerMode = AKLanguagePickerModeTOC;
		[[self navigationController] pushViewController:picker animated:YES];
	}

	if(indexPath.section == self.bookmarkItemsSectionIndex) {
		SABookmarkItem* bookmarkItem = [[[self bookmarkItemResultsController] fetchedObjects] objectAtIndex:[indexPath row]];
		
		if([bookmarkItem isKindOfClass:[SABookmarkGroup class]]) {
			if(tableView.editing) {
				BookmarkGroupDetailViewController* viewController = [BookmarkGroupDetailViewController viewController];
				
				viewController.bookmarkGroup = (id)bookmarkItem;
				viewController.selectedBookmarkSupergroup = (id)bookmarkItem.superitem;
				viewController.managedObjectContext = self.managedObjectContext;

				viewController.delegate = self;
				
				[[self navigationController] pushViewController:viewController animated:YES];
			} else {
				self.userDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
					@"bookmarkItems", @"section",
					[[[bookmarkItem objectID] URIRepresentation] absoluteString], @"objectID",
					nil];
				
				BookmarkPickerController* viewController = [[BookmarkPickerController alloc]
					initWithSupergroup:(id)bookmarkItem
					managedObjectContext:[self managedObjectContext]];
					
				viewController.delegate = self.delegate;
					
				[[self navigationController] pushViewController:viewController animated:YES];
			}
		} else {
			if(tableView.editing) {
				BookmarkDetailViewController* viewController = [BookmarkDetailViewController viewController];
			
				viewController.delegate = self;
				viewController.bookmark = (id)bookmarkItem;
			
				[[self navigationController] pushViewController:viewController animated:YES];
			} else {
				SABookmark* bookmark = (id)bookmarkItem;
				
				NSURL* articleURL = [NSURL URLWithString:[[bookmark article] articleURL]];
				
				if(articleURL) {
					[[Articles self] openArticleURL:articleURL];
				}

				[self done:nil]; // TODO
			}
		}
	}
}

- (BOOL)tableView:(UITableView*)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath*)indexPath {
	if(indexPath.section == self.bookmarkItemsSectionIndex) {
		SABookmarkItem* bookmarkItem = [[[self bookmarkItemResultsController] fetchedObjects] objectAtIndex:[indexPath row]];
		return [bookmarkItem isKindOfClass:[SABookmark class]];
	}
	
	return NO;
}

- (BOOL)tableView:(UITableView*)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath*)indexPath withSender:(id)sender {
	if(indexPath.section == self.bookmarkItemsSectionIndex && action == @selector(copy:)) {
		return YES;
	}
	
	return NO;
}

- (void)tableView:(UITableView*)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath*)indexPath withSender:(id)sender {
	if(indexPath.section == self.bookmarkItemsSectionIndex && action == @selector(copy:)) {
		SABookmark* bookmark = [[[self bookmarkItemResultsController] fetchedObjects] objectAtIndex:[indexPath row]];
		
		NSString* articleURLString = [[bookmark article] articleURL];
		if(articleURLString.length <= 0) { return; }
		
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
	if(controller == self.readLaterCountController) { return; }
	
	if(!_userDidReorderBookmarkItem) {
		[[self tableView] beginUpdates];
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController*)controller {
	if(controller == self.readLaterCountController) {
		NSIndexSet* sections = [NSIndexSet indexSetWithIndex:[self readLaterItemSectionIndex]];
		[[self tableView] reloadSections:sections withRowAnimation:UITableViewRowAnimationNone];
		
		return; 
	}
	
	if(!_userDidReorderBookmarkItem) {
		[[self tableView] endUpdates];
	}

	_userDidReorderBookmarkItem = NO;
	
	// Show or hide the placeholder view if needed
	[self updateContentViewAnimated:YES];
}

- (void)controller:(NSFetchedResultsController*)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath*)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath*)newIndexPath {
	if(controller == self.readLaterCountController) { return; }
	
	UITableView* tableView = self.tableView;
	
	if(_userDidReorderBookmarkItem) {
		return;
	}
	
	indexPath = [NSIndexPath
		indexPathForRow:[indexPath row]
		inSection:[self bookmarkItemsSectionIndex]];
		
	newIndexPath = [NSIndexPath
		indexPathForRow:[newIndexPath row]
		inSection:[self bookmarkItemsSectionIndex]];
	
	switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
				withRowAnimation:UITableViewRowAnimationLeft];
            break;
 
        case NSFetchedResultsChangeDelete:
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
				withRowAnimation:UITableViewRowAnimationLeft];
            break;
 
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath]
				atIndexPath:indexPath];
            break;
 
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
				withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
				withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

#pragma mark -
#pragma mark BookmarkGroupDetailViewDelegate

- (void)bookmarkDetailViewController:(BookmarkDetailViewController*)viewController didSaveBookmark:(SABookmark*)bookmark {
	[self setEditing:NO animated:NO];
//	[[self tableView] reloadData];
}

#pragma mark -
#pragma mark BookmarkGroupDetailViewDelegate

- (void)bookmarkGroupDetailViewController:(BookmarkGroupDetailViewController*)viewController didSaveGroup:(SABookmarkGroup*)bookmarkGroup {
	[self setEditing:NO animated:NO];
//	[[self tableView] reloadData];
}

#pragma mark -
#pragma mark Private

- (void)applicationWillTerminate:(NSNotification*)notification {
	[self updateUserDefaults];
}

- (NSUInteger)nearbySectionIndex {
	return 0;
}

- (NSUInteger)recentItemsSectionIndex {
	return 3;
}

- (NSUInteger)featuredItemSectionIndex {
	return -1;
}

- (NSUInteger)randomItemSectionIndex {
	return 2;
}

- (NSUInteger)readLaterItemSectionIndex {
	return 4;
}

- (NSUInteger)languagesItemSectionIndex {
	return 5;
}

- (NSUInteger)tableOfContentsItemSectionIndex {
	return 6;
}

- (NSUInteger)bookmarkItemsSectionIndex {
	return 7;
}

- (NSArray*)defaultToolbarItems {
	NSArray* toolbarItems = [NSArray arrayWithObjects:
		[self editButtonItem],
		nil];
	return toolbarItems;
}

- (NSArray*)editingToolbarItems {
	NSArray* toolbarItems = [NSArray arrayWithObjects:
		[self editButtonItem],
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
		[self addBookmarkGroupButtonItem],
		nil];
	return toolbarItems;
}

- (id)currrentArticle {
	AKArticleView* articleView = [[[Articles self] articleViewController] articleView];

	if(![articleView isLoading]) {
		return [articleView visibleArchive];
	}

	return nil;
}

- (void)initBookmarkItemResultsController {
	NSManagedObjectContext* context = self.managedObjectContext;

	NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
	
	NSEntityDescription* entity = [NSEntityDescription entityForName:@"BookmarkItem" inManagedObjectContext:context];
	[fetchRequest setEntity:entity];

	NSArray* sortDescriptors = [NSArray arrayWithObjects:
		[[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:YES],
		[[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES],
		nil];
	[fetchRequest setSortDescriptors:sortDescriptors];
	
	if(self.supergroup) {
		NSPredicate* predicate = [NSPredicate predicateWithFormat:@"superitem == %@", [self supergroup]];
		[fetchRequest setPredicate:predicate];
	} else {
		NSPredicate* predicate = [NSPredicate predicateWithFormat:@"superitem == nil"];
		[fetchRequest setPredicate:predicate];
	}
	
	NSFetchedResultsController* fetchedResultsController = [[NSFetchedResultsController alloc]
        initWithFetchRequest:fetchRequest
        managedObjectContext:context
        sectionNameKeyPath:nil
        cacheName:nil];
		
	fetchedResultsController.delegate = self;
	
	_bookmarkItemResultsController = fetchedResultsController;
	
	
	// ...
	NSError* error = nil;
	
	if(![fetchedResultsController performFetch:&error]) {
		NSLog(@"%@", error);
	}
}

- (void)initReadLaterCountControllerIfNeeded {
	if(self.readLaterCountController) { return; }
	
	NSManagedObjectContext* context = self.managedObjectContext;

	NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
	
	NSEntityDescription* entity = [NSEntityDescription entityForName:@"Article" inManagedObjectContext:context];
	[fetchRequest setEntity:entity];
	
	NSArray* sortDescriptors = [NSArray arrayWithObjects:
		[[NSSortDescriptor alloc] initWithKey:@"readLaterDate" ascending:NO],
		nil];
	[fetchRequest setSortDescriptors:sortDescriptors];

	NSPredicate* predicate = [NSPredicate predicateWithFormat:@"unread == true"];
	[fetchRequest setPredicate:predicate];

	NSFetchedResultsController* fetchedResultsController = [[NSFetchedResultsController alloc]
		initWithFetchRequest:fetchRequest
		managedObjectContext:context
		sectionNameKeyPath:nil
		cacheName:nil];
		
	fetchedResultsController.delegate = self;
	self.readLaterCountController = fetchedResultsController;
	
	// ...
	NSError* error = nil;
	
	if(![fetchedResultsController performFetch:&error]) {
		NSLog(@"%@", error);
	}
}

- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath {
	if(indexPath.section == self.bookmarkItemsSectionIndex) {
		SABookmarkItem* item = [[[self bookmarkItemResultsController] fetchedObjects] objectAtIndex:[indexPath row]];
		
		BOOL isBookmarkGroup = [[[item entity] name] isEqualToString:@"BookmarkGroup"];
		
		cell.textLabel.text = item.title;
		
		cell.imageView.image = isBookmarkGroup ?
			[UIImage imageNamed:@"bookmarkGroup.png"] :
			[UIImage imageNamed:@"bookmark.png"];
		
		cell.accessoryType = isBookmarkGroup ?
			UITableViewCellAccessoryDisclosureIndicator :
			UITableViewCellAccessoryNone;
		
		cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
}

- (void)updateContentViewAnimated:(BOOL)animated {
	BOOL showPlaceholderView =
		self.supergroup &&
		self.bookmarkItemResultsController.fetchedObjects.count <= 0;
	[self setShowsPlaceholderView:showPlaceholderView animated:animated];
}

- (void)restoreFromUserDefaults:(NSDictionary*)userDefaults inSelection:(NSArray*)selection {
	self.userDefaults = userDefaults;
	
	if(selection) {
		NSString* selectedSection = [userDefaults objectForKey:@"section"];
		
		if(!self.currrentArticle) {
			if(SFEqualStrings(selectedSection, @"languages") ||
			   SFEqualStrings(selectedSection, @"tableOfContents")) {
				selectedSection = nil;
			}
		}
		
		if(SFEqualStrings(selectedSection, @"nearby")) {
			[self showNearbyItems:[NSUserDefaults standardUserDefaults]];
		} else if(SFEqualStrings(selectedSection, @"recentItems")) {
			RecentItemsViewController* viewController = [RecentItemsViewController viewController];
			viewController.managedObjectContext = self.managedObjectContext;
			[[self navigationController] pushViewController:viewController animated:NO];
			
			// Drill further down if needed
			if(userDefaults != [selection lastObject]) {
				NSDictionary* subviewUserDefaults = [selection objectAtIndex:
					[selection indexOfObject:userDefaults] + 1];
					
				[viewController restoreFromUserDefaults:subviewUserDefaults inSelection:selection];
			}
		} else if(SFEqualStrings(selectedSection, @"readLater")) {
			ReadLaterViewController* viewController = [ReadLaterViewController viewController];
			
			viewController.managedObjectContext = self.managedObjectContext;
			
			[[self navigationController] pushViewController:viewController animated:NO];
			
			[viewController restoreFromUserDefaults:[selection lastObject] inSelection:selection];
		} else if(SFEqualStrings(selectedSection, @"languages")) {
			AKLanguagePicker* picker = [[[[Articles self] articleViewController] articleView] languagePicker];
			picker.pickerMode = AKLanguagePickerModeDefault;
			
			[[self navigationController] pushViewController:picker animated:NO];
			
			[(id)picker restoreFromUserDefaults:userDefaults inSelection:selection];
		} else if(SFEqualStrings(selectedSection, @"tableOfContents")) {
			AKLanguagePicker* picker = [[[[Articles self] articleViewController] articleView] languagePicker];
			picker.pickerMode = AKLanguagePickerModeTOC;
			
			[[self navigationController] pushViewController:picker animated:NO];
			
			[(id)picker restoreFromUserDefaults:userDefaults inSelection:selection];
		} else if(SFEqualStrings(selectedSection, @"bookmarkItems")) {
			NSURL* objectURI = [NSURL URLWithString:[userDefaults objectForKey:@"objectID"]];
			NSManagedObjectID* objectID = [[[self managedObjectContext]
				persistentStoreCoordinator]
				managedObjectIDForURIRepresentation:objectURI];
			if(!objectID) { return; }

			SABookmarkGroup* bookmarkItem = (id)[[self managedObjectContext] objectWithID:objectID];
			if(!bookmarkItem) { return; }

			BookmarkPickerController* viewController = [[BookmarkPickerController alloc]
				initWithSupergroup:bookmarkItem
				managedObjectContext:[self managedObjectContext]];
			[[self navigationController] pushViewController:viewController animated:NO];
				
			// Drill further down if needed
			if(userDefaults != [selection lastObject]) {
				NSDictionary* subviewUserDefaults = [selection objectAtIndex:
					[selection indexOfObject:userDefaults] + 1];

				[viewController restoreFromUserDefaults:subviewUserDefaults inSelection:selection];
			}
		}
	}
}

- (void)updateUserDefaults {
	NSMutableArray* userDefaultsSelection = [NSMutableArray array];

	for(UIViewController* viewController in self.navigationController.viewControllers) {
		NSDictionary* userDefaults = nil;
		
		// Only store user defaults if it isn't the currently visible controller
		if(self.navigationController.topViewController != viewController) {
			if([viewController respondsToSelector:@selector(userDefaults)]) {
				userDefaults = [(id)viewController userDefaults];
			}
		}
		
		if(!userDefaults) {
			userDefaults = [NSDictionary dictionary];
		}
		
		// Automatically store the table views content offset
		if([viewController isViewLoaded] && [viewController respondsToSelector:@selector(tableView)]) {
			CGPoint contentOffset = [[(id)viewController tableView] contentOffset];
			
			NSMutableDictionary* newUserDefaults = [NSMutableDictionary dictionaryWithDictionary:userDefaults];
			[newUserDefaults setObject:NSStringFromCGPoint(contentOffset) forKey:@"contentOffset"];
			userDefaults = newUserDefaults;
		}
		
		// Also store the current search text if needed
		if([viewController isViewLoaded] && [[viewController searchDisplayController] isActive]) {
			NSString* searchText = [[[viewController searchDisplayController] searchBar] text];
			
			NSMutableDictionary* newUserDefaults = [NSMutableDictionary dictionaryWithDictionary:userDefaults];
			[newUserDefaults setObject:searchText forKey:@"searchText"];
			userDefaults = newUserDefaults;
		}
		
		[userDefaultsSelection addObject:userDefaults];
	}
	
	[[NSUserDefaults standardUserDefaults]
		setObject:userDefaultsSelection
		forKey:@"SABookmarkPicker"];
}

- (void)restoreFromUserDefaults {
	NSArray* userDefaultsSelection = [[NSUserDefaults standardUserDefaults]
		objectForKey:@"SABookmarkPicker"];
		
	NSDictionary* userDefaults = [userDefaultsSelection firstObject];
	
	if(userDefaults) {
		[self restoreFromUserDefaults:userDefaults inSelection:userDefaultsSelection];
	}
}

@end
