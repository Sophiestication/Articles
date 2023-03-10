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

#import "SFToolbarCustomizationView.h"
#import "SFToolbarCustomizationView+Private.h"

#import "SFToolbarCustomizationController.h"
#import "SFToolbarCustomizationController+Private.h"

#import "SFBarButtonItem.h"
#import "SFBarButtonItem+Private.h"

#import "SFBarButtonItemWell.h"
#import "SFBarButtonWiggleView.h"

#import "UIBarButtonItem+Additions.h"
#import "UIButton+Graphite.h"
#import "UILabel+Graphite.h"

@implementation SFToolbarCustomizationView

@synthesize navigationBar = _navigationBar;
@synthesize backgroundView = _backgroundView;
@synthesize visibleToolbarItems = _visibleToolbarItems;
@dynamic wigglesToolbarItems;

#pragma	mark -
#pragma mark Construction & Destruction

- (id)initWithCustomizationController:(SFToolbarCustomizationController*)customizationController {
    if((self = [super initWithFrame:CGRectZero])) {
		_customizationController = customizationController;

		[self initIvars];
		[self initBackgroundView];
		[self initNavigationBar];
		[self initDoneButtonItem];
		[self initGestureRecognizers];
	}

    return self;
}


#pragma mark -
#pragma mark SFToolbarCustomizationView

- (BOOL)wigglesToolbarItems {
	return _wigglesToolbarItems;
}

- (void)setWigglesToolbarItems:(BOOL)wigglesToolbarItems {
	if(self.wigglesToolbarItems != wigglesToolbarItems) {
		_wigglesToolbarItems = wigglesToolbarItems;
		
		_needsToolbarItemLayout = YES;
		[self setNeedsLayout];
	}
}

#pragma	mark -
#pragma mark UIView

