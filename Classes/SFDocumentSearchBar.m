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

#import "SFDocumentSearchBar.h"
#import "SFDocumentSearchBar+Private.h"

#import "SFShadowView.h"
#import "SFDocumentSearchField.h"
#import "SFBadgeAccessoryView.h"
#import "SFSegmentedControl.h"
#import "UIButton+Graphite.h"

@implementation SFDocumentSearchBar

@synthesize delegate = _delegate;
@synthesize text = _text;
@synthesize placeholder = _placeholder;
@dynamic barMode;
@dynamic controlSize;
@synthesize iPadInterfaceIdiom = _iPadInterfaceIdiom;
@synthesize toolbar = _toolbar;
@synthesize backgroundView = _backgroundView;
@synthesize backgroundShadowView = _backgroundShadowView;
@synthesize searchField = _searchField;
@synthesize searchResultView = _searchResultView;
@synthesize doneButton = _doneButton;
@synthesize navigationSegmentedControl = _navigationSegmentedControl;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
		[self initIvars];
		
		if(self.iPadInterfaceIdiom) {
			[self initToolbar];
			[self initSearchField];
			[self initNavigationSegmentedControl];
			[self initToolbarItems];
		} else {
			[self initBackgroundView];
			[self initSearchField];
			[self initDoneButton];
			[self initNavigationSegmentedControl];
		}
		
		self.controlSize = SFRegularControlSize;
		[self updateForControlSize:[self controlSize]];
		
		[self layoutIfNeeded];
	}

    return self;
}

- (void)dealloc {
	self.delegate = nil;

}

#pragma mark -
#pragma mark SFDocumentSearchBar

- (NSString*)text {
	return self.searchField.text;
}

- (void)setText:(NSString*)text {
	self.searchField.text = text;
}

- (NSString*)placeholder {
	return self.searchField.placeholder;
}

- (void)setPlaceholder:(NSString*)placeholder {
	self.searchField.placeholder = placeholder;
}

- (SFDocumentSearchBarMode)barMode {
	return _barMode;
}

- (void)setBarMode:(SFDocumentSearchBarMode)barMode {
	[self setBarMode:barMode animated:NO];
}

- (void)setBarMode:(SFDocumentSearchBarMode)barMode animated:(BOOL)animated {
	if(barMode != _barMode) {
		if(animated) {
			[UIView beginAnimations:@"barModeAnimation" context:NULL];
			
			[UIView setAnimationDuration:0.2];
		}
		
		_barMode = barMode;
		[self setNeedsLayout];
		
		if(animated) {
			[self layoutIfNeeded];
			
			if(self.toolbar) {
				BOOL enabled = barMode == SFDocumentSearchBarModeNavigation;
				[[self navigationSegmentedControl] setEnabled:enabled];
			}
			
			[UIView commitAnimations];
		}
	}
}

- (SFControlSize)controlSize {
	return _controlSize;
}

- (void)setControlSize:(SFControlSize)controlSize {
	if(controlSize != _controlSize) {
		_controlSize = controlSize;
		
		[self updateForControlSize:controlSize];
		[self setNeedsLayout];
	}
}

- (void)setCurrentResultIndex:(NSInteger)resultIndex numberOfResults:(NSInteger)numberOfResults {
	self.searchResultView.text = [NSString localizedStringWithFormat:@"%ld", (long)resultIndex + 1];
	self.searchResultView.otherText = [NSString localizedStringWithFormat:@"%ld", (long)numberOfResults];
	
	[[self searchResultView] sizeToFit];
	
	self.searchField.rightViewMode = numberOfResults > 0 ?
		UITextFieldViewModeUnlessEditing :
		UITextFieldViewModeNever;
}

#pragma mark -
#pragma mark UIView

