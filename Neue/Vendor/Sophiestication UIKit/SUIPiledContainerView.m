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

#import "SUIPiledContainerView.h"

@interface SUIPiledContainerView()<UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property(nonatomic, readwrite) NSUInteger numberOfItems;
@property(nonatomic, readwrite) NSInteger selectedItemIndex;

@property(nonatomic, strong) UIScrollView* scrollView;

@property(nonatomic, strong) NSMutableSet* visibleItemViews;
@property(nonatomic, strong) NSMutableSet* reuseableItemViews;

@property(nonatomic, strong) SUIPiledItemView* selectedItemView;

@property(nonatomic, getter=isTransitioning) BOOL transitioning;
@property(nonatomic, copy) void (^transitionCompletion)(BOOL finished);

@property(nonatomic, getter=isInitialTransition) BOOL initialTransition;

@end

@implementation SUIPiledContainerView

#pragma mark - Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
		self.backgroundColor = [UIColor whiteColor];

		self.numberOfItems = 0;
		self.selectedItemIndex = NSNotFound;

		self.visibleItemViews = [NSMutableSet setWithCapacity:3];
		self.reuseableItemViews = [NSMutableSet set];

		[self initScrollView];
    }

    return self;
}

#pragma mark - SUIPiledContainerView

- (void)reloadWithNumberOfItems:(NSUInteger)numberOfItems selectedItemIndex:(NSInteger)selectedItemIndex animated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
	if(selectedItemIndex >= numberOfItems) { selectedItemIndex = NSNotFound; }

	self.transitioning = animated;

	if(self.selectedItemIndex == NSNotFound) {
		self.initialTransition = YES;
	}

	self.numberOfItems = numberOfItems;
	self.selectedItemIndex = selectedItemIndex;

	[self layoutForSelectionOrDataSourceUpdate];

	if(!animated) {
		if(completion) { completion(YES); }
		return;
	}

	self.scrollView.contentOffset = CGPointZero;

	self.transitionCompletion = completion;

	CGPoint offset = CGPointMake(CGRectGetWidth(self.bounds), 0.0);
	[[self scrollView] setContentOffset:offset animated:YES];
}

#pragma mark - UIView

- (void)layoutSubviews {
	[super layoutSubviews];

	if(self.selectedItemIndex == NSNotFound) {
		[self enqueueReuseablePileViewsIfNeeded];
		return;
	}

	[self layoutScrollViewIfNeeded];

	if(!self.scrollView.dragging) {
		[self enqueueReuseablePileViewsIfNeeded];
	}

	[self layoutPileItemViews];

	SUIPiledItemView* view = [self visibleViewForItemAtIndex:[self selectedItemIndex]];
	self.selectedItemView = view;

//	[self applyDebuggingInformationToVisibleItemViews];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
	[self layoutPileItemViews];
}

- (void)scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(BOOL)decelerate {
	if(decelerate) { return; }
	[self evaluateSelectedItemIndex];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView*)scrollView {
	scrollView.scrollEnabled = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView*)scrollView {
	[self evaluateSelectedItemIndex];
	scrollView.scrollEnabled = YES;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView*)scrollView {
	[self evaluateSelectedItemIndex];

	if(self.transitioning) {
		self.transitioning = NO;
		self.initialTransition = NO;

		[self layoutForSelectionOrDataSourceUpdate];

		if([[self delegate] respondsToSelector:@selector(piledContainerView:didSelectItemAtIndex:)]) {
			[[self delegate] piledContainerView:self didSelectItemAtIndex:[self selectedItemIndex]];
		}

		if(self.transitionCompletion) {
			self.transitionCompletion(YES);
			self.transitionCompletion = nil;
		}
	}
}

#pragma mark - Layout

- (void)layoutScrollViewIfNeeded {
	UIScrollView* scrollView = self.scrollView;
	
	CGRect contentRect = self.bounds;
	
	NSInteger selectedItemIndex = self.selectedItemIndex;

	NSUInteger numberOfVisibleItems = 1;
	if(selectedItemIndex > 0) { ++numberOfVisibleItems; }
	if(selectedItemIndex + 1 < self.numberOfItems) { ++numberOfVisibleItems; }

	// act like as if there is a preceeding item while doing the initial transition
	if(self.initialTransition && selectedItemIndex == 0) { ++numberOfVisibleItems; }
	
	CGSize newContentSize = CGSizeMake(
		CGRectGetWidth(contentRect) * (CGFloat)numberOfVisibleItems,
		CGRectGetHeight(contentRect));

	if(!CGSizeEqualToSize(newContentSize, scrollView.contentSize)) {
		scrollView.frame = contentRect;
		scrollView.contentSize = newContentSize;
	}
}

- (void)layoutPileItemViews {
	NSInteger selectedItemIndex = self.selectedItemIndex;

	// preceeding
	if(selectedItemIndex > 0 && selectedItemIndex != NSNotFound) {
		[self layoutViewForItemAtIndex:selectedItemIndex - 1];
	}

	// selected
	[self layoutViewForItemAtIndex:selectedItemIndex];

	// following
	if(selectedItemIndex + 1 < self.numberOfItems) {
		[self layoutViewForItemAtIndex:selectedItemIndex + 1];
	}
}

