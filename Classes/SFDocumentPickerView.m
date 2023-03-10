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
#import "SFDocumentPickerView+Private.h"

#import "SFDocumentView.h"
#import "SFDocumentView+Private.h"

#import "AKGraphics.h"

@implementation SFDocumentPickerView

@synthesize delegate = _delegate;
@synthesize textLabel = _textLabel;
@synthesize detailTextLabel = _detailTextLabel;
@synthesize scrollView = _scrollView;
@synthesize pageControl = _pageControl;
@synthesize documents = _documents;
@dynamic selectedDocument;
@synthesize visibleDocument = _visibleDocument;
@dynamic documentVisibleRect;
@synthesize reuseableDocumentViews = _reuseableDocumentViews;
@dynamic documentScaleFactors;

#pragma mark -
#pragma mark Consts

CGFloat const SFDocumentPickerContentOffsetAnimationDuration = 1.0 / 2.0;
CGFloat const SFDocumentPickerMaximizeAnimationDuration = 0.2;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
		[self initIvars];
		[self initSubviews];
	}

    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	self.delegate = nil;
	self.selectedDocument = nil;

}

#pragma mark -
#pragma mark SFDocumentPickerView

- (id<SFDocument>)selectedDocument {
	return _selectedDocument;
}

- (void)setSelectedDocument:(id<SFDocument>)selectedDocument {
	if(_selectedDocument != selectedDocument) {
		_selectedDocument = selectedDocument;
		
		[self setNeedsDocumentLayout];
	}
}

- (CGRect)documentVisibleRect {
	return self.scrollView.bounds;
}

- (void)present:(id)sender {
	id<SFDocument> selectedDocument = self.selectedDocument;
	[self minimizeDocument:selectedDocument];
}

- (void)dismiss:(id)sender {
	// First ask the delegate if we're really done
	if([[self delegate] respondsToSelector:@selector(documentPickerView:shouldFinishPickingDocument:)]) {
		if(![[self delegate] documentPickerView:self shouldFinishPickingDocument:[self selectedDocument]]) {
			return; // NEIN!
		}
	}
	
	// ...
	_maximizing = YES;
	
	// Hide the close button
	SFDocumentView* selectedDocumentView = [self visibleViewForDocument:[self selectedDocument]];
	[selectedDocumentView setShowsCloseButton:NO animated:YES];
	
	// Maximize the selected document
	[self maximizeDocument:[self selectedDocument]];
}

- (void)addDocument:(id<SFDocument>)document animated:(BOOL)animated {
	// First check if the document is already registered in our view
	BOOL needsToAddDocument = ![[self documents] containsObject:document];
	
	// Ask the delegate if we are allowed to insert this document
	if(needsToAddDocument && [[self delegate] respondsToSelector:@selector(documentPickerView:shouldCommitEditingStyle:forDocument:)]) {
		if(![[self delegate] documentPickerView:self shouldCommitEditingStyle:SFDocumentPickerViewEditingStyleInsert forDocument:document]) {
			return; // Nope.
		}
	}
	
	// Update our documents array
	NSArray* newDocuments = needsToAddDocument ?
		[[self documents] arrayByAddingObject:document] :
		self.documents;
	
	// Set our scroll view's content size
	CGSize newContentSize = [self scrollViewContentSizeForDocuments:newDocuments];
	self.scrollView.contentSize = newContentSize;

	// Mark the document as selected
	self.selectedDocument = document;
	
	if(animated) {
		// Ignore user interaction
		[[UIApplication sharedApplication] beginIgnoringInteractionEvents];

		// We don't want to scroll to the new document if we're currently delete one
		if(_animatingDocumentDeletion) {
			[self revealDocumentView:document];
			return;
		}

		// Update the page control right away
		// self.pageControl.numberOfPages = newDocuments.count;

		// Animate to the new documents position
		CGRect viewRect = [self viewRectForDocument:document inArray:newDocuments];
	
		CGPoint contentOffset = CGPointMake(
			floorf(CGRectGetMidX(viewRect) - CGRectGetWidth(self.documentVisibleRect) * 0.5),
			0.0);
		[self setContentOffset:contentOffset animated:YES];

		// Fade it in after some delay
		[self performSelector:@selector(revealDocumentView:)
			withObject:document
			afterDelay:SFDocumentPickerContentOffsetAnimationDuration];
	} else {
		// Layout now
		self.documents = newDocuments;
		[self setNeedsDocumentLayout];
		
		// Notify our delegate about the insert
		if(needsToAddDocument && [[self delegate] respondsToSelector:@selector(documentPickerView:commitEditingStyle:forDocument:)]) {
			[[self delegate] documentPickerView:self commitEditingStyle:SFDocumentPickerViewEditingStyleInsert forDocument:document];
		}
	}
}