- (CGSize)sizeThatFits:(CGSize)size {
	CGFloat const height = self.controlSize == SFRegularControlSize ?
		44.0 :
		32.0;
		
	return CGSizeMake(size.width, height);
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	// Now do the actual layout
	CGRect bounds = self.bounds;
	static const CGFloat margin = 10.0;
	
	CGRect contentRect = bounds;
	
	self.toolbar.frame = contentRect;
	
	if(self.toolbar) {
		return; // the toolbar does the layout for us
	}
	
	CGSize backgroundSize = [[self backgroundView]
		sizeThatFits:CGSizeZero];
	CGRect backgroundRect = CGRectMake(
		CGRectGetMinX(contentRect),
		CGRectGetMaxY(contentRect) - backgroundSize.height,
		CGRectGetWidth(contentRect),
		backgroundSize.height);
	
	CGSize backgroundShadowSize = [[self backgroundShadowView]
		sizeThatFits:bounds.size];
	CGRect backgroundShadowRect = CGRectMake(
		CGRectGetMinX(bounds),
		CGRectGetMinY(bounds) - backgroundShadowSize.height,
		CGRectGetWidth(bounds),
		backgroundShadowSize.height);
	
	CGSize doneButtonSize = [[self doneButton]
		sizeThatFits:contentRect.size];
	CGRect doneButtonRect = CGRectMake(
		CGRectGetMaxX(contentRect) - doneButtonSize.width - margin * 0.5,
		floorf(CGRectGetMidY(contentRect) - doneButtonSize.height * 0.5) + 1.0,
		doneButtonSize.width,
		doneButtonSize.height);
		
	[[[self searchField] rightView] sizeToFit];
	
	static const CGFloat searchFieldHeight = 30.0;
		
	CGRect searchFieldRect = CGRectMake(
		CGRectGetMinX(contentRect) + margin * 0.5,
		floorf(CGRectGetMidY(contentRect) - searchFieldHeight * 0.5),
		CGRectGetWidth(contentRect) - doneButtonSize.width - margin * 2.0,
		searchFieldHeight);
		
	CGSize navigationSegmentedControlSize = [[self navigationSegmentedControl]
		sizeThatFits:contentRect.size];
	CGRect navigationSegmentedControlRect = CGRectMake(
		CGRectGetMinX(contentRect) - navigationSegmentedControlSize.width,
		floorf(CGRectGetMidY(contentRect) - navigationSegmentedControlSize.height * 0.5) + 1.0,
		navigationSegmentedControlSize.width,
		navigationSegmentedControlSize.height);
	
	if(self.barMode == SFDocumentSearchBarModeNavigation) {
		navigationSegmentedControlRect = CGRectOffset(navigationSegmentedControlRect,
			navigationSegmentedControlSize.width + margin * 0.5,
			0.0);
		
		searchFieldRect.size.width -= navigationSegmentedControlSize.width + margin;
		searchFieldRect.origin.x += navigationSegmentedControlSize.width + margin;
	}
	
	self.backgroundView.frame = backgroundRect;
	self.backgroundShadowView.frame = backgroundShadowRect;
	self.doneButton.frame = doneButtonRect;
	self.searchField.frame = searchFieldRect;
	self.navigationSegmentedControl.frame = navigationSegmentedControlRect;
}

#pragma mark -
#pragma mark UIResponder

- (BOOL)isFirstResponder {
	return [[self searchField] isFirstResponder];
}

- (BOOL)becomeFirstResponder {
	return [[self searchField] becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
	return [[self searchField] resignFirstResponder];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	return [[self searchField] canPerformAction:action withSender:sender];
}

- (void)cut:(id)sender {
	[[self searchField] cut:sender];
}

- (void)copy:(id)sender {
	[[self searchField] copy:sender];
}

- (void)paste:(id)sender {
	[[self searchField] paste:sender];
}

- (void)select:(id)sender {
	[[self searchField] select:sender];
}

- (void)selectAll:(id)sender {
	[[self searchField] selectAll:sender];
}

- (void)delete:(id)sender {
	[[self searchField] delete:sender];
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string {
	if([[self delegate] respondsToSelector:@selector(documentSearchBar:textDidChange:)]) {
		NSString* newText = [[textField text]
			stringByReplacingCharactersInRange:range
			withString:string];
		[[self delegate] documentSearchBar:self textDidChange:newText];
	}

	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField*)textField {
	if([[self delegate] respondsToSelector:@selector(documentSearchBar:textDidChange:)]) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.0), dispatch_get_main_queue(), ^{
			[[self delegate] documentSearchBar:self textDidChange:@""];
		});
	}
	
	[self setCurrentResultIndex:-1 numberOfResults:0];
	
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
	if([[self delegate] respondsToSelector:@selector(documentSearchBarSearchButtonTapped:)]) {
		[[self delegate] documentSearchBarSearchButtonTapped:self];
	}
	
	return YES;
}

