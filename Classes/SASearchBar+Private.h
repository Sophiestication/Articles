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

#import "SASearchBar.h"
#import "SAScopeBarSegmentedControl.h"

@interface SASearchBar()

@property(nonatomic, strong) UIImageView* backgroundView;
@property(nonatomic, strong) UILabel* promptLabel;
@property(nonatomic, strong) SASearchBarTextField* searchField;
@property(nonatomic, strong) SASearchBarTextField* progressSearchField;
@property(nonatomic, strong) CALayer* searchFieldMask;
@property(nonatomic, strong) UIButton* cancelButton;
@property(nonatomic, strong) UIImageView* scopeBarBackgroundView;
@property(nonatomic, strong) SAScopeBarSegmentedControl* scopeBar;
@property(nonatomic, strong) UIButton* calloutButton;
@property(nonatomic, strong) UIButton* accessoryView;
@property(nonatomic, readonly) BOOL compactLayout;
@property(nonatomic, copy) NSString* searchText;
@property(nonatomic) BOOL animatingLayout;
@property(nonatomic, strong) UIButton* pickerButton;
@property(nonatomic, readonly, strong) UIButton* searchButton;

- (void)initIvars;
- (void)initObservers;
- (void)initBackgroundView;
- (void)initPromptLabel;
- (void)initSearchField;
- (void)initAccessoryView;
- (void)initPickerButton;
- (void)initCancelButton;
- (void)initScopeBar;
- (void)initScopeBarBackgroundView;
- (void)initCalloutButton;

- (void)updateScopeBarIfNeeded;
- (void)updateScopeBar;
- (void)updateProgressSearchField;
- (void)updateAccessoryView;

- (void)cancelButtonTapped:(id)sender;

- (void)searchFieldTextDidChange:(NSNotification*)notification;

@end

@interface SASearchBarTextField : UITextField {
@private
	SASearchBar* _searchBar;
	UIButton* _clearButton2;
	UILabel* _placeholderLabel2;
	BOOL _progressShown;
	BOOL _searchButtonShown;
	BOOL _appearanceNeedsUpdate;
}

- (id)initWithSearchBar:(SASearchBar*)searchBar;

@property(nonatomic, strong) UIButton* clearButton2;
@property(nonatomic, strong) UILabel* placeholderLabel2;

@property(nonatomic, getter=isProgressShown) BOOL progressShown;
@property(nonatomic, getter=isSearchButtonShown) BOOL searchButtonShown;

- (void)updateAppearance;

@end

@interface SASearchBarCalloutButton : UIButton
@end
