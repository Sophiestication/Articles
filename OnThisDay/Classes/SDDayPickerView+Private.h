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

#import "SDDayPickerView.h"

@interface SDDayPickerView()

@property(nonatomic, strong) NSCalendar* calendar;
@property(nonatomic, strong) NSArray* dayViews;
@property(nonatomic, strong) UILabel* selectedDayView;
@property(nonatomic, strong) UIImageView* daySelectionView;
@property(nonatomic, strong) UILabel* todayView;
@property(nonatomic, strong) UIImageView* gridView;

- (void)initIvars;
- (void)initSubviews;

- (CGRect)rectForDay:(NSInteger)day inContentRect:(CGRect)contentRect;
- (CGRect)todayRectForContentRect:(CGRect)contentRect;

- (NSInteger)numberOfVisibleMonths;

- (void)updateSubviewsForTouches:(NSSet*)touches withEvent:(UIEvent*)event;
- (UILabel*)dayViewForTouches:(NSSet*)touches withEvent:(UIEvent*)event;

- (void)pickDate:(NSDate*)date;

@end
