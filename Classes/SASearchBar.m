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

#import "SASearchBar.h"
#import "SASearchBar+Private.h"

#import "SAScopeBarSegmentedControl.h"

#import "NSString+Additions.h"
#import "NSURL+Wikipedia.h"
#import "UIButton+Graphite.h"

@implementation SASearchBar

@synthesize backgroundView = _backgroundView;
@synthesize promptLabel = _promptLabel;
@synthesize searchField = _searchField;
@synthesize progressSearchField = _progressSearchField;
@synthesize searchFieldMask = _searchFieldMask;
@synthesize cancelButton = _cancelButton;
@synthesize scopeBarBackgroundView = _scopeBarBackgroundView;
@synthesize scopeBar = _scopeBar;
@synthesize calloutButton = _calloutButton;
@synthesize accessoryView = _accessoryView;
@synthesize pickerButton = _pickerButton;
@dynamic searchButton;
@synthesize searchText = _searchText;
@dynamic text;
@dynamic placeholder;
@dynamic prompt;
@dynamic active;
@dynamic accessoryType;
@dynamic pickerButtonShown;
@dynamic searchButtonShown;
@dynamic progress;
@dynamic compactLayout;
@dynamic scopeButtonTitles;
@dynamic selectedScopeButtonIndex;
@dynamic scopeCalloutButtonTitle;
@synthesize animatingLayout = _animatingLayout;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		[self initIvars];
		[self initObservers];
		[self initBackgroundView];
		[self initPromptLabel];
		[self initSearchField];
		[self initAccessoryView];
		[self initPickerButton];
		[self initCancelButton];
		[self initScopeBarBackgroundView];
		[self initScopeBar];
		[self initCalloutButton];
		
		[self layoutIfNeeded];
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder*)coder {
	if((self = [super initWithCoder:coder])) {
		[self initIvars];
		[self initObservers];
		[self initBackgroundView];
		[self initPromptLabel];
		[self initSearchField];
		[self initAccessoryView];
		[self initPickerButton];
		[self initCancelButton];
		[self initScopeBarBackgroundView];
		[self initScopeBar];
		[self initCalloutButton];
		
		[self layoutIfNeeded];
	}
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark SASearchBar

- (NSString*)text {
	return self.searchField.text;
}

- (void)setText:(NSString*)text {
	self.searchText = self.searchField.text = text;
	[self updateProgressSearchField];

	[[NSNotificationCenter defaultCenter]
		postNotificationName:UITextFieldTextDidChangeNotification
		object:[self searchField]
		userInfo:nil];
}

- (NSString*)placeholder {
	return self.searchField.placeholder;
}

- (void)setPlaceholder:(NSString*)placeholder {
	self.searchField.placeholder = placeholder;
	[self updateProgressSearchField];
}

- (NSString*)prompt {
	return self.promptLabel.text;
}

- (void)setPrompt:(NSString*)prompt {
	[self setPrompt:prompt animated:NO];
}

- (void)setPrompt:(NSString*)prompt animated:(BOOL)animated {
	animated = NO; // TODO
	
	if(!SFEqualStrings(prompt, self.prompt)) {
		if(animated) {
			CATransition* transition = [CATransition animation];
	
			transition.type = kCATransitionFade;
			transition.duration = 0.1;
		
			transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	
			CALayer* layer = self.promptLabel.layer;
			[layer addAnimation:transition forKey:@"searchBarPromptTransition"];
		}
		
		self.promptLabel.text = prompt;
		
		[self setNeedsLayout];
		
		if(animated) {
			[self layoutIfNeeded];
		}
	}
}

- (NSArray*)scopeButtonTitles {
	return self.scopeBar.segments;
}

- (void)setScopeButtonTitles:(NSArray*)scopeButtonTitles {
	self.scopeBar.segments = scopeButtonTitles;
}

- (NSInteger)selectedScopeButtonIndex {
	return self.scopeBar.selectedSegmentIndex;
}

- (void)setSelectedScopeButtonIndex:(NSInteger)selectedScopeButtonIndex {
	self.scopeBar.selectedSegmentIndex = selectedScopeButtonIndex;
}

- (NSString*)scopeCalloutButtonTitle {
	return self.calloutButton.currentTitle;
}

- (void)setScopeCalloutButtonTitle:(NSString*)scopeCalloutButtonTitle {
//	if(!SFEqualStrings(scopeCalloutButtonTitle, self.scopeCalloutButtonTitle)) {
		[[self calloutButton] setTitle:scopeCalloutButtonTitle forState:UIControlStateNormal];
		[self updateScopeBar];
		[self setNeedsLayout];
//	}
}

- (BOOL)isActive {
	return _active;
}

- (void)setActive:(BOOL)active {
	[self setActive:active animated:NO];
}

- (void)setActive:(BOOL)active animated:(BOOL)animated {
	if(self.active != active) {
		if(animated) {
			// Setup the animation
			[UIView beginAnimations:@"searchBarLayoutAnimation" context:NULL];
			
			[UIView setAnimationDuration:_preferredAnimationDuration];
			[UIView setAnimationCurve:_preferredAnimationCurve];
			
			[UIView setAnimationDelegate:self];
			[UIView setAnimationWillStartSelector:@selector(layoutAnimationWillStart:context:)];
			[UIView setAnimationDidStopSelector:@selector(layoutAnimationDidStop:finished:context:)];
		
			[UIView setAnimationBeginsFromCurrentState:YES];
		} else {
        	self.searchField.text = active ?
        		self.searchText :
        		nil;
        }
		
		// Update state and layout
		_active = active;
		
		[self updateAccessoryView];
		[self setNeedsLayout];
		
		// Commit animations if needed
		if(animated) {
			self.animatingLayout = YES;

			[self layoutIfNeeded];

			[UIView commitAnimations];
		} else {
			// Update the hidden property immediately if we're not animating
			self.scopeBar.hidden = !self.active;
		}
        
        [self updateProgressSearchField];
	}
}

- (SASearchBarAccessoryType)accessoryType {
	return _accessoryType;
}

- (void)setAccessoryType:(SASearchBarAccessoryType)accessoryType {
	[self setAccessoryType:accessoryType animated:NO];
}

- (void)setAccessoryType:(SASearchBarAccessoryType)accessoryType animated:(BOOL)animated {
	if(self.accessoryType != accessoryType) {
		if(animated) {
			// Setup the animation
			[UIView beginAnimations:@"searchBarLayoutAnimation" context:NULL];
			
			[UIView setAnimationDuration:_preferredAnimationDuration];
			[UIView setAnimationCurve:_preferredAnimationCurve];
			
			[UIView setAnimationBeginsFromCurrentState:YES];
		}
		
		_accessoryType = accessoryType;
		[self updateAccessoryView];
		[self setNeedsLayout];
		
		if(animated) {
			[self layoutIfNeeded];
			
			[UIView commitAnimations];
		}
	}
}

- (BOOL)isPickerButtonShown {
	return _pickerButtonShown;
}

- (void)setPickerButtonShown:(BOOL)pickerButtonShown {
	if(pickerButtonShown != self.pickerButtonShown) {
		if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { return; }
		
		_pickerButtonShown = pickerButtonShown;
		[self setNeedsLayout];
	}
}

- (BOOL)isSearchButtonShown {
	return _searchButtonShown;
}

- (void)setSearchButtonShown:(BOOL)searchButtonShown {
	if(searchButtonShown != self.searchButtonShown) {
		if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { return; }
		
		_searchButtonShown = searchButtonShown;
		
		[self setNeedsLayout];
		[self updateAccessoryView];
	}
}

- (float)progress {
	return _progress;
}

- (void)setProgress:(float)progress {
	progress = MAX(progress, 0.0);
	progress = MIN(progress, 1.0);
	
	if(progress != _progress) {
		_progress = progress;
		[self setNeedsLayout];
	}
}

- (UIButton*)searchButton {
	return (id)self.searchField.leftView;
}

- (void)layoutAnimationWillStart:(NSString*)animationID context:(void*)context {
	if(self.active) {
		self.cancelButton.hidden = self.scopeBar.hidden = self.calloutButton.hidden = self.scopeBarBackgroundView.hidden = NO;
	}
    
    self.searchField.text = self.active ?
        self.searchText :
        nil;
}

- (void)layoutAnimationDidStop:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context {
	self.animatingLayout = NO;
	
	if([finished boolValue]) {
		self.cancelButton.hidden = self.scopeBar.hidden = self.calloutButton.hidden = self.scopeBarBackgroundView.hidden = !self.active;
	}
}

#pragma mark -
#pragma mark UIView

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event {
	if(!self.active && self.userInteractionEnabled && self.accessoryType != SASearchBarAccessoryTypeNone) {
		// Did the hit the accessory view?
		CGRect bounds = self.bounds;
		CGRect accessoryViewRect = CGRectMake(
			CGRectGetMaxX(bounds) - 44.0,
			CGRectGetMinY(bounds),
			44.0,
			CGRectGetHeight(bounds));
			
		if(CGRectContainsPoint(accessoryViewRect, point)) {
			return self.accessoryView;
		}
		
		// The picker button maybe?
		if(self.pickerButtonShown && !self.pickerButton.hidden) {
			CGRect pickerButtonRect = self.pickerButton.frame;
			pickerButtonRect.origin.y = CGRectGetMinY(bounds);
			pickerButtonRect.size.height = CGRectGetHeight(accessoryViewRect);
			
			if(CGRectContainsPoint(pickerButtonRect, point)) {
				return self.pickerButton;
			}
		}
		
		// Or the searchfield?
		CGRect searchFieldRect = self.searchField.frame;
		searchFieldRect.size.height = CGRectGetMaxY(searchFieldRect);
		searchFieldRect.origin.x = CGRectGetMinX(bounds);
		searchFieldRect.origin.y = CGRectGetMinY(bounds);
		
		if(CGRectContainsPoint(searchFieldRect, point)) {
			if(self.searchField.searchButtonShown) {
				CGRect searchButtonRect = searchFieldRect;
				searchButtonRect.size.width = 40.0;
			
				if(CGRectContainsPoint(searchButtonRect, point)) {
					return self.searchField.leftView;
				}
			}
			
			return self.searchField;
		}
	}
	
	return [super hitTest:point withEvent:event];
}

- (CGSize)sizeThatFits:(CGSize)size {
	size.height = self.active ?
		44.0 :
		60.0;
	
	if(!self.compactLayout && self.active) {
		size.height += 44.0;
	}
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		size.height = 36.0;
	}
	
	return size;
}

