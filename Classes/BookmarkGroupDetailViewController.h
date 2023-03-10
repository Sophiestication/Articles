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

#import <UIKit/UIKit.h>

#import "BookmarkGroupDetailViewDelegate.h"
#import "BookmarkGroupPickerDelegate.h"

@class SABookmarkGroup;

@interface BookmarkGroupDetailViewController : UITableViewController<BookmarkGroupPickerDelegate, UITextFieldDelegate> {
@private
	UIBarButtonItem* _cancelButtonItem;
	UIBarButtonItem* _saveButtonItem;
	
	SABookmarkGroup* _bookmarkGroup;
	SABookmarkGroup* _selectedBookmarkSupergroup;
	NSManagedObjectContext* _managedObjectContext;
	
	NSString* _bookmarkGroupTitle;
}

@property(nonatomic, strong) IBOutlet UIBarButtonItem* cancelButtonItem;
@property(nonatomic, strong) IBOutlet UIBarButtonItem* saveButtonItem;

@property(nonatomic, weak) id<BookmarkGroupDetailViewDelegate> delegate;

@property(nonatomic, strong) SABookmarkGroup* bookmarkGroup;
@property(nonatomic, strong) SABookmarkGroup* selectedBookmarkSupergroup;

@property(nonatomic, strong) NSManagedObjectContext* managedObjectContext;

@property(nonatomic, copy) NSString* bookmarkGroupTitle; // Considered Private

+ (id)viewController;

- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;

@end
