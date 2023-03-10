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
#import "SDDayPickerView+Private.h"

#import "UIFont+OnThisDay.h"

@implementation SDDayPickerView

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
		[self initIvars];
		[self initSubviews];
	}

    return self;
}

- (id)initWithCoder:(NSCoder*)coder {
    if(self = [super initWithCoder:coder]) {
		[self initIvars];
		[self initSubviews];
	}

    return self;
}

#pragma mark -
#pragma mark SDDayPickerView

- (NSInteger)month {
	return _month;
}

- (void)setMonth:(NSInteger)month {
	[self setMonth:month animated:NO];
}

- (void)setMonth:(NSInteger)month animated:(BOOL)animated {
	if(month != self.month) {
		if(animated) {
			CATransition* transition = [CATransition animation];
			
			transition.duration = 0.4;
			transition.type = kCATransitionPush;
			
			if((month > self.month || (month == 1 && self.month == 12)) && !(month == 12 && self.month == 1)) {
				transition.subtype = kCATransitionFromRight;
			} else {
				transition.subtype = kCATransitionFromLeft;
			}

			transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			
			[[self layer] addAnimation:transition forKey:@"pushMonthTransition"];
		}
		
		_month = month;
		[self setNeedsLayout];
		
		if(animated) {
			[self layoutIfNeeded];
		}
	}
}

#pragma mark -
#pragma mark UIResponder

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
	[self updateSubviewsForTouches:touches withEvent:event];
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
	[self updateSubviewsForTouches:touches withEvent:event];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
	[self updateSubviewsForTouches:touches withEvent:event];
	
	if(self.selectedDayView && !self.selectedDayView.hidden) {
		if(self.selectedDayView == (id)self.todayView) {
			NSDate* today = [NSDate date];
			NSCalendar* calendar = self.calendar;
		
			NSDateComponents* dateComponents = [calendar components:NSDayCalendarUnit|NSMonthCalendarUnit fromDate:today];
			
			[dateComponents setSecond:0];
			[dateComponents setMinute:0];
			[dateComponents setHour:0];
			
			[dateComponents setYear:2012]; // 2012 is a leap year
			
			today = [calendar dateFromComponents:dateComponents];
			
			[self pickDate:today];
		} else {
			NSInteger day = [[self dayViews] indexOfObject:[self selectedDayView]];
		
			if(day != NSNotFound) {
				NSCalendar* calendar = self.calendar;
				
				NSDateComponents* dateComponents = [[NSDateComponents alloc] init];
				
				[dateComponents setSecond:0];
				[dateComponents setMinute:0];
				[dateComponents setHour:0];
				
				[dateComponents setDay:day + 1];
				[dateComponents setMonth:[self month]];
				[dateComponents setYear:2012]; // 2012 is a leap year
				
				NSDate* newDate = [calendar dateFromComponents:dateComponents];
				[self pickDate:newDate];
			}
		}
	}
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
	self.selectedDayView.highlighted = NO;
	self.selectedDayView.backgroundColor = [UIColor clearColor];
}

#pragma mark -
#pragma mark UIView

