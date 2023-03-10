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

#import "ArticleKit.h"
#import "SFToolbar.h"
#import "SFDocumentPicker.h"

#import "WikipediaAPI.h"

#import "AKLanguagePicker.h"

#import "SAArticleStackController.h"
#import "SFToolbarCustomizationController.h"

#import "SFDocumentSearchBar.h"

@class SAArticleStack;
@class SAArticle;
@class SASearchBar;
@class SASearchDisplayController;

@interface ArticleViewController : UIViewController {
@private
	BOOL _shaking;
	BOOL _networkActivity;
	BOOL _keyboardVisible;
	BOOL _searchingDocument;
	BOOL _pickingDocument;
	BOOL _shouldRestoreContentOffset;
	BOOL _loadingDocument;
	BOOL _layoutSubviewsAnimated; // for debugging
	BOOL _launching;
	BOOL _searchBarPinned;
	BOOL _didNavigateBack;
	BOOL _animatingSubviewLayout;
	
	SFDocumentSearchBar* _documentSearchBar;
	CGRect _keyboardRect;
}

+ (id)viewController;

@property(nonatomic, strong) SASearchBar* searchBar;
@property(nonatomic, strong) AKArticleView* articleView;
@property(nonatomic, strong) SFToolbar* toolbar;

@property(nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property(nonatomic, strong) SAArticleStackController* articleStackController;

- (void)loadArticle:(NSURL*)articleURL;
- (void)loadArticle:(NSURL*)articleURL animated:(BOOL)animated;

- (void)openFromURL:(NSURL*)URL options:(NSDictionary*)options; // experimental

- (IBAction)back:(id)sender;
- (IBAction)forward:(id)sender;
- (IBAction)copyArticleURL:(id)sender;
- (IBAction)addBookmark:(id)sender;
- (IBAction)showBookmarks:(id)sender;
- (IBAction)showArticleStacks:(id)sender;
- (IBAction)reload:(id)sender;
- (IBAction)findInDocument:(id)sender;
- (IBAction)cancelFindInDocument:(id)sender;
- (IBAction)customizeToolbar:(id)sender;
- (IBAction)showLocalizationPicker:(id)sender;
- (IBAction)showChapterPicker:(id)sender;

@end