#pragma mark -
#pragma mark Private

- (void)initIvars {
	self.iPadInterfaceIdiom = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
	self.clipsToBounds = NO;
	self.barMode = SFDocumentSearchBarModeDefault;
}

- (void)initToolbar {
	UIToolbar* toolbar = [[UIToolbar alloc] initWithFrame:[self bounds]];
	
	toolbar.barStyle = UIBarStyleBlack;
	toolbar.translucent = YES;
	
	self.toolbar = toolbar;
	[self addSubview:toolbar];
}

- (void)initToolbarItems {
	UIBarButtonItem* doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonTapped:)];

	self.toolbar.items = [NSArray arrayWithObjects:
		doneButtonItem,
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL],
		[[UIBarButtonItem alloc] initWithCustomView:[self searchField]],
		[[UIBarButtonItem alloc] initWithCustomView:[self navigationSegmentedControl]],
		nil];
}

- (void)initBackgroundView {
	if(self.toolbar) { return; } // no custom background in this case
	
	UIImageView* backgroundView = [[UIImageView alloc] initWithImage:nil];
	
	self.backgroundView = backgroundView;
	[self addSubview:backgroundView];
}

- (void)initBackgroundShadowView {
}

- (void)initSearchField {
	SFDocumentSearchField* searchField = [[SFDocumentSearchField alloc] initWithFrame:CGRectZero];
	
	searchField.delegate = self;
	
	SFBadgeAccessoryView* searchResultView = [[SFBadgeAccessoryView alloc] initWithFrame:CGRectZero];
	
	searchResultView.text = @"0",
	searchResultView.otherText = @"0";
	
	searchResultView.badgeColor = [UIColor lightGrayColor];
	
	searchResultView.opaque = NO;
	searchResultView.backgroundColor = [UIColor clearColor];

	[searchResultView sizeToFit];
	
	self.searchResultView = searchResultView;
	
	searchField.rightView = searchResultView;
	searchField.rightViewMode = UITextFieldViewModeNever;
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		searchField.frame = CGRectMake(0.0, 0.0, 280.0, 40.0);
	}
	
	self.searchField = searchField;
	[self insertSubview:searchField aboveSubview:[self backgroundView]];
}

- (void)initDoneButton {
	UIButton* doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
	
	[doneButton addTarget:self action:@selector(doneButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	
	self.doneButton = doneButton;
	[self insertSubview:doneButton aboveSubview:[self backgroundView]];
}

- (void)initNavigationSegmentedControl {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		NSArray* items = [NSArray arrayWithObjects:
			[UIImage imageNamed:@"buttonitem-arrow-left"],
			[UIImage imageNamed:@"buttonitem-arrow-right"],
			nil];
		UISegmentedControl* navigationSegmentedControl = [[UISegmentedControl alloc] initWithItems:items];
		
		navigationSegmentedControl.momentary = YES;
		navigationSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
		
		[navigationSegmentedControl setWidth:44.0 forSegmentAtIndex:0];
		[navigationSegmentedControl setContentOffset:CGSizeMake(0.0, -1.0) forSegmentAtIndex:0];
		
		[navigationSegmentedControl setWidth:44.0 forSegmentAtIndex:1];
		[navigationSegmentedControl setContentOffset:CGSizeMake(0.0, -1.0) forSegmentAtIndex:1];
		
		[navigationSegmentedControl addTarget:self action:@selector(navigationSegmentedControlTapped:) forControlEvents:UIControlEventValueChanged];
		
		navigationSegmentedControl.enabled = NO;
		
		self.navigationSegmentedControl = (id)navigationSegmentedControl;
	} else {
		NSArray* items = [NSArray arrayWithObjects:
			[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"documentSearchNavigateUp.png"] highlightedImage:nil],
			[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"documentSearchNavigateDown.png"] highlightedImage:nil],
			nil];
		SFSegmentedControl* navigationSegmentedControl = [[SFSegmentedControl alloc] initWithItems:items interfaceStyle:SFGraphicsInterfaceStyleDocumentSearch];
		
		navigationSegmentedControl.momentary = YES;
		
		[navigationSegmentedControl addTarget:self action:@selector(navigationSegmentedControlTapped:) forControlEvents:UIControlEventValueChanged];
		
		self.navigationSegmentedControl = navigationSegmentedControl;
		[self insertSubview:navigationSegmentedControl aboveSubview:[self backgroundView]];
	}
}