- (void)removeDocument:(id<SFDocument>)document animated:(BOOL)animated {
	// ...
	_animatingDocumentDeletion = animated;
	
	// First ask the delegate if we are allowed to delete this document
	if([[self delegate] respondsToSelector:@selector(documentPickerView:shouldCommitEditingStyle:forDocument:)]) {
		if(![[self delegate] documentPickerView:self shouldCommitEditingStyle:SFDocumentPickerViewEditingStyleDelete forDocument:document]) {
			_animatingDocumentDeletion = NO;
			return; // Nope.
		}
	}

	// Now animate the changes
	if(animated) {
		// First look if the document is currently visible
		SFDocumentView* documentView = [self visibleViewForDocument:document];
		
		if(documentView) {
			[UIView beginAnimations:@"removeDocumentAnimation" context:(__bridge void *)(document)];
			
			[UIView setAnimationDelegate:self];
			[UIView setAnimationDidStopSelector:@selector(removeDocumentAnimationDidStop:finished:context:)];
			
			documentView.alpha = 0.0;
			
			[UIView commitAnimations];
			
			return;
		}
	}
	
	// Remove the document from our array
	NSMutableArray* newDocuments = [NSMutableArray arrayWithArray:[self documents]];
	[newDocuments removeObject:document];
	self.documents = newDocuments;
	
	// We need to layout
	[self setNeedsDocumentLayout];
	
	// Notify our delegate about the deletion
	if([[self delegate] respondsToSelector:@selector(documentPickerView:commitEditingStyle:forDocument:)]) {
		[[self delegate] documentPickerView:self commitEditingStyle:SFDocumentPickerViewEditingStyleDelete forDocument:document];
	}
}

- (void)removeDocumentAnimationDidStop:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context {
	// Enqueue the removed document view
	id<SFDocument> removedDocument = (__bridge id)context;
	SFDocumentView* removedDocumentView = [self visibleViewForDocument:removedDocument];
	
	[self enqueueReusableDocumentView:removedDocumentView];
	
	// Make a new document array
	NSMutableArray* newDocuments = [NSMutableArray arrayWithArray:[self documents]];
	[newDocuments removeObject:removedDocument];
	
	// Is this the last document in the array
	if([[[self documents] lastObject] isEqual:removedDocument]) {
		// Update the documents array
		self.documents = newDocuments;
		
		// And scroll forward to the previous document view
		CGSize newContentSize = [self scrollViewContentSizeForDocuments:newDocuments];
		[self setContentOffset:
			CGPointMake(newContentSize.width - CGRectGetWidth(self.documentVisibleRect), 0.0)
			animated:YES];
			
		// Update the layout after the scroll view animation did finish
		[self performSelector:@selector(updateDocuments:)
			withObject:newDocuments
			afterDelay:SFDocumentPickerContentOffsetAnimationDuration];
	} else {
		// Animate the other document views to their new positions
		[UIView beginAnimations:@"removeDocumentViewAnimation" context:(__bridge void *)(removedDocument)];
		
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(removeDocumentViewAnimationDidStop:finished:context:)];
		
		[UIView setAnimationDuration:SFDocumentPickerContentOffsetAnimationDuration];
		
		for(id<SFDocument> document in newDocuments) {
			CGRect documentViewRect = [self viewRectForDocument:document inArray:newDocuments];
			//documentViewRect = [[self scrollView] convertRect:documentViewRect toView:self];
			
			if(CGRectIntersectsRect(documentViewRect, self.documentVisibleRect)) {
				SFDocumentView* documentView = [self viewForDocument:document];
				
				documentView.frame = documentViewRect;
				
				[self updateDocumentViewOpacity:documentView];
			}
		}
		
		[UIView commitAnimations];
	}
	
	// Notify our delegate about the deletion
	if([[self delegate] respondsToSelector:@selector(documentPickerView:commitEditingStyle:forDocument:)]) {
		[[self delegate] documentPickerView:self commitEditingStyle:SFDocumentPickerViewEditingStyleDelete forDocument:removedDocument];
	}
	
	// ...
	_animatingDocumentDeletion = NO;
}

- (void)removeDocumentViewAnimationDidStop:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context {
	// Make a new document array
	id<SFDocument> removedDocument = (__bridge id)context;

	NSMutableArray* newDocuments = [NSMutableArray arrayWithArray:[self documents]];
	[newDocuments removeObject:removedDocument];
	
	[self updateDocuments:newDocuments];
}

- (SFDocumentView*)viewForDocument:(id<SFDocument>)document {
	// First check if the document is already registered
	NSAssert([[self documents] containsObject:document], @"Document was not added to picker view.");
	
	// First check if there is currently a view for this document visible
	SFDocumentView* documentView = [self visibleViewForDocument:document];
	
	// Give the delegate the chance to return a document view
	if(!documentView) {
		if([[self delegate] respondsToSelector:@selector(documentPickerView:viewForDocument:)]) {
			documentView = [[self delegate] documentPickerView:self viewForDocument:document];
		}
	}

	if(!documentView) {
		// Try to dequeue a document view
		NSString* const identifier = @"SFRegularDocumentViewIdentifier";
		documentView = [self dequeueReusableDocumentViewWithIdentifier:identifier];
		
		if(!documentView) {
			// Make a new document view
			documentView = [[SFDocumentView alloc] initWithDocument:document reuseIdentifier:identifier];
			// NSLog(@"New SFDocumentView %@ for document %@", documentView, document.title);
		}

		// Now setup the view based on our document
		CGRect documentContentRect = [documentView contentRectForBounds:[documentView bounds]];
		CGRect documentImageRect = [documentView imageRectForContentRect:documentContentRect];

		CGSize preferredImageSize = documentImageRect.size;

		documentView.image = [document imageForSize:preferredImageSize];
	}
	
	// Update the document and picker view properties
	documentView.document = document;
	documentView.documentPickerView = self;
	
//	documentView.layer.shouldRasterize = YES;
//	documentView.layer.rasterizationScale = self.window.screen.scale;
	
	// Add our new document view to the scroll view hiearchy if needed
	if(!documentView.superview) {
		CGRect documentViewRect = [self viewRectForDocument:document inArray:[self documents]];
		
		documentView.frame = documentViewRect;
		
		[[self scrollView] addSubview:documentView];
	}

	return documentView;
}

