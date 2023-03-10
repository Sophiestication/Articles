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

#import "SFGraphics.h"
#import "SFDocumentSearchBarDelegate.h"

@class SFSegmentedControl;
@class SFDocumentSearchField;
@class SFBadgeAccessoryView;

typedef enum {
    SFDocumentSearchBarModeDefault,
    SFDocumentSearchBarModeNavigation
} SFDocumentSearchBarMode;

enum {
	SFDocumentSearchBarPrevNavigationItemIndex = 0,
	SFDocumentSearchBarNextNavigationItemIndex = 1
};

@interface SFDocumentSearchBar : UIView<UITextFieldDelegate> {
@private
	SFControlSize _controlSize;
	SFDocumentSearchBarMode _barMode;
}

@property(nonatomic, weak) id<SFDocumentSearchBarDelegate> delegate;

@property(nonatomic, strong) NSString* text;
@property(nonatomic, strong) NSString* placeholder;

@property(nonatomic) SFDocumentSearchBarMode barMode;
- (void)setBarMode:(SFDocumentSearchBarMode)barMode animated:(BOOL)animated;

@property(nonatomic) SFControlSize controlSize;

- (void)setCurrentResultIndex:(NSInteger)resultIndex numberOfResults:(NSInteger)numberOfResults;

@end
