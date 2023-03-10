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

#import "BookmarkDetailViewController.h"
#import "BookmarkDetailViewController+Private.h"

#import "BookmarkGroupPickerController.h"

#import "SABookmark.h"
#import "SABookmarkGroup.h"
#import "SAArticle.h"

#import "SFEditableTableViewCell.h"

#import "UIColor+Additions.h"
#import "UINavigationController+Additions.h"

@implementation BookmarkDetailViewController

@synthesize delegate = _delegate;

@synthesize cancelButtonItem = _cancelButtonItem;
@synthesize saveButtonItem = _saveButtonItem;

@synthesize bookmark = _bookmark;
@synthesize bookmarkGroup = _bookmarkGroup;
@synthesize bookmarkTitle = _bookmarkTitle;

@dynamic detailSectionIndex;
@dynamic bookmarkGroupSectionIndex;

#pragma mark - Construction & Destruction

+ (id)viewController {
	return [[self alloc] initWithNibName:@"BookmarkDetailViewController" bundle:nil];
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
	if(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		self.contentSizeForViewInPopover = CGSizeMake(320.0, 480.0);
		self.hidesBottomBarWhenPushed = YES;

		self.modalPresentationStyle = UIModalPresentationFormSheet;
		self.definesPresentationContext = YES;
	}
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - BookmarkDetailViewController

- (void)cancel:(id)sender {
	if(self.bookmark.objectID.isTemporaryID) {
		NSManagedObjectContext* managedObjectContext = self.bookmark.managedObjectContext;
		[managedObjectContext deleteObject:[self bookmark]];
	}

	if([[self delegate] respondsToSelector:@selector(bookmarkDetailViewControllerDidCancel:)]) {
		[[self delegate] bookmarkDetailViewControllerDidCancel:self];
	}

	[self dismissViewControllerIfNeeded];
}

- (void)save:(id)sender {
	self.bookmark.title = self.bookmarkTitle;
	self.bookmark.superitem = self.bookmarkGroup;
	
	NSManagedObjectContext* managedObjectContext = self.bookmark.managedObjectContext;
	NSError* error = nil;
	
	if(![managedObjectContext save:&error]) {
		NSLog(@"%@", error);
	}
	
	if([[self delegate] respondsToSelector:@selector(bookmarkDetailViewController:didSaveBookmark:)]) {
		[[self delegate] bookmarkDetailViewController:self didSaveBookmark:[self bookmark]];
	}

	[self dismissViewControllerIfNeeded];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

	// keyboard notifications
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(keyboardDidChangeFrame:)
		name:UIKeyboardDidChangeFrameNotification
		object:nil];
	
	if([UIDocument class]) {
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
	}
	
	self.navigationItem.leftBarButtonItem = self.cancelButtonItem;
	self.navigationItem.rightBarButtonItem = self.saveButtonItem;
	
	if(!self.bookmark || [self.bookmark.objectID isTemporaryID]) {
		self.title = NSLocalizedString(@"NEW_BOOKMARK_NAVIGATIONITEM_TITLE", @"");
	} else {
		self.title = NSLocalizedString(@"UIBarButtonSystemItemEdit", @"");
	}
	
	self.bookmarkGroup = (id)self.bookmark.superitem;
	self.bookmarkTitle = self.bookmark.title;
	
	if(!self.bookmarkGroup && [self.bookmark.objectID isTemporaryID]) {
		NSString* objectURIString = [[NSUserDefaults standardUserDefaults] objectForKey:@"SARecentlySelectedBookmarkGroup"];
		
		if(objectURIString.length > 0) {
			NSURL* objectURI = [NSURL URLWithString:objectURIString];
			NSManagedObjectID* objectID = [[[[self bookmark] managedObjectContext]
				persistentStoreCoordinator]
				managedObjectIDForURIRepresentation:objectURI];
				
			self.bookmarkGroup = (id)[[[self bookmark] managedObjectContext] objectWithID:objectID];
		}
	}
}

