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

#import "SFTableViewController.h"

@class AKArchive;
@class AKArticleView;
@class AKLanguagePicker;

typedef enum AKLanguagePickerMode {
	AKLanguagePickerModeDefault = 0,
	AKLanguagePickerModeTOC
} AKLanguagePickerMode;

@protocol AKLanguagePickerDelegate<NSObject>

@required
- (BOOL)languagePickerShouldDismiss:(AKLanguagePicker*)picker animated:(BOOL)animated;

@end

@interface AKLanguagePicker : SFTableViewController {
@private
	AKLanguagePickerMode _pickerMode;
	BOOL _allowsModeSelection;
	AKArchive* _archive;
	AKArticleView* _articleView;
	NSArray* _languages;
	NSString* _currentLanguageCode;
	CGFloat _languagesOffset;
	NSArray* _chapters;
	CGFloat _chaptersOffset;
	UIBarButtonItem* _doneButtonItem;
}

@property(nonatomic, weak) id<AKLanguagePickerDelegate> delegate;

@property(nonatomic) AKLanguagePickerMode pickerMode;
@property(nonatomic) BOOL allowsModeSelection;

@property(nonatomic, strong) AKArchive* archive;
@property(nonatomic, strong) AKArticleView* articleView;

+ (id)viewController;

- (IBAction)done:(id)sender;

@end