- (void)layoutSubviews {
	[super layoutSubviews];

	CGFloat barHeight = self.active ? 44.0 : 60.0;
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		barHeight = 36.0;
	}
	
	CGFloat const margin = 5.0;

	CGRect bounds = self.bounds;
	
	CGRect backgroundRect = CGRectMake(
		CGRectGetMinX(bounds), CGRectGetMinY(bounds),
		CGRectGetWidth(bounds), barHeight);
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		backgroundRect = CGRectOffset(backgroundRect, 0.0, 4.0);
	}
	
	CGFloat const scopeBarBackgroundHeight = 44.0;
	CGRect scopeBarBackgroundRect = CGRectMake(
		CGRectGetMinX(backgroundRect), CGRectGetMaxY(backgroundRect) - scopeBarBackgroundHeight,
		CGRectGetWidth(backgroundRect), scopeBarBackgroundHeight);
	
	CGSize promptLabelSize = [[self promptLabel] sizeThatFits:backgroundRect.size];
	
//	promptLabelSize.width = MIN(promptLabelSize.width, CGRectGetWidth(bounds) - margin * 2.0);
	promptLabelSize.width = CGRectGetWidth(bounds);
	
	CGRect promptLabelRect = CGRectMake(
		floorf(CGRectGetMidX(backgroundRect) - promptLabelSize.width * 0.5),
		CGRectGetMinY(backgroundRect) + 4.0,
		promptLabelSize.width,
		promptLabelSize.height);
	
	if(self.active) {
		promptLabelRect = CGRectOffset(promptLabelRect, 0.0, -20.0);
	}
		
	self.promptLabel.frame = promptLabelRect;
	
	// Simply hide when the label is empty so we get a nice fade in when we set a text again
