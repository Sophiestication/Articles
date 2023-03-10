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

#import "SAReadLaterTableViewCell.h"
#import "SAReadLaterTableViewCell+Private.h"

#import "SAReadLaterTableViewCellContentView.h"

#import <QuartzCore/QuartzCore.h>

@implementation SAReadLaterTableViewCell

@synthesize textView = _textView;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier {
    if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
		[self initSubviews];
    }

    return self;
}


#pragma mark -
#pragma mark UIView

- (CGSize)sizeThatFits:(CGSize)size {
	CGSize contentSize = [[self textView]
		sizeThatFits:CGSizeMake(size.width, 480.0)];
	
	size = CGSizeMake(size.width, contentSize.height);
	
	return size;
}

- (void)layoutSubviews {
	[super layoutSubviews];

	self.textView.frame = self.contentView.bounds;
}

#pragma mark -
#pragma mark UITableViewCell

- (void)willTransitionToState:(UITableViewCellStateMask)state {
	[super willTransitionToState:state];
	
	CATransition* transition = [CATransition animation];
	
	transition.type = kCATransitionFade;
	transition.duration = 0.2;

	[[[self textView] layer] addAnimation:transition forKey:@"tableViewCellTransition"];
}

- (void)didTransitionToState:(UITableViewCellStateMask)state {
	[super didTransitionToState:state];
}

#pragma mark -
#pragma mark Private

- (void)initSubviews {
	SAReadLaterTableViewCellContentView* textView = [[SAReadLaterTableViewCellContentView alloc] initWithFrame:CGRectZero];
	
	self.textView = textView;
	[[self contentView] addSubview:textView];
}

@end
