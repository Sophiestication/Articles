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

#import "UIColor+Additions.h"

@implementation UIColor(Additions)

+ (UIColor*)alternateTableViewCellTextColor {
	static UIColor* _alternateTableViewCellTextColor = nil;

	if(!_alternateTableViewCellTextColor) {
		_alternateTableViewCellTextColor = [[UIColor alloc] initWithRed:(55.0 / 0xff) green:(116.0 / 0xff) blue:(215.0 / 0xff) alpha:1.0];
	}
	
	return _alternateTableViewCellTextColor;
}

+ (UIColor*)otherTableViewCellTextColor {
	static UIColor* _otherTableViewCellTextColor = nil;

	if(!_otherTableViewCellTextColor) {
		_otherTableViewCellTextColor = [[UIColor alloc] initWithRed:(140.0 / 0xff) green:(153.0 / 0xff) blue:(180.0 / 0xff) alpha:1.0];
	}
	
	return _otherTableViewCellTextColor;
}

+ (UIColor*)alternateButtonTextColor {
	static UIColor* _alternateButtonTextColor = nil;
	
	if(!_alternateButtonTextColor) {
		_alternateButtonTextColor = [[UIColor alloc] initWithRed:(50.0 / 0xff) green:(79.0 / 0xff) blue:(133.0 / 0xff) alpha:1.0];
	}
	
	return _alternateButtonTextColor;
}

+ (UIColor*)checkedTableViewCellBackgroundColor {
	static UIColor* _checkedTableViewCellBackgroundColor = nil;
	
	if(!_checkedTableViewCellBackgroundColor) {
		_checkedTableViewCellBackgroundColor = [[UIColor alloc] initWithRed:(233.0 / 0xff) green:(240.0 / 0xff) blue:(250.0 / 0xff) alpha:1.0];
	}
	
	return _checkedTableViewCellBackgroundColor;
}

@end