- (CGSize)sizeThatFits:(CGSize)size {
	UIScreen* screen = [[self window] screen];
	
	if(!screen) {
		screen = [UIScreen mainScreen];
	}
	
	CGRect applicationFrame = [screen applicationFrame];
	
	if(UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {		
		applicationFrame = CGRectApplyAffineTransform(
			applicationFrame,
			CGAffineTransformMakeRotation(90.0 * M_PI / 180.0));
	}
	
//	CGRect toolbarRect = _customizationController.toolbar.frame;
//	applicationFrame.size.height -= CGRectGetHeight(toolbarRect);

	return applicationFrame.size;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect bounds = self.bounds;
	
	// Layout the navigation bar
	CGSize navigationBarSize = [_navigationBar sizeThatFits:bounds.size];
	CGRect navigationBarRect = CGRectMake(
		CGRectGetMinX(bounds),
		CGRectGetMinY(bounds),
		CGRectGetWidth(bounds),
		navigationBarSize.height);
	_navigationBar.frame = navigationBarRect;
	
	// Layout the done button item
	BOOL miniBar = CGRectGetHeight(navigationBarRect) < 44.0;
	
	UIButton* doneButton = (id)_navigationBar.topItem.rightBarButtonItem.customView;
	[doneButton
		setGraphiteStyle:UIBarButtonItemStyleDone
		miniBar:miniBar
		systemItem:UIBarButtonSystemItemDone];
		
	// Layout the navigation title
	UILabel* navigationTitle = (id)_navigationBar.topItem.titleView;

	navigationTitle.font = miniBar ?
		[UIFont boldSystemFontOfSize:16.0] :
		[UIFont boldSystemFontOfSize:19.0];
		
	// Layout the background view
	CGRect toolbarRect = _customizationController.toolbar.frame;
	
	CGRect backgroundViewRect = CGRectMake(
		CGRectGetMinX(bounds),
		CGRectGetMaxY(navigationBarRect),
		CGRectGetWidth(bounds),
		CGRectGetHeight(bounds) - CGRectGetHeight(navigationBarRect) - CGRectGetHeight(toolbarRect));
	self.backgroundView.frame = backgroundViewRect;
	
	// TODO
	if(_needsToolbarItemLayout || YES) {
		// Layout our item wells and views
		[self layoutItemWells];
		[self layoutItemViews];
		[self layoutToolbarItemViews];
		
		_needsToolbarItemLayout = NO;
	}
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer {
	UIView* targetView = [self
		hitTest:[gestureRecognizer locationInView:self]
		withEvent:nil];
	
	if([targetView isKindOfClass:[SFBarButtonItemWell class]] ||
	   [targetView isKindOfClass:[SFBarButtonWiggleView class]] ||
	   targetView == self) {
		return YES;
	}
	
	return NO;
}

#pragma	mark -
#pragma mark Private

- (void)initIvars {
	self.opaque = NO;
	self.backgroundColor = [UIColor clearColor];
	
	self.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	
	self.wigglesToolbarItems = NO;
	
	self.visibleToolbarItems = [NSMutableArray arrayWithCapacity:5];
	
	for(UIBarButtonItem* buttonItem in _customizationController.toolbar.items) {
		if([buttonItem isKindOfClass:[SFBarButtonItem class]]) {
			[[self visibleToolbarItems] addObject:buttonItem];
		}
	}
}

- (void)initBackgroundView {
	UIView* backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
	
	backgroundView.backgroundColor = [UIColor whiteColor];
	backgroundView.opaque = YES;
	
	backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	
	self.backgroundView = backgroundView;
	[self addSubview:backgroundView];
}

- (void)initNavigationBar {
	SFNavigationBar* navigationBar = [[SFNavigationBar alloc] initWithFrame:CGRectZero];
	
	NSString* title = NSLocalizedString(@"CUSTOMIZATION_NAVIGATIONITEM_TITLE", @"");
	UINavigationItem* navigationItem = [[UINavigationItem alloc] initWithTitle:title];
	
	UILabel* titleLabel = [UILabel graphiteNavigationBarLabelWithText:
		[navigationItem title]];
	
	titleLabel.font = [UIFont boldSystemFontOfSize:19.0];
		
	navigationItem.titleView = titleLabel;
	
	[navigationBar pushNavigationItem:navigationItem animated:NO];
	
	self.navigationBar = navigationBar;
	[self insertSubview:navigationBar aboveSubview:[self backgroundView]];
}

- (void)initDoneButtonItem {
	UIButton* doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
		
	[doneButton addTarget:self action:@selector(endCustomizing:) forControlEvents:UIControlEventTouchUpInside];
	[doneButton
		setGraphiteStyle:UIBarButtonItemStyleDone
		miniBar:NO
		systemItem:UIBarButtonSystemItemDone];
	
	UIBarButtonItem* doneButtonItem = [[UIBarButtonItem alloc] initWithCustomView:doneButton];
	_navigationBar.topItem.rightBarButtonItem = doneButtonItem;
}

- (void)initGestureRecognizers {
	UILongPressGestureRecognizer* longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc]
		initWithTarget:self
		action:@selector(didRecognizeLongPressGesture:)];
	
	longPressGestureRecognizer.delegate = self;
	longPressGestureRecognizer.minimumPressDuration = 0.0;

	[self addGestureRecognizer:longPressGestureRecognizer];
}

