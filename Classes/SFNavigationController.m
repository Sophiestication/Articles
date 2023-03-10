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

#import "SFNavigationController.h"

#import	"SFNavigationBar.h"
#import "SFToolbar.h"

@implementation SFNavigationController

- (instancetype)initWithNavigationBarClass:(Class)navigationBarClass toolbarClass:(Class)toolbarClass {
	if((self = [super initWithNavigationBarClass:[SFNavigationBar class] toolbarClass:[SFToolbar class]])) {
	}

	return self;
}

- (id)initWithRootViewController:(UIViewController*)rootViewController {
	if((self = [super initWithNavigationBarClass:[SFNavigationBar class] toolbarClass:[SFToolbar class]])) {
		[self pushViewController:rootViewController animated:NO];
	}

	return self;
}

- (void)loadView {
	[super loadView];

	if([self respondsToSelector:@selector(initWithNavigationBarClass:toolbarClass:)]) { return; } // no need for custom setup on iOS 6
	
	SEL setNavigationBarSelector = NSSelectorFromString(@"setNavigationBar:");
	
	if([self respondsToSelector:setNavigationBarSelector]) {
		SFNavigationBar* navigationBar = [[SFNavigationBar alloc] initWithFrame:CGRectZero];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		[self performSelector:setNavigationBarSelector withObject:navigationBar];
#pragma clang diagnostic pop
	}
	
	SEL setToolbarSelector = NSSelectorFromString(@"setToolbar:");
	
	if([self respondsToSelector:setToolbarSelector]) {
		SFToolbar* toolbar = [[SFToolbar alloc] initWithFrame:CGRectZero];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		[self performSelector:setToolbarSelector withObject:toolbar];
#pragma clang diagnostic pop
	}
}

@end
