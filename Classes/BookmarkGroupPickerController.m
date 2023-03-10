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

#import "BookmarkGroupPickerController.h"

#import "SABookmarkGroup.h"
#import "SABookmark.h"

@implementation BookmarkGroupPickerController

@synthesize selectedBookmarkGroup = _selectedBookmarkGroup;
@synthesize excludedBookmarkGroups = _excludedBookmarkGroups;
@synthesize delegate = _delegate;
@synthesize managedObjectContext = _managedObjectContext;

#pragma mark -
#pragma mark Construction & Destruction

+ (id)viewController {
	return [[self alloc] initWithNibName:@"BookmarkGroupPickerController" bundle:nil]; 
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
	if(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		self.contentSizeForViewInPopover = CGSizeMake(320.0, 460.0);
		self.hidesBottomBarWhenPushed = YES;
	}
	
	return self;
}


#pragma mark -
#pragma mark BookmarkGroupPickerController

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.title = NSLocalizedString(@"BOOKMARKS_NAVIGATIONITEM_TITLE", @"");
	
	// Load our bookmark groups
	NSManagedObjectContext* context = self.managedObjectContext;

	NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
	
	NSEntityDescription* entity = [NSEntityDescription entityForName:@"BookmarkGroup" inManagedObjectContext:context];
	[fetchRequest setEntity:entity];

	NSArray* sortDescriptors = [NSArray arrayWithObjects:
		[[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:YES],
		[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES],
		nil];
	[fetchRequest setSortDescriptors:sortDescriptors];
	
	NSPredicate* predicate = [NSPredicate predicateWithFormat:@"superitem == nil"];
	[fetchRequest setPredicate:predicate];
	
	NSArray* relationshipKeyPathsForPrefetching = [NSArray arrayWithObjects:
		@"subitems",
		nil];
	[fetchRequest setRelationshipKeyPathsForPrefetching:relationshipKeyPathsForPrefetching];
	
	NSArray* bookmarkGroups = [context executeFetchRequest:fetchRequest error:nil];
	NSMutableArray* sectionItems = [NSMutableArray array];
	
	NSDictionary* rootSectionItem = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInteger:0], @"level",
		nil];
	[sectionItems addObject:rootSectionItem];
	
	for(SABookmarkGroup* bookmarkGroup in bookmarkGroups) {
		[sectionItems addObjectsFromArray:
			[self sectionItemsForBookmarkGroup:bookmarkGroup level:1]];
	}
	
	_sections = sectionItems;
}

- (void)viewDidUnload {
	[super viewDidUnload];
	
	_selectedBookmarkGroup = nil;
	_sections = nil;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
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
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView*)table numberOfRowsInSection:(NSInteger)section {
	return _sections.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	static NSString* const reuseIdentifier = @"regular";
		
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
		
	if(!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
	}
		
	SABookmarkGroup* bookmarkGroup = [[_sections objectAtIndex:[indexPath row]] objectForKey:@"bookmarkGroup"];
		
	cell.textLabel.text = bookmarkGroup ?
		bookmarkGroup.title :
		NSLocalizedString(@"BOOKMARKS_NAVIGATIONITEM_TITLE", @"");
	
	cell.imageView.image = [UIImage imageNamed:@"bookmarkGroup.png"];
	cell.accessoryType = bookmarkGroup == self.selectedBookmarkGroup || [bookmarkGroup isEqual:[self selectedBookmarkGroup]] ?
		UITableViewCellAccessoryCheckmark :
		UITableViewCellAccessoryNone;
	
	cell.indentationLevel = [[[_sections objectAtIndex:[indexPath row]] objectForKey:@"level"] integerValue];
		
	return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	for(NSInteger rowIndex = 0; rowIndex < _sections.count; ++rowIndex) {
		[[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:rowIndex inSection:0]]
			setAccessoryType:UITableViewCellAccessoryNone];
	}
	
	[[tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
		
	self.selectedBookmarkGroup = [[_sections objectAtIndex:[indexPath row]] objectForKey:@"bookmarkGroup"];
	
	if([[self delegate] respondsToSelector:@selector(bookmarkGroupPickerController:didFinishPickingGroup:)]) {
		[[self delegate] bookmarkGroupPickerController:self didFinishPickingGroup:[self selectedBookmarkGroup]];
	}
	
	[[self navigationController] popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Private

- (NSArray*)sectionItemsForBookmarkGroup:(SABookmarkGroup*)bookmarkGroup level:(NSInteger)level {
	NSMutableArray* sectionItems = [NSMutableArray array];
	
	if(![[self excludedBookmarkGroups] containsObject:bookmarkGroup]) {
		NSDictionary* sectionItem = [NSDictionary dictionaryWithObjectsAndKeys:
			bookmarkGroup, @"bookmarkGroup",
			[NSNumber numberWithInteger:level], @"level",
			nil];
		[sectionItems addObject:sectionItem];
	
		for(SABookmarkGroup* subgroup in bookmarkGroup.subitems) {
			if([subgroup isKindOfClass:[SABookmarkGroup class]]) {
				[sectionItems addObjectsFromArray:
					[self sectionItemsForBookmarkGroup:subgroup level:level + 1]];
			}
		}
	}

	return sectionItems;
}

@end