- (void)layoutItemWells {
	const NSInteger itemWellTag = 100;
	NSMutableSet* itemWells = [self
		subviewsWithTag:itemWellTag
		inView:self];
	
	// Re-use or create wells as needed
	CGRect contentRect = self.bounds;
	
	CGFloat navigationBarHeight = CGRectGetHeight([[self navigationBar] bounds]);

	contentRect.origin.y += navigationBarHeight;
	contentRect.size.height -= navigationBarHeight;
	
	CGFloat const margin = 15.0;
	contentRect.origin.y += margin;
	
	const NSInteger numberOfColumns = CGRectGetWidth(self.bounds) <= 320.0 ? 3 : 4;
	NSInteger itemIndex = 0;
	
	CGFloat const itemWellWidth = CGRectGetWidth(contentRect) / numberOfColumns;
	CGFloat const itemWellHeight = 80.0;

	for(SFBarButtonItem* buttonItem in [_customizationController toolbarItems]) {
		if(![buttonItem isKindOfClass:[SFBarButtonItem class]]) { continue; }
		
		SFBarButtonItemWell* itemWell = [self viewForButtonItem:buttonItem inSet:itemWells];

		NSInteger rowIndex = floorf((float)itemIndex / (float)numberOfColumns);
		NSInteger columnIndex = itemIndex - (rowIndex * numberOfColumns);

		CGRect itemWellRect = CGRectMake(
			floorf(CGRectGetMinX(contentRect) + itemWellWidth * columnIndex),
			floorf(CGRectGetMinY(contentRect) + itemWellHeight * rowIndex) + margin * rowIndex,
			floorf(itemWellWidth),
			floorf(itemWellHeight));

		if(!itemWell) {
			itemWell = [[SFBarButtonItemWell alloc] initWithBarButtonItem:buttonItem];
			
			itemWell.tag = itemWellTag;
			itemWell.frame = itemWellRect; // to prevent initial animations
			
			[self addSubview:itemWell];
		} else {
			[itemWell setNeedsLayout];
		}
		
		itemWell.frame = itemWellRect;
		
//		// for debugging
//		if((columnIndex % 2 && rowIndex % 2) || (!(itemIndex % 2) && rowIndex == 0) || (!(itemIndex % 2) && rowIndex == 2)) {
//			itemWell.backgroundColor = [[UIColor orangeColor] colorWithAlphaComponent:0.2];
//		} else {
//			itemWell.backgroundColor = [[UIColor purpleColor] colorWithAlphaComponent:0.2];
//		}
		
		++itemIndex;
		[itemWells removeObject:itemWell];
	}
	
	// Release unneeded views
	for(SFBarButtonItemWell* itemWell in itemWells) {
		[itemWell removeFromSuperview];
	}
}

- (void)layoutItemViews {
	const NSInteger itemWellTag = 100; // TODO
	const NSInteger itemViewTag = 200; // TODO
	
	UIView* containerView = self;
	
	NSArray* visibleToolbarItems = self.visibleToolbarItems;
	
	NSMutableSet* itemWells = [self
		subviewsWithTag:itemWellTag
		inView:containerView];
	NSMutableSet* itemViews = [self
		subviewsWithTag:itemViewTag
		inView:containerView];
	
	// Re-use or create wells as needed
	NSInteger itemIndex = 0;

	for(SFBarButtonItem* buttonItem in [_customizationController toolbarItems]) {
		if(![buttonItem isKindOfClass:[SFBarButtonItem class]]) { continue; }
		
		SFWiggleView* itemView = [self viewForButtonItem:buttonItem inSet:itemViews];
		
		if(_draggingView && _draggingView == itemView) {
			++itemIndex;
			[itemViews removeObject:itemView];

			continue;
		}
		
		SFBarButtonItemWell* itemWell = [self viewForButtonItem:buttonItem inSet:itemWells];
		
		if(!itemView) {
			itemView = [SFBarButtonWiggleView wiggleViewForButtonItem:buttonItem];
			
			itemView.tag = itemViewTag;
			[itemView sizeToFit]; // to prevent initial animations
			
			[containerView insertSubview:itemView aboveSubview:itemWell];
		} else {
			[itemView setNeedsLayout];
		}
		
		BOOL selected = [visibleToolbarItems containsObject:buttonItem];
		
		if(selected) {
			itemView.hidden = !self.wigglesToolbarItems;
		} else {
			CGRect wellContentRect = [itemWell
				convertRect:[itemWell contentViewRect]
				toView:containerView];
			
			itemView.center = CGPointMake(
				CGRectGetMidX(wellContentRect),
				CGRectGetMidY(wellContentRect));
		}
		
		itemView.wiggling = YES;
		
		++itemIndex;
		[itemViews removeObject:itemView];
	}
	
	// Release unneeded views
	for(SFBarButtonItemWell* itemView in itemViews) {
		[itemView removeFromSuperview];
	}
}

