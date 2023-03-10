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

#import "SFTableViewController.h"

#import "BookmarkDetailViewDelegate.h"
#import "BookmarkGroupDetailViewDelegate.h"

@class SABookmarkGroup;
@class BookmarkPickerController;

@protocol BookmarkPickerControllerDelegate<NSObject>
	
@required
- (void)bookmarkPickerShouldDismiss:(BookmarkPickerController*)bookmarkPicker animated:(BOOL)animated;

@end

@interface BookmarkPickerController : SFTableViewController<NSFetchedResultsControllerDelegate, BookmarkDetailViewDelegate, BookmarkGroupDetailViewDelegate> {
@private
	UIBarButtonItem* _doneButtonItem;
	UIBarButtonItem* _addBookmarkGroupButtonItem;
	NSFetchedResultsController* _bookmarkItemResultsController;
	NSFetchedResultsController* _readLaterCountController;
	SABookmarkGroup* _supergroup;
	NSManagedObjectContext* _managedObjectContext;
	BOOL _userDidReorderBookmarkItem;
	NSDictionary* _userDefaults;
}

@property(nonatomic, strong) IBOutlet UIBarButtonItem* doneButtonItem;
@property(nonatomic, strong) IBOutlet UIBarButtonItem* addBookmarkGroupButtonItem;

@property(nonatomic, strong) SABookmarkGroup* supergroup;
@property(nonatomic, strong) NSManagedObjectContext* managedObjectContext;

@property(nonatomic, weak) id<BookmarkPickerControllerDelegate> delegate;

- (id)initWithSupergroup:(SABookmarkGroup*)supergroup managedObjectContext:(NSManagedObjectContext*)managedObjectContext;

- (IBAction)done:(id)sender;
- (IBAction)addBookmarkGroup:(id)sender;

- (IBAction)showNearbyItems:(id)sender;
- (IBAction)showRandomArticle:(id)sender;

- (void)updateUserDefaults;
- (void)restoreFromUserDefaults;

@end
