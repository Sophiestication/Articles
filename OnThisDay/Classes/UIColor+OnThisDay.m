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

#import "UIColor+OnThisDay.h"

@implementation UIColor(Additions)

+ (UIColor*)calendarTextColor {
	static UIColor* _calendarTextColor = nil;
	
	if(!_calendarTextColor) {
		_calendarTextColor = [[UIColor alloc] initWithRed:1.929 green:0.907 blue:0.852 alpha:1.0];
	}
	
	return _calendarTextColor;
}

+ (UIColor*)calendarFlipsideTextColor {
	static UIColor* _calendarFlipsideTextColor = nil;
	
	if(!_calendarFlipsideTextColor) {
		_calendarFlipsideTextColor = [[UIColor alloc] initWithRed:1.0 green:0.975 blue:0.875 alpha:1.0];
	}

	return _calendarFlipsideTextColor;
}

@end
