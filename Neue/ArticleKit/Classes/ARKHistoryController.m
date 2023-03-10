//
//  ARKHistoryController.m
//  Articles
//
//  Created by Sophia Teutschler on 24.12.11.
//  Copyright (c) 2011 Sophiestication Software. All rights reserved.
//

#import "ARKHistoryController.h"

#import "ARKHistory+Additions.h"
#import "NSArray+Additions.h"

@interface ARKHistoryController()

@property(nonatomic, readwrite, strong) ARKHistory* history;
@property(nonatomic, readwrite, strong) ARKHistoryItem* selectedHistoryItem;

@property(nonatomic) NSUInteger numberOfHistoryItems;

- (void)navigateToItem:(ARKHistoryItem*)item;

@end

@implementation ARKHistoryController

#pragma mark - Construction & Destruction

- (id)initWithIdentifier:(NSString*)identifier managedObjectContext:(NSManagedObjectContext*)managedObjectContext {
	if((self = [super init])) {
		[self initHistoryForIdentifier:identifier managedObjectContext:managedObjectContext];
	}
	
	return self;
}

#pragma mark - ARKHistoryController

- (BOOL)canNavigateBack {
	NSInteger selectedItemIndex = [[[self history] selectedItemIndex] integerValue];
	return selectedItemIndex > 0;
}

- (ARKHistoryItem*)navigateBack {
	NSInteger selectedItemIndex = [[[self history] selectedItemIndex] integerValue];
	NSInteger newSelectedItemIndex = selectedItemIndex - 1;

	ARKHistoryItem* newSelectedItem = [self fetchHistoryItemAtIndex:newSelectedItemIndex];
	[self navigateToItem:newSelectedItem];

	return newSelectedItem;
}

- (BOOL)canNavigateForward {
	NSInteger selectedItemIndex = [[[self history] selectedItemIndex] integerValue];
	return selectedItemIndex + 1 < self.numberOfHistoryItems;
}

- (ARKHistoryItem*)navigateForward {
	NSInteger selectedItemIndex = [[[self history] selectedItemIndex] integerValue];
	NSInteger newSelectedItemIndex = selectedItemIndex + 1;

	ARKHistoryItem* newSelectedItem = [self fetchHistoryItemAtIndex:newSelectedItemIndex];
	[self navigateToItem:newSelectedItem];

	return newSelectedItem;
}

- (ARKHistoryItem*)navigateToItemAtIndex:(NSInteger)index {
	ARKHistoryItem* selectedHistoryItem = self.selectedHistoryItem;

	if(selectedHistoryItem && [[selectedHistoryItem index] integerValue] == index) {
		return selectedHistoryItem;
	}
	
	ARKHistoryItem* newSelectedItem = [self fetchHistoryItemAtIndex:index];

	[self navigateToItem:newSelectedItem];

	return newSelectedItem;
}

- (ARKHistoryItem*)historyItemAtIndex:(NSInteger)index {
	NSInteger selectedItemIndex = [[[self selectedHistoryItem] index] integerValue];
	if(selectedItemIndex == index) { return self.selectedHistoryItem; }

	ARKHistoryItem* historyItem = [self fetchHistoryItemAtIndex:index];
	return historyItem;
}

- (ARKHistoryItem*)navigateToURL:(NSURL*)URL {
	NSString* URLString = [URL absoluteString];
	ARKHistoryItem* selectedHistoryItem = self.selectedHistoryItem;

	if([[selectedHistoryItem identifier] isEqualToString:URLString]) { return selectedHistoryItem; }

	ARKHistory* history = self.history;

	NSInteger newSelectedIndex = history.selectedItemIndex ?
		[[history selectedItemIndex] integerValue] + 1 :
		0;

	__block NSUInteger numberOfItems = self.numberOfHistoryItems;
	__block ARKHistoryItem* newItem;

	NSManagedObjectContext* managedObjectContext = history.managedObjectContext;

	[managedObjectContext performBlockAndWait:^{
		if(newSelectedIndex < numberOfItems) {
			NSRange range = NSMakeRange(newSelectedIndex, numberOfItems - newSelectedIndex);
			[self deleteItemsOfHistory:history inRange:range managedObjectContext:managedObjectContext];
		}

		numberOfItems = newSelectedIndex + 1;

		newItem = [NSEntityDescription
			insertNewObjectForEntityForName:@"HistoryItem"
			inManagedObjectContext:managedObjectContext];

		newItem.identifier = URLString;
		newItem.lastVisitDate = newItem.creationDate = [NSDate date];

		newItem.index = @(newSelectedIndex);

		[history addHistoryItemsObject:newItem];
		history.selectedItemIndex = @(newSelectedIndex);
	}];

	self.numberOfHistoryItems = numberOfItems;
	self.selectedHistoryItem = newItem;

	[self saveAllChanges];

	return newItem;
}