- (void)viewDidUnload {
	[super viewDidUnload];
	
	self.cancelButtonItem = nil;
	self.saveButtonItem = nil;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	// Update the button items first
	[self updateButtonItems];
	
	// And now the content insets
	[self updateForInterfaceOrientation:[self interfaceOrientation]];
	
	// Start editing
	SFEditableTableViewCell* cell = (id)[[self tableView] cellForRowAtIndexPath:
		[NSIndexPath indexPathForRow:0 inSection:[self detailSectionIndex]]];
	[[cell textField] performSelector:@selector(becomeFirstResponder)
		withObject:nil
		afterDelay:0.0];

	[self adjustContentInsetsIfNeeded];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if(self.navigationController.parentViewController) {
		return [[[self navigationController] parentViewController] shouldAutorotateToInterfaceOrientation:interfaceOrientation];
	}
	
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

	[self updateForInterfaceOrientation:toInterfaceOrientation];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	if(section == self.detailSectionIndex) {
		return 2;
	}
	
	if(section == self.bookmarkGroupSectionIndex) {
		return 1;
	}

    return 0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	if(indexPath.section == self.detailSectionIndex) {
		if(indexPath.row == 0) { // TODO
			static NSString* cellIdentifier = @"editable";
			SFEditableTableViewCell* cell = (id)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
			if(!cell) {
				cell = [[SFEditableTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
			}
			
			cell.textField.text = self.bookmarkTitle;
			cell.textField.placeholder = NSLocalizedString(@"PROPERTY_NAME_TITLE", @"");
		
			cell.textField.delegate = self;
		
			return cell;
		}
		
		if(indexPath.row == 1) { // TODO
			static NSString* cellIdentifier = @"regular";
			UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
			if(!cell) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
			}
			
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			
			cell.textLabel.font = [UIFont systemFontOfSize:17.0];
			cell.textLabel.textColor = [UIColor lightGrayColor];
			cell.textLabel.text = self.bookmark.article.articleURL;
			cell.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
		
			return cell;
		}
	}
	
	if(indexPath.section == self.bookmarkGroupSectionIndex) {
		static NSString* cellIdentifier = @"group";

		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
		if(!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
		}
		
		cell.textLabel.font = [UIFont systemFontOfSize:17.0];
		cell.textLabel.textColor = cell.detailTextLabel.textColor;
		
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
		cell.textLabel.text = self.bookmarkGroup ?
			self.bookmarkGroup.title :
			NSLocalizedString(@"BOOKMARKS_NAVIGATIONITEM_TITLE", @"");
		
		return cell;
	}
	
    return nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	if(indexPath.section == self.detailSectionIndex) {
		if(indexPath.row == 0) {
			SFEditableTableViewCell* cell = (id)[tableView cellForRowAtIndexPath:indexPath];
			[[cell textField] becomeFirstResponder];
		}
	}
	
	if(indexPath.section == self.bookmarkGroupSectionIndex) {
		// Deselect the selected row
		[tableView deselectRowAtIndexPath:indexPath animated:YES];

		// Make a new bookmark group picker
		BookmarkGroupPickerController* picker = [BookmarkGroupPickerController viewController];
		
		picker.delegate = self;
		
		picker.selectedBookmarkGroup = self.bookmarkGroup;
		picker.managedObjectContext = self.bookmark.managedObjectContext;
		
		[[self navigationController] pushViewController:picker animated:YES];
	}
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string {
	NSString* newTitle = [[textField text]
		stringByReplacingCharactersInRange:range
		withString:string];
	self.bookmarkTitle = newTitle;
	
	[self performSelector:@selector(updateButtonItems)
		withObject:nil
		afterDelay:0.0];

	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField*)textField {
	self.bookmarkTitle = nil;

	[self performSelector:@selector(updateButtonItems)
		withObject:nil
		afterDelay:0.0];

	return YES;
}

#pragma mark - BookmarkGroupPickerDelegate

- (void)bookmarkGroupPickerController:(BookmarkGroupPickerController*)picker didFinishPickingGroup:(SABookmarkGroup*)group {
	[[NSUserDefaults standardUserDefaults]
		setObject:[[[group objectID] URIRepresentation] absoluteString]
		forKey:@"SARecentlySelectedBookmarkGroup"];
	
	self.bookmarkGroup = group;
	
	[[self tableView] reloadData];
}

#pragma mark - UIKeyboardDidChangeFrameNotification

- (void)keyboardDidChangeFrame:(NSNotification*)notification {
	CGRect keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	keyboardRect = [[self tableView] convertRect:keyboardRect fromView:nil];
	self.keyboardRect = keyboardRect;
	
	[self adjustContentInsetsIfNeeded];
}

#pragma mark - Private

- (NSInteger)detailSectionIndex {
	return 0;
}

- (NSInteger)bookmarkGroupSectionIndex {
	return 1;
}

- (void)updateButtonItems {
	self.saveButtonItem.enabled = self.bookmarkTitle.length > 0;
}

- (void)updateForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
//	if(UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
//		self.tableView.contentInset = UIEdgeInsetsMake(12.0, 0.0, 0.0, 0.0);
//	} else {
//		self.tableView.contentInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
//	}
}

- (void)dismissViewControllerIfNeeded {
	if([[self delegate] respondsToSelector:@selector(bookmarkDetailViewControllerShouldDismiss:)]) {
		BOOL shouldDismiss = [[self delegate] bookmarkDetailViewControllerShouldDismiss:self];
		if(!shouldDismiss) { return; }
	}

	if(self.navigationController.rootViewController == self) {
		[[self navigationController] dismissViewControllerAnimated:YES completion:nil];
	} else {
		[[self navigationController] popViewControllerAnimated:YES];
	}
}

- (void)adjustContentInsetsIfNeeded {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { return; }
	if(CGRectGetHeight([[UIScreen mainScreen] bounds]) <= 480.0) { return; }

	NSInteger lastSectionIndex = [[self tableView] numberOfSections] - 1;
	if(lastSectionIndex < 0) { return; }
	
	UIEdgeInsets contentInset = UIEdgeInsetsZero;
	
	self.tableView.contentInset = contentInset; // reset for [rectForSection:]
	
	CGRect rect = [[self tableView] rectForSection:lastSectionIndex];
	CGRect contentRect = self.tableView.bounds;
	
	if(CGRectIsEmpty([self keyboardRect])) {
		contentRect.size.height -= 216.0; // TODO:
	} else {
		contentRect.size.height -= CGRectGetHeight([self keyboardRect]);
	}
	
	if(CGRectGetHeight(contentRect) > CGRectGetMaxY(rect)) {
		CGFloat padding = CGRectGetHeight(contentRect) - CGRectGetMaxY(rect);
		contentInset.top = round(padding * 0.5);
	}
	
	self.tableView.contentInset = contentInset;
}

@end
