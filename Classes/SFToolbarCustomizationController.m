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

#import "SFToolbarCustomizationController.h"
#import "SFToolbarCustomizationController+Private.h"

#import "SFToolbarCustomizationView.h"
#import "SFToolbarCustomizationView+Private.h"

#import "SFBarButtonItem.h"
#import "SFBarButtonItem+Private.h"

#import "SFBarButtonItemWell.h"

@implementation SFToolbarCustomizationController

@dynamic customizing;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithToolbar:(SFToolbar*)toolbar {
	if((self = [super init])) {
		self.toolbar = toolbar;

		[self initIvars];
		[self initObserver];
		[self initCustomizationViewIfNeeded];
	}
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[[self customizationView] removeFromSuperview];
	
	self.toolbar = nil;
	self.delegate = nil;
}

#pragma mark -
#pragma mark SFToolbarCustomizationController

- (BOOL)isCustomizing {
	return _customizing;
}

- (void)beginCustomizingItems:(NSArray*)items fromRect:(CGRect)rect inView:(UIView*)view animated:(BOOL)animated {
	[self beginCustomizingItems:items fromBarButtonItem:nil animated:animated]; // TODO
}

- (void)beginCustomizingItems:(NSArray*)items fromBarButtonItem:(UIBarButtonItem*)buttonItem animated:(BOOL)animated {
	if([self isCustomizing]) { return; }
	
	_customizing = YES;
	
	self.toolbarItems = items;
	
	// Make sure all items are set up
	for(SFBarButtonItem* item in items) {
		if(![[[self toolbar] items] containsObject:item]) {
			[item layoutForBarViewIfNeeded:[self toolbar]];
		}
	}

	[self initCustomizationViewIfNeeded];
	
	CGRect customizationViewRect = self.customizationView.frame;
	
	self.customizationView.frame = CGRectOffset(
		self.customizationView.frame,
		0.0,
		CGRectGetHeight(self.customizationView.frame));
	
	id animations = ^() {
		self.customizationView.hidden = NO;
		self.customizationView.frame = customizationViewRect;
	};
	
	id completion = ^() {
		[[[self customizationView] superview] bringSubviewToFront:[self customizationView]];
		self.customizationView.wigglesToolbarItems = YES;
		
		if([[self delegate] respondsToSelector:@selector(toolbarCustomizationControllerDidAppear:)]) {
			[[self delegate] toolbarCustomizationControllerDidAppear:self];
		}
	};
	
	if([[self delegate] respondsToSelector:@selector(toolbarCustomizationControllerWillAppear:)]) {
		[[self delegate] toolbarCustomizationControllerWillAppear:self];
	}
	
	CGFloat duration = animated ?
		0.4 :
		0.0;
	
	[UIView
		animateWithDuration:duration
		delay:0.0
		options:UIViewAnimationOptionCurveEaseInOut
		animations:animations
		completion:completion];
}

- (void)endCustomizingAnimated:(BOOL)animated {
	if(![self isCustomizing]) { return; }
	
	// Let the toolbar layout our items again
	self.customizationView.wigglesToolbarItems = NO;
	
	if([[self delegate] respondsToSelector:@selector(toolbarCustomizationControllerWillHide:)]) {
		[[self delegate] toolbarCustomizationControllerWillHide:self];
	}
	
	id animations = ^() {
		[[[self customizationView] superview]
			insertSubview:[self customizationView]
			belowSubview:[self toolbar]];
		
		self.customizationView.frame = CGRectOffset(
			self.customizationView.frame,
			0.0,
			CGRectGetHeight(self.customizationView.frame));
	};
	
	id completion = ^() {
		_customizing = NO;
		self.customizationView.hidden = YES;
		
		if([[self delegate] respondsToSelector:@selector(toolbarCustomizationControllerDidHide:)]) {
			[[self delegate] toolbarCustomizationControllerDidHide:self];
		}
		
		self.toolbarItems = nil;
	};
	
	CGFloat duration = animated ?
		0.4 :
		0.0;
	
	[UIView
		animateWithDuration:duration
		delay:0.0
		options:UIViewAnimationOptionCurveEaseInOut
		animations:animations
		completion:completion];
}

#pragma mark -
#pragma mark Private

- (void)initIvars {
	_customizing = NO;
}

- (void)initObserver {
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(applicationDidChangeStatusBarOrientation:)
		name:UIApplicationDidChangeStatusBarOrientationNotification
		object:nil];
}

- (void)initCustomizationViewIfNeeded {
	if(self.customizationView) { return; }
	
	SFToolbarCustomizationView* customizationView = [[SFToolbarCustomizationView alloc] initWithCustomizationController:self];
	
	[[[self toolbar] superview]
		bringSubviewToFront:[self toolbar]];
	[[[self toolbar] superview]
		insertSubview:customizationView
		belowSubview:[self toolbar]];

	self.customizationView = customizationView;
	
	[self layoutCustomizationView];
}

- (void)layoutCustomizationView {
	CGRect toolbarRect = self.toolbar.frame;
	
	CGSize customizationViewSize = [[self customizationView]
		sizeThatFits:CGSizeZero];
	
	CGRect customizationViewRect = CGRectMake(
		CGRectGetMinX(toolbarRect),
		CGRectGetMaxY(toolbarRect) - customizationViewSize.height,
		customizationViewSize.width,
		customizationViewSize.height);
		
	self.customizationView.frame = customizationViewRect;
}

- (void)applicationDidChangeStatusBarOrientation:(NSNotification*)notification {
	[self performSelector:@selector(layoutCustomizationView)
		withObject:nil
		afterDelay:0.0];
}

@end
