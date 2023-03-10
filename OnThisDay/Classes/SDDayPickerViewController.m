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
#import "SDDayPickerViewController+Private.h"

#import "SDCalendarNavigationButton.h"
#import "SDDayPickerView.h"

#import "SDCalendarViewController.h"

#import "UIFont+OnThisDay.h"
#import "UIColor+OnThisDay.h"
#import "NSLocale+OnThisDay.h"

@implementation SDDayPickerViewController

@synthesize backButton = _backButton;
@synthesize forwardButton = _forwardButton;
@synthesize titleLabel = _titleLabel;
@synthesize dayPickerView = _dayPickerView;
@synthesize doneButton = _doneButton;
@synthesize selectedDay = _selectedDay;

#pragma mark - Construction & Destruction

+ (id)viewController {
	return [[self alloc] initWithNibName:nil bundle:nil];
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
	if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	}
	
	return self;
}

#pragma mark - SDDayPickerViewController

- (void)back:(id)sender {
	// Determine the previous date
	NSCalendar* gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	
	NSDateComponents* dayBackComponent = [[NSDateComponents alloc] init];
	
	[dayBackComponent setMonth:-1];
	
	NSDate* newDate = [gregorian dateByAddingComponents:dayBackComponent
		toDate:[self selectedDay]
		options:0];
	
	// First update the instance variable
	self.selectedDay = newDate;
	
	// Now transition to the new state
	[self selectMonth:newDate animated:YES];
}

- (void)forward:(id)sender {
	// Determine the previous date
	NSCalendar* gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	
	NSDateComponents* dayBackComponent = [[NSDateComponents alloc] init];
	
	[dayBackComponent setMonth:1];
	
	NSDate* newDate = [gregorian dateByAddingComponents:dayBackComponent
		toDate:[self selectedDay]
		options:0];
	
	// First update the instance variable
	self.selectedDay = newDate;
	
	// Now transition to the new state
	[self selectMonth:newDate animated:YES];
}

- (void)showCalendar:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIResponder

- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent*)event {
	if(motion == UIEventSubtypeMotionShake) {
		_shaking = YES;
	}
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent*)event {
	if(motion == UIEventSubtypeMotionShake) {
		_shaking = NO;
	}
}

- (void)motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent*)event {
	if(motion == UIEventSubtypeMotionShake) {
		_shaking = NO;
	}
}