- (SFDocumentView*)dequeueReusableDocumentViewWithIdentifier:(NSString*)identifier {
	// Look for document views with a certain reuse identifier
	NSMutableSet* documentViews = [[self reuseableDocumentViews]
		objectForKey:identifier];
	
	if(documentViews) {
		// Enqueue any available document view
		SFDocumentView* documentView = [documentViews anyObject];
		
		if(documentView) {
			// [[documentView retain] autorelease];
			[documentViews removeObject:documentView];
			
			return documentView;
		}
	}
		
	return nil;
}

#pragma mark -
#pragma mark UIResponder

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
	[super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
	[super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
	if(touches.count == 1) {
		CGPoint point = [[touches anyObject] locationInView:self];
		[self touchUpAtPoint:point];
	}
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
	[super touchesCancelled:touches withEvent:event];
}

#pragma mark -
#pragma mark UIView

- (void)drawRect:(CGRect)rect {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { return; }
	
	CGRect bounds = self.bounds;
	AKRectFillOrnamentBackground(bounds);
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	BOOL landscapeOrientation = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
	
	// Layout our content views
	CGRect bounds = self.bounds;
	
	CGSize textLabelSize = [[self textLabel]
		sizeThatFits:bounds.size];
	textLabelSize.width = MIN(textLabelSize.width, CGRectGetWidth(bounds) - 20.0);
	textLabelSize.height = MAX(textLabelSize.height, 24.0);
	
	CGSize screenSize = [[UIScreen mainScreen] bounds].size;
	CGSize scrollViewSize = CGSizeMake(
		bounds.size.width,
		landscapeOrientation ? floorf(screenSize.width / 1.777) : roundf(screenSize.height / 1.744));

    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        scrollViewSize.height = landscapeOrientation ?
            480.0 :
            640.0;
    }

	CGSize pageControlSize = [[self pageControl]
		sizeThatFits:bounds.size];
	pageControlSize.height = MAX(pageControlSize.height, 36.0);
	
	/* self.textLabel.backgroundColor = [[UIColor orangeColor] colorWithAlphaComponent:0.5];
	self.pageControl.backgroundColor = [[UIColor purpleColor] colorWithAlphaComponent:0.5];
	self.scrollView.backgroundColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5]; */
		
	CGFloat const contentHeight = textLabelSize.height + scrollViewSize.height + pageControlSize.height;
	CGRect contentRect = CGRectMake(
		CGRectGetMinX(bounds),
		floorf(CGRectGetMidY(bounds) - contentHeight * 0.5),
		CGRectGetWidth(bounds),
		contentHeight);
		
	if(landscapeOrientation) {
		contentRect = CGRectOffset(contentRect, 0.0, 5.0);
	}
	
	CGFloat const margin = 5.0;
	
	CGRect textLabelRect = CGRectMake(
		CGRectGetMinX(bounds) + margin, // floorf(CGRectGetMidX(contentRect) - textLabelSize.width * 0.5),
		CGRectGetMinY(contentRect),
		CGRectGetWidth(bounds) - margin * 2.0, // textLabelSize.width,
		textLabelSize.height);
	
	CGRect pageControlRect = CGRectMake(
		floorf(CGRectGetMidX(contentRect) - pageControlSize.width * 0.5),
		CGRectGetMaxY(contentRect) - pageControlSize.height,
		pageControlSize.width,
		pageControlSize.height);
	
	CGRect scrollViewRect = CGRectMake(
		CGRectGetMinX(contentRect),
		CGRectGetMaxY(textLabelRect),
		CGRectGetWidth(contentRect),
		CGRectGetMinY(pageControlRect) - CGRectGetMaxY(textLabelRect));
	
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && landscapeOrientation) {
        textLabelRect = CGRectOffset(textLabelRect, 0.0, -8.0);
    }
    
	// Update the scroll view content size if needed
	BOOL scrollViewFrameDidChange = !CGSizeEqualToSize(scrollViewRect.size, self.scrollView.frame.size);

	if(scrollViewFrameDidChange) {
		CGSize contentSize = [self scrollViewContentSizeForDocuments:[self documents]];
		self.scrollView.contentSize = contentSize;
	}
	
	// Update the subview frames. Prevent animations if needed
	BOOL animationsEnabled = [UIView areAnimationsEnabled];
	
	[UIView setAnimationsEnabled:NO]; {
		self.textLabel.frame = textLabelRect;
		self.pageControl.frame = pageControlRect;
		
//		if(!CGSizeEqualToSize(self.scrollView.frame.size, scrollViewRect.size) ||
//		    CGSizeEqualToSize(self.scrollView.frame.size, CGSizeZero)) {
			self.scrollView.frame = scrollViewRect;
//		}
	} [UIView setAnimationsEnabled:animationsEnabled];

	// Layout our document views too if needed
	if(scrollViewFrameDidChange || _needsDocumentViewLayout) {
//		CGFloat contentInsetWidth = ceil(CGRectGetWidth(self.scrollView.frame) * 0.5);
//		self.scrollView.contentInset = UIEdgeInsetsMake(0.0, contentInsetWidth, 0.0, contentInsetWidth);

		[self layoutDocumentViews];
		_needsDocumentViewLayout = NO;
	}
	
	if(scrollViewFrameDidChange) {
		[self scrollDocumentToVisible:[self selectedDocument] animated:NO];
	}
}