- (void)updateForControlSize:(SFControlSize)controlSize {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { return; }
	
	if(controlSize == SFRegularControlSize) {
		self.backgroundView.image = [UIImage imageNamed:@"documentSearchBarBackground.png"];
		
		[[self doneButton] setGraphiteStyle:UIBarButtonItemStyleDone miniBar:NO systemItem:UIBarButtonSystemItemDone];
        
        UIImage* backgroundImage = [[UIImage imageNamed:@"documentSearchButtonBackground.png"]
			stretchableImageWithLeftCapWidth:8.0 topCapHeight:0.0];
		[[self doneButton] setBackgroundImage:backgroundImage forState:UIControlStateNormal];
		
		UIImage* highlightedBackgroundImage = [[UIImage imageNamed:@"documentSearchButtonBackgroundHighlighted.png"]
			stretchableImageWithLeftCapWidth:8.0 topCapHeight:0.0];
		[[self doneButton] setBackgroundImage:highlightedBackgroundImage forState:UIControlStateHighlighted];
	} else {
		self.backgroundView.image = [UIImage imageNamed:@"documentSearchBarSmallBackground.png"];
		
		[[self doneButton] setGraphiteStyle:UIBarButtonItemStyleDone miniBar:YES systemItem:UIBarButtonSystemItemDone];
	
		UIImage* backgroundImage = [[UIImage imageNamed:@"documentSearchSmallButtonBackground.png"]
			stretchableImageWithLeftCapWidth:8.0 topCapHeight:0.0];
		[[self doneButton] setBackgroundImage:backgroundImage forState:UIControlStateNormal];
		
		UIImage* highlightedBackgroundImage = [[UIImage imageNamed:@"documentSearchSmallButtonBackgroundHighlighted.png"]
			stretchableImageWithLeftCapWidth:8.0 topCapHeight:0.0];
		[[self doneButton] setBackgroundImage:highlightedBackgroundImage forState:UIControlStateHighlighted];
	}
	
	self.searchResultView.controlSize = controlSize;
	self.searchField.controlSize = controlSize;
}

- (void)doneButtonTapped:(id)sender {
	if([[self delegate] respondsToSelector:@selector(documentSearchBarCancelButtonTapped:)]) {
		[[self delegate] documentSearchBarCancelButtonTapped:self];
	}
}

- (void)navigationSegmentedControlTapped:(id)sender {
	NSInteger selectedSegmentIndex = UISegmentedControlNoSegment;
	
	if(self.iPadInterfaceIdiom) {
		selectedSegmentIndex = self.navigationSegmentedControl.selectedSegmentIndex;
	} else {
		selectedSegmentIndex = self.navigationSegmentedControl.highlightedSegmentIndex;
	}
	
	if(selectedSegmentIndex == 0) {
		if([[self delegate] respondsToSelector:@selector(documentSearchBarPrevButtonTapped:)]) {
			[self resignFirstResponder];
			[[self delegate] documentSearchBarPrevButtonTapped:self];
		}
	} else if(selectedSegmentIndex == 1) {
		if([[self delegate] respondsToSelector:@selector(documentSearchBarNextButtonTapped:)]) {
			[self resignFirstResponder];
			[[self delegate] documentSearchBarNextButtonTapped:self];
		}
	}
}

@end