//	self.promptLabel.alpha = self.prompt.length > 0 ? 1.0 : 0.0;
	
	CGSize searchFieldSize = [[self searchField] sizeThatFits:backgroundRect.size];
	CGRect searchFieldRect = CGRectMake(
		CGRectGetMinX(backgroundRect) + margin,
		CGRectGetMaxY(backgroundRect) - searchFieldSize.height - 6.0,
		CGRectGetWidth(backgroundRect) - margin * 2.0,
		searchFieldSize.height);
	
	CGSize cancelButtonSize = [[self cancelButton] sizeThatFits:backgroundRect.size];
	CGRect cancelButtonRect = CGRectMake(
		CGRectGetMaxX(backgroundRect),
		ceilf(CGRectGetMidY(searchFieldRect) - cancelButtonSize.height * 0.5),
		cancelButtonSize.width,
		cancelButtonSize.height);

	if(self.active && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		if(!self.compactLayout) {
			scopeBarBackgroundRect = CGRectOffset(scopeBarBackgroundRect, 0.0, barHeight);
		}

		cancelButtonRect = CGRectOffset(cancelButtonRect, -(cancelButtonSize.width + margin), 0.0);
		searchFieldRect.size.width -= cancelButtonSize.width + margin * 2.0;
	}
	
	// ...
	[self updateScopeBarIfNeeded];
	
	CGSize scopeBarSize = [[self scopeBar] sizeThatFits:scopeBarBackgroundRect.size];
	CGRect scopeBarRect = CGRectMake(
		CGRectGetMinX(scopeBarBackgroundRect) + margin,
		floorf(CGRectGetMidY(scopeBarBackgroundRect) - scopeBarSize.height * 0.5) + 1.0,
		CGRectGetWidth(scopeBarBackgroundRect) - margin * 2.0,
		scopeBarSize.height);
	
	CGSize calloutButtonSize = [[self calloutButton] sizeThatFits:scopeBarBackgroundRect.size];
	CGRect calloutButtonRect = CGRectMake(
		CGRectGetMaxX(scopeBarBackgroundRect) - (calloutButtonSize.width + margin),
        floorf(CGRectGetMidY(scopeBarBackgroundRect) - calloutButtonSize.height * 0.5) + 1.0,
		calloutButtonSize.width,
        calloutButtonSize.height);
	
	if(self.compactLayout) {
		scopeBarRect.origin.y = ceilf(CGRectGetMidY(searchFieldRect) - scopeBarSize.height * 0.5);
		scopeBarRect.size.width = scopeBarSize.width - margin * 2.0;

		if(self.active) {
			searchFieldRect.size.width -= scopeBarSize.width;
			scopeBarRect.origin.x = CGRectGetMaxX(searchFieldRect) + margin * 2.0;
		} else {
			scopeBarRect.origin.x = CGRectGetMaxX(backgroundRect);
			cancelButtonRect.origin.x = CGRectGetMaxX(scopeBarRect) + margin;
		}
	} else {
		scopeBarRect.size.width -= calloutButtonSize.width + margin;
	}
	
	// Layout the accessory view
	CGSize accessoryViewSize = CGSizeMake(28.0, 20.0);
	
	CGRect accessoryViewRect = CGRectMake(
		CGRectGetMaxX(searchFieldRect) - accessoryViewSize.width - 5.0,
		ceilf(CGRectGetMidY(searchFieldRect) - accessoryViewSize.height * 0.5),
		accessoryViewSize.width,
		accessoryViewSize.height);
	
	// Layout the picker button
	CGSize pickerButtonSize = [[self pickerButton]
		sizeThatFits:searchFieldSize];
	CGRect pickerButtonRect = CGRectMake(
		CGRectGetMinX(accessoryViewRect) - pickerButtonSize.width - 5.0,
		ceilf(CGRectGetMidY(searchFieldRect) - pickerButtonSize.height * 0.5),
		pickerButtonSize.width,
		pickerButtonSize.height);
	
	self.backgroundView.frame = backgroundRect;
	self.scopeBarBackgroundView.frame = scopeBarBackgroundRect;
	self.searchField.frame = searchFieldRect;
	self.pickerButton.frame = pickerButtonRect;
	self.accessoryView.frame = accessoryViewRect;
	self.progressSearchField.frame = searchFieldRect;
	self.cancelButton.frame = cancelButtonRect;
	self.scopeBar.frame = scopeBarRect;
	self.calloutButton.frame = calloutButtonRect;
	
	if(self.compactLayout) {
		[self insertSubview:[self scopeBar] aboveSubview:[self backgroundView]];
		[[self scopeBar] setShowsCalloutButton:YES];
	} else {
		[self insertSubview:[self scopeBar] aboveSubview:[self scopeBarBackgroundView]];
		[[self scopeBar] setShowsCalloutButton:NO];
	}
	
	// Update our accessory views
	self.accessoryView.alpha =
		self.accessoryType == SASearchBarAccessoryTypeNone || self.active ?
		0.0 : 1.0;
	
	// Now update the picker button
	self.pickerButton.alpha =
		!self.pickerButtonShown || self.active ? // self.accessoryType != SASearchBarAccessoryTypeReload || self.active ?
		0.0 : 1.0;
		
	// Fade scope bar and cancel button
	CGFloat scopeBarAlpha = self.active ? 1.0 : 0.0;
	self.scopeBar.alpha = scopeBarAlpha;
	self.calloutButton.alpha = scopeBarAlpha;
	self.cancelButton.alpha = scopeBarAlpha;

	// Now layout the progress indicator	
	BOOL progressShown = !self.active && self.progress > 0.0 && self.accessoryType == SASearchBarAccessoryTypeStop;

	[CATransaction begin];

	[CATransaction setDisableActions:YES];

	if(progressShown) {
		CGFloat progressWith = ceilf(CGRectGetWidth(searchFieldRect) * self.progress);
		
		CGRect progressSearchFieldMaskRect = self.progressSearchField.bounds;
		progressSearchFieldMaskRect.size.width = progressWith;
		self.progressSearchField.layer.mask.frame = progressSearchFieldMaskRect;
		
		CGRect searchFieldMaskRect = self.searchField.bounds;
		
		searchFieldMaskRect.origin.x = progressWith;
		searchFieldMaskRect.size.width = CGRectGetWidth(searchFieldRect) - progressWith;
		
		self.searchFieldMask.frame = searchFieldMaskRect;
		
		if(!self.searchFieldMask.superlayer) {
			self.searchField.layer.mask = self.searchFieldMask;
		}
	} else {
		self.progressSearchField.layer.mask.frame = CGRectZero;
		
		self.searchFieldMask.frame = self.searchField.bounds;
		
		self.searchField.layer.mask = nil;
		[[self searchFieldMask] removeFromSuperlayer];
	}

	[CATransaction commit];
	
	self.progressSearchField.alpha = progressShown ? 1.0 : 0.0;
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField*)textfield {
	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
	return YES;
}

