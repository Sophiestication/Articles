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

#import "SASearchDisplayPopoverContentViewController.h"

@interface SASearchDisplayPopoverContentViewController()

@property(nonatomic, readwrite, strong) UISegmentedControl* scopeBar;
@property(nonatomic, readwrite, strong) UIButton* calloutButton;

@end

@implementation SASearchDisplayPopoverContentViewController

#pragma mark - SASearchDisplayPopoverContentViewController

- (void)setSelectedScopeBarItemIndex:(NSUInteger)selectedScopeBarItemIndex {
	if(self.selectedScopeBarItemIndex == selectedScopeBarItemIndex) { return; }

	_selectedScopeBarItemIndex = selectedScopeBarItemIndex;
	self.scopeBar.selectedSegmentIndex = selectedScopeBarItemIndex;
}

- (void)setCalloutButtonTitle:(NSString*)calloutButtonTitle {
	if([[self calloutButtonTitle] isEqualToString:calloutButtonTitle]) { return; }

	_calloutButtonTitle = [calloutButtonTitle copy];

	UIButton* calloutButton = self.calloutButton;
	[calloutButton setTitle:calloutButtonTitle forState:UIControlStateNormal];

	[calloutButton sizeToFit];
}

#pragma mark - UIViewController

- (void)loadView {
	[super loadView];

	UIBarButtonItem* backButtonItem = [[UIBarButtonItem alloc]
		initWithImage:[UIImage imageNamed:@"backBarButtonItem"]
		style:UIBarButtonItemStyleBordered
		target:nil
		action:NULL];
	self.navigationItem.backBarButtonItem = backButtonItem;

	NSArray* scopeBarItems = @[
		NSLocalizedString(@"SEARCHSCOPE_TITLE", @""),
		NSLocalizedString(@"SEARCHSCOPE_CONTENT", @"") ];
	UISegmentedControl* scopeBar = [[UISegmentedControl alloc] initWithItems:scopeBarItems];
	
	scopeBar.segmentedControlStyle = UISegmentedControlStyleBar;

	[scopeBar setWidth:106.0 forSegmentAtIndex:0];
	[scopeBar setWidth:106.0 forSegmentAtIndex:1];

	scopeBar.selectedSegmentIndex = self.selectedScopeBarItemIndex;
	
	[scopeBar sizeToFit];
	
	CGRect scopeBarRect = scopeBar.bounds;
	scopeBarRect.size.width = 320.0;
	scopeBar.bounds = scopeBarRect;

	self.scopeBar = scopeBar;
	
	self.navigationItem.titleView = scopeBar;
	
	SAPopoverCalloutButton* calloutButton = [[SAPopoverCalloutButton alloc] initWithFrame:CGRectZero];
	[calloutButton setTitle:[self calloutButtonTitle] forState:UIControlStateNormal];
	self.calloutButton = calloutButton;
	
	UIBarButtonItem* calloutButtonItem = [[UIBarButtonItem alloc] initWithCustomView:calloutButton];
	self.navigationItem.rightBarButtonItem = calloutButtonItem;
}

@end

#pragma mark - SAPopoverCalloutButton

@implementation SAPopoverCalloutButton

- (id)initWithFrame:(CGRect)frame {
	if(self = [super initWithFrame:frame]) {
		UIImage* backgroundImage = [[UIImage imageNamed:@"popoverButtonBackground"]
			stretchableImageWithLeftCapWidth:6.0 topCapHeight:0.0];
		[self setBackgroundImage:backgroundImage forState:UIControlStateNormal];

		UIImage* highlightedBackgroundImage = [[UIImage imageNamed:@"popoverButtonBackgroundHighlighted"]
			stretchableImageWithLeftCapWidth:6.0 topCapHeight:0.0];
		[self setBackgroundImage:highlightedBackgroundImage forState:UIControlStateHighlighted];
		
		[self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[self setTitleShadowColor:[[UIColor blackColor] colorWithAlphaComponent:0.5] forState:UIControlStateNormal];
		
		[self setImage:[UIImage imageNamed:@"popoverButtonDisclosureIndicator"] forState:UIControlStateNormal];
		
		self.titleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
		self.reversesTitleShadowWhenHighlighted = NO;
		self.adjustsImageWhenHighlighted = NO;
		self.showsTouchWhenHighlighted = NO;
		
		self.titleLabel.font = [UIFont boldSystemFontOfSize:13.0];
		self.contentEdgeInsets = UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0);
	
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
	}

	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	self.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);

	CGRect titleRect = self.titleLabel.frame;
	CGRect imageRect = self.imageView.frame;

	CGFloat titleOrigin = CGRectGetMinX(imageRect);

	imageRect.origin.x = (CGRectGetMaxX(titleRect) + 1.0) - CGRectGetWidth(imageRect);
	self.imageView.frame = imageRect;

	titleRect.origin.x = titleOrigin;
	titleRect.origin.y -= 1.0;
	self.titleLabel.frame = titleRect;
}

- (CGSize)sizeThatFits:(CGSize)size {
	size = [super sizeThatFits:size];
	
//	size.width += 5.0; // Margin right
	size.width = MAX(size.width, 100.0);
	
	return size;
}

@end