- (void)didMoveToSuperview {
	[super didMoveToSuperview];
	
	if(self.superview) {
		[self setNeedsDocumentLayout];
		[self layoutIfNeeded];

		[self scrollDocumentToVisible:[self selectedDocument] animated:NO];
	}
}

#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
	[self setNeedsDocumentLayout];
}

- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView {
	_initialContentOffset = scrollView.contentOffset;
	self.selectedDocument = self.visibleDocument;
}

- (void)scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(BOOL)decelerate {
	CGPoint newContentOffset = scrollView.contentOffset;
	CGFloat offsetDifference = newContentOffset.x - _initialContentOffset.x;
	
	id<SFDocument> visibleDocument = self.selectedDocument;
	id<SFDocument> newVisibleDocument = nil;
	
	if(fabs(offsetDifference) > 35.0) {
		NSInteger selectedDocumentIndex = [[self documents] indexOfObject:visibleDocument];
		
		if(selectedDocumentIndex == NSNotFound) {
			// What now?
		} else if(offsetDifference >= 0) {
			if(selectedDocumentIndex + 1 < self.documents.count) {
				newVisibleDocument = [[self documents] objectAtIndex:selectedDocumentIndex + 1];
			}
		} else {
			if(selectedDocumentIndex - 1 >= 0) {
				newVisibleDocument = [[self documents] objectAtIndex:selectedDocumentIndex - 1];
			}
		}
	}
	
	if(newVisibleDocument) {
		self.visibleDocument = newVisibleDocument;
		[self scrollDocumentToVisible:newVisibleDocument animated:YES animationDuration:0.2];
	} else {
		[self scrollDocumentToVisible:[self selectedDocument] animated:YES];
	}
	
	_initialContentOffset = CGPointZero;
}

#pragma mark -
#pragma mark Private

- (CGSize)documentScaleFactors {
	return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 
		CGSizeMake(0.6, 0.6) : 
		CGSizeMake(0.6, 0.6);
}

- (void)initIvars {
	_needsDocumentViewLayout = YES;
	_animatingContentOffset = NO;
	_animatingDocumentDeletion = NO;
	_maximizing = NO;
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
	} else {
		self.opaque = YES;
		self.backgroundColor = [UIColor whiteColor];
	}
	
	self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleBottomMargin;
	
	self.documents = [NSArray array];
	self.reuseableDocumentViews = [NSMutableDictionary dictionary];
	
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

- (void)initSubviews {
	// Init the text label
	UILabel* textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		textLabel.font = [UIFont systemFontOfSize:22.0];
		textLabel.textColor = [UIColor colorWithRed:0.175 green:0.124 blue:0.094 alpha:1.000];
		textLabel.shadowColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
		textLabel.shadowOffset = CGSizeMake(0.0, 1.0);
		textLabel.backgroundColor = [UIColor clearColor];
	} else {
		textLabel.font = [UIFont boldSystemFontOfSize:19.0];
		textLabel.textColor = [UIColor whiteColor];
		textLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
		textLabel.shadowOffset = CGSizeMake(0.0, -1.0);
		textLabel.backgroundColor = [UIColor clearColor];
	}

	textLabel.minimumScaleFactor = 0.8;
	textLabel.adjustsFontSizeToFitWidth = NO; // TODO
	
	textLabel.textAlignment = NSTextAlignmentCenter;
	
	[self addSubview:textLabel];
	self.textLabel = textLabel;
	
	// Init the detail text label
	UILabel* detailTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	self.detailTextLabel = detailTextLabel;
	
	// Init the scroll view
	UIScrollView* scrollView = [[SFDocumentPickerScrollView alloc] initWithFrame:CGRectZero];
	
	scrollView.decelerationRate = 0.0;
	scrollView.showsHorizontalScrollIndicator = NO;
	scrollView.showsVerticalScrollIndicator = NO;
	
	scrollView.bounces = NO;
	scrollView.alwaysBounceHorizontal = NO;
	
	scrollView.clipsToBounds = NO;
	scrollView.delegate = self;
	
	scrollView.pagingEnabled = NO;
	scrollView.scrollEnabled = NO;

	self.scrollView = scrollView;
	
	// Init the page control
	UIPageControl* pageControl = [[UIPageControl alloc] initWithFrame:CGRectZero];
	
	pageControl.userInteractionEnabled = NO;
	
	pageControl.numberOfPages = self.documents.count;
	pageControl.hidesForSinglePage = NO;
	pageControl.defersCurrentPageDisplay = YES;
	
	[pageControl
		addTarget:self
		action:@selector(pageControlDidChangePage:event:)
		forControlEvents:UIControlEventValueChanged];
	self.pageControl = pageControl;
	
	// Add the views to our hierarchy
	[self addSubview:detailTextLabel];
	[self addSubview:pageControl];
	
	[self addSubview:scrollView];
}

- (void)pageControlDidChangePage:(id)sender event:(UIEvent*)event {
}

- (void)applicationDidReceiveMemoryWarning:(NSNotification*)notification {
	// Clear our document view queue
	[[self reuseableDocumentViews] removeAllObjects];
}

- (void)applicationDidChangeStatusBarFrame:(NSNotification*)notification {
}

- (void)applicationWillChangeStatusBarOrientation:(NSNotification*)notification {
	UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication]
		statusBarOrientation];
	UIInterfaceOrientation newInterfaceOrientation = [[[notification userInfo]
		objectForKey:UIApplicationStatusBarOrientationUserInfoKey]
		integerValue];
		
	if(UIInterfaceOrientationIsPortrait(interfaceOrientation) != UIInterfaceOrientationIsPortrait(newInterfaceOrientation)) {
		// We need to release all views in order to get the correct layout after
		// changing the status bar orientation
		[self enqueueAllDocumentViews];
	}
}