- (void)layoutToolbarItemViews {
	if(!self.wigglesToolbarItems) {
		for(SFBarButtonItem* buttonItem in self.visibleToolbarItems) {
			buttonItem.customView.hidden = NO;
		}
		
		return;
	}
	
	const NSInteger itemViewTag = 200; // TODO
	
	UIView* containerView = self;
//	containerView.clipsToBounds = NO;
	
	NSMutableSet* itemViews = [self
		subviewsWithTag:itemViewTag
		inView:containerView];
		
	SFToolbar* toolbar = _customizationController.toolbar;
//	CGRect toolbarRect = [toolbar
//		convertRect:[toolbar bounds]
//		toView:containerView];
//		
//	toolbarRect = CGRectInset(toolbarRect, 0.0, 0.0);
	
	NSInteger itemIndex = 0;
	
	for(SFBarButtonItem* buttonItem in self.visibleToolbarItems) {
		SFBarButtonWiggleView* itemView = [self viewForButtonItem:buttonItem inSet:itemViews];
		
		UIView* toolbarItemView = [buttonItem customView];

		CGRect toolbarItemViewRect = [toolbarItemView convertRect:
			[toolbarItemView bounds]
			toView:containerView];
			
		[buttonItem layoutForBarViewIfNeeded:toolbar];
		[(UIImageView*)[itemView contentView] setImage:[buttonItem previewImageForCustomization]];
		
		if(_draggingView != itemView) {
			itemView.center = CGPointMake(
				ceilf(CGRectGetMidX(toolbarItemViewRect)),
				ceilf(CGRectGetMidY(toolbarItemViewRect)));
		}

		toolbarItemView.hidden = YES;
		
		++itemIndex;
	}
}

- (id)viewForButtonItem:(SFBarButtonItem*)buttonItem inSet:(NSSet*)set {
	for(SFBarButtonItemWell* itemWell in set) {
		if([[itemWell buttonItem] isEqual:buttonItem]) {
			return itemWell;
		}
	}
	
	return nil;
}

- (NSMutableSet*)subviewsWithTag:(NSInteger)tag inView:(UIView*)view {
	NSMutableSet* views = [NSMutableSet set];
	
	for(UIView* subview in view.subviews) {
		if(subview.tag == tag) {
			[views addObject:subview];
		}
	}
	
	return views;
}

- (SFBarButtonWiggleView*)draggingViewForGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer {
	id view = [self
		hitTest:[gestureRecognizer locationInView:self]
		withEvent:nil];
	
	if([view isKindOfClass:[SFBarButtonItemWell class]]) {
		SFBarButtonItemWell* wellView = (id)view;
		view = nil; // reset right here
		
		CGPoint point = [gestureRecognizer locationInView:wellView];
		
		if(CGRectContainsPoint([wellView contentViewRect], point)) {
			SFBarButtonItem* buttonItem = wellView.buttonItem;
			
			if(![[self visibleToolbarItems] containsObject:buttonItem]) {
				NSInteger const itemViewTag = 200; // TODO
				NSMutableSet* itemViews = [self
					subviewsWithTag:itemViewTag
					inView:self];
			
				view = [self viewForButtonItem:buttonItem inSet:itemViews];
			}
		}
	}
	
	if(![view isKindOfClass:[SFBarButtonWiggleView class]]) {
		view = nil;
	}
	
	if(!view) {
		UIToolbar* toolbar = _customizationController.toolbar;
		CGPoint point = [gestureRecognizer locationInView:toolbar];
		
		if(CGRectContainsPoint([toolbar bounds], point)) {
			NSArray* toolbarItemRects = [self toolbarItemRects];
			NSUInteger itemIndex = 0;
			
			for(NSValue* toolbarItemRect in toolbarItemRects) {
				if(CGRectContainsPoint([toolbarItemRect CGRectValue], point)) {
					SFBarButtonItem* buttonItem = [[self visibleToolbarItems] objectAtIndex:itemIndex];
			
					NSInteger const itemViewTag = 200; // TODO
					NSMutableSet* itemViews = [self
						subviewsWithTag:itemViewTag
						inView:self];
			
					view = [self viewForButtonItem:buttonItem inSet:itemViews];
					
					break;
				}
				
				++itemIndex;
			}
		}
	}
	
	return view;
}

