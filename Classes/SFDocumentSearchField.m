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

#import "SFDocumentSearchField.h"
#import "SFDocumentSearchField+Private.h"

@implementation SFDocumentSearchField

@synthesize controlSize = _controlSize;
@synthesize iPadInterfaceIdiom = _iPadInterfaceIdiom;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
		[self initIvars];
//		[self initSearchIndicatorView];
	}

    return self;
}


#pragma mark - SFDocumentSearchField

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

#pragma mark - UITextField

- (CGRect)borderRectForBounds:(CGRect)bounds {
	CGRect rect =  [super borderRectForBounds:bounds];
	
	CGFloat borderHeight = self.background.size.height;
	rect.size.height = borderHeight;
	rect.origin.y = floorf(CGRectGetMidY(bounds) - borderHeight * 0.5 + 1.0);
	
	return rect;
}

- (CGRect)textRectForBounds:(CGRect)bounds {
	CGRect rect =  [super textRectForBounds:bounds];
	
	rect.size.width -= 10.0;
	
	if(self.iPadInterfaceIdiom) {
		rect.size.height = 40.0;
		rect.origin.y += 5.0;
	}
	
	rect = CGRectOffset(rect, 12.0, 6.0);
	
	if(self.controlSize == SFMiniControlSize) {
		rect = CGRectOffset(rect, 0.0, 1.0);
	}
	
	return rect;
}

- (CGRect)placeholderRectForBounds:(CGRect)bounds {
	CGRect rect = [super placeholderRectForBounds:bounds];

//	if(self.controlSize == SFMiniControlSize) {
//		rect = CGRectOffset(rect, 0.0, 1.0);
//	}
	
	return rect;
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
	CGRect rect =  [super editingRectForBounds:bounds];
	
	if(self.iPadInterfaceIdiom) {
		rect.size.height = 40.0;
		rect.origin.y += 5.0;
	}
	
	rect = CGRectOffset(rect, 12.0, 6.0);
	
	if(self.controlSize == SFMiniControlSize) {
		rect = CGRectOffset(rect, 0.0, 1.0);
	}
	
	return rect;
}

- (CGRect)clearButtonRectForBounds:(CGRect)bounds {
	return [super clearButtonRectForBounds:bounds];
}

- (CGRect)leftViewRectForBounds:(CGRect)bounds {
	CGRect rect = [super leftViewRectForBounds:bounds];
	
	rect = CGRectOffset(rect, 5.0, 0.0);
	
	return rect;
}

- (CGRect)rightViewRectForBounds:(CGRect)bounds {
	CGRect rect =  [super rightViewRectForBounds:bounds];

	rect = CGRectOffset(rect, -5.0, 0.0);
	
//	if(self.controlSize == SFMiniControlSize) {
//		rect = CGRectOffset(rect, 0.0, 1.0);
//	}

	return rect;
}

#pragma mark - Private

- (void)initIvars {
	self.iPadInterfaceIdiom = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
	
	self.placeholder = NSLocalizedString(@"FIND_MENUITEM", @"");

	self.clearButtonMode = UITextFieldViewModeWhileEditing;
	
	self.autocorrectionType = UITextAutocorrectionTypeNo;
	self.returnKeyType = UIReturnKeySearch;

	self.enablesReturnKeyAutomatically = YES;
	
	[self updateForControlSize:SFRegularControlSize];
}

- (void)initSearchIndicatorView {
	UIImage* searchIndicatorImage = [UIImage imageNamed:@"searchFieldIndicator.png"];
	UIImageView* searchIndicatorView = [[UIImageView alloc] initWithImage:searchIndicatorImage];
	
	self.leftView = searchIndicatorView;
	self.leftViewMode = UITextFieldViewModeAlways;
	
	searchIndicatorView.backgroundColor = [UIColor orangeColor];
}

- (void)updateForControlSize:(SFControlSize)controlSize {
	UIImage* backgroundImage = nil;
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.font = [UIFont systemFontOfSize:15.0];

		backgroundImage = [[UIImage imageNamed:@"searchBarBorderInline.png"]
			stretchableImageWithLeftCapWidth:16.0 topCapHeight:0.0];
	} else if(controlSize == SFMiniControlSize) {
		self.font = [UIFont systemFontOfSize:14.0];
	
		backgroundImage = [[UIImage imageNamed:@"documentSearchFieldSmallBackground.png"]
			stretchableImageWithLeftCapWidth:12.0 topCapHeight:0.0];
	} else {
		self.font = [UIFont systemFontOfSize:15.0];

		backgroundImage = [[UIImage imageNamed:@"documentSearchFieldBackground.png"]
			stretchableImageWithLeftCapWidth:16.0 topCapHeight:0.0];
	}

	self.background = backgroundImage;
	
	[[self rightView] setNeedsLayout];
}

@end