#pragma mark -
#pragma mark Private

- (BOOL)compactLayout {
	return UIDeviceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
}

- (void)initIvars {
	self.animatingLayout = NO;

	_progress = 0.0;

	_preferredAnimationCurve = UIViewAnimationCurveEaseInOut;
	_preferredAnimationDuration = 0.3;

	self.opaque = YES;
	self.backgroundColor = [UIColor clearColor];
	self.clipsToBounds = YES;
	self.active = NO;
	self.selectedScopeButtonIndex = -1;
	
	self.accessoryType = SASearchBarAccessoryTypeStop;
	self.pickerButtonShown = NO;
	self.searchButtonShown = YES;
}

- (void)initObservers {
//	[[NSNotificationCenter defaultCenter]
//		addObserver:self
//		selector:@selector(statusbarOrientationDidChange:)
//		name:UIApplicationDidChangeStatusBarOrientationNotification
//		object:nil];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(keyboardWillShow:)
		name:UIKeyboardWillShowNotification
		object:nil];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(keyboardDidShow:)
		name:UIKeyboardDidShowNotification
		object:nil];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(keyboardWillHide:)
		name:UIKeyboardWillHideNotification
		object:nil];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(keyboardDidHide:)
		name:UIKeyboardDidHideNotification
		object:nil];
}

- (void)initBackgroundView {
	UIImage* backgroundImage = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ?
		[UIImage imageNamed:@"graphiteSearchBarBackground.png"] :
		nil;
    UIImageView* backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
	
	backgroundView.contentMode = UIViewContentModeScaleToFill;
	
	[self addSubview:backgroundView];
	
	self.backgroundView = backgroundView;
}

