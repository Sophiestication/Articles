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

@interface BookmarkPickerController()

@property(nonatomic, strong) NSFetchedResultsController* bookmarkItemResultsController;
@property(nonatomic, strong) NSFetchedResultsController* readLaterCountController;

@property(nonatomic, readonly) NSUInteger nearbySectionIndex;
@property(nonatomic, readonly) NSUInteger recentItemsSectionIndex;
@property(nonatomic, readonly) NSUInteger featuredItemSectionIndex;
@property(nonatomic, readonly) NSUInteger randomItemSectionIndex;
@property(nonatomic, readonly) NSUInteger readLaterItemSectionIndex;
@property(nonatomic, readonly) NSUInteger languagesItemSectionIndex;
@property(nonatomic, readonly) NSUInteger tableOfContentsItemSectionIndex;
@property(nonatomic, readonly) NSUInteger bookmarkItemsSectionIndex;

@property(weak, nonatomic, readonly) NSArray* defaultToolbarItems;
@property(weak, nonatomic, readonly) NSArray* editingToolbarItems;

@property(weak, nonatomic, readonly) id currrentArticle;

- (void)initBookmarkItemResultsController;
- (void)initReadLaterCountControllerIfNeeded;

- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath;

- (void)updateContentViewAnimated:(BOOL)animated;

@property(nonatomic, strong) NSDictionary* userDefaults;
- (void)restoreFromUserDefaults:(NSDictionary*)userDefaults inSelection:(NSArray*)selection;

@end
