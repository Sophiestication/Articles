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

#import "SFBarButtonItem.h"
#import "SFBarButtonItem+Private.h"

#import "SFToolbar.h"

#import "SFGraphics.h"

#import "UIButton+Graphite.h"
#import "UILabel+Graphite.h"

@implementation SFBarButtonItem

@synthesize appItem = _appItem;
@synthesize itemIdentifier = _itemIdentifier;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithTitle:(NSString*)title style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action {
	if((self = [self initWithBarButtonAppItem:SFBarButtonAppItemDone target:target action:action])) {
		_needsAutomaticButtonStyling = NO;
		_isSystemItem = NO;
		
		self.title = title;
		self.style = style;
	}
	
	return self;
}

- (id)initWithImage:(UIImage*)image style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action {
	if((self = [self initWithBarButtonAppItem:SFBarButtonAppItemDone target:target action:action])) {
		_needsAutomaticButtonStyling = NO;
		_isSystemItem = NO;
		
		self.image = image;
		self.style = style;
	}
	
	return self;
}

- (id)initWithBarButtonAppItem:(SFBarButtonAppItem)appItem target:(id)target action:(SEL)action {
	if((self = [super initWithCustomView:nil])) {
		_needsInitialization = YES;
		_needsAutomaticButtonStyling = YES;
		_isSystemItem = NO;
		
		_appItem = appItem;
		
		self.target = target;
		self.action = action;
	}
	
	return self;
}

- (id)initWithBarButtonSystemItem:(UIBarButtonSystemItem)systemItem target:(id)target action:(SEL)action {
	if((self = [super initWithBarButtonSystemItem:systemItem target:target action:action])) {
		_needsInitialization = NO;
		_needsAutomaticButtonStyling = NO;
		
		_isSystemItem = YES;
		_systemItem = systemItem;
		
//		if(systemItem == UIBarButtonSystemItemFlexibleSpace) { _systemItem = SFBarButtonAppItemFlexibleSpace; }
//		if(systemItem == UIBarButtonSystemItemFixedSpace) { _systemItem = SFBarButtonAppItemFixedSpace; }
	}
	
	return self;
}


#pragma mark -
#pragma mark UIBarItem

- (void)setTag:(NSInteger)tag {
	if(tag != self.tag) {
		[super setTag:tag];
		_needsInitialization = YES;
	}
}

- (void)setStyle:(UIBarButtonItemStyle)style {
	if(style != self.style) {
		[super setStyle:style];
		_needsInitialization = YES;
	}
}

#pragma mark -
#pragma mark Private