- (void)initPromptLabel {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { return; }
	
	UILabel* promptLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	
	promptLabel.font = [UIFont boldSystemFontOfSize:12.0];
	
	promptLabel.textColor = [UIColor colorWithRed:0.205 green:0.266 blue:0.375 alpha:1.000];
	
	promptLabel.shadowColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
	promptLabel.shadowOffset = CGSizeMake(0.0, 1.0);
	
	promptLabel.opaque = NO;
	promptLabel.backgroundColor = [UIColor clearColor];
	promptLabel.clipsToBounds = NO;
	
	promptLabel.textAlignment = NSTextAlignmentCenter;
	
	// promptLabel.alpha = 0.0; // Initially hidden
	
	[promptLabel sizeToFit];
	
	self.promptLabel = promptLabel;
	[self insertSubview:promptLabel aboveSubview:[self backgroundView]];
}

- (void)initSearchField {
	SASearchBarTextField* searchField = [[SASearchBarTextField alloc] initWithSearchBar:self];
	
	searchField.delegate = self;
	searchField.userInteractionEnabled = self.userInteractionEnabled;
	
	searchField.text = @" ";
	
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(searchFieldTextDidChange:)
		name:UITextFieldTextDidChangeNotification
		object:searchField];
	
	[self insertSubview:searchField aboveSubview:[self backgroundView]];
	self.searchField = searchField;
	
	// Force the first layout to fix some ugly animation bug later on
	[searchField setNeedsLayout];
	[searchField layoutIfNeeded];
	
	searchField.text = nil;
	
	// ...
	CALayer* searchFieldMask = [CALayer layer];
	searchFieldMask.backgroundColor = [[UIColor blackColor] CGColor];
	self.searchFieldMask = searchFieldMask;
	
	// ...
	SASearchBarTextField* progressSearchField = [[SASearchBarTextField alloc] initWithSearchBar:self];
	
	progressSearchField.userInteractionEnabled = NO;
	progressSearchField.progressShown = YES;
	
	CALayer* progressSearchFieldMask = [CALayer layer];
	progressSearchFieldMask.backgroundColor = [[UIColor blackColor] CGColor];
	progressSearchField.layer.mask = progressSearchFieldMask;
	
	[self insertSubview:progressSearchField aboveSubview:searchField];
	self.progressSearchField = progressSearchField;
}

- (void)initCancelButton {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { return; }
	
	UIButton* cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
	
	[cancelButton setGraphiteStyle:UIBarButtonItemStyleDone miniBar:NO systemItem:UIBarButtonSystemItemCancel];
	cancelButton.hidden = YES; // Initially hidden
	
	[self insertSubview:cancelButton aboveSubview:[self backgroundView]];
	
	self.cancelButton = cancelButton;
}

- (void)initAccessoryView {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UIButton* accessoryView = [UIButton buttonWithType:UIButtonTypeCustom];
		
		[accessoryView setImage:[UIImage imageNamed:@"searchFieldReloadButton.png"] forState:UIControlStateNormal];
		
		self.accessoryView = accessoryView;
		[self insertSubview:accessoryView aboveSubview:[self progressSearchField]];
	} else {
		UIButton* accessoryView = [UIButton buttonWithType:UIButtonTypeCustom];
		
		UIImage* backgroundImage = [[UIImage imageNamed:@"searchFieldButtonBackground.png"]
			stretchableImageWithLeftCapWidth:9.0 topCapHeight:0.0];
		[accessoryView setBackgroundImage:backgroundImage forState:UIControlStateNormal];
		
		UIImage* highlightedBackgroundImage = [[UIImage imageNamed:@"searchFieldButtonBackgroundHighlighted.png"]
			stretchableImageWithLeftCapWidth:9.0 topCapHeight:0.0];
		[accessoryView setBackgroundImage:highlightedBackgroundImage forState:UIControlStateHighlighted];
		
		accessoryView.adjustsImageWhenHighlighted = NO;
		accessoryView.adjustsImageWhenDisabled = NO;
		
		//accessoryView.contentEdgeInsets = UIEdgeInsetsMake(7.0, 3.0, 7.0, 3.0);
		
		self.accessoryView = accessoryView;
		[self insertSubview:accessoryView aboveSubview:[self progressSearchField]];
	}
}

- (void)initPickerButton {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { return; }
	
	UIButton* pickerButton = [UIButton buttonWithType:UIButtonTypeCustom];
	
	[pickerButton setImage:[UIImage imageNamed:@"searchFieldPickerButton.png"] forState:UIControlStateNormal];
	[pickerButton setImage:[UIImage imageNamed:@"searchFieldPickerButtonHighlighted.png"] forState:UIControlStateHighlighted];
	
	self.pickerButton = pickerButton;
	[self insertSubview:pickerButton aboveSubview:[self progressSearchField]];
}

- (void)initScopeBarBackgroundView {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { return; }
	
	UIImage* scopeBarBackgroundImage = [UIImage imageNamed:@"scopeBarBackground.png"];
	UIImageView* scopeBarBackgroundView = [[UIImageView alloc] initWithImage:scopeBarBackgroundImage];
	
    scopeBarBackgroundView.contentMode = UIViewContentModeScaleToFill;
	scopeBarBackgroundView.hidden = YES;
	
	[self insertSubview:scopeBarBackgroundView belowSubview:[self backgroundView]];
	
	self.scopeBarBackgroundView = scopeBarBackgroundView;
}

