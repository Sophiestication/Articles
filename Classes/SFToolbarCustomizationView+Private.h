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

@class SFBarButtonItem;

@interface SFToolbarCustomizationView()

@property(nonatomic, readwrite, strong) SFNavigationBar* navigationBar;
@property(nonatomic, strong) UIView* backgroundView;
@property(nonatomic, strong) NSMutableArray* visibleToolbarItems;

- (void)initIvars;
- (void)initBackgroundView;
- (void)initNavigationBar;
- (void)initDoneButtonItem;
- (void)initGestureRecognizers;

- (void)layoutItemWells;
- (void)layoutItemViews;
- (void)layoutToolbarItemViews;

- (id)viewForButtonItem:(SFBarButtonItem*)buttonItem inSet:(NSSet*)set;
- (NSMutableSet*)subviewsWithTag:(NSInteger)tag inView:(UIView*)view;

- (SFBarButtonWiggleView*)draggingViewForGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer;
- (void)rearrangeToolbarItemsForGestureRecognizerIfNeeded:(UIGestureRecognizer*)gestureRecognizer;
- (void)updateToolbar;

- (NSArray*)toolbarItemRects;
- (NSInteger)toolbarItemIndexNearPoint:(CGPoint)point;

- (void)endCustomizing:(id)sender;

@end
