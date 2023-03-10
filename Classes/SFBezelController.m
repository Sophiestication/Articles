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

#import "SFBezelController.h"
#import "SFBezelController+Private.h"

@implementation SFBezelController

@dynamic visible;
@synthesize bezelView = _bezelView;
@synthesize window = _window;
@synthesize interfaceOrientation = _interfaceOrientation;

#pragma mark -
#pragma mark Construction & Destruction

+ (SFBezelController*)sharedBezelController {
	static dispatch_once_t once;
    static SFBezelController* sharedBezelController;
	
    dispatch_once(&once, ^{
		sharedBezelController = [[self alloc] init];
	});

    return sharedBezelController;
}

- (id)init {
	if((self = [super init])) {
		[self initIvars];
		[self initObservers];
//		[self initWindow];
//		[self initBezelView];
	}
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];


}

#pragma mark -
#pragma mark SFBezelViewController

- (BOOL)isVisible {
	return !self.window.hidden;
}

- (void)presentBezelWithText:(NSString*)text image:(UIImage*)image {
	[self initWindowIfNeeded];
	[self initBezelViewIfNeeded];
	
	self.bezelView.textLabel.text = text;
	self.bezelView.imageView.image = image;
	
	self.window.hidden = NO;
	[[self bezelView] setVisible:YES animated:YES];
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self
		selector:@selector(dismissBezelAnimated)
		object:nil];
        
    NSTimer* dismissTimer = [NSTimer
    	timerWithTimeInterval:2.0
        target:self
        selector:@selector(dismissBezelAnimated)
        userInfo:nil
        repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:dismissTimer forMode:NSRunLoopCommonModes];
}

- (void)dismissBezelAnimated {
	[[self bezelView] setVisible:NO animated:YES];
}

#pragma mark -
#pragma mark SFBezelViewDelegate

- (void)bezelViewWillAppear:(SFBezelView*)bezelView {
	self.window.hidden = NO;
}

- (void)bezelViewDidAppear:(SFBezelView*)bezelView {
}

- (void)bezelViewWillDisappear:(SFBezelView*)bezelView {
}

- (void)bezelViewDidDisappear:(SFBezelView*)bezelView {
	self.window.hidden = YES;
}

#pragma mark -
#pragma mark Notifications

- (void)applicationDidReceiveMemoryWarning:(NSNotification*)notification {
	self.bezelView = nil;
	self.window = nil;
}

- (void)applicationDidChangeStatusBarFrame:(NSNotification*)notification {
}

- (void)applicationWillChangeStatusBarOrientation:(NSNotification*)notification {
	self.interfaceOrientation = [[[notification userInfo]
		objectForKey:UIApplicationStatusBarOrientationUserInfoKey]
		integerValue];
}

- (void)applicationDidChangeStatusBarOrientation:(NSNotification*)notification {
//	self.interfaceOrientation = [[[notification userInfo]
//		objectForKey:UIApplicationStatusBarOrientationUserInfoKey]
//		integerValue];
//	self.interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
	[self updateBezelViewForOrientation:[self interfaceOrientation] animated:YES];
}

#pragma mark -
#pragma mark Private

- (void)initIvars {
	self.interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
}

- (void)initObservers {
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(applicationDidReceiveMemoryWarning:)
		name:UIApplicationDidReceiveMemoryWarningNotification
		object:nil];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(applicationDidChangeStatusBarFrame:)
		name:UIApplicationDidChangeStatusBarFrameNotification
		object:nil];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(applicationWillChangeStatusBarOrientation:)
		name:UIApplicationWillChangeStatusBarOrientationNotification
		object:nil];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(applicationDidChangeStatusBarOrientation:)
		name:UIApplicationDidChangeStatusBarOrientationNotification
		object:nil];
}

- (void)initWindowIfNeeded {
	if(self.window) { return; }

	UIWindow* window = [[UIWindow alloc] initWithFrame:CGRectZero];
	
	window.hidden = YES;
	window.frame = [[window screen] bounds];
	window.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleBottomMargin;
	window.backgroundColor = [UIColor clearColor];
	window.windowLevel = UIWindowLevelAlert;
	window.userInteractionEnabled = NO;
		
	// For debugging
//	window.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.25];
	
	self.window = window;
}

- (void)initBezelViewIfNeeded {
	if(self.bezelView) { return; }
	
	SFBezelView* bezelView = [[SFBezelView alloc] initWithFrame:CGRectZero];
	
	bezelView.center = CGPointMake(
		CGRectGetMidX(self.window.bounds),
		CGRectGetMidY(self.window.bounds));
	
	bezelView.delegate = self;
	
	self.bezelView = bezelView;
	[[self window] addSubview:bezelView];
	
	[self updateBezelViewForOrientation:[self interfaceOrientation] animated:NO];
}

- (void)updateBezelViewForOrientation:(UIInterfaceOrientation)interfaceOrientation animated:(BOOL)animated {
	if(animated) {
	}
	
	self.bezelView.transform = [self transformForOrientation:interfaceOrientation];
	
	if(animated) {
	}
}

- (CGAffineTransform)transformForOrientation:(UIInterfaceOrientation)interfaceOrientation {
	CGAffineTransform transform;
	
	switch(interfaceOrientation) {
		case UIInterfaceOrientationLandscapeLeft:
			transform = CGAffineTransformMakeRotation(-90.0 * M_PI / 180.0);
		break;
		
		case UIInterfaceOrientationLandscapeRight:
			transform = CGAffineTransformMakeRotation(90.0 * M_PI / 180.0);
		break;
		
		case UIInterfaceOrientationPortraitUpsideDown:
			transform = CGAffineTransformMakeRotation(180.0 * M_PI / 180.0);
		break;
		
		default:
			transform = CGAffineTransformIdentity;
		break;
	}
	
	return transform;
}

@end