- (void)initScopeBar {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { return; }
	
	SAScopeBarSegmentedControl* scopeBar = [[SAScopeBarSegmentedControl alloc] initWithFrame:CGRectZero];

	scopeBar.opaque = NO;
	scopeBar.backgroundColor = [UIColor clearColor];
	
	scopeBar.contentMode = UIViewContentModeRedraw;
	
	scopeBar.hidden = YES;

	[self insertSubview:scopeBar aboveSubview:[self scopeBarBackgroundView]];

	self.scopeBar = scopeBar;
}

- (void)initCalloutButton {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { return; }
	
	UIButton* calloutButton = [[SASearchBarCalloutButton alloc] initWithFrame:CGRectZero];
	
	[calloutButton setImage:[UIImage imageNamed:@"scopeBarDisclosureIndicator.png"] forState:UIControlStateNormal];
	[calloutButton setImage:[UIImage imageNamed:@"scopeBarDisclosureIndicatorHighlighted.png"] forState:UIControlStateHighlighted];
	
	[calloutButton setGraphiteStyle:UIBarButtonItemStyleBordered miniBar:NO];

	calloutButton.hidden = YES;
	calloutButton.reversesTitleShadowWhenHighlighted = YES;

	self.calloutButton = calloutButton;
	[self insertSubview:calloutButton aboveSubview:[self scopeBarBackgroundView]];
}

- (void)updateScopeBarIfNeeded {
	if(self.compactLayout) {
		if(self.scopeBar.segments.count != 3) {
			[self updateScopeBar];
		}
	} else {
		if(self.scopeBar.segments.count != 2) {
			[self updateScopeBar];
		}
	}
}

- (void)updateScopeBar {
	if(self.compactLayout) {
		self.scopeBar.segments = [NSArray arrayWithObjects:
			NSLocalizedString(@"SEARCHSCOPE_TITLE", @""),
			NSLocalizedString(@"SEARCHSCOPE_CONTENT", @""),
			self.scopeCalloutButtonTitle,
			nil];
	} else {
		self.scopeBar.segments = [NSArray arrayWithObjects:
			NSLocalizedString(@"SEARCHSCOPE_TITLE", @""),
			NSLocalizedString(@"SEARCHSCOPE_CONTENT", @""),
			nil];
	}
}

- (void)updateProgressSearchField {
	self.progressSearchField.placeholder = self.active && self.searchText.length > 0 ?
		self.searchText :
		self.placeholder;
}

- (void)updateAccessoryView {
	UIImage* image = nil;
	
	if(self.accessoryType == SASearchBarAccessoryTypeStop) {
		image = [UIImage imageNamed:@"searchFieldStopButton.png"];
	} else {
		image = [UIImage imageNamed:@"searchFieldReloadButton.png"];
	}
	
	[[self accessoryView] setImage:image forState:UIControlStateNormal];
	[[self accessoryView] setImage:image forState:UIControlStateHighlighted];
	
	// Workaround since having this line of code causes layout issues in layoutSubviews
	self.searchField.searchButtonShown = self.progressSearchField.searchButtonShown =
		self.searchButtonShown && self.accessoryType == SASearchBarAccessoryTypeReload && self.pickerButton && !self.active;
}

- (void)statusbarOrientationDidChange:(NSNotification*)notification {
	[self setNeedsLayout];
}

- (void)cancelButtonTapped:(id)sender {
}

- (void)searchFieldTextDidChange:(NSNotification*)notification {
	if(self.active || YES) {
		self.searchText = self.searchField.text;
		[[self searchField] setNeedsDisplay];
		
		[self updateProgressSearchField];
	}
}

- (void)keyboardWillShow:(NSNotification*)notification {
	_preferredAnimationCurve = [[[notification userInfo]
		objectForKey:UIKeyboardAnimationCurveUserInfoKey]
		unsignedIntegerValue];
	_preferredAnimationDuration = [[[notification userInfo]
		objectForKey:UIKeyboardAnimationDurationUserInfoKey]
		doubleValue];
}

- (void)keyboardDidShow:(NSNotification*)notification {
}

- (void)keyboardWillHide:(NSNotification*)notification {
	_preferredAnimationCurve = [[[notification userInfo]
		objectForKey:UIKeyboardAnimationCurveUserInfoKey]
		unsignedIntegerValue];
	_preferredAnimationDuration = [[[notification userInfo]
		objectForKey:UIKeyboardAnimationDurationUserInfoKey]
		doubleValue];
}

- (void)keyboardDidHide:(NSNotification*)notification {
}

@end

#pragma mark -
#pragma mark SASearchBarTextField

@implementation SASearchBarTextField

@synthesize clearButton2 = _clearButton2;
@synthesize placeholderLabel2 = _placeholderLabel2;
@dynamic progressShown;
@dynamic searchButtonShown;