- (void)navigateToItem:(ARKHistoryItem*)item {
	if(!item) { return; }
	
	// update the selection in our model
	self.history.selectedItemIndex = item.index;
	self.selectedHistoryItem = item;
		
	// update the article last used date
	item.lastVisitDate = [NSDate date];

	[self saveAllChanges];
}

#pragma mark - Private

- (void)initHistoryForIdentifier:(NSString*)identifier managedObjectContext:(NSManagedObjectContext*)managedObjectContext {
	__block ARKHistory* history;
	__block NSUInteger numberOfHistoryItems;

	[managedObjectContext performBlockAndWait:^{
		NSString* const historyEntityName = @"History";
		NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:historyEntityName];

		NSPredicate* predicate = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
		[fetchRequest setPredicate:predicate];

		[fetchRequest setFetchLimit:1];

		history = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] firstObject];

		if(!history) {
			history = [NSEntityDescription insertNewObjectForEntityForName:historyEntityName inManagedObjectContext:managedObjectContext];
			history.identifier = identifier;
		}

		// items
		fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"HistoryItem"];
		
		predicate = [NSPredicate predicateWithFormat:@"history == %@", history];
		[fetchRequest setPredicate:predicate];

		numberOfHistoryItems = [managedObjectContext countForFetchRequest:fetchRequest error:nil];
	}];

	self.history = history;
	self.numberOfHistoryItems = numberOfHistoryItems;

	if(history.selectedItemIndex) {
		self.selectedHistoryItem = [self fetchHistoryItemAtIndex:[[history selectedItemIndex] integerValue]];
	}
}

- (ARKHistoryItem*)fetchHistoryItemAtIndex:(NSInteger)index {
	ARKHistory* history = self.history;
	__block ARKHistoryItem* historyItem;

	NSManagedObjectContext* managedObjectContext = history.managedObjectContext;

	[managedObjectContext performBlockAndWait:^{
		NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"HistoryItem"];
		
		NSPredicate* predicate = [NSPredicate predicateWithFormat:@"history == %@ && index == %ld", history, index];
		[fetchRequest setPredicate:predicate];

		fetchRequest.fetchLimit = 1;

		[fetchRequest setReturnsObjectsAsFaults:NO];

		historyItem = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] firstObject];
	}];

	return historyItem;
}

- (void)deleteItemsOfHistory:(ARKHistory*)history inRange:(NSRange)range managedObjectContext:(NSManagedObjectContext*)managedObjectContext {
	NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"HistoryItem"];
		
	NSPredicate* predicate = [NSPredicate predicateWithFormat:@"history == %@ && (index >= %ld && index <= %ld)",
		history,
		range.location,
		NSMaxRange(range)];
	[fetchRequest setPredicate:predicate];

	[fetchRequest setIncludesPropertyValues:NO];
	[fetchRequest setReturnsObjectsAsFaults:YES];

	NSArray* items = [managedObjectContext executeFetchRequest:fetchRequest error:nil];

	for(NSManagedObject* item in items) {
		[managedObjectContext deleteObject:item];
	}
}

- (void)saveAllChanges {
	NSManagedObjectContext* managedObjectContext = self.history.managedObjectContext;

	[managedObjectContext performBlock:^() {
		NSError* error;

		if(![managedObjectContext save:&error]) {
			NSLog(@"Could not save navigation history: %@", error);
		}
	}];
}

@end