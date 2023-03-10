//
//  SFPiledViewController.m
//  Articles
//
//  Created by Sophia Teutschler on 29.01.12.
//  Copyright (c) 2012 Sophiestication Software. All rights reserved.
//

#import "SFPiledViewController.h"
#import "SFPiledViewController+Private.h"

@implementation SFPiledViewController

@synthesize dataSource = dataSource_;
@synthesize delegate = delegate_;

@synthesize visibleViewControllers = visibleViewControllers_;
@synthesize reusableViewControllers = reusableViewControllers_;

#pragma mark - SFPiledViewController

#pragma mark - View Controller Reusing

- (UIViewController*)dequeueReuseableViewControllerWithIdentifier:(NSString*)identifier {
	return nil;
}

- (void)enqueuReuseableViewController:(UIViewController*)viewController {
}

#pragma mark - UIViewController

- (void)loadView {
	UIScrollView* pagingScrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
	
	pagingScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
	
	pagingScrollView.delegate = (id)self;
	
	pagingScrollView.pagingEnabled = YES;
	
	pagingScrollView.alwaysBounceHorizontal = YES;
	pagingScrollView.alwaysBounceVertical = NO;
	
	pagingScrollView.directionalLockEnabled = YES;
	
	pagingScrollView.showsHorizontalScrollIndicator = NO;
	pagingScrollView.showsVerticalScrollIndicator = NO;
	
	self.view = pagingScrollView;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// view controller caching
	self.reusableViewControllers = [NSMutableSet setWithCapacity:3];
	self.visibleViewControllers = [NSMutableArray arrayWithCapacity:3];
}

- (void)viewDidUnload {
    [super viewDidUnload];
	
	self.visibleViewControllers = nil;
	self.reusableViewControllers = nil;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView*)scrollView {
	return NO;
}

#pragma mark - Private

@end