- (id)initWithSearchBar:(SASearchBar*)searchBar {
	if((self = [super initWithFrame:CGRectZero])) {
		// ...
		_appearanceNeedsUpdate = YES;
		
		self.progressShown = NO;
		self.searchButtonShown = NO;
	
		_searchBar = searchBar;

		// ...
		self.clearButtonMode = UITextFieldViewModeNever;
		self.leftViewMode = UITextFieldViewModeAlways;
		self.rightViewMode = UITextFieldViewModeUnlessEditing;
	
		self.enablesReturnKeyAutomatically = NO;
		self.returnKeyType = UIReturnKeySearch;
		self.autocorrectionType = UITextAutocorrectionTypeNo;
		self.autocapitalizationType = UITextAutocapitalizationTypeWords;
		
		// Make a new clear button
		UIButton* clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
		
		[clearButton setImage:[UIImage imageNamed:@"searchFieldClearButton.png"] forState:UIControlStateNormal];
		[clearButton setImage:[UIImage imageNamed:@"searchFieldClearButtonHighlighted.png"] forState:UIControlStateHighlighted];

		[clearButton
			addTarget:self
			action:@selector(textFieldShouldClear:)
			forControlEvents:UIControlEventTouchUpInside];

		[self addSubview:clearButton];

		self.clearButton2 = clearButton;
		
		if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
			UIButton* searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
		
			UIImage* backgroundImage = [[UIImage imageNamed:@"searchFieldButtonBackground.png"]
				stretchableImageWithLeftCapWidth:9.0 topCapHeight:0.0];
			[searchButton setBackgroundImage:backgroundImage forState:UIControlStateNormal];
		
			UIImage* highlightedBackgroundImage = [[UIImage imageNamed:@"searchFieldButtonBackgroundHighlighted.png"]
				stretchableImageWithLeftCapWidth:9.0 topCapHeight:0.0];
			[searchButton setBackgroundImage:highlightedBackgroundImage forState:UIControlStateHighlighted];
		
			UIImage* searchButtonImage = [UIImage imageNamed:@"searchFieldSearchButton.png"];
			[searchButton setImage:searchButtonImage forState:UIControlStateNormal];
			[searchButton setImage:searchButtonImage forState:UIControlStateHighlighted];
			
			searchButton.adjustsImageWhenHighlighted = NO;
			searchButton.adjustsImageWhenDisabled = NO;
		
			[searchButton sizeToFit];
		
			self.leftView = searchButton;
		}

		[self updateAppearance];
	}
	
	return self;
}


- (BOOL)isProgressShown {
	return _progressShown;
}

- (void)setProgressShown:(BOOL)progressShown {
	if(progressShown != self.progressShown) {
		_progressShown = progressShown;

		_appearanceNeedsUpdate = YES;
		[self updateAppearance];
		[self setNeedsLayout];
	}
}

- (BOOL)isSearchButtonShown {
	return _searchButtonShown;
}

- (void)setSearchButtonShown:(BOOL)searchButtonShown {
	if(searchButtonShown != self.searchButtonShown) {
		_searchButtonShown = searchButtonShown;
		[self setNeedsLayout];
	}
}

- (void)paste:(id)sender {
	NSURL* URL = [[UIPasteboard generalPasteboard] URL];
	
	if(URL && [URL isWikipediaURL]) {
		NSString* titleString = [URL wikipediaTitle];
		
		if(titleString.length > 0) {
			NSRange range = NSMakeRange(0, self.text.length);
			if([[self delegate] textField:self shouldChangeCharactersInRange:range replacementString:titleString]) {
				_searchBar.text = titleString;
			}
		}

		return;
	}

	[super paste:sender];
}

- (CGSize)sizeThatFits:(CGSize)size {
	size = [super sizeThatFits:size];
	
	size.height = MAX(size.height, 30.0);
	
	return size;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect bounds = self.bounds;

	CGSize rightViewSize = [_clearButton2 sizeThatFits:bounds.size];

	CGRect clearButtonRect = CGRectMake(
		CGRectGetMaxX(bounds) - rightViewSize.width - 6.0,
		CGRectGetMinY(bounds),
		rightViewSize.width,
		CGRectGetHeight(bounds));
        
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && self.window.screen.scale > 1.0) {
    	clearButtonRect = CGRectOffset(clearButtonRect, 0.0, -0.5);
    }
    
    self.clearButton2.frame = clearButtonRect;
	self.clearButton2.hidden = self.text.length == 0; // !(self.editing && self.text.length > 0);
	
	CGRect placeholderRect = [self placeholderRectForBounds:bounds];
	placeholderRect = CGRectOffset(placeholderRect, 0.0, -3.0);
	self.placeholderLabel2.frame = placeholderRect;
	
	self.placeholderLabel2.text = self.placeholder;
	[self bringSubviewToFront:[self placeholderLabel2]];

	// self.rightView.alpha = self.editing ? 0.0 : 1.0;
	
	self.leftView.alpha = self.searchButtonShown ? 1.0 : 0.0;
	
//	NSLog(@"%@ - %@", NSStringFromCGRect(self.frame), NSStringFromCGRect([[self _placeholderLabel] frame]));
}

- (CGRect)borderRectForBounds:(CGRect)bounds {
	CGRect borderRect = bounds;
	return borderRect;
}

- (CGRect)leftViewRectForBounds:(CGRect)bounds {
//	CGRect leftViewRect = CGRectMake(6.0, 5.0, 20.0, 20.0);
	CGRect leftViewRect = CGRectMake(5.0, 5.0, 28.0, 20.0);
	return leftViewRect;
}

- (CGRect)rightViewRectForBounds:(CGRect)bounds {
	CGRect rightViewRect = CGRectMake(bounds.size.width - 26.0, 5.0, 20.0, 20.0);
	return rightViewRect;
}