- (void)applicationDidChangeStatusBarOrientation:(NSNotification*)notification {
}

- (void)enqueueReusableDocumentView:(SFDocumentView*)documentView {
	// NSLog(@"enqueue %@", documentView);

	NSString* identifier = documentView.reuseIdentifier;
	
	if(!identifier) { return; }
	
	// Look for document views with a certain reuse identifier
	NSMutableSet* documentViews = [[self reuseableDocumentViews]
		objectForKey:identifier];
		
	if(!documentViews) {
		// Make a new set for our document views
		documentViews = [NSMutableSet set];
		[[self reuseableDocumentViews] setValue:documentViews forKey:identifier];
	}
	
	// Prepare for reuse
	[documentView removeFromSuperview];
	[documentView prepareForReuse];
	
	// Now enqueue
	[documentViews addObject:documentView];
}

- (void)enqueueAllDocumentViews {
	for(id<SFDocument> document in self.documents) {
		SFDocumentView* documentView = [self visibleViewForDocument:document];
		
		if(documentView) {
			[self enqueueReusableDocumentView:documentView];
		}
	}
}

- (CGSize)scrollViewContentSizeForDocuments:(NSArray*)documents {
	CGRect lastDocumentViewRect = [self viewRectForDocument:[documents lastObject] inArray:documents];
	
	BOOL landscapeOrientation = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
	CGFloat margin = landscapeOrientation ?
		86.0 :
		54.0;
		
	CGSize documentScaleFactors = self.documentScaleFactors;
		
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		CGSize pickerSize = self.bounds.size;
		CGSize size = CGSizeMake(
			pickerSize.width * documentScaleFactors.width,
			pickerSize.height * documentScaleFactors.height);
		margin = pickerSize.width * 0.5 - size.width * 0.5;
	}
	
	CGSize contentSize = CGSizeMake(
		CGRectGetMaxX(lastDocumentViewRect) + margin,
		CGRectGetHeight(self.documentVisibleRect));
	
	contentSize.width = MAX(CGRectGetWidth(self.documentVisibleRect), contentSize.width);
	
	return contentSize;
}

- (CGRect)viewRectForDocument:(id<SFDocument>)document inArray:(NSArray*)documents {
	BOOL landscapeOrientation = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
	
	//CGSize screenSize = [[UIScreen mainScreen] bounds].size;
	CGSize pickerSize = self.bounds.size;
	
//	CGSize size = CGSizeMake(
//		pickerSize.width * 0.6,
//		landscapeOrientation ? ((pickerSize.width * 0.6) / 1.8) : pickerSize.width * 0.6 * 1.3125); // TODO
	
	CGSize documentScaleFactors = self.documentScaleFactors;
	
	CGSize size = CGSizeMake(
		pickerSize.width * documentScaleFactors.width,
		pickerSize.height * documentScaleFactors.height);
	
	CGFloat margin = landscapeOrientation ?
		86.0 :
		54.0;
	CGFloat const padding = 10.0;
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		margin = pickerSize.width * 0.5 - size.width * 0.5;
	}
	
	size.width += padding * 2.0;
	size.height += padding * 2.0;
	
	NSInteger documentIndex = [documents indexOfObject:document];
	
	CGRect viewRect = CGRectMake(
		round(margin + (size.width * documentIndex) + (15.0 * documentIndex)),
		round(landscapeOrientation ? 5.0 : 15.0),
		round(size.width),
		round(size.height));
		
	return viewRect;
}

- (SFDocumentView*)visibleViewForDocument:(id<SFDocument>)document {
	for(SFDocumentView* view in self.scrollView.subviews) {
		// Skip none document subviews
		if(![view isKindOfClass:[SFDocumentView class]]) {
			continue;
		}
		
		// Check if it's the right document
		if([[view document] isEqual:document]) {
			return view;
		}
	}
	
	return nil;
}

- (void)setNeedsDocumentLayout {
	_needsDocumentViewLayout = YES;
	[self setNeedsLayout];
}

- (void)layoutDocumentViews {
	// Are animations enabled?
	BOOL animationsEnabled = [UIView areAnimationsEnabled];

	// Show/Hide our document views
	for(id<SFDocument> document in self.documents) {
		CGRect documentViewRect = [self
			viewRectForDocument:document
			inArray:[self documents]];

		if(CGRectIntersectsRect(documentViewRect, self.documentVisibleRect)) {
			// Dequeue a new view if needed
			SFDocumentView* documentView = nil;
			
			// Disable animations while dequeueing
			[UIView setAnimationsEnabled:NO]; {
				documentView = [self viewForDocument:document];
			} [UIView setAnimationsEnabled:animationsEnabled];
			
			if(!documentView) {
				// TODO
			}
			
			// Update the view opacity based on it's scroll offset
			[self updateDocumentViewOpacity:documentView];
		} else {
			// Enqueue if needed
			if(!_animatingContentOffset && !self.scrollView.dragging) {
				SFDocumentView* reuseableDocumentView = [self visibleViewForDocument:document];
			
				if(reuseableDocumentView) {
					[self enqueueReusableDocumentView:reuseableDocumentView];
				}
			}
		}
	}
	
	// Update text labels and page control
	if(!_animatingContentOffset && !_animatingDocumentDeletion) {
		[UIView setAnimationsEnabled:NO]; {
			[self layoutPageControl];
			[self layoutTextLabels];
		} [UIView setAnimationsEnabled:animationsEnabled];
	}
}