#pragma mark - UIViewController

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return !_shaking && UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)viewDidLoad {
	[super viewDidLoad];

	// Init the background view
	BOOL isLongPhone = CGRectGetHeight([[UIScreen mainScreen] bounds]) > 480.0;

	NSString* backgroundImageName = isLongPhone ?
		@"flipside-568h" :
		@"flipside";
	UIImageView* backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:backgroundImageName]];
	self.backgroundView = backgroundView;
	[[self view] addSubview:backgroundView];

	// Init the day picker view
	SDDayPickerView* dayPickerView = [[SDDayPickerView alloc] initWithFrame:CGRectZero];
	dayPickerView.delegate = self;

	self.dayPickerView = dayPickerView;
	[[self view] insertSubview:dayPickerView aboveSubview:backgroundView];

	dayPickerView.selectedDay = self.selectedDay;

	// Init the overlay views
	NSString* leftOverlayImageName = isLongPhone ?
		@"flipsideOverlayLeft-568h" :
		@"flipsideOverlayLeft";
	UIImageView* leftOverlayView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:leftOverlayImageName]];
	self.leftOverlayView = leftOverlayView;
	[[self view] insertSubview:leftOverlayView aboveSubview:dayPickerView];

	NSString* rightOverlayImageName = isLongPhone ?
		@"flipsideOverlayRight-568h" :
		@"flipsideOverlayRight";
	UIImageView* rightOverlayView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:rightOverlayImageName]];
	self.rightOverlayView = rightOverlayView;
	[[self view] insertSubview:rightOverlayView aboveSubview:dayPickerView];

	// Init the navigation bar buttons
	SDCalendarNavigationButton* backButton = [SDCalendarNavigationButton calendarButtonWithStyle:SDCalendarButtonStyleMonthNavigateBack];

	backButton.frame = [[self backButton] frame];
	backButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin;
	
	[backButton addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];

	self.backButton = backButton;
	[[self view] insertSubview:backButton aboveSubview:leftOverlayView];
	
	SDCalendarNavigationButton* forwardButton = [SDCalendarNavigationButton calendarButtonWithStyle:SDCalendarButtonStyleMonthNavigateForward];
	
	forwardButton.frame = [[self forwardButton] frame];
	forwardButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin;
	
	[forwardButton addTarget:self action:@selector(forward:) forControlEvents:UIControlEventTouchUpInside];

	self.forwardButton = forwardButton;
	[[self view] insertSubview:forwardButton aboveSubview:rightOverlayView];

	// Title label
	UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];

	titleLabel.textAlignment = NSTextAlignmentCenter;

	titleLabel.font = [UIFont boldCalendarHeaderFontOfSize:30.0];
	titleLabel.textColor = [UIColor colorWithRed:1.000 green:0.970 blue:0.870 alpha:1.000];

	titleLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
	titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);

	titleLabel.backgroundColor = [UIColor clearColor];

	self.titleLabel = titleLabel;
	[[self view] insertSubview:titleLabel aboveSubview:backgroundView];
	
	// Done button
	UIButton* doneButton = [UIButton buttonWithType:UIButtonTypeCustom];

	doneButton.titleLabel.font = [UIFont calendarHeaderFontOfSize:26.0];
	doneButton.titleLabel.textAlignment = NSTextAlignmentCenter;

	[doneButton setTitleColor:[UIColor colorWithRed:0.309 green:0.426 blue:0.185 alpha:1.000] forState:UIControlStateNormal];
	[doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];

	[doneButton setBackgroundImage:[UIImage imageNamed:@"flipsideDoneButton"] forState:UIControlStateNormal];
	[doneButton setBackgroundImage:[UIImage imageNamed:@"flipsideDoneButtonHighlighted"] forState:UIControlStateHighlighted];

	[doneButton
		setTitle:NSLocalizedString(@"DONE_LABEL", @"")
		forState:UIControlStateNormal];

	[doneButton addTarget:self action:@selector(showCalendar:) forControlEvents:UIControlEventTouchUpInside];

	self.doneButton = doneButton;
	[[self view] insertSubview:doneButton aboveSubview:backgroundView];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	// Show the current selection
	[self selectMonth:[self selectedDay] animated:NO];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];

	CGRect contentRect = self.view.bounds;

	CGRect rightOverlayViewRect = self.rightOverlayView.frame;
	rightOverlayViewRect.origin.x = CGRectGetMaxX(contentRect) - CGRectGetWidth(rightOverlayViewRect);
	self.rightOverlayView.frame = rightOverlayViewRect;

	self.backButton.frame = CGRectMake(
		16.0, 25.0,
		61.0, 30.0);
	self.forwardButton.frame = CGRectMake(
		243.0, 25.0,
		61.0, 30.0);

	self.titleLabel.frame = CGRectMake(
		85.0, 23.0,
		150.0, 35.0);

	self.doneButton.frame = CGRectMake(
		20.0, CGRectGetMaxY(contentRect) - 60.0,
		280.0, 41.0);

	self.dayPickerView.frame = CGRectMake(
		20.0, 66.0,
		280.0, CGRectGetMinY([[self doneButton] frame]) - 66.0 - 14.0);
}

#pragma mark - SDDayPickerViewDelegate

- (void)dayPickerView:(SDDayPickerView*)dayPickerView didFinishPickingDay:(NSDate*)day {
	[self showCalendar:dayPickerView];
	
	SDCalendarViewController* calendarViewController = (id)self.parentViewController;
	
	if(!calendarViewController && [self respondsToSelector:@selector(presentingViewController)]) {
		calendarViewController = (id)self.presentingViewController;
	}
	
	[calendarViewController
		performSelector:@selector(showDay:)
		withObject:day
		afterDelay:0.75];
}

#pragma mark - Private

- (void)selectMonth:(NSDate*)date animated:(BOOL)animated {
	NSCalendar* gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	
	// Update the previous date
	NSDateComponents* dayBackComponent = [[NSDateComponents alloc] init];
	
	[dayBackComponent setMonth:-1];
	
	NSDate* previousDate = [gregorian dateByAddingComponents:dayBackComponent
		toDate:date
		options:0];
	
	// Update the next date
	NSDateComponents* dayForwardComponent = [[NSDateComponents alloc] init];
	
	[dayForwardComponent setMonth:1];
	
	NSDate* nextDate = [gregorian dateByAddingComponents:dayForwardComponent
		toDate:date
		options:0];
	
	// Update the back/forward buttons
	[[self backButton] setDate:previousDate];
	[[self forwardButton] setDate:nextDate];
	
	//Update the month title
	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	
	[formatter setLocale:[NSLocale preferredLocale]];
	[formatter setDateFormat:@"MMM"];
	
	NSString* monthString = [[formatter stringFromDate:date] uppercaseString];
	self.titleLabel.text = monthString;
	
	// Now update our day picker
	NSDateComponents* dateComponents = [gregorian components:NSMonthCalendarUnit fromDate:date];
	
	[[self dayPickerView] setMonth:[dateComponents month] animated:animated];
}

@end
