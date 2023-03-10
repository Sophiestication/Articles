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

#import "ReadLaterViewController.h"
#import "ReadLaterViewController+Private.h"

#import "SAReadLaterTableViewCell.h"
#import "SFShadowView.h"

#import "SAArticle.h"

#import "SAReadLaterBookmark.h"
#import "SAReadLaterBookmark+Additions.h"

#import "SAReadLaterTableViewCell+Private.h"
#import "SAReadLaterTableViewCellContentView.h"

#import "Articles.h"

#import "UINavigationController+Additions.h"
#import "UIBarButtonItem+Additions.h"

@implementation ReadLaterViewController

@synthesize doneButtonItem = _doneButtonItem;
@synthesize clearButtonItem = _clearButtonItem;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize userDefaults = _userDefaults;
@dynamic defaultToolbarItems;
@dynamic editingToolbarItems;

#pragma mark -
#pragma mark Construction & Destruction

+ (id)viewController {
	return [[self alloc] initWithNibName:@"ReadLaterViewController" bundle:nil]; 
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
	if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		self.title = NSLocalizedString(@"READLATER_NAVIGATIONITEM_TITLE", @"");
		self.contentSizeForViewInPopover = CGSizeMake(320.0, 480.0);
	}
	
	return self;
}

- (void)dealloc {

	
	self.fetchedResultsController.delegate = nil;


}

#pragma mark -
#pragma mark ReadLaterViewController

- (IBAction)done:(id)sender {
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
		destructiveButtonTitle:NSLocalizedString(@"SHEETBUTTON_MARKALLREAD", @"")
		otherButtonTitles:nil];
	
	actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
	
    if(self.navigationController.toolbarHidden) {
    	[actionSheet showInView:[[self navigationController] view]];
    } else {
    	[actionSheet showInView:[[self navigationController] toolbar]];
    }
}

- (IBAction)clearAll:(id)sender {
	for(SAArticle* article in self.fetchedResultsController.fetchedObjects) {
		article.unread = [NSNumber numberWithBool:NO];
	}
	
//	[self updateContentViewAnimated:YES];
}

#pragma mark -
#pragma mark SFTableViewController

- (void)placeholderView:(SFPlaceholderView*)placeholderView willAppearAnimated:(BOOL)animated {
	placeholderView.imageView.image = [UIImage imageNamed:@"readLaterPlaceholder.png"];
	placeholderView.textLabel.text = NSLocalizedString(@"READLATER_PLACEHOLDER_TITLE", @"");
	placeholderView.detailTextLabel.text = NSLocalizedString(@"READLATER_PLACEHOLDER_DESCRIPTION", @"");
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self initFetchedResultsControllerIfNeeded];
    
    self.clearButtonItem.title = NSLocalizedString(@"BARBUTTON_ITEM_CLEAR", @"");
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		self.navigationItem.rightBarButtonItem = self.doneButtonItem;
	}

	self.toolbarItems = self.defaultToolbarItems;
	
	[self updateContentViewAnimated:NO];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	
	self.doneButtonItem = nil;
	self.clearButtonItem = nil;
	
	self.fetchedResultsController.delegate = nil;
	self.fetchedResultsController = nil;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	_visible = YES;
	
	// Make sure to recreate a results controller in case we reset it earlier
	[self initFetchedResultsControllerIfNeeded];
	
	// Retrieve the content offset from user defaults if needed
	NSString* contentOffsetString = [[self userDefaults] objectForKey:@"contentOffset"];
	
	if(contentOffsetString.length > 0) {
		self.tableView.contentOffset = CGPointFromString(contentOffsetString);
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
    
// 	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
//		[[self navigationController] setToolbarHidden:NO animated:YES];
//	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	_visible = NO;
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

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	if(self.editing != editing) {
		[super setEditing:editing animated:animated];
		
		// Adjust the top right button item
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
			UIBarButtonItem* rightButtonItem = editing ? 
				nil :
				self.doneButtonItem;
			[[self navigationItem]
				setRightBarButtonItem:rightButtonItem
				animated:animated];
        
			// Now adjust the toolbat items
			NSArray* toolbarItems = editing ?
				self.editingToolbarItems :
				self.defaultToolbarItems;
			[self setToolbarItems:toolbarItems animated:NO];
        } else {
        	UIBarButtonItem* rightButtonItem = editing ? 
				[self editButtonItem] :
				[self clearButtonItem];
			[[self navigationItem]
				setRightBarButtonItem:rightButtonItem
				animated:animated];
        }
	}
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    NSInteger numberOfSections = [[[self fetchedResultsController] sections] count];
	return numberOfSections;
}
 
- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	id <NSFetchedResultsSectionInfo> sectionInfo = [[[self fetchedResultsController] sections] objectAtIndex:section];
	return [sectionInfo numberOfObjects];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* cellIdentifier = @"regular";
    
	SAReadLaterTableViewCell* cell = (id)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
	if(!cell) {
        cell = [[SAReadLaterTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
	[self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
	if(editingStyle == UITableViewCellEditingStyleDelete) {
		SAArticle* article = [[self fetchedResultsController] objectAtIndexPath:indexPath];
		article.unread = [NSNumber numberWithBool:NO];
		
//		NSArray* rows = [NSArray arrayWithObject:indexPath];
//		[tableView deleteRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationLeft];
	}
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	SAArticle* article = [[self fetchedResultsController] objectAtIndexPath:indexPath];
	
	NSURL* articleURL = [NSURL URLWithString:[article articleURL]];
	[[Articles self] openArticleURL:articleURL];
	
	[self done:tableView];
	
	// We wait for the sheet animation to complete
	[article performSelector:@selector(setUnread:)
		withObject:[NSNumber numberWithBool:NO]
		afterDelay:0.3];
}

- (NSString*)tableView:(UITableView*)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath*)indexPath {
	return NSLocalizedString(@"MARKREAD_TITLE", @"");
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	
	CGSize cellSize = [cell sizeThatFits:[tableView bounds].size];
	
	return ceilf(cellSize.height);
}

#pragma mark -
#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController*)controller {
	[[self tableView] beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController*)controller {
	[[self tableView] endUpdates];
	[self updateContentViewAnimated:YES];
}

- (void)controller:(NSFetchedResultsController*)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath*)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath*)newIndexPath {
	UITableView* tableView = self.tableView;

	switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
				withRowAnimation:_visible ? UITableViewRowAnimationLeft : UITableViewRowAnimationNone];
            break;
 
        case NSFetchedResultsChangeDelete:
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
				withRowAnimation:_visible ? UITableViewRowAnimationLeft : UITableViewRowAnimationNone];
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
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(buttonIndex == actionSheet.cancelButtonIndex) { return; }
	
	[self clearAll:actionSheet];
}

#pragma mark -
#pragma mark Private

- (void)initFetchedResultsControllerIfNeeded {
	if(!self.fetchedResultsController) {
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
		self.fetchedResultsController = fetchedResultsController;
		
		// ...
		NSError* error = nil;
		
		if(![fetchedResultsController performFetch:&error]) {
			NSLog(@"%@", error);
		}
	}
}

- (void)configureCell:(SAReadLaterTableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath {
//	SAArticle* article = [[self fetchedResultsController] objectAtIndexPath:indexPath];
//	
//	cell.textLabel.text = article.title;
//	cell.imageView.image = [UIImage imageNamed:@"bookmark.png"];

	SAArticle* article = [[self fetchedResultsController] objectAtIndexPath:indexPath];
	SAReadLaterBookmark* bookmark = article.readLater;
	
	cell.textView.text = bookmark.text;
	cell.textView.markedTextRange = NSRangeFromString([bookmark targetTextRange]);
}

- (NSArray*)defaultToolbarItems {
	NSArray* toolbarItems = [NSArray arrayWithObjects:
		[self editButtonItem],
		[UIBarButtonItem flexibleSpaceSystemItem],
		[self clearButtonItem],
		nil];
	return toolbarItems;
}

- (NSArray*)editingToolbarItems {
	NSArray* toolbarItems = [NSArray arrayWithObjects:
		[self editButtonItem],
		nil];
	return toolbarItems;
}

- (void)updateContentViewAnimated:(BOOL)animated {
	BOOL showPlaceholderView = self.fetchedResultsController.fetchedObjects.count <= 0;
	
	self.clearButtonItem.enabled = !showPlaceholderView;
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    	UIBarButtonItem* rightButtonItem = showPlaceholderView ?
        	nil :
            [self clearButtonItem];
		[[self navigationItem]
        	setRightBarButtonItem:rightButtonItem
            animated:animated];
	}
    
	[[self editButtonItem] setEnabled:!showPlaceholderView];
	
	[self setShowsPlaceholderView:showPlaceholderView animated:animated];
}

- (void)restoreFromUserDefaults:(NSDictionary*)userDefaults inSelection:(NSArray*)selection {
	self.userDefaults = userDefaults;
}

@end