- (void)layoutPageControl {
	self.pageControl.numberOfPages = self.documents.count;
	
	NSInteger selectedDocumentIndex = [[self documents] indexOfObject:[self visibleDocument]];
	
	if(selectedDocumentIndex != NSNotFound) {
		self.pageControl.currentPage = selectedDocumentIndex;
	}
}

- (void)layoutTextLabels {
	self.textLabel.text = self.visibleDocument.title;
	self.detailTextLabel.text = self.visibleDocument.subtitle;
}

- (void)updateDocumentViewOpacity:(SFDocumentView*)documentView {
	// Adjust the document alpha
	CGFloat scrollViewWidth = CGRectGetWidth(self.scrollView.frame);
	
	CGPoint center = CGPointMake(
		floorf(CGRectGetMidX(self.scrollView.frame)),
		floorf(CGRectGetMidY(self.scrollView.frame)));
	
	CGPoint leftPoint = CGPointMake(
		center.x - (scrollViewWidth / 8.0),
		center.y);
	CGPoint rightPoint = CGPointMake(
		center.x + (scrollViewWidth / 8.0),
		center.y);
		
	CGPoint documentCenter = [self
		convertPoint:documentView.center
		fromView:[self scrollView]];
		
	CGFloat distance = MAX(documentCenter.x - leftPoint.x, rightPoint.x - documentCenter.x);
	CGFloat width = leftPoint.x - CGRectGetMinX(self.scrollView.frame);
	
	CGFloat alpha = width / fabs(distance);
	
	alpha = MIN(alpha, 1.0);
	alpha = MAX(alpha, 0.4);
	
	documentView.alpha = alpha;
	
	// Now adjust the close button alpha
	BOOL closeButtonShown = alpha >= 1.0 && !_animatingDocumentDeletion && !_maximizing; // CGRectIntersectsRect(centerRect, documentRect);
	[documentView
		setShowsCloseButton:closeButtonShown
		animated:self.scrollView.dragging];
		
	// TODO?
	if(alpha >= 0.8) {
		self.visibleDocument = documentView.document;
	}
}

- (void)updateDocuments:(NSArray*)documents {
	self.documents = documents;
	
	[self setNeedsDocumentLayout];
	
	CGSize contentSize = [self scrollViewContentSizeForDocuments:[self documents]];
	self.scrollView.contentSize = contentSize;
	
	for(id<SFDocument> document in documents) {
		SFDocumentView* documentView = [self visibleViewForDocument:document];
		
		if(documentView) {
			[self updateDocumentViewOpacity:documentView];
		}
	}
}

- (void)revealDocumentView:(id<SFDocument>)document {
	// First check if the document is already registered in our view
	BOOL needsToAddDocument = ![[self documents] containsObject:document];
	
	// Update the documents array if needed
	NSArray* newDocuments = needsToAddDocument ?
		[[self documents] arrayByAddingObject:document] :
		self.documents;
	self.documents = newDocuments;
	
	// Layout now
	[self setNeedsDocumentLayout];
	[self layoutIfNeeded];
	
	// Retrieve the visible document view and hide it
	SFDocumentView* documentView = [self viewForDocument:document];
	
	if(needsToAddDocument) {
		documentView.alpha = 0.0;
	}
	
	// Now animated the view smooooothly in
	[UIView beginAnimations:@"insertDocumentAnimation" context:(__bridge void *)(document)]; {
		if(_animatingDocumentDeletion) {
			[UIView setAnimationDuration:SFDocumentPickerContentOffsetAnimationDuration + 0.1];
		}

		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(insertDocumentViewAnimationDidStop:finished:context:)];
		
		documentView.alpha = 1.0;
	} [UIView commitAnimations];
}

