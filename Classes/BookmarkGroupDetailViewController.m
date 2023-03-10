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

#import "BookmarkGroupDetailViewController.h"

#import "BookmarkGroupPickerController.h"

#import "SABookmarkGroup.h"

#import "SFEditableTableViewCell.h"

#import "NSArray+Additions.h"
#import "UIColor+Additions.h"
#import "UINavigationController+Additions.h"

@interface BookmarkGroupDetailViewController()

@property(nonatomic) CGRect keyboardRect;

@end

@implementation BookmarkGroupDetailViewController

@synthesize cancelButtonItem = _cancelButtonItem;
@synthesize saveButtonItem = _saveButtonItem;

@synthesize delegate = _delegate;

@synthesize bookmarkGroup = _bookmarkGroup;
@synthesize selectedBookmarkSupergroup = _selectedBookmarkSupergroup;

@synthesize managedObjectContext = _managedObjectContext;
@synthesize bookmarkGroupTitle = _bookmarkGroupTitle;

#pragma mark - Construction & Destruction

+ (id)viewController {
	return [[self alloc] initWithNibName:@"BookmarkGroupDetailViewController" bundle:nil]; 
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
	if(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		self.contentSizeForViewInPopover = CGSizeMake(320.0, 480.0);
		self.hidesBottomBarWhenPushed = YES;
		self.modalInPopover = YES;
		self.modalPresentationStyle = UIModalPresentationPageSheet;
	}
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - BookmarkGroupDetailViewController

- (IBAction)cancel:(id)sender {
	if(self.navigationController.rootViewController == self) {
		[[self navigationController] dismissViewControllerAnimated:YES completion:nil];
	} else {
		[[self navigationController] popViewControllerAnimated:YES];
	}
}

- (IBAction)save:(id)sender {
	// Save the new bookmark group
	SABookmarkGroup* bookmarkGroup = self.bookmarkGroup;

	bookmarkGroup.title = self.bookmarkGroupTitle;
	
	NSManagedObjectContext* managedObjectContext = self.managedObjectContext;
	
	if(/*![bookmarkGroup isInserted]*/ bookmarkGroup.objectID.isTemporaryID) {
		[managedObjectContext insertObject:bookmarkGroup];
	}
	
	if(bookmarkGroup.superitem != self.selectedBookmarkSupergroup) {
		[[bookmarkGroup superitem] removeSubitemsObject:bookmarkGroup];
		[[self selectedBookmarkSupergroup] addSubitemsObject:bookmarkGroup];
	}
	
	if([managedObjectContext hasChanges]) {
		[managedObjectContext save:nil];
	}
	
	if([[self delegate] respondsToSelector:@selector(bookmarkGroupDetailViewController:didSaveGroup:)]) {
		[[self delegate] bookmarkGroupDetailViewController:self didSaveGroup:bookmarkGroup];
	}

	if(self.navigationController.rootViewController == self) {
		[[self navigationController] dismissViewControllerAnimated:YES completion:nil];
	} else {
		[[self navigationController] popViewControllerAnimated:YES];
	}
}

#pragma mark -
#pragma mark UIViewController

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
	
	if([self.bookmarkGroup.objectID isTemporaryID]) {
		self.title = NSLocalizedString(@"NEW_BOOKMARKGROUP_NAVIGATIONITEM_TITLE", @"");
	} else {
		self.title = NSLocalizedString(@"UIBarButtonSystemItemEdit", @"");
		self.bookmarkGroupTitle = self.bookmarkGroup.title;
	}
	
	self.navigationItem.leftBarButtonItem = self.cancelButtonItem;
	self.navigationItem.rightBarButtonItem = self.saveButtonItem;
	
	[self updateSaveButtonItem];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	
	self.cancelButtonItem = nil;
	self.saveButtonItem = nil;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[self updateForInterfaceOrientation:[self interfaceOrientation]];
	
	// Start editing
	SFEditableTableViewCell* cell = (id)[[self tableView] cellForRowAtIndexPath:
		[NSIndexPath indexPathForRow:0 inSection:0]];
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

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
	return 2;
}

- (NSInteger)tableView:(UITableView*)table numberOfRowsInSection:(NSInteger)section {
	return 1;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	if(indexPath.section == 0) { // TODO
		static NSString* cellIdentifier = @"editable";
		SFEditableTableViewCell* cell = (id)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];

		if(!cell) {
			cell = [[SFEditableTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		}
		
		cell.textField.text = self.bookmarkGroupTitle;
		cell.textField.placeholder = NSLocalizedString(@"PROPERTY_NAME_TITLE", @"");

		cell.textField.delegate = self;
	
		return cell;
	}
	
	if(indexPath.section == 1) { // TODO
		static NSString* cellIdentifier = @"group";

		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
		if(!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
		}
		
		cell.textLabel.font = [UIFont systemFontOfSize:17.0];
		cell.textLabel.textColor = cell.detailTextLabel.textColor;
		
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
		SABookmarkGroup* supergroup = self.selectedBookmarkSupergroup;
		cell.textLabel.text = supergroup ?
			supergroup.title :
			NSLocalizedString(@"BOOKMARKS_NAVIGATIONITEM_TITLE", @"");
		
		return cell;
	}
	
    return nil;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	if(indexPath.section == 1) {
		BookmarkGroupPickerController* picker = [BookmarkGroupPickerController viewController];
		
		picker.selectedBookmarkGroup = self.selectedBookmarkSupergroup;
		picker.excludedBookmarkGroups = [NSSet setWithObject:[self bookmarkGroup]];
		picker.managedObjectContext = self.managedObjectContext;
		
		picker.delegate = self;
		
		[[self navigationController] pushViewController:picker animated:YES];
	}
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	return YES;
}

- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string {
	NSString* newTitle = [[textField text]
		stringByReplacingCharactersInRange:range
		withString:string];
	self.bookmarkGroupTitle = newTitle;
	
	[self performSelector:@selector(updateSaveButtonItem)
		withObject:nil
		afterDelay:0.0];

	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField*)textField {
	self.bookmarkGroupTitle = nil;

	[self performSelector:@selector(updateSaveButtonItem)
		withObject:nil
		afterDelay:0.0];

	return YES;
}

#pragma mark - BookmarkGroupPickerDelegate

- (void)bookmarkGroupPickerController:(BookmarkGroupPickerController*)picker didFinishPickingGroup:(SABookmarkGroup*)group {
	self.selectedBookmarkSupergroup = group;
	
	NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
	UITableViewCell* cell = [[self tableView] cellForRowAtIndexPath:indexPath];
	cell.textLabel.text = self.selectedBookmarkSupergroup ?
		self.selectedBookmarkSupergroup.title :
		NSLocalizedString(@"BOOKMARKS_NAVIGATIONITEM_TITLE", @"");
}

#pragma mark - UIKeyboardDidChangeFrameNotification

- (void)keyboardDidChangeFrame:(NSNotification*)notification {
	CGRect keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	keyboardRect = [[self tableView] convertRect:keyboardRect fromView:nil];
	self.keyboardRect = keyboardRect;
	
	[self adjustContentInsetsIfNeeded];
}

#pragma mark - Private

- (void)updateSaveButtonItem {
	self.saveButtonItem.enabled = self.bookmarkGroupTitle.length > 0;
}

- (void)updateForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if(UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
		self.tableView.contentInset = UIEdgeInsetsMake(36.0, 0.0, 0.0, 0.0);
	} else {
		self.tableView.contentInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
	}
}

- (void)adjustContentInsetsIfNeeded {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { return; }

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
