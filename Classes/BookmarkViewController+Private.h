//
//  BookmarkPickerController+Private.h
//  Articles
//
//  Created by Sophia Teutschler on 22.06.09.
//  Copyright 2009 Sophiestication. All rights reserved.
//

#import "BookmarkPickerController.h"

@interface BookmarkPickerController()

@property(nonatomic, retain) NSFetchedResultsController* bookmarkGroupResultsController;
@property(nonatomic, retain) NSFetchedResultsController* bookmarkResultsController;

@property(nonatomic, readonly) NSUInteger nearbySectionIndex;
@property(nonatomic, readonly) NSUInteger recentItemsSectionIndex;
@property(nonatomic, readonly) NSUInteger bookmarkGroupsSectionIndex;
@property(nonatomic, readonly) NSUInteger bookmarksSectionIndex;

@property(nonatomic, readonly) NSArray* defaultToolbarItems;
@property(nonatomic, readonly) NSArray* editingToolbarItems;

- (void)initBookmarkGroupResultsController;
- (void)initBookmarkResultsController;

@end