- (void)insertDocumentViewAnimationDidStop:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context {
	// Enable user interaction again
	[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	
	// Make a new document array
	id<SFDocument> document = (__bridge id)context;
	
	// Notify our delegate about the insert
	if([[self delegate] respondsToSelector:@selector(documentPickerView:commitEditingStyle:forDocument:)]) {
		[[self delegate] documentPickerView:self commitEditingStyle:SFDocumentPickerViewEditingStyleInsert forDocument:document];
	}
}

- (void)scrollDocumentToVisible:(id<SFDocument>)document animated:(BOOL)animated {
	[self scrollDocumentToVisible:document animated:animated animationDuration:SFDocumentPickerContentOffsetAnimationDuration];
}

- (void)scrollDocumentToVisible:(id<SFDocument>)document animated:(BOOL)animated animationDuration:(CGFloat)animationDuration {
	if(document) {
		CGRect viewRect = [self viewRectForDocument:document inArray:[self documents]];
	
		CGPoint contentOffset = CGPointMake(
			floorf(CGRectGetMidX(viewRect) - CGRectGetWidth(self.documentVisibleRect) * 0.5),
			0.0);
		[self setContentOffset:contentOffset animated:animated animationDuration:animationDuration];
	}
}

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated {
	[self setContentOffset:contentOffset animated:animated animationDuration:SFDocumentPickerContentOffsetAnimationDuration];
}

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated animationDuration:(CGFloat)animationDuration {
	if(animated) {
		[UIView beginAnimations:@"setContentOffsetAnimation" context:NULL];
		
		[UIView setAnimationBeginsFromCurrentState:YES];
	
		[UIView setAnimationDuration:animationDuration];
		
		[UIView setAnimationDelegate:self];
		[UIView setAnimationWillStartSelector:@selector(contentOffsetAnimationWillStart:context:)];
		[UIView setAnimationDidStopSelector:@selector(contentOffsetAnimationDidStop:finished:context:)];
		
		_animatingContentOffset = YES;
	}

	self.scrollView.contentOffset = contentOffset;
	[self setNeedsDocumentLayout];
	
	if(animated) {
		[self layoutIfNeeded];
	
		[UIView commitAnimations];
	}
}

- (void)contentOffsetAnimationWillStart:(NSString*)animationID context:(void*)context {
}

- (void)contentOffsetAnimationDidStop:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context {
	_animatingContentOffset = NO;
	[self setNeedsDocumentLayout];
	[self layoutIfNeeded];
	
	self.selectedDocument = self.visibleDocument;
}

- (void)touchUpAtPoint:(CGPoint)point {
	// Do nothing while animating
	if(_animatingContentOffset) {
		return;
	}
	
	// Check if we hit the target rect
	CGRect eventTargetRect = CGRectMake(
		CGRectGetMinX(self.bounds),
		CGRectGetMinY(self.scrollView.frame),
		CGRectGetWidth(self.bounds),
		CGRectGetHeight(self.bounds) - CGRectGetMinY(self.scrollView.frame));
	
	if(!CGRectContainsPoint(eventTargetRect, point)) {
		return;
	}
	
	// Did we hit the selected document
	id<SFDocument> selectedDocument = self.visibleDocument;

	CGRect documentViewRect = [self
		viewRectForDocument:selectedDocument
		inArray:[self documents]];
	documentViewRect = [self convertRect:documentViewRect fromView:[self scrollView]];
	
	if(CGRectContainsPoint(documentViewRect, point)) {		
		self.selectedDocument = selectedDocument;
		
		if(CGAffineTransformIsIdentity(self.transform)) {
			[self dismiss:self];
		}
		
		return;
	}
	
	// Do we have to select the previous or next document
	NSInteger selectedDocumentIndex = [[self documents] indexOfObject:selectedDocument];
	NSInteger newSelectedDocumentIndex;
	
	if(point.x > self.center.x) {
		newSelectedDocumentIndex = selectedDocumentIndex + 1;
	} else {
		newSelectedDocumentIndex = selectedDocumentIndex - 1;
	}
	
	if(newSelectedDocumentIndex >= 0 && newSelectedDocumentIndex < self.documents.count) {
		id<SFDocument> newSelectedDocument = [[self documents] objectAtIndex:newSelectedDocumentIndex];
		[self scrollDocumentToVisible:newSelectedDocument animated:YES];
	}
}

- (void)minimizeDocument:(id<SFDocument>)document {
	// We don't want any user interaction during the animation
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	// First center our document
	[self scrollDocumentToVisible:document animated:NO];

	[self setNeedsLayout];
	[self layoutIfNeeded];
	
	// Retrieve the docment view
	SFDocumentView* documentView = [self visibleViewForDocument:document];
	[[documentView superview] bringSubviewToFront:documentView];
	
	// Now set the views transform to maximum
	CGAffineTransform transform = [self maximizeTransformForDocumentView:documentView];
	documentView.transform = transform;
	
	// Order out the previous and following documents, then order in animated at minimizeDocumentAnimationDidStop:
	NSInteger documentIndex = [[self documents] indexOfObject:document];
	
	SFDocumentView* previousDocumentView = nil;
	SFDocumentView* followingDocumentView = nil;
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if(documentIndex > 0) {
			previousDocumentView = [self visibleViewForDocument:
				[[self documents] objectAtIndex:documentIndex - 1]];
			previousDocumentView.alpha = 0.0;
		}
		
		if(documentIndex + 1 < self.documents.count) {
			followingDocumentView = [self visibleViewForDocument:
				[[self documents] objectAtIndex:documentIndex + 1]];
			followingDocumentView.alpha = 0.0;
		}
	}

	// Animate back to the identity transform for the desired effect
	[UIView beginAnimations:@"minimizeDocumentAnimation" context:NULL]; {
		[UIView setAnimationDuration:SFDocumentPickerMaximizeAnimationDuration];
//		[UIView setAnimationDelay:1.0];
//		[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
		
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(minimizeDocumentAnimationDidStop:finished:context:)];

		// Determine our minimize transform
		documentView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9);
		
		if(previousDocumentView) { [self updateDocumentViewOpacity:previousDocumentView]; }
		if(followingDocumentView) { [self updateDocumentViewOpacity:followingDocumentView]; }
	} [UIView commitAnimations];
}

- (void)minimizeDocumentAnimationDidStop:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context {
	// Animate back to the identity transform for the desired effect
	[UIView beginAnimations:@"minimizeDocumentAnimation" context:NULL]; {
		[UIView setAnimationDuration:SFDocumentPickerMaximizeAnimationDuration];
//		[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
		
		// Determine our minimize transform
		SFDocumentView* documentView = [self visibleViewForDocument:[self selectedDocument]];
		documentView.transform = CGAffineTransformIdentity;
	} [UIView commitAnimations];
	
	// Re-enable user interaction
	[[UIApplication sharedApplication] endIgnoringInteractionEvents];
}

