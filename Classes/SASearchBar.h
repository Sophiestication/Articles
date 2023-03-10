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

@class SAScopeBarSegmentedControl;
@class SASearchBarTextField;

typedef enum {
    SASearchBarAccessoryTypeNone,
    SASearchBarAccessoryTypeReload,
    SASearchBarAccessoryTypeStop
} SASearchBarAccessoryType;

@interface SASearchBar : UIView<UITextFieldDelegate> {
@private
	UIImageView* _backgroundView;
	UILabel* _promptLabel;
	SASearchBarTextField* _searchField;
	SASearchBarTextField* _progressSearchField;
	CALayer* _searchFieldMask;
	UIButton* _cancelButton;
	UIImageView* _scopeBarBackgroundView;
	SAScopeBarSegmentedControl* _scopeBar;
	UIButton* _calloutButton;
	BOOL _active;
	NSString* _searchText;
	UIViewAnimationCurve _preferredAnimationCurve;
	NSTimeInterval _preferredAnimationDuration;
	SASearchBarAccessoryType _accessoryType;
	UIButton* _accessoryView;
	float _progress;
	BOOL _animatingLayout;
	UIButton* _pickerButton;
	BOOL _pickerButtonShown;
	BOOL _searchButtonShown;
}

@property(nonatomic, copy) NSString* text;
@property(nonatomic, copy) NSString* placeholder;

@property(nonatomic, copy) NSString* prompt;
- (void)setPrompt:(NSString*)prompt animated:(BOOL)animated;

@property(nonatomic, getter=isActive) BOOL active;
- (void)setActive:(BOOL)active animated:(BOOL)animated;

@property(nonatomic) SASearchBarAccessoryType accessoryType;
- (void)setAccessoryType:(SASearchBarAccessoryType)accessoryType animated:(BOOL)animated;

@property(nonatomic, getter=isPickerButtonShown) BOOL pickerButtonShown;
@property(nonatomic, getter=isSearchButtonShown) BOOL searchButtonShown;

@property(nonatomic) float progress;

@property(nonatomic, copy) NSArray* scopeButtonTitles;
@property(nonatomic) NSInteger selectedScopeButtonIndex;
@property(nonatomic, copy) NSString* scopeCalloutButtonTitle;

@end
