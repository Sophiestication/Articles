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

#import "UIButton+Graphite.h"

@implementation UIButton(Graphite)

- (void)setGraphiteStyle:(UIBarButtonItemStyle)style miniBar:(BOOL)miniBar systemItem:(UIBarButtonSystemItem)systemItem {
	[self setGraphiteStyle:style miniBar:miniBar];
	
	if(systemItem == UIBarButtonSystemItemDone) {
		NSString* title = NSLocalizedString(@"UIBarButtonSystemItemDone", @"Title for the Done system bar button item");
		[self setTitle:title forState:UIControlStateNormal];
	} else if(systemItem == UIBarButtonSystemItemEdit) {
		NSString* title = NSLocalizedString(@"UIBarButtonSystemItemEdit", @"Title for the Edit system bar button item");
		[self setTitle:title forState:UIControlStateNormal];
	} else if(systemItem == UIBarButtonSystemItemSave) {
		NSString* title = NSLocalizedString(@"UIBarButtonSystemItemSave", @"Title for the Save system bar button item");
		[self setTitle:title forState:UIControlStateNormal];
	} else if(systemItem == UIBarButtonSystemItemCancel) {
		NSString* title = NSLocalizedString(@"UIBarButtonSystemItemCancel", @"Title for the Cancel system bar button item");
		[self setTitle:title forState:UIControlStateNormal];
	} else if(systemItem == UIBarButtonSystemItemAdd) {
		[self setImage:[UIImage imageNamed:@"addBarButtonImage.png"] forState:UIControlStateNormal];
		[self setImage:[UIImage imageNamed:@"addBarButtonImageHighlighted.png"] forState:UIControlStateHighlighted];
	} else if(systemItem == UIBarButtonSystemItemAction) {
		[self setImage:[UIImage imageNamed:@"actionBarButtonImage.png"] forState:UIControlStateNormal];
		[self setImage:[UIImage imageNamed:@"actionBarButtonImageHighlighted.png"] forState:UIControlStateHighlighted];
	} else if(systemItem == UIBarButtonSystemItemOrganize) {
		[self setImage:[UIImage imageNamed:@"organizeBarButtonImage.png"] forState:UIControlStateNormal];
		[self setImage:[UIImage imageNamed:@"organizeBarButtonImageHighlighted.png"] forState:UIControlStateHighlighted];
	} else if(systemItem == UIBarButtonSystemItemTrash) {
		[self setImage:[UIImage imageNamed:@"trashBarButtonImage.png"] forState:UIControlStateNormal];
		[self setImage:[UIImage imageNamed:@"trashBarButtonImage.png"] forState:UIControlStateHighlighted];
	}
	
	[self sizeToFit];
}