- (void)rearrangeToolbarItemsForGestureRecognizerIfNeeded:(UIGestureRecognizer*)gestureRecognizer {
	CGRect toolbarRect = _customizationController.toolbar.bounds;
	toolbarRect = [self convertRect:toolbarRect fromView:[_customizationController toolbar]];
		
	CGPoint point = [gestureRecognizer locationInView:self];
	SFBarButtonItem* buttonItem = _draggingView.buttonItem;
	
	NSMutableArray* visibleToolbarItems = self.visibleToolbarItems;
	
	BOOL needsToolbarUpdate = NO;
	
	if(CGRectContainsPoint(toolbarRect, point)) {
		NSUInteger proposedItemIndex = [self toolbarItemIndexNearPoint:point];
		
		if([visibleToolbarItems containsObject:buttonItem]) {
			NSUInteger itemIndex = [visibleToolbarItems indexOfObject:buttonItem];
			
			if(proposedItemIndex != itemIndex) {
				[visibleToolbarItems removeObjectAtIndex:itemIndex];
				[visibleToolbarItems insertObject:buttonItem atIndex:proposedItemIndex];

				needsToolbarUpdate = YES;
			}
		} else {
			if(visibleToolbarItems.count == 0) {
				[visibleToolbarItems addObject:buttonItem];
			} else {
				[visibleToolbarItems insertObject:buttonItem atIndex:proposedItemIndex];
			}

			needsToolbarUpdate = YES;
		}
	} else {
		if([visibleToolbarItems containsObject:buttonItem]) {
			[visibleToolbarItems removeObject:buttonItem];
			needsToolbarUpdate = YES;
		}
	}
	
	if(needsToolbarUpdate) {
		[buttonItem layoutForBarViewIfNeeded:[_customizationController toolbar]];
		[self updateToolbar];
	}
}

- (void)updateToolbar {
	NSMutableArray* newToolbarItems = [NSMutableArray array];
	
	if(self.visibleToolbarItems.count == 1) {
		[newToolbarItems addObject:[UIBarButtonItem flexibleSpaceSystemItem]];
		[newToolbarItems addObject:[[self visibleToolbarItems] lastObject]];
		[newToolbarItems addObject:[UIBarButtonItem flexibleSpaceSystemItem]];
	} /* else if(self.visibleToolbarItems.count >= 6) {
		for(UIBarButtonItem* buttonItem in self.visibleToolbarItems) {
			[newToolbarItems addObject:[UIBarButtonItem flexibleSpaceSystemItem]];
			[newToolbarItems addObject:buttonItem];
		
			if(buttonItem == self.visibleToolbarItems.lastObject) {
				[newToolbarItems addObject:[SFBarButtonItem flexibleSpaceSystemItem]];
			}
		}
	} */ else {
		for(UIBarButtonItem* buttonItem in self.visibleToolbarItems) {
			[newToolbarItems addObject:buttonItem];
		
			if(buttonItem != self.visibleToolbarItems.lastObject) {
				[newToolbarItems addObject:[UIBarButtonItem flexibleSpaceSystemItem]];
			}
		}
	}
	
	_customizationController.toolbar.items = newToolbarItems;
	[self setNeedsLayout];
	
	id animations = ^() {
		[self layoutIfNeeded];
	};
	
	NSTimeInterval duration = 0.3;
	
	[UIView
		animateWithDuration:duration
		delay:0.0
		options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionLayoutSubviews
		animations:animations
		completion:nil];
}