- (void)layoutForBarViewIfNeeded:(id)barView {
	if(_isSystemItem) {
		return;
	}
	
	SFControlSize controlSize = !barView || CGRectGetHeight([barView frame]) >= 44.0 ?
		SFRegularControlSize :
		SFMiniControlSize;
	BOOL miniBar = controlSize == SFMiniControlSize;

	SFGraphicsInterfaceStyle interfaceStyle = SFGraphicsInterfaceStyleGraphite;

	if(interfaceStyle == _interfaceStyle &&
	   controlSize == _controlSize &&
	   !_needsInitialization) {
		return;
	}

	UIButton* button = (id)[self customView];
	
	if(!button) {
		button = [UIButton buttonWithType:UIButtonTypeCustom];
		self.customView = button;
	}
	
	if(self.target && self.action) {
		[button addTarget:[self target] action:[self action] forControlEvents:UIControlEventTouchUpInside];
	}
		
	if(!_needsAutomaticButtonStyling) {
		if(self.title) {
			[button setTitle:[self title] forState:UIControlStateNormal];
		}
		
		if(self.image) {
			[button setImage:[self image] forState:UIControlStateNormal];
		}
	}
		
	button.enabled = self.enabled;
	
	if(_needsAutomaticButtonStyling) {
		switch(_appItem) {
			case SFBarButtonAppItemDone: {
				[button setGraphiteStyle:UIBarButtonItemStyleDone miniBar:miniBar];
				[button setTitle:NSLocalizedString(@"UIBarButtonSystemItemDone", @"") forState:UIControlStateNormal];
			} break;
			
			case SFBarButtonAppItemCancel: {
				[button setGraphiteStyle:UIBarButtonItemStyleDone miniBar:miniBar];
				[button setTitle:NSLocalizedString(@"UIBarButtonSystemItemCancel", @"") forState:UIControlStateNormal];
			} break;
			
			case SFBarButtonAppItemEdit: {
				[button setGraphiteStyle:UIBarButtonItemStyleBordered miniBar:miniBar];
				[button setTitle:NSLocalizedString(@"UIBarButtonSystemItemEdit", @"") forState:UIControlStateNormal];
			} break;
			
			case SFBarButtonAppItemSave: {
				[button setGraphiteStyle:UIBarButtonItemStyleBordered miniBar:miniBar];
				[button setTitle:NSLocalizedString(@"UIBarButtonSystemItemSave", @"") forState:UIControlStateNormal];
			} break;
			
			case SFBarButtonAppItemAction: {
				[button setGraphiteStyle:UIBarButtonItemStylePlain miniBar:miniBar];
				
				if(miniBar) {
					[button setImage:[UIImage imageNamed:@"smallAddBookmark.png"] forState:UIControlStateNormal];
				} else {
					[button setImage:[UIImage imageNamed:@"addBookmark.png"] forState:UIControlStateNormal];
				}
				
				if(!self.title) {
					self.title = NSLocalizedString(@"SFBarButtonAppItemAction", @"");
				}
			} break;
			
			case SFBarButtonAppItemBookmarks: {
				[button setGraphiteStyle:UIBarButtonItemStylePlain miniBar:miniBar];
				
				if(miniBar) {
					[button setImage:[UIImage imageNamed:@"smallBookmarks.png"] forState:UIControlStateNormal];
				} else {
					[button setImage:[UIImage imageNamed:@"bookmarks.png"] forState:UIControlStateNormal];
				}
				
				if(!self.title) {
					self.title = NSLocalizedString(@"SFBarButtonAppItemBookmarks", @"");
				}
			} break;
			
			case SFBarButtonAppItemNavigateBack: {
				[button setGraphiteStyle:UIBarButtonItemStylePlain miniBar:miniBar];
				
				if(miniBar) {
					[button setImage:[UIImage imageNamed:@"smallNavigateBack.png"] forState:UIControlStateNormal];
				} else {
					[button setImage:[UIImage imageNamed:@"navigateBack.png"] forState:UIControlStateNormal];
				}
				
				if(!self.title) {
					self.title = NSLocalizedString(@"SFBarButtonAppItemNavigateBack", @"");
				}
			} break;
			
			case SFBarButtonAppItemNavigateForward: {
				[button setGraphiteStyle:UIBarButtonItemStylePlain miniBar:miniBar];
				
				if(miniBar) {
					[button setImage:[UIImage imageNamed:@"smallNavigateForward.png"] forState:UIControlStateNormal];
				} else {
					[button setImage:[UIImage imageNamed:@"navigateForward.png"] forState:UIControlStateNormal];
				}
				
				if(!self.title) {
					self.title = NSLocalizedString(@"SFBarButtonAppItemNavigateForward", @"");
				}
			} break;

			case SFBarButtonAppItemLocalizations: {
				[button setGraphiteStyle:UIBarButtonItemStylePlain miniBar:miniBar];
				
				if(miniBar) {
					[button setImage:[UIImage imageNamed:@"smallLanguagesButtonItem.png"] forState:UIControlStateNormal];
				} else {
					[button setImage:[UIImage imageNamed:@"languagesButtonItem.png"] forState:UIControlStateNormal];
				}
				
				if(!self.title) {
					self.title = NSLocalizedString(@"SFBarButtonAppItemLocalizations", @"");
				}
			} break;
			
			case SFBarButtonAppItemChapters: {
				[button setGraphiteStyle:UIBarButtonItemStylePlain miniBar:miniBar];
				
				if(miniBar) {
					[button setImage:[UIImage imageNamed:@"smallTOCButtonItem.png"] forState:UIControlStateNormal];
				} else {
					[button setImage:[UIImage imageNamed:@"TOCButtonItem.png"] forState:UIControlStateNormal];
				}
				
				if(!self.title) {
					self.title = NSLocalizedString(@"SFBarButtonAppItemChapters", @"");
				}
			} break;
			
			case SFBarButtonAppItemTabs: {
				[button setGraphiteStyle:UIBarButtonItemStylePlain miniBar:miniBar];
				
				NSString* tabIndex = [self tag] >= 2 && [self tag] <= 9 ?
					[NSString stringWithFormat:@"%02ld", (long)[self tag]] :
					@"";
				NSString* imageName = miniBar ?
					[NSString stringWithFormat:@"smallNavigationTab%@.png", tabIndex] :
					[NSString stringWithFormat:@"navigationTab%@.png", tabIndex];
				
				[button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
				
				if(!self.title) {
					self.title = NSLocalizedString(@"SFBarButtonAppItemTabs", @"");
				}
			} break;

			case SFBarButtonAppItemSearch: {
				[button setGraphiteStyle:UIBarButtonItemStylePlain miniBar:miniBar];

				if(miniBar) {
					[button setImage:[UIImage imageNamed:@"smallDocumentSearch.png"] forState:UIControlStateNormal];
				} else {
					[button setImage:[UIImage imageNamed:@"documentSearch.png"] forState:UIControlStateNormal];
				}
				
				if(!self.title) {
					self.title = NSLocalizedString(@"SFBarButtonAppItemSearch", @"");
				}
			} break;

			default: {
			} break;
		}
	} else {
		[button setGraphiteStyle:[self style] miniBar:miniBar];
	}
	
	[button setEnabled:[self isEnabled]];

	[button sizeToFit];

	_interfaceStyle = interfaceStyle;
	_controlSize = controlSize;
	_needsInitialization = NO;
}

- (void)didLayoutForBarView:(id)barView {
	if(CGRectGetHeight([barView bounds]) < 44.0) { return; }

	BOOL shouldOffset = NO;

	if(_needsAutomaticButtonStyling) {
		if(_appItem == SFBarButtonAppItemDone ||
		   _appItem == SFBarButtonAppItemCancel ||
		   _appItem == SFBarButtonAppItemEdit ||
		   _appItem == SFBarButtonAppItemSave) {
			shouldOffset = YES;
		}
	} else {
		shouldOffset = YES;
	}

	if(shouldOffset) {
		self.customView.frame = CGRectOffset([[self customView] frame], 0.0, 1.0);
	}
}

- (UIImage*)previewImageForCustomization {
	// TODO: Make this a bit more cleverere
	return [(UIButton*)[self customView] imageForState:UIControlStateNormal];
}

@end
