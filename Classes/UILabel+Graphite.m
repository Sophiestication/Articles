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

#import "UILabel+Graphite.h"

@implementation UILabel(Graphite)

+ (UILabel*)graphiteNavigationBarLabelWithText:(NSString*)text {
	UILabel* label = [[UILabel alloc] initWithFrame:CGRectZero];
	
	label.text = text;

	[label setGraphiteStyle];
	
	label.font = [UIFont boldSystemFontOfSize:20.0];
	label.minimumScaleFactor = 0.8;
	
	[label sizeToFit];
	
	return label;
}

- (void)setGraphiteStyle {
	self.backgroundColor = [UIColor clearColor];
	self.opaque = NO;
	
	self.textColor = [UIColor colorWithRed:69.0 / 256.0 green:90.0 / 256.0 blue:119.0 / 256.0 alpha:1.0];
	self.highlightedTextColor = [UIColor whiteColor];
	
	self.textAlignment = NSTextAlignmentCenter;
	
	self.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
	
	self.shadowColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
	self.shadowOffset = CGSizeMake(0.0, 1.0);
	
	self.adjustsFontSizeToFitWidth = YES;
	self.font = [UIFont boldSystemFontOfSize:13.5];
}

@end
