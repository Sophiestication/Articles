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

#import "SFNavigationBar.h"

#import "SFBarButtonItem.h"
#import "SFBarButtonItem+Private.h"

@interface UINavigationBar(UIKitPrivate)

- (void)_setHidesShadow:(BOOL)hidesShadow;

@end

@implementation SFNavigationBar

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		[self initBackgroundImages];
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder*)coder {
	if((self = [super initWithCoder:coder])) {
		[self initBackgroundImages];
	}
	
	return self;
}

#pragma mark - UIView

- (void)layoutSubviews {
	// Update all SFBarButtonItems if needed
	for(UIBarButtonItem* item in self.items) {
		if([item respondsToSelector:@selector(layoutForBarViewIfNeeded:)]) {
			[(SFBarButtonItem*)item layoutForBarViewIfNeeded:self];
		}
	}
	
	[super layoutSubviews];
}

#pragma mark - Private

- (void)initBackgroundImages {
	[self setBackgroundImage:[UIImage imageNamed:@"graphiteNavigationBarBackground.png"]
		forBarMetrics:UIBarMetricsDefault];

//	if([self respondsToSelector:@selector(setShadowImage:forToolbarPosition:)]) {
//		[self setShadowImage:
//			[UIImage imageNamed:@"whitespace.png"]
//			forToolbarPosition:UIToolbarPositionBottom];
//	}

	SEL hidesShadowSelector = NSSelectorFromString([NSString stringWithFormat:@"_%@%@:", @"set", @"HidesShadow"]);

	if([self respondsToSelector:hidesShadowSelector]) {
		NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:
     		[(id)self methodSignatureForSelector:hidesShadowSelector]];
     	[invocation setSelector:hidesShadowSelector];
    	[invocation setTarget:self];

		BOOL hidesShadow = YES;
		[invocation setArgument:&hidesShadow atIndex:2];

		[invocation invoke];
	}
}

@end