- (void)layoutSubviews {
	[super layoutSubviews];

	if(!self.selectedDay) { return; }
	
	// Retrieve the selected month and day
	NSCalendar* calendar = self.calendar;
	NSDateComponents* dateComponents = [calendar components:NSDayCalendarUnit|NSMonthCalendarUnit fromDate:[self selectedDay]];

	NSInteger selectedMonth = dateComponents.month;
	NSInteger selectedDay = dateComponents.day;
	
	UIView* selectedDayView = nil;
	
	// Layout all day views
	CGSize gridImageSize = self.gridView.image.size;

	CGRect contentRect = CGRectMake(
		0.0, 0.0,
		gridImageSize.width, gridImageSize.height);

	NSInteger day = 1;
	NSInteger numberOfVisibleMonths = [self numberOfVisibleMonths];
	
	for(UIImageView* dayView in self.dayViews) {
		CGRect dayViewRect = [self rectForDay:day inContentRect:contentRect];
		dayViewRect = CGRectOffset(dayViewRect, 0.0, 1.0);
		dayView.frame = dayViewRect;
		
		dayView.hidden = day > numberOfVisibleMonths;
		
		if(day == selectedDay && selectedMonth == self.month) {
			selectedDayView = dayView;
		}
		
		++day;
	}
	
	// Layout the "Go to Today" view
	CGRect todayViewRect = [self todayRectForContentRect:contentRect];
	self.todayView.frame = todayViewRect;
	
	// Layout the selected day view
	if(selectedDayView) {
		CGRect selectedDayViewRect = selectedDayView.frame;
		
		CGSize daySelectionViewSize = [[self daySelectionView]
			sizeThatFits:selectedDayViewRect.size];
		CGRect daySelectionViewRect = CGRectMake(
			floorf(CGRectGetMidX(selectedDayViewRect) - daySelectionViewSize.width * 0.5),
			floorf(CGRectGetMidY(selectedDayViewRect) - daySelectionViewSize.height * 0.5),
			daySelectionViewSize.width,
			daySelectionViewSize.height);
		self.daySelectionView.frame = daySelectionViewRect;
			
		self.daySelectionView.hidden = NO;
	} else {
		self.daySelectionView.hidden = YES;
	}
	
	// Layout the grid view
	self.gridView.frame = contentRect;
}

#pragma mark -
#pragma mark Private

- (void)initIvars {
	self.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];

	self.backgroundColor = [UIColor clearColor];
	self.opaque = NO;
	
	self.clipsToBounds = NO;
}

