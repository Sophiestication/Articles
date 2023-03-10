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

#import "SUIPiledViewController.h"
#import "SUIPiledContainerView.h"

@interface SUIPiledViewController()<SUIPiledContainerViewDelegate>

@property(nonatomic, readwrite) NSUInteger numberOfItems;

@property(nonatomic, strong) NSMutableDictionary* visibleViewControllers;
@property(nonatomic, readonly) SUIPiledContainerView* containerView;

@property(nonatomic, readwrite, strong) UIViewController* selectedViewController;

@end

@implementation SUIPiledViewController

@dynamic containerView;

#pragma mark - Construction & Destruction

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		self.visibleViewControllers = [NSMutableDictionary dictionaryWithCapacity:3];
    }

    return self;
}

#pragma mark - SUIPiledViewController

- (void)setSelectedItemIndex:(NSInteger)selectedItemIndex {
	[self setSelectedItemIndex:selectedItemIndex animated:NO completion:nil];
}

- (void)setSelectedItemIndex:(NSInteger)selectedItemIndex animated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
	NSUInteger numberOfItems = [[self dataSource] numberOfItemsInPiledViewController:self];
	self.numberOfItems = numberOfItems;

	[[self containerView] reloadWithNumberOfItems:numberOfItems selectedItemIndex:selectedItemIndex animated:animated completion:completion];
}

#pragma mark - UIViewController

- (void)loadView {
	SUIPiledContainerView* containerView = [[SUIPiledContainerView alloc] initWithFrame:CGRectZero];

	containerView.delegate = self;
	containerView.backgroundColor = [UIColor colorWithWhite:0.873 alpha:1.000];

	self.view = containerView;
}

- (UIViewController*)childViewControllerForStatusBarStyle {
	return self.selectedViewController;
}

- (UIViewController*)childViewControllerForStatusBarHidden {
	return self.selectedViewController;
}

#pragma mark - SUIPiledContainerViewDelegate

- (void)piledContainerView:(SUIPiledContainerView*)piledContainerView willDisplayView:(SUIPiledItemView*)view forItemAtIndex:(NSInteger)index {
	UIViewController* viewController = [self viewControllerForItemAtIndex:index];
	[self presentViewController:viewController forItemAtIndex:index view:view];
}

- (void)piledContainerView:(SUIPiledContainerView*)piledContainerView didEndDisplayingView:(SUIPiledItemView*)view forItemAtIndex:(NSInteger)index {
	UIViewController* viewController = self.visibleViewControllers[@(index)];
	if(viewController) { [self dismissViewController:viewController forItemAtIndex:index]; }
}

- (void)piledContainerView:(SUIPiledContainerView*)piledContainerView didSelectItemAtIndex:(NSInteger)index {
	UIViewController* viewController = self.visibleViewControllers[@(index)];
	if(!viewController) { return; }

	self.selectedViewController = viewController;

	if([[self delegate] respondsToSelector:@selector(piledViewController:didSelectViewController:forItemAtIndex:)]) {
		[[self delegate] piledViewController:self didSelectViewController:viewController forItemAtIndex:index];
	}
}

#pragma mark - Private

- (SUIPiledContainerView*)containerView {
	return (SUIPiledContainerView*)self.view;
}

- (void)setSelectedViewController:(UIViewController*)selectedViewController {
	if(self.selectedViewController == selectedViewController) { return; }

	_selectedViewController = selectedViewController;

	if([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
//		[self setNeedsStatusBarAppearanceUpdate];
	}
}

- (UIViewController*)viewControllerForItemAtIndex:(NSInteger)index {
	if(index == NSNotFound) { return nil; }

	UIViewController* viewController = [[self visibleViewControllers] objectForKey:@(index)];
	if(viewController) { return viewController; }
	
	viewController = [[self dataSource] piledViewController:self viewControllerForItemAtIndex:index];
	NSAssert(viewController != nil, @"A piled view controller data source needs to return a valid view controller.");

	return viewController;
}

- (void)presentViewController:(UIViewController*)viewController forItemAtIndex:(NSInteger)index view:(SUIPiledItemView*)view {
	if(!viewController) { return; }
	if(viewController.parentViewController == self) { return; }

	if([[self delegate] respondsToSelector:@selector(piledViewController:willPresentViewController:forItemAtIndex:)]) {
		[[self delegate] piledViewController:self willPresentViewController:viewController forItemAtIndex:index];
	}

	[[self visibleViewControllers] setObject:viewController forKey:@(index)];

	[viewController beginAppearanceTransition:YES animated:NO];

	view.contentView = viewController.view;
	[self addChildViewController:viewController];

	[viewController endAppearanceTransition];
}

- (void)dismissViewController:(UIViewController*)viewController forItemAtIndex:(NSInteger)index {
	[[self visibleViewControllers] removeObjectForKey:@(index)];

	[viewController willMoveToParentViewController:nil];

	[viewController beginAppearanceTransition:NO animated:NO];

	if([viewController isViewLoaded]) {
		[[viewController view] removeFromSuperview]; // TODO Check for performance penalties
	}

	[viewController endAppearanceTransition];

	[viewController removeFromParentViewController];

	if([[self delegate] respondsToSelector:@selector(piledViewController:didDismissViewController:forItemAtIndex:)]) {
		[[self delegate] piledViewController:self didDismissViewController:viewController forItemAtIndex:index];
	}
}

@end
