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

#import "SFEditableTableViewCell.h"
#import "SFEditableTableViewCell+Private.h"

@implementation SFEditableTableViewCell

@synthesize textField = _textField;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier {
	// We don't just init, we initWithStyle!
    if(self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier]) {
		self.selectionStyle = UITableViewCellSelectionStyleNone;

		[self initTextField];
		[self initKeyValueObservers];
	}

    return self;
}


#pragma mark -
#pragma mark UIView

- (void)layoutSubviews {
	[super layoutSubviews];
	
	// We show the textfield instead
	self.detailTextLabel.hidden = YES;
	
	// Now layout our textfield
	CGRect contentRect = self.bounds;
	CGRect textRect = self.textLabel.frame;
	
	textRect.size.width = MAX(textRect.size.width, 110.0); // TODO

	CGFloat const margin = 10.0;
	
	CGFloat minX = CGRectIsEmpty(textRect) ?
		CGRectGetMinX(contentRect) :
		CGRectGetMaxX(textRect);
	
	CGSize textfieldSize = [[self textField]
		sizeThatFits:contentRect.size];
		
	CGRect textfieldRect = CGRectMake(
		floorf(minX + margin),
		roundf(CGRectGetMidY(contentRect) - textfieldSize.height * 0.5) - 1.0,
		roundf(CGRectGetMaxX(contentRect) - minX - margin * 3.0),
		textfieldSize.height);
	
	self.textField.frame = textfieldRect;
	
	self.textLabel.frame = textRect;
}

#pragma mark -
#pragma mark Private

- (void)initTextField {
	SFTextField* textField = [[SFTextField alloc] initWithFrame:CGRectZero];
		
	textField.borderStyle = UITextBorderStyleNone;
	textField.clearButtonMode = UITextFieldViewModeWhileEditing;
	
	//textfield.font = self.detailTextLabel.font;
	textField.textColor = self.detailTextLabel.textColor;
		
	[[self contentView] addSubview:textField];
		
	self.textField = textField;
}

- (void)initKeyValueObservers {
}

@end