- (void)maximizeDocument:(id<SFDocument>)document {
	// We don't want any user interaction during the animation
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	// Zoom in
	[UIView beginAnimations:@"maximizeDocumentAnimation" context:NULL]; {
		[UIView setAnimationDuration:SFDocumentPickerMaximizeAnimationDuration];
		
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(maximizeDocumentAnimationDidStop:finished:context:)];
		
		// First bring the document view to front
		SFDocumentView* documentView = [self visibleViewForDocument:document];
		[[documentView superview] bringSubviewToFront:documentView];
		
		// Tell our delegate
		if([[self delegate] respondsToSelector:@selector(documentPickerView:willFinishPickingDocument:)]) {
			[[self delegate] documentPickerView:self willFinishPickingDocument:document];
		}

		// Determine our maximize transform
		CGAffineTransform transform = [self maximizeTransformForDocumentView:documentView];
		documentView.transform = transform;
		
		// Order out the previous and following documents if needed
		if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			NSInteger documentIndex = [[self documents] indexOfObject:document];
		
			if(documentIndex > 0) {
				SFDocumentView* previousDocumentView = [self visibleViewForDocument:
					[[self documents] objectAtIndex:documentIndex - 1]];
				previousDocumentView.alpha = 0.0;
			}
		
			if(documentIndex + 1 < self.documents.count) {
				SFDocumentView* followingDocumentView = [self visibleViewForDocument:
					[[self documents] objectAtIndex:documentIndex + 1]];
				followingDocumentView.alpha = 0.0;
			}
		}
	} [UIView commitAnimations];
}

- (void)maximizeDocumentAnimationDidStop:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context {
	// Re-enable user interaction
	[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	_maximizing = NO;
	
	// Notify our delegate
	if([[self delegate] respondsToSelector:@selector(documentPickerView:didFinishPickingDocument:)]) {
		id<SFDocument> document = self.selectedDocument;
		[[self delegate] documentPickerView:self didFinishPickingDocument:document];
	}
}

- (CGAffineTransform)maximizeTransformForDocumentView:(SFDocumentView*)documentView {
	// Determine our view geometry
	CGRect documentContentRect = [documentView contentRectForBounds:[documentView bounds]];
	CGRect documentImageRect = [documentView imageRectForContentRect:documentContentRect];
	
	CGAffineTransform transform = CGAffineTransformIdentity;

	CGRect viewRect = self.bounds;
	
	if([[self delegate] respondsToSelector:@selector(documentPickerView:needsMaximizedRectForDocument:)]) {
		viewRect = [[self delegate] documentPickerView:self needsMaximizedRectForDocument:[documentView document]];
	}

	CGRect documentViewRect = [self
		convertRect:documentImageRect
		fromView:documentView];
		
	// First scale up
	CGFloat scaleX = CGRectGetWidth(viewRect) / CGRectGetWidth(documentViewRect);
	CGFloat scaleY = CGRectGetHeight(viewRect) / CGRectGetHeight(documentViewRect);

//	scaleY = scaleX; // TODO?

	transform = CGAffineTransformScale(transform, scaleX, scaleY);
		
	// Now reposition
	CGFloat offsetX = CGRectGetMidX(viewRect) - CGRectGetMidX(documentViewRect);
	CGFloat offsetY = CGRectGetMidY(viewRect) - CGRectGetMidY(documentViewRect);
	
	offsetX /= scaleX;
	offsetY /= scaleY;

	transform = CGAffineTransformTranslate(transform, offsetX, offsetY);
	
	return transform;
}

@end

#pragma mark -
#pragma mark SFDocumentPickerScrollView

@implementation SFDocumentPickerScrollView

- (BOOL)isDragging {
	return _dragging;
}

- (BOOL)touchesShouldBegin:(NSSet*)touches withEvent:(UIEvent*)event inContentView:(UIView*)view {
	return [super touchesShouldBegin:touches withEvent:event inContentView:view];
}

- (BOOL)touchesShouldCancelInContentView:(UIView*)view {
	return [super touchesShouldCancelInContentView:view];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent*)event {
	_touchDownTimestamp = _previousTouchTimestamp = event.timestamp;

	_touchDown = [[touches anyObject] locationInView:self];
	_touchesMoved = NO;

	[[self delegate] scrollViewWillBeginDragging:self];
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
	_dragging = YES;

	_touchesMoved = YES;

	_previousTouchTimestamp = event.timestamp;
		
	[self updateContentOffsetForTouches:touches withEvent:event];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
	_dragging = NO;
	
	NSTimeInterval delta = event.timestamp - _touchDownTimestamp;
	
	if(_touchesMoved) {
		[self updateContentOffsetForTouches:touches withEvent:event];
		[self endDraggingForTouches:touches withEvent:event];
	} if(touches.count == 1) {
		if(delta >= 0.025) {
			CGPoint point = [[touches anyObject] locationInView:[self superview]];
			[(id)[self superview] touchUpAtPoint:point];
		}
	}
	
	_touchDownTimestamp = 0;
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
	_dragging = NO;
	
	[self updateContentOffsetForTouches:touches withEvent:event];
	[self endDraggingForTouches:touches withEvent:event];
}

- (void)updateContentOffsetForTouches:(NSSet*)touches withEvent:(UIEvent*)event {
	CGPoint previousPoint = [[touches anyObject]
		previousLocationInView:self];
	CGPoint point = [[touches anyObject]
		locationInView:self];
		
	CGFloat deltaX = previousPoint.x - point.x;

	CGPoint contentOffset = self.contentOffset;
	self.contentOffset = CGPointMake(contentOffset.x + deltaX, contentOffset.y);
}

- (void)endDraggingForTouches:(NSSet*)touches withEvent:(UIEvent*)event {
	[[self delegate] scrollViewDidEndDragging:self willDecelerate:NO];
}

@end