- (void)layoutViewForItemAtIndex:(NSInteger)itemIndex {
	SUIPiledItemView* view = [self visibleViewForItemAtIndex:itemIndex];
	CGRect rect = [self rectForItemAtIndex:itemIndex];

	if(!view && [self isRectConsideredAsVisible:rect forItemAtIndex:itemIndex]) {
		view = [self dequeueReuseablePileViewForItemAtIndex:itemIndex];
	}

	if(view) {
		view.frame = rect;

		CGFloat transitionProgress = 0.0;

		if(itemIndex >= self.selectedItemIndex) {
			CGRect contentRect = self.bounds;
			CGRect visibleItemRect = CGRectIntersection(contentRect, rect);
			transitionProgress = CGRectGetWidth(visibleItemRect) / (CGRectGetWidth(contentRect) * 0.2);
		}

		view.transitionProgress = transitionProgress;

		[self insertSubview:view atIndex:itemIndex + 1];
	}
}

- (CGRect)rectForItemAtIndex:(NSInteger)itemIndex {
	CGRect contentRect = self.bounds;
	CGRect itemRect = contentRect;
	
	NSInteger selectedItemIndex = self.selectedItemIndex;
	
	CGFloat contentOffset = self.scrollView.contentOffset.x;
	
	if(itemIndex == selectedItemIndex) { // selected item
		// act like as if there is a preceeding item while doing the initial transition
		if(self.initialTransition && itemIndex == 0) {
			itemIndex = 1;
		}

		if(itemIndex > 0) { itemRect = CGRectOffset(itemRect, CGRectGetWidth(itemRect), 0.0); }
		itemRect = CGRectOffset(itemRect, -contentOffset, 0.0);

//		if(self.numberOfItems > 1) {
//			if(CGRectGetMinX(itemRect) < 0.0) { itemRect.origin.x = 0.0; }
//		}
	} else if(itemIndex < selectedItemIndex) { // preceding items
		CGFloat shift = 0.0;

		if(-contentOffset > CGRectGetMinX(itemRect)) {
			shift = contentOffset - CGRectGetMinX(itemRect);
			if(shift < 0.0 && self.scrollView.decelerating) { shift = 0.0; } // prevent bounce
		} else if(contentOffset > CGRectGetMaxX(itemRect)) {
			shift = contentOffset - CGRectGetMaxX(itemRect);
		}

		itemRect = CGRectOffset(itemRect, -shift, 0.0);
	} else if(itemIndex > selectedItemIndex) { // following items
		NSInteger pileOffset = 1;
		if(itemIndex > 1) { pileOffset = 2; }
		
		itemRect = CGRectOffset(itemRect, CGRectGetWidth(itemRect) * pileOffset, 0.0);
		itemRect = CGRectOffset(itemRect, -contentOffset, 0.0);
	}
	
	return itemRect;
}

- (BOOL)isRectConsideredAsVisible:(CGRect)rect forItemAtIndex:(NSInteger)itemIndex {
	NSInteger selectedItemIndex = self.selectedItemIndex;
	if(itemIndex == selectedItemIndex) { return YES; }

	if(self.initialTransition && itemIndex < selectedItemIndex) {
		return NO;
	}

	CGRect selectedViewRect = [self rectForItemAtIndex:selectedItemIndex];

	if(itemIndex < selectedItemIndex) {
		return CGRectGetMinX(selectedViewRect) > CGRectGetMinX(rect);
	}

	return /*CGRectIntersectsRect(selectedViewRect, rect) ||*/ CGRectGetMinX(selectedViewRect) < 0.0;
}

#pragma mark - View Reusing

- (SUIPiledItemView*)visibleViewForItemAtIndex:(NSInteger)itemIndex {
	SUIPiledItemView* view = [self viewForItemAtIndex:itemIndex inSet:[self visibleItemViews]];
	return view;
}

- (SUIPiledItemView*)dequeueReuseablePileViewForItemAtIndex:(NSInteger)itemIndex {
	CGRect rect = [self rectForItemAtIndex:itemIndex];

	SUIPiledItemView* view = [self viewForItemAtIndex:itemIndex inSet:[self reuseableItemViews]];
	if(!view) { view = [[self reuseableItemViews] anyObject]; }

	if(view) {
		[[self reuseableItemViews] removeObject:view];
//		NSLog(@"Dequeue %i", itemIndex);
	} else {
		view = [[SUIPiledItemView alloc] initWithFrame:rect];
//		NSLog(@"Create %i", itemIndex);
	}

	[view prepareForReuse];

	view.tag = itemIndex;
	view.hidden = NO;

	view.frame = rect;

	[[self visibleItemViews] addObject:view];
	[self insertSubview:view atIndex:itemIndex + 1]; // insert right here to prevent view controller container side effects

	if([[self delegate] respondsToSelector:@selector(piledContainerView:willDisplayView:forItemAtIndex:)]) {
		[[self delegate]
			piledContainerView:self
			willDisplayView:view
			forItemAtIndex:itemIndex];
	}

	return view;
}

