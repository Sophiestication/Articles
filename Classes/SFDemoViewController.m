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

#import "SFDemoViewController.h"
#import "SFDemoViewController+Private.h"

@implementation SFDemoViewController

@synthesize window = _window;
@synthesize view = _view;
@synthesize imageView = _imageView;
@synthesize interfaceOrientation = _interfaceOrientation;

#pragma mark -
#pragma mark Construction & Destruction

+ (id)demoController {
	return [[self alloc] init];
}

- (id)init {
	if(self = [super init]) {
		[self initIvars];
		[self initWindow];
		[self initView];
		[self initObservers];
	}
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];


}

#pragma mark -
#pragma mark SFDemoViewController

- (void)present:(id)sender {

	[self updateForInterfaceOrientation:[self interfaceOrientation]];
	
	[[self window] makeKeyAndVisible];
	
	[UIView beginAnimations:@"presentDemoViewAnimation" context:NULL]; {
		
		[UIView setAnimationDuration:0.5];
	
		self.view.alpha = 1.0;
	
	} [UIView commitAnimations];
}

- (void)dismiss:(id)sender {
	[UIView beginAnimations:@"demoViewDismissAnimation" context:NULL]; {
		
		[UIView setAnimationDuration:0.5];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(dismissAnimationDidStop:finished:context:)];
	
		self.view.alpha = 0.0;
	
	} [UIView commitAnimations];
}

#pragma mark -
#pragma mark Private

- (void)initIvars {
	self.interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
}

- (void)initWindow {
	CGRect windowRect = [[UIScreen mainScreen] bounds];
	UIWindow* window = [[UIWindow alloc] initWithFrame:windowRect];
	
	window.windowLevel = UIWindowLevelAlert;

	window.backgroundColor = [UIColor clearColor];
	window.opaque = NO;
	
	self.window = window;
}

- (void)initView {
	CGRect windowRect = self.window.bounds;

	// ...
	UIView* dimmingView = [[UIView alloc] initWithFrame:windowRect];
	
	dimmingView.opaque = NO;
	dimmingView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
	
	dimmingView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;

	dimmingView.alpha = 0.0;

	// ...
	UIImage* image = [UIImage imageNamed:@"demo.png"];
	UIImageView* imageView = [[UIImageView alloc] initWithImage:image];
	
	imageView.opaque = NO;
	imageView.backgroundColor = [UIColor clearColor];
	
	imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
	imageView.contentMode = UIViewContentModeCenter;
	
	imageView.frame = dimmingView.bounds;
	
	self.imageView = imageView;
	[dimmingView addSubview:imageView];
	
	self.view = dimmingView;
	[[self window] addSubview:dimmingView];
}

- (void)initObservers {
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(applicationDidChangeStatusBarOrientation:)
		name:UIApplicationWillChangeStatusBarOrientationNotification
		object:nil];
}

- (void)dismissAnimationDidStop:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context {
	[[self window] resignKeyWindow];
}

- (void)applicationDidChangeStatusBarOrientation:(NSNotification*)notification {
	UIInterfaceOrientation interfaceOrientation = [[[notification userInfo]
		objectForKey:UIApplicationStatusBarOrientationUserInfoKey]
		integerValue];
	
	self.interfaceOrientation = interfaceOrientation;
	
	[self updateForInterfaceOrientation:interfaceOrientation];
}

- (void)updateForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if(interfaceOrientation == UIDeviceOrientationPortrait) {
		self.imageView.transform = CGAffineTransformIdentity;
	} else {
		CGFloat rotation = 0.0;
		
		if(interfaceOrientation == UIDeviceOrientationLandscapeRight) {
			rotation = -90.0;
		} else if(interfaceOrientation == UIDeviceOrientationLandscapeLeft) {
			rotation = 90.0;
		} else if(interfaceOrientation == UIDeviceOrientationPortraitUpsideDown) {
			rotation = 180.0;
		}
		
		self.imageView.transform = CGAffineTransformMakeRotation((M_PI / 180) * rotation);
	}
}

@end
