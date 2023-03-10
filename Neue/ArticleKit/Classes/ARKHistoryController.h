//
//  ARKHistoryController.h
//  Articles
//
//  Created by Sophia Teutschler on 24.12.11.
//  Copyright (c) 2011 Sophiestication Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "ARKHistory.h"
#import "ARKHistoryItem.h"

@interface ARKHistoryController : NSObject

@property(nonatomic, readonly, strong) ARKHistory* history;

@property(nonatomic, readonly) NSUInteger numberOfHistoryItems;
@property(nonatomic, readonly, strong) ARKHistoryItem* selectedHistoryItem;

- (id)initWithIdentifier:(NSString*)identifier managedObjectContext:(NSManagedObjectContext*)managedObjectContext;

- (BOOL)canNavigateBack;
- (ARKHistoryItem*)navigateBack;

- (BOOL)canNavigateForward;
- (ARKHistoryItem*)navigateForward;

- (ARKHistoryItem*)navigateToItemAtIndex:(NSInteger)index;
- (ARKHistoryItem*)historyItemAtIndex:(NSInteger)index;

- (ARKHistoryItem*)navigateToURL:(NSURL*)URL;

@end