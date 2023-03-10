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

#import "SDCalendarTitleView.h"
#import "SDCalendarTitleView+Private.h"

#import "NSLocale+OnThisDay.h"
#import "UIColor+OnThisDay.h"
#import "UIFont+OnThisDay.h"

@implementation SDCalendarTitleView

@dynamic date;
@synthesize monthLabel = _monthLabel;
@synthesize dayLabel = _dayLabel;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
		[self initIvars];
		[self initMonthLabel];
		[self initDayLabel];
	}

    return self;
}

- (id)initWithCoder:(NSCoder*)coder {
    if(self = [super initWithCoder:coder]) {
		[self initIvars];
		[self initMonthLabel];
		[self initDayLabel];
	}

    return self;
}

#pragma mark -
#pragma mark SDCalendarTitleView

- (NSDate*)date {
	return _date;
}

- (void)setDate:(NSDate*)date {
	if(date != _date) {
		_date = [date copy];
		
		NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
		
		[formatter setLocale:[NSLocale preferredLocale]];
		
		// Update the month string
		[formatter setDateFormat:@"MMM"];
		NSString* monthString = [[formatter stringFromDate:date] uppercaseString];
		self.monthLabel.text = monthString;
		
		// Update the day string
		[formatter setDateFormat:@"dd"];
		NSString* dayString = [formatter stringFromDate:date];
		self.dayLabel.text = dayString;

		[self setNeedsLayout];
	}
}

#pragma mark -
#pragma mark UIView

- (void)layoutSubviews {
	[super layoutSubviews];

	CGRect bounds = self.bounds;
	
	CGSize monthLabelSize = [[self monthLabel]
		sizeThatFits:bounds.size];
	CGSize dayLabelSize = [[self dayLabel]
		sizeThatFits:bounds.size];
	
	CGFloat width = monthLabelSize.width + dayLabelSize.width + 5.0;
	CGFloat height = MAX(monthLabelSize.height, dayLabelSize.height);
	
	CGRect monthLabelRect = CGRectMake(
		ceilf(CGRectGetMidX(bounds) - width * 0.5) + 2.0,
		floorf(CGRectGetMidY(bounds) - height * 0.5) - 1.0,
		monthLabelSize.width,
		height);
	self.monthLabel.frame = monthLabelRect;
		
	CGRect dayLabelRect = CGRectMake(
		ceilf((CGRectGetMidX(bounds) + width * 0.5) - dayLabelSize.width) + 1.0,
		floorf(CGRectGetMidY(bounds) - height * 0.5) - 1.0,
		dayLabelSize.width,
		height);
	self.dayLabel.frame = dayLabelRect;
}

#pragma mark -
#pragma mark Private

- (void)initIvars {
	self.userInteractionEnabled = NO;

	self.opaque = NO;
	self.backgroundColor = [UIColor clearColor];
}

- (void)initMonthLabel {
	UILabel* monthLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	
	monthLabel.font = [UIFont boldCalendarHeaderFontOfSize:31.0];
	monthLabel.textAlignment = NSTextAlignmentRight;
	monthLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
	monthLabel.textColor = [UIColor calendarTextColor];
	monthLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
	monthLabel.shadowOffset = CGSizeMake(0.0, -1.0);
	monthLabel.backgroundColor = [UIColor clearColor];
	monthLabel.opaque = NO;
	
	[self addSubview:monthLabel];
	
	self.monthLabel = monthLabel;
}

- (void)initDayLabel {
	UILabel* dayLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	
	dayLabel.font = [UIFont calendarHeaderFontOfSize:31.0];
	dayLabel.textAlignment = NSTextAlignmentLeft;
	dayLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
	dayLabel.textColor = [UIColor calendarTextColor];
	dayLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
	dayLabel.shadowOffset = CGSizeMake(0.0, -1.0);
	dayLabel.backgroundColor = [UIColor clearColor];
	dayLabel.opaque = NO;
	
	[self addSubview:dayLabel];
	
	self.dayLabel = dayLabel;
}

@end
