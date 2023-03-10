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

#import "SFToolbar.h"

#import "SFBarButtonItem.h"
#import "SFBarButtonItem+Private.h"

#import "UIBarButtonItem+Additions.h"

@implementation SFToolbar

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		[self initIvars];
		[self initBackgroundImages];
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder*)coder {
	if((self = [super initWithCoder:coder])) {
		[self initIvars];
		[self initBackgroundImages];
	}
	
	return self;
}

#pragma mark -
#pragma mark UIView

- (void)layoutSubviews {
	// Update all SFBarButtonItems if needed
	for(UIBarButtonItem* item in self.items) {
		if([item respondsToSelector:@selector(layoutForBarViewIfNeeded:)]) {
			[(SFBarButtonItem*)item layoutForBarViewIfNeeded:self];
		}
	}
	
	[super layoutSubviews];

	for(UIBarButtonItem* item in self.items) {
		if([item respondsToSelector:@selector(didLayoutForBarView:)]) {
			[(SFBarButtonItem*)item didLayoutForBarView:self];
		}
	}
}

#pragma mark -
#pragma mark Private

- (void)initIvars {
	// self.clipsToBounds = NO;
}

- (void)initBackgroundImages {
	[self setBackgroundImage:
		[UIImage imageNamed:@"graphiteToolbarBackground.png"]
		forToolbarPosition:UIToolbarPositionBottom
		barMetrics:UIBarMetricsDefault];
	[self setBackgroundImage:
		[UIImage imageNamed:@"graphiteMiniToolbarBackground.png"]
		forToolbarPosition:UIToolbarPositionBottom
		barMetrics:UIBarMetricsLandscapePhone];

	if([self respondsToSelector:@selector(setShadowImage:forToolbarPosition:)]) {
		[self setShadowImage:
			[UIImage imageNamed:@"whitespace.png"]
			forToolbarPosition:UIToolbarPositionBottom];
	}
}

@end