- (CGRect)textRectForBounds:(CGRect)bounds {
	CGRect textRect = CGRectMake(
		CGRectGetMinX(bounds) + 36.0,
		CGRectGetMinY(bounds) + 6.0,
		CGRectGetWidth(bounds) - 55.0,
		CGRectGetHeight(bounds) - 6.0);
		
	if(!self.searchButtonShown || self.editing) {
		textRect.origin.x = CGRectGetMinX(bounds) + 15.0;
	}
		
	return textRect;
}

- (CGRect)placeholderRectForBounds:(CGRect)bounds {
	CGRect textRect = CGRectMake(
		CGRectGetMinX(bounds) + 36.0,
		CGRectGetMinY(bounds) + 6.0,
		CGRectGetWidth(bounds) - 55.0,
		CGRectGetHeight(bounds) - 6.0);
		
	if(!self.searchButtonShown || self.editing) {
		textRect.origin.x = CGRectGetMinX(bounds) + 15.0;
	}
	
	return textRect;
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
	CGRect editingRect = CGRectMake(
		CGRectGetMinX(bounds) + 36.0,
		CGRectGetMinY(bounds) + 6.0,
		CGRectGetWidth(bounds) - 55.0,
		CGRectGetHeight(bounds) - 6.0);
	
	if(!self.searchButtonShown || self.editing) {
		editingRect.origin.x = CGRectGetMinX(bounds) + 15.0;
	}
		
	return editingRect;
}

- (void)updateAppearance {
	_appearanceNeedsUpdate = NO;

	self.font = [UIFont systemFontOfSize:14.0];
	
	self.opaque = NO;
	self.backgroundColor = [UIColor clearColor];

	UIImage* backgroundImage = self.progressShown ?
		[[UIImage imageNamed:@"searchFieldBackgroundHighlighted.png"] stretchableImageWithLeftCapWidth:24.0 topCapHeight:0.0] :
		[[UIImage imageNamed:@"searchFieldBackground.png"] stretchableImageWithLeftCapWidth:24.0 topCapHeight:0.0];

	self.background = backgroundImage;
	self.disabledBackground = backgroundImage;
	
	UIControl* searchButton = (id)self.leftView;
	searchButton.enabled = !self.progressShown;

/*	
	UIImageView* searchIndicatorView = (id)self.leftView;
	searchIndicatorView.image = self.progressShown ?
		[UIImage imageNamed:@"searchFieldIndicatorHighlighted.png"] :
		[UIImage imageNamed:@"searchFieldIndicator.png"];
	searchIndicatorView.alpha = 1.0;
*/
	
	if(self.progressShown) {
		if(!self.placeholderLabel2) {
			self.placeholderLabel2 = [[UILabel alloc] initWithFrame:CGRectZero];
			
			self.placeholderLabel2.font = self.font;
			
//			if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
				self.placeholderLabel2.textColor = [UIColor whiteColor];
//			} else {
				self.placeholderLabel2.textColor = [UIColor colorWithRed:0.216 green:0.335 blue:0.455 alpha:1.000];
				self.placeholderLabel2.shadowColor = [[UIColor whiteColor] colorWithAlphaComponent:1.0 / 3.0];
				self.placeholderLabel2.shadowOffset = CGSizeMake(0.0, 1.0);
//			}

			self.placeholderLabel2.alpha = 1.0;
			self.placeholderLabel2.opaque = NO;
			self.placeholderLabel2.backgroundColor = [UIColor clearColor];
		}

		[self addSubview:[self placeholderLabel2]];
	} else {
		[[self placeholderLabel2] removeFromSuperview];
	}
}

- (void)textFieldShouldClear:(id)sender {
	self.text = nil;
	[self becomeFirstResponder];

	if([[self delegate] respondsToSelector:@selector(textFieldShouldClear:)]) {
		[(id<UITextFieldDelegate>)[self delegate] textFieldShouldClear:self];
	}

	if([[self delegate] respondsToSelector:@selector(searchFieldTextDidChange:)]) {
		[(id)[self delegate] searchFieldTextDidChange:nil];
	}
}

@end

#pragma mark - SASearchBarCalloutButton

@implementation SASearchBarCalloutButton

- (CGSize)sizeThatFits:(CGSize)size {
	size = [super sizeThatFits:size];
	
	size.width += 4.0; // Margin right
	size.width += self.imageView.image.size.width;
	size.width = MAX(size.width, 100.0);
	
	return size;
}

- (void)layoutSubviews {
	[super layoutSubviews];

	CGRect titleLabelRect = self.titleLabel.frame;
	titleLabelRect = CGRectOffset(titleLabelRect, -self.currentImage.size.width, 0.0);

	CGRect imageViewRect = self.imageView.frame;
	imageViewRect.origin.x = CGRectGetMaxX(titleLabelRect) + 4.0;

	if(!self.highlighted && !self.selected) {
		imageViewRect.origin.y += 1.0;
	}

	self.imageView.frame = imageViewRect;
	self.titleLabel.frame = titleLabelRect;

	self.titleLabel.shadowOffset = self.highlighted || self.selected ?
		CGSizeMake(0.0, -1.0) : CGSizeMake(0.0, 1.0);
}

@end