- (void)enqueueReuseablePileViewsIfNeeded {
	NSMutableSet* viewsToEnqueue = nil;

	for(SUIPiledItemView* view in self.visibleItemViews) {
		CGRect rect = view.frame;
		NSInteger index = view.tag;

		if([self isRectConsideredAsVisible:rect forItemAtIndex:index]) { continue; }

		if(!viewsToEnqueue) { viewsToEnqueue = [NSMutableSet setWithCapacity:1]; }
		[viewsToEnqueue addObject:view];
	}

	for(SUIPiledItemView* view in viewsToEnqueue) {
		[[self reuseableItemViews] addObject:view];
		[[self visibleItemViews] removeObject:view];

		view.hidden = YES;

		if([[self delegate] respondsToSelector:@selector(piledContainerView:didEndDisplayingView:forItemAtIndex:)]) {
			[[self delegate]
				piledContainerView:self
				didEndDisplayingView:view
				forItemAtIndex:[view tag]];
		}

//		NSLog(@"Enqueue %i", view.tag);
	}
}

- (SUIPiledItemView*)viewForItemAtIndex:(NSInteger)itemIndex inSet:(NSSet*)set {
	for(SUIPiledItemView* view in set) {
		if(view.tag == itemIndex) { return view; }
	}

	return nil;
}

#pragma mark - Private

- (void)initScrollView {
	CGRect rect = self.bounds;
	UIScrollView* scrollView = [[UIScrollView alloc] initWithFrame:rect];
	
	scrollView.pagingEnabled = YES;
	
	scrollView.directionalLockEnabled = YES;

	scrollView.showsHorizontalScrollIndicator = NO;
	scrollView.showsVerticalScrollIndicator = NO;
	
	scrollView.scrollsToTop = NO;
	
	scrollView.delegate = self;
	
	self.scrollView = scrollView;
	[self insertSubview:scrollView atIndex:0];
}

#pragma mark -

- (void)setSelectedItemView:(SUIPiledItemView*)selectedItemView {
	if(self.selectedItemView == selectedItemView) { return; }

	UIGestureRecognizer* gestureRecognizer = self.scrollView.panGestureRecognizer;

	[_selectedItemView removeGestureRecognizer:gestureRecognizer];

	_selectedItemView = selectedItemView;

	[selectedItemView addGestureRecognizer:gestureRecognizer];
}

- (void)evaluateSelectedItemIndex {
	NSInteger selectedItemIndex = self.selectedItemIndex;
	CGRect selectedViewRect = [self rectForItemAtIndex:selectedItemIndex];

	NSInteger newSelectedItemIndex = selectedItemIndex;

	if(CGRectGetMinX(selectedViewRect) > 0.0) { // preceeding
		if(selectedItemIndex > 0) {
			newSelectedItemIndex = selectedItemIndex - 1;
		}
	} else if(CGRectGetMinX(selectedViewRect) < 0.0) { // following
		if(selectedItemIndex + 1 < self.numberOfItems) {
			newSelectedItemIndex = selectedItemIndex + 1;
		}
	}

	if(selectedItemIndex != newSelectedItemIndex) {
		self.selectedItemIndex = newSelectedItemIndex;
		[self layoutForSelectionOrDataSourceUpdate];

		if([[self delegate] respondsToSelector:@selector(piledContainerView:didSelectItemAtIndex:)]) {
			[[self delegate] piledContainerView:self didSelectItemAtIndex:newSelectedItemIndex];
		}
	}
}

- (void)layoutForSelectionOrDataSourceUpdate {
	[self layoutScrollViewIfNeeded];

	UIScrollView* scrollView = self.scrollView;

	scrollView.delegate = nil;
	scrollView.contentOffset = CGPointZero;
	CGRect rect = [self rectForItemAtIndex:[self selectedItemIndex]];

	scrollView.delegate = self;
	scrollView.contentOffset = CGPointMake(CGRectGetMinX(rect), 0.0);

	self.selectedItemView = nil;

	if(!self.transitioning) {
		[self enqueueReuseablePileViewsIfNeeded];
		[self setNeedsLayout];
	}
}

#pragma mark -

- (void)applyDebuggingInformationToVisibleItemViews {
	NSArray* colors = @[
		[UIColor purpleColor],
		[UIColor orangeColor],
		[UIColor cyanColor],
		[UIColor magentaColor],
		[UIColor yellowColor],
		[UIColor blueColor],
		[UIColor redColor],
		[UIColor greenColor],
		[UIColor brownColor] ];

	for(SUIPiledItemView* view in self.visibleItemViews) {
		view.backgroundColor = colors[view.tag];
	}
}

@end
