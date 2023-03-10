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

#import "SDDayPickerViewController.h"

@interface SDDayPickerViewController()<SDDayPickerViewDelegate>

@property(nonatomic, strong) UIImageView* backgroundView;
@property(nonatomic, strong) UIImageView* leftOverlayView;
@property(nonatomic, strong) UIImageView* rightOverlayView;

@property(nonatomic, strong) SDCalendarNavigationButton* backButton;
@property(nonatomic, strong) SDCalendarNavigationButton* forwardButton;
@property(nonatomic, strong) UILabel* titleLabel;

@property(nonatomic, strong) SDDayPickerView* dayPickerView;

@property(nonatomic, strong) UIButton* doneButton;

@property(nonatomic, copy) NSDate* selectedDay;
- (void)selectMonth:(NSDate*)selectedDay animated:(BOOL)animated;

@property(nonatomic) BOOL shaking;

@end