- (void)setGraphiteStyle:(UIBarButtonItemStyle)style miniBar:(BOOL)miniBar {
	// Setup the button background
	UIImage* backgroundImage = nil;
	UIImage* highlightedBackgroundImage = nil;
	UIImage* disabledBackgroundImage = nil;

	if(style == UIBarButtonItemStyleBordered) {
		if(miniBar) {
			backgroundImage = [[UIImage imageNamed:@"graphiteMiniBarButtonBackground.png"]
				stretchableImageWithLeftCapWidth:4.0 topCapHeight:0.0];
			highlightedBackgroundImage = [[UIImage imageNamed:@"graphiteMiniBarButtonBackgroundHighlighted.png"]
				stretchableImageWithLeftCapWidth:4.0 topCapHeight:0.0];
			disabledBackgroundImage = [[UIImage imageNamed:@"graphiteMiniBarButtonBackgroundDisabled.png"]
				stretchableImageWithLeftCapWidth:4.0 topCapHeight:0.0];
		} else {
			backgroundImage = [[UIImage imageNamed:@"graphiteBarButtonBackground.png"]
				stretchableImageWithLeftCapWidth:4.0 topCapHeight:0.0];
			highlightedBackgroundImage = [[UIImage imageNamed:@"graphiteBarButtonBackgroundHighlighted.png"]
				stretchableImageWithLeftCapWidth:4.0 topCapHeight:0.0];
			disabledBackgroundImage = [[UIImage imageNamed:@"graphiteBarButtonBackgroundDisabled.png"]
				stretchableImageWithLeftCapWidth:4.0 topCapHeight:0.0];
		}
		
		self.showsTouchWhenHighlighted = NO;
		self.adjustsImageWhenDisabled = NO;
		self.adjustsImageWhenHighlighted = NO;
	} else if(style == UIBarButtonItemStyleDone) {
		if(miniBar) {
			backgroundImage = [[UIImage imageNamed:@"graphiteMiniDoneBarButtonBackground.png"]
				stretchableImageWithLeftCapWidth:4.0 topCapHeight:0.0];
			highlightedBackgroundImage = [[UIImage imageNamed:@"graphiteMiniDoneBarButtonBackgroundHighlighted.png"]
				stretchableImageWithLeftCapWidth:4.0 topCapHeight:0.0];
		} else {
			backgroundImage = [[UIImage imageNamed:@"graphiteDoneBarButtonBackground.png"]
				stretchableImageWithLeftCapWidth:4.0 topCapHeight:15.0];
			highlightedBackgroundImage = [[UIImage imageNamed:@"graphiteDoneBarButtonBackgroundHighlighted.png"]
				stretchableImageWithLeftCapWidth:4.0 topCapHeight:15.0];
		}
		
		self.showsTouchWhenHighlighted = NO;
	} else if(style == UIBarButtonItemStylePlain) {
		self.showsTouchWhenHighlighted = YES;
	}

	[self setBackgroundImage:backgroundImage forState:UIControlStateNormal];
	[self setBackgroundImage:highlightedBackgroundImage forState:UIControlStateHighlighted];
	
	if(disabledBackgroundImage) {
		[self setBackgroundImage:disabledBackgroundImage forState:UIControlStateDisabled];
	}

	// Setup the text label
	UIColor* titleColor = nil;
	UIColor* highlightedTitleColor = nil;
	UIColor* disabledTitleColor = nil;

	if(style == UIBarButtonItemStyleDone) {
		highlightedTitleColor = titleColor = [UIColor whiteColor];
		
		[self setTitleShadowColor:[[UIColor blackColor] colorWithAlphaComponent:1.0 / 3.0] forState:UIControlStateNormal];
		
		self.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
		self.reversesTitleShadowWhenHighlighted = NO;
	} else {
		titleColor = [UIColor colorWithRed:69.0 / 256.0 green:90.0 / 256.0 blue:119.0 / 256.0 alpha:1.0];
		disabledTitleColor = [titleColor colorWithAlphaComponent:0.5];
		highlightedTitleColor = [UIColor whiteColor];
		
		[self setTitleShadowColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5] forState:UIControlStateNormal];
		[self setTitleShadowColor:[[UIColor whiteColor] colorWithAlphaComponent:1.0 / 3.0] forState:UIControlStateDisabled];
		[self setTitleShadowColor:[[UIColor blackColor] colorWithAlphaComponent:1.0 / 3.0] forState:UIControlStateHighlighted];
		
		self.titleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
		self.reversesTitleShadowWhenHighlighted = YES;
	}

	[self setTitleColor:titleColor forState:UIControlStateNormal];
	[self setTitleColor:highlightedTitleColor forState:UIControlStateHighlighted];
	
	if(disabledTitleColor) {
		[self setTitleColor:disabledTitleColor forState:UIControlStateDisabled];
	}	
	
	self.titleLabel.font = [UIFont boldSystemFontOfSize:miniBar ?
		12.0 :
		13.5];
	self.contentEdgeInsets = UIEdgeInsetsMake(0.0, 11.0, 0.0, 10.0);
	
	self.opaque = NO;
	self.backgroundColor = [UIColor clearColor];
	self.alpha = 1.0;
	
	[self sizeToFit];
}

- (void)setGraphiteBackStyle:(BOOL)miniBar {
	[self setGraphiteStyle:UIBarButtonItemStyleBordered miniBar:miniBar];
	
	UIImage* backgroundImage = nil;
	UIImage* highlightedBackgroundImage = nil;
	UIImage* disabledBackgroundImage = nil;
	
	if(miniBar) {
		backgroundImage = [[UIImage imageNamed:@"graphiteMiniBackBarButtonBackground.png"]
			stretchableImageWithLeftCapWidth:15.0 topCapHeight:0.0];
		highlightedBackgroundImage = [[UIImage imageNamed:@"graphiteMiniBackBarButtonBackgroundHighlighted.png"]
			stretchableImageWithLeftCapWidth:15.0 topCapHeight:0.0];
		disabledBackgroundImage = nil;
	} else {
		backgroundImage = [[UIImage imageNamed:@"graphiteBackBarButtonBackground.png"]
			stretchableImageWithLeftCapWidth:20.0 topCapHeight:0.0];
		highlightedBackgroundImage = [[UIImage imageNamed:@"graphiteBackBarButtonBackgroundHighlighted.png"]
			stretchableImageWithLeftCapWidth:20.0 topCapHeight:0.0];
		disabledBackgroundImage = nil;
	}
	
	[self setBackgroundImage:backgroundImage forState:UIControlStateNormal];
	[self setBackgroundImage:highlightedBackgroundImage forState:UIControlStateHighlighted];
	
	if(disabledBackgroundImage) {
		[self setBackgroundImage:disabledBackgroundImage forState:UIControlStateDisabled];
	}
	
	UIImage* backImage = miniBar ?
		[UIImage imageNamed:@"back.png"] :
		[UIImage imageNamed:@"back.png"];
	[self setImage:backImage forState:UIControlStateNormal];
		
	UIImage* highlightedBackImage = miniBar ?
		[UIImage imageNamed:@"backHighlighted.png"] :
		[UIImage imageNamed:@"backHighlighted.png"];
	[self setImage:highlightedBackImage forState:UIControlStateHighlighted];

//	[self setTitle:NSLocalizedString(@"BARBUTTON_ITEM_BACK", @"") forState:UIControlStateNormal];
	
	UIEdgeInsets contentEdgeInsets = self.contentEdgeInsets;
	contentEdgeInsets.left += 3.0;
	self.contentEdgeInsets = contentEdgeInsets;
	
	[self sizeToFit];
}

@end
