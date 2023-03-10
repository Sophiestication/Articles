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

#import "SDCalendarNavigationButton.h"
#import "SDCalendarNavigationButton+Private.h"

#import "NSLocale+OnThisDay.h"
#import "UIColor+OnThisDay.h"
#import "UIFont+OnThisDay.h"

@implementation SDCalendarNavigationButton

@synthesize calendarButtonStyle = _calendarButtonStyle;
@synthesize detailTitleLabel = _detailTitleLabel;
@dynamic date;

#pragma mark -
#pragma mark Construction & Destruction

+ (id)calendarButtonWithStyle:(SDCalendarButtonStyle)calendarButtonStyle {
	SDCalendarNavigationButton* button = [self buttonWithType:UIButtonTypeCustom];
	
	button.calendarButtonStyle = calendarButtonStyle;
	
	NSString* backgroundImageName = nil;
	NSString* highlightedBackgroundImageName = nil;
	
	if(calendarButtonStyle == SDCalendarButtonStyleDayNavigateBack) {
		backgroundImageName = @"redBackButton.png";
		highlightedBackgroundImageName = @"redBackButtonHighlighted.png";
	} else if(calendarButtonStyle == SDCalendarButtonStyleDayNavigateForward) {
		backgroundImageName = @"redForwardButton.png";
		highlightedBackgroundImageName = @"redForwardButtonHighlighted.png";
	} else if(calendarButtonStyle == SDCalendarButtonStyleMonthNavigateBack) {
		backgroundImageName = @"greenBackButton.png";
		highlightedBackgroundImageName = @"greenBackButtonHighlighted.png";
	} else if(calendarButtonStyle == SDCalendarButtonStyleMonthNavigateForward) {
		backgroundImageName = @"greenForwardButton.png";
		highlightedBackgroundImageName = @"greenForwardButtonHighlighted.png";
	}
	
	button.titleLabel.textAlignment = NSTextAlignmentCenter;
	
	[button setTitleColor:[UIColor calendarTextColor] forState:UIControlStateNormal];
	
	if(calendarButtonStyle == SDCalendarButtonStyleDayNavigateBack ||
	   calendarButtonStyle == SDCalendarButtonStyleDayNavigateForward) {
		[[button titleLabel] setFont:[UIFont boldCalendarHeaderFontOfSize:12.5]];
		
		[button setTitleShadowColor:[[UIColor blackColor] colorWithAlphaComponent:0.75]
			forState:UIControlStateNormal];
		[[button titleLabel] setShadowOffset:CGSizeMake(0.0, -1.0)];
		
		// Setup the detail label
		UILabel* detailTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		
		detailTitleLabel.font = [UIFont calendarHeaderFontOfSize:11.5];
		detailTitleLabel.textColor = [UIColor calendarTextColor];
		detailTitleLabel.textAlignment = NSTextAlignmentCenter;
		detailTitleLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
		detailTitleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
		
		detailTitleLabel.backgroundColor = [UIColor clearColor];
		detailTitleLabel.opaque = NO;
		
		[button addSubview:detailTitleLabel];
		
		button.detailTitleLabel = detailTitleLabel;
	} else if(calendarButtonStyle == SDCalendarButtonStyleMonthNavigateBack ||
	   calendarButtonStyle == SDCalendarButtonStyleMonthNavigateForward) {
		[[button titleLabel] setFont:[UIFont boldCalendarHeaderFontOfSize:16]];
		button.titleLabel.textAlignment = NSTextAlignmentCenter;
	}
	
	if(calendarButtonStyle == SDCalendarButtonStyleDayNavigateBack ||
	   calendarButtonStyle == SDCalendarButtonStyleMonthNavigateBack) {
		button.titleEdgeInsets = UIEdgeInsetsMake(0.0, 15.0, 0.0, 7.0);
	} else {
		button.titleEdgeInsets = UIEdgeInsetsMake(0.0, 7.0, 0.0, 15.0);
	}
	
	if(calendarButtonStyle == SDCalendarButtonStyleMonthNavigateBack) {
		button.titleEdgeInsets = UIEdgeInsetsMake(1.0, 10.0, 0.0, 0.0);
	} else if(calendarButtonStyle == SDCalendarButtonStyleMonthNavigateForward) {
		button.titleEdgeInsets = UIEdgeInsetsMake(1.0, 5.0, 0.0, 10.0);
	}
	
	UIImage* backgroundImage = [[UIImage imageNamed:backgroundImageName]
		stretchableImageWithLeftCapWidth:14.0 topCapHeight:15.0];
	[button setBackgroundImage:backgroundImage forState:UIControlStateNormal];
	
	UIImage* highlightedBackgroundImage = [[UIImage imageNamed:highlightedBackgroundImageName]
		stretchableImageWithLeftCapWidth:14.0 topCapHeight:15.0];
	[button setBackgroundImage:highlightedBackgroundImage forState:UIControlStateHighlighted];
	
	return button;
}

- (void)dealloc {
	self.date = nil;
	self.detailTitleLabel = nil;
}

#pragma mark -
#pragma mark SDCalendarNavigationButton

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
		NSString* monthString = [[formatter stringFromDate:[self date]] uppercaseString];
		[self setTitle:monthString forState:UIControlStateNormal];
		
		// Update the day string
		[formatter setDateFormat:@"dd"];
		NSString* dayString = [formatter stringFromDate:[self date]];
		[[self detailTitleLabel] setText:dayString];
		
		[self setNeedsLayout];
	}
}

#pragma mark -
#pragma mark UIView

- (void)layoutSubviews {
	[super layoutSubviews];

	if(self.calendarButtonStyle == SDCalendarButtonStyleDayNavigateBack ||
	   self.calendarButtonStyle == SDCalendarButtonStyleDayNavigateForward) {
		CGRect titleRect = self.titleLabel.frame;
		CGSize detailTitleSize = [[self detailTitleLabel]
			sizeThatFits:titleRect.size];
		CGRect detailTitleRect = CGRectMake(
			CGRectGetMinX(titleRect), CGRectGetMaxY(titleRect) - 5.0,
			CGRectGetWidth(titleRect), detailTitleSize.height);
		self.detailTitleLabel.frame = detailTitleRect;
	}
}

#pragma mark -
#pragma mark UIButton

- (CGRect)titleRectForContentRect:(CGRect)contentRect {
	CGRect titleRect = [super titleRectForContentRect:contentRect];
	
	if(self.calendarButtonStyle == SDCalendarButtonStyleDayNavigateBack ||
	   self.calendarButtonStyle == SDCalendarButtonStyleDayNavigateForward) {
		UIEdgeInsets titleEdgeInsets = self.titleEdgeInsets;
	
		titleRect.origin.x = CGRectGetMinX(contentRect) + titleEdgeInsets.left;
		titleRect.size.width = CGRectGetWidth(contentRect) - (titleEdgeInsets.left + titleEdgeInsets.right);
	
		titleRect = CGRectOffset(titleRect, 0.0, -5.0);
	}
	
	return titleRect;
}

@end