- (NSArray*)toolbarItemRects {
	NSMutableArray* toolbarItemRects = [NSMutableArray array];
	
	CGRect toolbarRect = _customizationController.toolbar.bounds;
	
	for(SFBarButtonItem* buttonItem in self.visibleToolbarItems) {
		CGRect itemRect = [[buttonItem customView] frame];
		
		itemRect = CGRectMake(
			CGRectGetMinX(itemRect),
			CGRectGetMinY(toolbarRect),
			CGRectGetWidth(itemRect),
			CGRectGetHeight(toolbarRect));
			
		[toolbarItemRects addObject:[NSValue valueWithCGRect:itemRect]];
	}
	
	return toolbarItemRects;
}

- (NSInteger)toolbarItemIndexNearPoint:(CGPoint)point {
	NSArray* toolbarItemRects = [self toolbarItemRects];
	
	NSInteger toolbarItemIndex = NSNotFound;
	NSInteger index = 0;
	
	CGFloat shortestDelta = CGFLOAT_MAX;
	
	for(NSValue* rectValue in toolbarItemRects) {
		CGRect rect = [rectValue CGRectValue];
		
		if(CGRectContainsPoint(rect, point)) {
			toolbarItemIndex = index;
			
			break;
		} else {
			CGFloat delta = fabs(CGRectGetMidX(rect) - point.x);
		
			if(delta < shortestDelta) {
				shortestDelta = delta;
				toolbarItemIndex = index;
			}
		}
		
		++index;
	}
	
	return toolbarItemIndex;
}

- (void)didRecognizeLongPressGesture:(UILongPressGestureRecognizer*)gestureRecognizer {
	id animations = nil;
	id completion = nil;
	
	NSTimeInterval duration = 0.2;
	UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction;
	
	if(gestureRecognizer.state == UIGestureRecognizerStateBegan) {
		_draggingView = [self draggingViewForGestureRecognizer:gestureRecognizer];
		
		if(!_draggingView) { return; }
		
		[[_draggingView superview] bringSubviewToFront:_draggingView];
		
		CGPoint point = [gestureRecognizer locationInView:[_draggingView superview]];
		
		_draggingStartingPoint = point;
		_draggingButtonItemViewStartingCenter = _draggingView.center;

		animations = ^() {
			_draggingView.wiggling = NO;
			_draggingView.transform = CGAffineTransformMakeScale(3.0, 3.0);
		};
	}
	
	if(gestureRecognizer.state == UIGestureRecognizerStateChanged) {
		if(!_draggingView) { return; }
		
		SFBarButtonWiggleView* view = _draggingView;
		CGPoint point = [gestureRecognizer locationInView:[view superview]];
		
		CGPoint newCenter = CGPointMake(
			_draggingButtonItemViewStartingCenter.x - (_draggingStartingPoint.x - point.x),
			_draggingButtonItemViewStartingCenter.y - (_draggingStartingPoint.y - point.y));
		
		view.center = newCenter;
		
		[self rearrangeToolbarItemsForGestureRecognizerIfNeeded:gestureRecognizer];
	}
	
	if(gestureRecognizer.state == UIGestureRecognizerStateEnded ||
	   gestureRecognizer.state == UIGestureRecognizerStateCancelled ||
	   gestureRecognizer.state == UIGestureRecognizerStateFailed) {
		if(!_draggingView) { return; }
		
		SFBarButtonWiggleView* view = _draggingView;
		
		duration *= 2.0;
		options = UIViewAnimationOptionBeginFromCurrentState;

		[self setNeedsLayout];

		animations = ^() {
			_draggingView = nil;

			view.transform = CGAffineTransformIdentity;
			view.wiggling = YES;
			
			[self layoutIfNeeded];
		};
		
		completion = ^(BOOL finished) {
			if(!finished) { return; }
		};
	}
	
	if(!animations) { return; }
	
	[UIView
		animateWithDuration:duration
		delay:0.0
		options:options
		animations:animations
		completion:completion];
}

- (void)endCustomizing:(id)sender {
	[_customizationController endCustomizingAnimated:YES];
}

@end
