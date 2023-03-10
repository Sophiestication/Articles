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

#import "ArticleViewController.h"

#import "BookmarkPickerController.h"

#import "SARSearchController.h"
#import "WikipediaPickerDelegate.h"

#import "ARKSearchTableViewController.h"

@interface ArticleViewController()<UIWebViewDelegate, AKArticleViewDelegate, SFDocumentPickerViewDelegate, SFDocumentSearchBarDelegate, SFToolbarCustomizationDelegate, SASearchControllerDelegate, WikipediaPickerDelegate, BookmarkPickerControllerDelegate, UIPopoverControllerDelegate, AKLanguagePickerDelegate, ARKSearchTableViewControllerDelegate>

@property(nonatomic, strong) SFBarButtonItem* backButtonItem;
@property(nonatomic, strong) SFBarButtonItem* forwardButtonItem;
@property(nonatomic, strong) SFBarButtonItem* addBookmarkButtonItem;
@property(nonatomic, strong) SFBarButtonItem* bookmarksButtonItem;
@property(nonatomic, strong) SFBarButtonItem* showTabsButtonItem;
@property(nonatomic, strong) SFBarButtonItem* localizationsButtonItem;
@property(nonatomic, strong) SFBarButtonItem* chaptersButtonItem;
@property(nonatomic, strong) SFBarButtonItem* documentSearchButtonItem;
@property(nonatomic, strong) UIBarButtonItem* addNewDocumentButtonItem;
@property(nonatomic, strong) UIBarButtonItem* documentPickerDoneButtonItem;

@property(nonatomic, strong) WikipediaAPI* wikipedia;

@property(nonatomic, strong) SARSearchController* searchController;
@property(nonatomic, strong) SFToolbarCustomizationController* toolbarCustomizationController;
@property(nonatomic, strong) SFDocumentPickerView* documentPicker;

@property(weak, nonatomic, readonly) NSArray* defaultToolbarItems;
@property(weak, nonatomic, readonly) NSArray* customizableToolbarItems;
@property(weak, nonatomic, readonly) NSArray* documentPickerToolbarItems;

@property(nonatomic, strong) SFDocumentSearchBar* documentSearchBar;
@property(nonatomic, strong) NSDictionary* openURLContext;

// iPad only
@property(nonatomic, strong) UIImageView* backgroundView;
@property(nonatomic, strong) UIView* backgroundPagesView;
@property(nonatomic, strong) UIImageView* backgroundPagesToolbarHeaderView;
@property(nonatomic, strong) UIImageView* backgroundPagesHeaderView;
@property(nonatomic, strong) UIImageView* backgroundPagesLeftBorderView;
@property(nonatomic, strong) UIImageView* backgroundPagesRightBorderView;
@property(nonatomic, strong) UIImageView* backgroundPagesFooterView;


@property(nonatomic, strong) UIActionSheet* actionSheet;
@property(nonatomic, strong) UIPopoverController* bookmarksPopoverController;
@property(nonatomic, strong) UIPopoverController* localizationsController;
@property(nonatomic, strong) UIPopoverController* chaptersPopoverController;
@property(nonatomic, strong) UIPopoverController* activitiesPopoverController;

@property(nonatomic, strong) UIBarButtonItem* searchbarButtonItem;

- (void)loadViewForiPad;
- (void)loadButtonItemsForiPad;
- (void)layoutForiPad;
- (void)layoutArticleView;
- (void)updateiPadForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void)updateiPadArticleViewEdgeInsets;
- (void)restoreiPadToolbarItemsIfNeeded;

- (UIBarButtonItem*)iPadButtonItemWithIdentifier:(NSString*)itemIdentifier borderType:(UIViewContentMode)borderType action:(SEL)action;
- (UIBarButtonItem*)iPadSeparatorButtonItem;

- (void)setPaperStyle:(UIButton*)button borderType:(UIViewContentMode)borderType;
- (void)setWoodenStyle:(UIButton*)button barStyle:(UIBarButtonItemStyle)barStyle;

- (void)dismissAllPopoverControllerExcept:(UIPopoverController*)popoverController animated:(BOOL)animated;

- (UIImage*)documentPreviewImage;

@end
