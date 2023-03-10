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

#import "SAArticleStackController.h"
#import "SAArticleStackController+Private.h"

#import "SAArticle.h"
#import "SAArticle+Additions.h"

#import "NSArray+Additions.h"

#import "ArticleKit.h"
#import	"AKArticleView+Private.h"

@implementation SAArticleStackController

@synthesize managedObjectContext = _managedObjectContext;

@synthesize stacks = _stacks;
@dynamic selectedStack;
@synthesize selectedStackItems = _selectedStackItems;

@synthesize articleView = _articleView;

#pragma mark -
#pragma mark Construction & Destruction

- (id)init {
	if(self = [super init]) {
	}
	
	return self;
}

- (void)dealloc {
	[self save];
	
	
	self.selectedStack = nil;

	
}

#pragma mark -
#pragma mark SAArticleStackController

- (SAArticleStack*)selectedStack {
	return _selectedStack;
}

- (void)setSelectedStack:(SAArticleStack*)selectedStack {
	if(selectedStack != _selectedStack) {
		_selectedStack = selectedStack;
		
		// Update the selectedStackItems array
		NSArray* sortDescriptors = [NSArray arrayWithObjects:
			[[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:YES],
			nil];
		NSArray* stackItems = [[selectedStack items] allObjects];
		
		self.selectedStackItems = [stackItems sortedArrayUsingDescriptors:sortDescriptors];

		[self save];
	}
}

- (void)refresh {
	NSInteger selectedStackIndex = [[NSUserDefaults standardUserDefaults]
		integerForKey:@"SASelectedStackIndex"];
	
	// Fetch all article stacks
	NSManagedObjectContext* managedObjectContext = self.managedObjectContext;

	NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
	
	NSEntityDescription* entity = [NSEntityDescription
		entityForName:@"ArticleStack"
		inManagedObjectContext:managedObjectContext];
	[fetchRequest setEntity:entity];
	
	NSArray* sortDescriptors = [NSArray arrayWithObjects:
		[[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:YES],
		nil];
	[fetchRequest setSortDescriptors:sortDescriptors];
	
	NSError* error = nil;
	NSArray* fetchResults = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
	
	
	if(error) {
		// TODO
	}
	
	// Make a stack if needed
	if(fetchResults.count == 0) {
		SAArticleStack* stack = [NSEntityDescription
			insertNewObjectForEntityForName:@"ArticleStack"
			inManagedObjectContext:managedObjectContext];
		
		stack.sortOrder = [NSNumber numberWithInteger:0];
		
		fetchResults = [NSArray arrayWithObject:stack];
		
		selectedStackIndex = 0;
	}
	
	// Determine the selected stack
	for(SAArticleStack* stack in fetchResults) {
		if([[stack sortOrder] integerValue] == selectedStackIndex) {
			self.selectedStack = stack;
			break;
		}
	}
	
	if(!self.selectedStack) {
		self.selectedStack = fetchResults.firstObject;
	}
	
	self.stacks = fetchResults;
}

- (void)save {
	NSNumber* selectedStackIndex = self.selectedStack.sortOrder;

	[[NSUserDefaults standardUserDefaults]
		setObject:selectedStackIndex
		forKey:@"SASelectedStackIndex"];
}

- (void)navigateToArticle:(SAArticle*)article {
	SAArticleStackItem* selectedStackItem = self.selectedStack.selectedItem;
	
	if([[selectedStackItem article] isEqual:article]) {
		return;
	}
	
	if(selectedStackItem && self.selectedStackItems.lastObject != selectedStackItem) {
		NSInteger selectedStackItemIndex = [[self selectedStackItems]
			indexOfObject:[[self selectedStack] selectedItem]];

		// Delete all obsolete stack items
		NSArray* obsoleteSelectedStackItems = [[self selectedStackItems]
			subarrayWithRange:NSMakeRange(selectedStackItemIndex + 1, self.selectedStackItems.count - selectedStackItemIndex - 1)];
		
		for(SAArticleStackItem* obsoleteStackItem in obsoleteSelectedStackItems) {
			[[obsoleteStackItem managedObjectContext] deleteObject:obsoleteStackItem];
		}
		
		// Now retain the remaining stack items
		NSArray* newSelectedStackItems = [[self selectedStackItems]
			subarrayWithRange:NSMakeRange(0, selectedStackItemIndex + 1)];
		self.selectedStackItems = newSelectedStackItems;
	}
	
	// Store the content offset in our stack item
	CGPoint contentOffset = self.articleView.contentOffset;
	selectedStackItem.contentOffset = [NSValue valueWithCGPoint:contentOffset];
	
	// Make a new stack item
	NSManagedObjectContext* managedObjectContext = self.managedObjectContext;
	SAArticleStack* stack = self.selectedStack;
	
	SAArticleStackItem* stackItem = [NSEntityDescription
		insertNewObjectForEntityForName:@"ArticleStackItem"
		inManagedObjectContext:managedObjectContext];
	
	stackItem.article = article;
	stackItem.sortOrder = [NSNumber numberWithInteger:[[self selectedStackItems] count]];
	
	[stack addItemsObject:stackItem];
	
	self.selectedStackItems = [[self selectedStackItems] arrayByAddingObject:stackItem];
	self.selectedStack.selectedItem = stackItem;
}

- (void)didNavigateToArticleURL:(NSURL*)articleURL {
	SAArticle* selectedArticle = self.selectedStack.selectedItem.article;
	selectedArticle.articleURL = [articleURL absoluteString];
    
    if(selectedArticle.title.length == 0) {
    	selectedArticle.title = [articleURL wikipediaTitle];
    }
	
//	[self dumpHierarchy];
}

- (BOOL)canNavigateBack {
	return self.selectedStackItems.firstObject != self.selectedStack.selectedItem;
}

- (SAArticleStackItem*)navigateBack {
	// Store the content offset in our stack item
	CGPoint contentOffset = self.articleView.contentOffset;
	self.selectedStack.selectedItem.contentOffset = [NSValue valueWithCGPoint:contentOffset];

	// Determine the previous article
	NSInteger selectedStackItemIndex = [[self selectedStackItems]
		indexOfObject:[[self selectedStack] selectedItem]];
	
	if(selectedStackItemIndex > 0) {
		NSInteger newSelectedStackItemIndex = selectedStackItemIndex - 1;

		SAArticleStackItem* stackItem = [[self selectedStackItems]
			objectAtIndex:newSelectedStackItemIndex];
			
		self.selectedStack.selectedItem = stackItem;
		
		return stackItem;
	}
	
	return nil;
}

- (BOOL)canNavigateForward {
	return self.selectedStackItems.lastObject != self.selectedStack.selectedItem;
}

- (SAArticleStackItem*)navigateForward {
	// Store the content offset in our stack item
	CGPoint contentOffset = self.articleView.contentOffset;
	self.selectedStack.selectedItem.contentOffset = [NSValue valueWithCGPoint:contentOffset];
	
	// Determine the next article
	NSInteger selectedStackItemIndex = [[self selectedStackItems]
		indexOfObject:[[self selectedStack] selectedItem]];
	
	if(selectedStackItemIndex < self.selectedStackItems.count) {
		NSInteger newSelectedStackItemIndex = selectedStackItemIndex + 1;

		SAArticleStackItem* stackItem = [[self selectedStackItems]
			objectAtIndex:newSelectedStackItemIndex];
			
		self.selectedStack.selectedItem = stackItem;
		
		return stackItem;
	}
	
	return nil;
}

- (SAArticleStack*)addNewArticleStack {
	SAArticleStack* articleStack = [NSEntityDescription
		insertNewObjectForEntityForName:@"ArticleStack"
		inManagedObjectContext:[self managedObjectContext]];
	
	NSInteger sortOrder = self.stacks.count + 1;
	articleStack.sortOrder = [NSNumber numberWithInteger:sortOrder];
	
	self.stacks = [[self stacks] arrayByAddingObject:articleStack];

	return articleStack;
}

- (void)deleteArticleStack:(SAArticleStack*)articleStack {
	[[self managedObjectContext] deleteObject:articleStack];

	if(articleStack == self.selectedStack) {
		self.selectedStack = nil;
	}
	
	self.stacks = [[self stacks] arrayByRemovingObject:articleStack];
	
	// Now Update the sort order for each stack
	NSInteger sortOrder = 0;

	for(SAArticleStack* stack in self.stacks) {
		stack.sortOrder = [NSNumber numberWithInteger:sortOrder];
		++sortOrder;
	}
	
	[self save];
}

- (SAArticleStack*)navigateToArticleURLInNewPageIfNeeded:(NSURL*)articleURL {
	SAArticleStack* selectedStack = nil;
	
	for(SAArticleStack* stack in self.stacks) {
		SAArticleStackItem* stackItem = stack.selectedItem;
		SAArticle* article = stackItem.article;
		
		NSString* URL = article.articleURL.length > 0 ?
			[NSURL URLWithString:[article articleURL]] :
			nil;
		
		if([URL isEqual:articleURL]) {
			selectedStack = stack;
			break;
		}
	}
	
	// Now look for empty documents
	if(!selectedStack) {
		for(SAArticleStack* stack in self.stacks) {
			if(!stack.selectedItem) {
				selectedStack = stack;
				break;
			}
		}
	}
	
	if(!selectedStack && self.stacks.count == 9) {
		selectedStack = [[self stacks] lastObject];
	}
	
	// Create a new one
	if(!selectedStack) {
		selectedStack = [self addNewArticleStack];
	}
	
	self.selectedStack = selectedStack;
	
	SAArticle* article = [SAArticle articleForURL:articleURL inContext:[self managedObjectContext]];
	[self navigateToArticle:article];
	
	return selectedStack;
}

#pragma mark -
#pragma mark Private

- (void)dumpHierarchy {
	NSMutableString* path = [NSMutableString string];
	
	for(SAArticleStackItem* stackItem in self.selectedStackItems) {
		if(stackItem != self.selectedStackItems.firstObject) {
			[path appendString:@" > "];
		}
		
		NSString* URL = [[stackItem article] articleURL];
		[path appendString:[URL lastPathComponent]];
	}
	
	NSLog(@"%@", path);
}

@end