- (void)initSubviews {
	// Init the day views
	NSMutableArray* dayViews = [NSMutableArray arrayWithCapacity:31];
	
	NSCalendar* calendar = self.calendar;
	
	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	
	[formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en"]];
	
	[formatter setDateFormat:@"d"];
	
	NSDateComponents* dateComponents = [[NSDateComponents alloc] init];
	
	for(NSInteger day=1; day<=31; ++day) {
		[dateComponents setDay:day];
		
		NSDate* date = [calendar dateFromComponents:dateComponents];
		NSString* dayString = [formatter stringFromDate:date];
		
		UILabel* dayLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		
		dayLabel.textColor = [UIColor colorWithRed:0.842 green:0.987 blue:0.629 alpha:1.000];
		dayLabel.highlightedTextColor = [UIColor whiteColor];
		
		dayLabel.font = [UIFont calendarHeaderFontOfSize:32.0];
		dayLabel.textAlignment = NSTextAlignmentCenter;
		
		dayLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
		dayLabel.shadowOffset = CGSizeMake(0.0, -1.0);
		
		dayLabel.backgroundColor = [UIColor clearColor];
		dayLabel.opaque = NO;
		
		dayLabel.alpha = 0.8;
		
		dayLabel.text = dayString;
		
		[self addSubview:dayLabel];
		[dayViews addObject:dayLabel];
	}
	
	self.dayViews = dayViews;
	
	// Init the Go to Today view
	UILabel* todayView = [[UILabel alloc] initWithFrame:CGRectZero];
	
	todayView.text = NSLocalizedString(@"GOTOTODAY_LABEL", @"");
		
	todayView.textColor = [UIColor colorWithRed:0.876 green:0.750 blue:0.351 alpha:1.000];
	todayView.highlightedTextColor = [UIColor whiteColor];
		
	todayView.font = [UIFont calendarHeaderFontOfSize:15.0];
	todayView.textAlignment = NSTextAlignmentCenter;
	
	todayView.numberOfLines = 2;
	// [todayView setLineSpacing:0.0];
		
	todayView.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
	todayView.shadowOffset = CGSizeMake(0.0, 1.0);
		
	todayView.backgroundColor = [[UIColor blackColor]
			colorWithAlphaComponent:0.5];
	todayView.opaque = NO;
		
	todayView.alpha = 0.8;
	
	[self addSubview:todayView];
	self.todayView = todayView;
	
	// Init the day selection view
	UIImageView* daySelectionView = [[UIImageView alloc] initWithImage:
		[UIImage imageNamed:@"daySelection.png"]];
	[self insertSubview:daySelectionView aboveSubview:todayView];
	self.daySelectionView = daySelectionView;
	
	// Init the grid view
	BOOL isLongPhone = CGRectGetHeight([[UIScreen mainScreen] bounds]) > 480.0;

	NSString* flipsideGridImageName = isLongPhone ?
		@"flipsideGrid-568h" :
		@"flipsideGrid";
	UIImageView* gridView = [[UIImageView alloc] initWithImage:
		[UIImage imageNamed:flipsideGridImageName]];

	gridView.contentMode = UIViewContentModeTopLeft;

	self.gridView = gridView;
	[self insertSubview:gridView belowSubview:daySelectionView];
}

- (CGRect)rectForDay:(NSInteger)day inContentRect:(CGRect)contentRect {
	// CGSize cellSize = CGSizeMake(70.0, 40.0);

	NSInteger const numberOfColumns = 4;
	NSInteger const numberOfRows = 8;

	CGSize gridImageSize = self.gridView.image.size;

	CGSize cellSize = CGSizeMake(
		ceil(gridImageSize.width / numberOfColumns),
		round(gridImageSize.height / numberOfRows));
	
	NSInteger dayIndex = day - 1;
	
	NSInteger row = floorf(dayIndex / (float)numberOfColumns);
	NSInteger column = dayIndex - row * numberOfColumns;
	
	CGRect rect = CGRectMake(
		CGRectGetMinX(contentRect) + (cellSize.width * column),
		CGRectGetMinY(contentRect) + (cellSize.height * row),
		cellSize.width,
		cellSize.height);
		
	// Cosmetic tweaks
	rect.origin.x += 1.0;

	if(column >= 3) {
		rect.size.width -= 2.0;
	}
			
	return rect;
}

- (CGRect)todayRectForContentRect:(CGRect)contentRect {
	return CGRectOffset([self rectForDay:32 inContentRect:contentRect], 0.0, 1.0);
}

- (NSInteger)numberOfVisibleMonths {
	NSCalendar* gregorian = self.calendar;

	NSDateComponents* dateComponents = [[NSDateComponents alloc] init];
	
	[dateComponents setMonth:[self month]];
	[dateComponents setYear:2012]; // 2012 is a leap year
	
	NSDate* date = [gregorian dateFromComponents:dateComponents];
	NSRange range = [gregorian
		rangeOfUnit:NSDayCalendarUnit
		inUnit:NSMonthCalendarUnit
		forDate:date];

	return range.length;
}

- (void)updateSubviewsForTouches:(NSSet*)touches withEvent:(UIEvent*)event {
	UILabel* selectedLabel = [self dayViewForTouches:touches withEvent:event];
	
	if(selectedLabel != self.selectedDayView) {
		self.selectedDayView.highlighted = NO;
	
		if(self.selectedDayView != self.todayView) {
			self.selectedDayView.backgroundColor = [UIColor clearColor];
		}

		selectedLabel.highlighted = YES;
		selectedLabel.backgroundColor = [[UIColor blackColor]
			colorWithAlphaComponent:0.5];
		
		self.selectedDayView = selectedLabel;
	}
}

- (UILabel*)dayViewForTouches:(NSSet*)touches withEvent:(UIEvent*)event {
	CGPoint pointInTodayView = [[touches anyObject]
		locationInView:[self todayView]];
		
	if([[self todayView] pointInside:pointInTodayView withEvent:nil]) {
		return self.todayView;
	}
	
	for(UILabel* dayView in self.dayViews) {
		CGPoint point = [[touches anyObject] locationInView:dayView];
		
		if([dayView pointInside:point withEvent:nil]) {
			return dayView.hidden ?
				nil :
				dayView;
		}
	}
	
	return nil;
}

- (void)pickDate:(NSDate*)date {
	if([[self delegate] respondsToSelector:@selector(dayPickerView:didFinishPickingDay:)]) {
		[[self delegate] dayPickerView:self didFinishPickingDay:date];
	}
	
	self.selectedDayView = nil;
}

@end
