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

#import "SFDocumentPickerView.h"

@interface SFDocumentPickerView()

extern CGFloat const SFDocumentPickerContentOffsetAnimationDuration;

@property(nonatomic, strong) UILabel* textLabel;
@property(nonatomic, strong) UILabel* detailTextLabel;

@property(nonatomic, strong) UIScrollView* scrollView;
@property(nonatomic, strong) UIPageControl* pageControl;

@property(nonatomic, strong) id<SFDocument> visibleDocument;

@property(nonatomic, strong) NSMutableDictionary* reuseableDocumentViews;

@property(nonatomic, readonly) CGSize documentScaleFactors;

- (void)initIvars;
- (void)initSubviews;

- (void)enqueueReusableDocumentView:(SFDocumentView*)documentView;
- (void)enqueueAllDocumentViews;

- (CGSize)scrollViewContentSizeForDocuments:(NSArray*)documents;
- (CGRect)viewRectForDocument:(id<SFDocument>)document inArray:(NSArray*)documents;
- (SFDocumentView*)visibleViewForDocument:(id<SFDocument>)document;

- (void)setNeedsDocumentLayout;

- (void)layoutDocumentViews;
- (void)layoutPageControl;
- (void)layoutTextLabels;

- (void)updateDocumentViewOpacity:(SFDocumentView*)documentView;
- (void)updateDocuments:(NSArray*)documents;

- (void)revealDocumentView:(id<SFDocument>)document;

- (void)scrollDocumentToVisible:(id<SFDocument>)document animated:(BOOL)animated;
- (void)scrollDocumentToVisible:(id<SFDocument>)document animated:(BOOL)animated animationDuration:(CGFloat)animationDuration;

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;
- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated animationDuration:(CGFloat)animationDuration;

- (void)touchUpAtPoint:(CGPoint)point;

- (void)minimizeDocument:(id<SFDocument>)document;
- (void)maximizeDocument:(id<SFDocument>)document;

- (CGAffineTransform)maximizeTransformForDocumentView:(SFDocumentView*)documentView;

@end

@interface SFDocumentPickerScrollView : UIScrollView {
	NSTimeInterval _touchDownTimestamp;
	NSTimeInterval _previousTouchTimestamp;
	CGPoint _touchDown;
	CGPoint _touchUp;
	BOOL _touchesMoved;
	BOOL _dragging;
}

- (void)updateContentOffsetForTouches:(NSSet*)touches withEvent:(UIEvent*)event;
- (void)endDraggingForTouches:(NSSet*)touches withEvent:(UIEvent*)event;

@end
