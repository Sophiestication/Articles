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

#import "SFSegmentedControl.h"
#import "SFSegmentedControl+Private.h"

#import "SFGraphics.h"

@implementation SFSegmentedControl

@dynamic interfaceStyle;

@dynamic selectedSegmentIndex;
@dynamic highlightedSegmentIndex;

@synthesize backgroundImage = _backgroundImage;
@synthesize highlightedBackgroundImage = _highlightedBackgroundImage;
@synthesize selectedBackgroundImage = _selectedBackgroundImage;
@synthesize initiallySelectedSegmentIndex = _initiallySelectedSegmentIndex;

@synthesize items = _items;

@synthesize momentary = _momentary;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithItems:(NSArray*)items {
   return [self initWithItems:items interfaceStyle:SFGraphicsInterfaceStyleGraphite];
}

- (id)initWithItems:(NSArray*)items interfaceStyle:(SFGraphicsInterfaceStyle)interfaceStyle {
	 if((self = [super initWithFrame:CGRectZero])) {
		self.interfaceStyle = interfaceStyle;

		[self initIvars];

		self.items = [self itemsForUserInfo:items];
		[self sizeToFit];
	}

    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];



}

#pragma mark -
#pragma mark SASegmentedControl

- (SFGraphicsInterfaceStyle)interfaceStyle {
	return _interfaceStyle;
}

- (void)setInterfaceStyle:(SFGraphicsInterfaceStyle)interfaceStyle {
	if(interfaceStyle != self.interfaceStyle) {
		_interfaceStyle = interfaceStyle;
		[self setNeedsLayout];
		[self setNeedsDisplay];
	}
}

- (NSInteger)selectedSegmentIndex {
	return _selectedSegmentIndex;
}

- (void)setSelectedSegmentIndex:(NSInteger)selectedSegmentIndex {
	if(selectedSegmentIndex != self.selectedSegmentIndex) {
		_selectedSegmentIndex = selectedSegmentIndex;
		[self setNeedsDisplay];
		[self setNeedsLayout];
	}
}

- (NSInteger)highlightedSegmentIndex {
	return _highlightedSegmentIndex;
}

- (void)setHighlightedSegmentIndex:(NSInteger)highlightedSegmentIndex {
	if(highlightedSegmentIndex != self.highlightedSegmentIndex) {
		_highlightedSegmentIndex = highlightedSegmentIndex;
		[self setNeedsDisplay];
		[self setNeedsLayout];
	}
}

- (void)setView:(UIView*)view forSegmentAtIndex:(NSUInteger)segment {
	NSMutableDictionary* item = [[self items] objectAtIndex:segment];
	[item setObject:view forKey:@"view"];

	[self setNeedsLayout];
}

- (UIView*)viewForSegmentAtIndex:(NSUInteger)segment {
	return [[[self items]
		objectAtIndex:segment]
		objectForKey:@"view"];
}

- (void)setEnabled:(BOOL)enabled forSegmentAtIndex:(NSUInteger)segment {
	return; // TODO
	
	if([self isEnabledForSegmentAtIndex:segment] != enabled) {
		NSMutableDictionary* item = [[self items] objectAtIndex:segment];
		[item setObject:[NSNumber numberWithBool:enabled] forKey:@"enabled"];
		
		[self setNeedsDisplay];
		[self setNeedsLayout];
	}
}

- (BOOL)isEnabledForSegmentAtIndex:(NSUInteger)segment {
	return [[[[self items]
		objectAtIndex:segment]
		objectForKey:@"enabled"]
		boolValue];
}

#pragma mark -
#pragma mark UIView

- (CGSize)sizeThatFits:(CGSize)size {
	static const CGFloat margin = 10.0;
	CGFloat width = 0.0;
	
	for(NSDictionary* item in self.items) {
		UIView* view = [item objectForKey:@"view"];
		width += [view sizeThatFits:size].width + margin * 2.0;
	}
	
	if(self.items.count > 1) {
		width += (self.items.count * 1.0) - 1.0; // We use 1px width separators, leave out the last one
	}
	
	CGFloat height = 30.0;
	
	if(UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) &&
	   UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		height = 25.0;
	}
	
	return CGSizeMake(MAX(width, 44.0), height);
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	
	NSArray* items = self.items;

	CGRect bounds = self.bounds;
//	CGFloat segmentWidth = floorf(CGRectGetWidth(bounds) / MAX(items.count, 1));

	NSInteger selectedSegmentIndex = self.selectedSegmentIndex;
	NSInteger highlightedSegmentIndex = self.highlightedSegmentIndex;

	// Draw the control background
    CGRect backgroundRect = bounds;
//	backgroundRect.size.width = segmentWidth * items.count;

	if(items.count == 1 && highlightedSegmentIndex == 0) {
		[[self highlightedBackgroundImage] drawInRect:backgroundRect];
	} else if(items.count == 1 && selectedSegmentIndex == 0) {
		[[self selectedBackgroundImage] drawInRect:backgroundRect];
	} else {
		[[self backgroundImage] drawInRect:backgroundRect];
	}
	
	// Now draw the selected segment if needed
	if(items.count > 1) {
		for(NSInteger segmentIndex = 0; segmentIndex < items.count; ++segmentIndex) {
			UIImage* selectedBackgroundImage = nil;
		
			if(segmentIndex == highlightedSegmentIndex && self.momentary) {
				selectedBackgroundImage = self.highlightedBackgroundImage;
			} else if(segmentIndex == selectedSegmentIndex) {
				selectedBackgroundImage = self.selectedBackgroundImage;
			} else {
				continue;
			}
			
			CGContextSaveGState(UIGraphicsGetCurrentContext()); {
		
				CGRect clipRect = [self rectForSegmentAtIndex:segmentIndex];
				UIRectClip(clipRect);
				
				[[UIColor clearColor] set];
				UIRectFill(clipRect);
				
				CGRect selectedSegmentRect = clipRect;
				CGFloat const capWidth = [self segmentCapWidth];
				
				if(segmentIndex == 0) {
					selectedSegmentRect.size.width += capWidth;
				} else if(segmentIndex + 1 == items.count) {
					selectedSegmentRect.size.width += capWidth;
					selectedSegmentRect.origin.x -= capWidth;
				} else {
					selectedSegmentRect.size.width += capWidth * 2.0;
					selectedSegmentRect.origin.x -= capWidth;
				}
				
				[selectedBackgroundImage drawInRect:selectedSegmentRect];
			
			} CGContextRestoreGState(UIGraphicsGetCurrentContext());
		}
	}
	
	// Draw the segment separators
	if(items.count > 1) {
		UIImage* separatorImage = self.interfaceStyle == SFGraphicsInterfaceStyleDocumentSearch ?
			[UIImage imageNamed:@"documentSearchButtonSeparator.png"] :
			[UIImage imageNamed:@"scopeBarButtonSeparator.png"];
		
		for(NSInteger segmentIndex = 1; segmentIndex < items.count; ++segmentIndex) {
			CGRect segmentRect = [self rectForSegmentAtIndex:segmentIndex];

			CGRect separatorRect = CGRectMake(
				floorf(CGRectGetMinX(segmentRect) - 0.5),
				floorf(CGRectGetMidY(segmentRect) - separatorImage.size.height * 0.5),
				separatorImage.size.width,
				CGRectGetHeight(segmentRect) - 2.0);

			// TODO	
			if(CGRectGetHeight(segmentRect) >= 30.0) {
				// separatorRect = CGRectOffset(separatorRect, 0.0, -2.0);
			} else {
				separatorRect.origin.y += 2.0;
				// separatorRect.size.height -= 2.0;
			}
			
			BOOL selectedSeparator =
				segmentIndex == selectedSegmentIndex ||
				segmentIndex == selectedSegmentIndex + 1;

			[separatorImage
				drawInRect:separatorRect
				blendMode:kCGBlendModeNormal // selectedSeparator ? kCGBlendModeNormal : kCGBlendModeSoftLight
				alpha:selectedSeparator ? 0.8 : 0.9];
		}
	}
	
	// Draw all images if needed
	for(NSInteger segmentIndex = 0; segmentIndex < items.count; ++segmentIndex) {
		// Does this segment item already have a UIView and do we have an image at all?
		UIView* view = [self viewForSegmentAtIndex:segmentIndex];
		
		UIImage* segmentImage = [[[self items]
			objectAtIndex:segmentIndex]
			objectForKey:@"image"];
		
		if(!segmentImage || view) {
			continue;
		}
		
		// Now draw our styled image on top of the background
		CGSize segmentImageSize = segmentImage.size;
		
		CGRect segmentRect = [self rectForSegmentAtIndex:segmentIndex];
		CGRect segmentImageRect = CGRectMake(
			floorf(CGRectGetMidX(segmentRect) - segmentImageSize.width * 0.5),
			floorf(CGRectGetMidY(segmentRect) - segmentImageSize.height * 0.5),
			segmentImageSize.width,
			segmentImageSize.height);
			
		if(segmentIndex == 0) {
			segmentImageRect = CGRectOffset(segmentImageRect, -1.0, 0.0);
		}
		
		UIControlState controlState = UIControlStateNormal;
		
		if(self.selectedSegmentIndex == segmentIndex) { controlState |= UIControlStateSelected; }
		if(self.highlightedSegmentIndex == segmentIndex) { controlState |= UIControlStateHighlighted; }
		
		SFGraphicsDrawImage(
			segmentImage,
			segmentImageRect,
			SFGraphicsInterfaceStyleGraphite,
			controlState);
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];

	for(NSInteger segmentIndex = 0; segmentIndex < self.items.count; ++segmentIndex) {
		UIView* view = [[[self items]
			objectAtIndex:segmentIndex]
			objectForKey:@"view"];
		
		if(view) {
			CGRect segmentRect = [self rectForSegmentAtIndex:segmentIndex];
			
			CGSize contentSize = segmentRect.size;
			
			if(CGRectGetHeight(segmentRect) < 30.0) {
				contentSize.height -= 4.0;
			}
			
			CGSize viewSize = [view sizeThatFits:contentSize];
			viewSize.height = MIN(viewSize.height, contentSize.height);
			
			CGRect viewRect = CGRectMake(
				floorf(CGRectGetMidX(segmentRect) - viewSize.width * 0.5),
				ceilf(CGRectGetMidY(segmentRect) - viewSize.height * 0.5),
				viewSize.width,
				viewSize.height);
				
			if(segmentIndex == 0) {
				viewRect = CGRectOffset(viewRect, 1.0, 0.0);
			}
				
			view.frame = viewRect;
			
			if([view respondsToSelector:@selector(isHighlighted)]) {
				BOOL highlighted =
					segmentIndex == self.selectedSegmentIndex ||
					segmentIndex == self.highlightedSegmentIndex;
				[(id)view setHighlighted:highlighted];
			}
			
			if([view respondsToSelector:@selector(isEnabled)]) {
				BOOL enabled = [self isEnabledForSegmentAtIndex:segmentIndex];
				[(id)view setEnabled:enabled];
			}
		}
	}
}

#pragma mark -
#pragma mark Private

- (void)initIvars {
	self.opaque = NO;
	self.backgroundColor = [UIColor clearColor];
	
	self.clipsToBounds = YES;
	
	self.selectedSegmentIndex = UISegmentedControlNoSegment;
	self.highlightedSegmentIndex = UISegmentedControlNoSegment;
	self.initiallySelectedSegmentIndex = UISegmentedControlNoSegment;
	
	self.momentary = NO;
	
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	[self updateForInterfaceOrientation:orientation];

	[self addTarget:self action:@selector(controlDidTouchDown:event:) forControlEvents:UIControlEventTouchDown];
	[self addTarget:self action:@selector(controlDidDragInside:event:) forControlEvents:UIControlEventTouchDragInside|UIControlEventTouchDragEnter];
	[self addTarget:self action:@selector(controlDidCancel:event:) forControlEvents:UIControlEventTouchCancel|UIControlEventTouchUpOutside|UIControlEventTouchDragExit];
	[self addTarget:self action:@selector(controlDidTouchUpInside:event:) forControlEvents:UIControlEventTouchUpInside];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(applicationDidChangeStatusBar:)
		name:UIApplicationDidChangeStatusBarOrientationNotification
		object:nil];
}

- (NSDictionary*)itemForUserInfo:(id)userInfo {
	UIView* view = nil;
	UIImage* image = nil;
	
	if([userInfo isKindOfClass:[UIView class]]) {
		view = userInfo;
	} else if([userInfo isKindOfClass:[UIImage class]]) {
		// view = [[[UIImageView alloc] initWithImage:userInfo] autorelease];
		image = userInfo;
	} else if([userInfo isKindOfClass:[NSString class]]) {
		UILabel* label = [[UILabel alloc] initWithFrame:CGRectZero];
		
		label.text = userInfo;
		// TODO Setup fonts and such…
		
		view = label;
	}
	
	view.contentMode = UIViewContentModeScaleAspectFit;
	view.userInteractionEnabled = NO;
	
	if(view.superview != self) {
		[self addSubview:view];
	}
	
	NSDictionary* item = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		userInfo, @"value",
		view, @"view",
		image, @"image", // can be nil
		nil];
		
	return item;
}

- (NSArray*)itemsForUserInfo:(NSArray*)userInfo {
	NSMutableArray* items = [NSMutableArray arrayWithCapacity:[userInfo count]];
	
	for(id info in userInfo) {
		NSDictionary* item = [self itemForUserInfo:info];
		[items addObject:item];
	}
	
	return items;
}

- (CGFloat)segmentCapWidth {
	return 6.0;
}

- (CGRect)rectForSegmentAtIndex:(NSInteger)segmentIndex {
	CGRect bounds = self.bounds;
	CGFloat segmentWidth = floorf(CGRectGetWidth(bounds) / MAX(self.items.count, 1));
	
	CGRect segmentRect = CGRectMake(
		floorf(CGRectGetMinX(bounds) + segmentWidth * segmentIndex),
		CGRectGetMinY(bounds),
		segmentWidth,
		CGRectGetHeight(bounds));
		
	if(self.items.count > 1 && segmentIndex > 0) {
		segmentRect = CGRectOffset(segmentRect, 1.0, 0.0);
	}

	return segmentRect;
}

- (void)controlDidTouchDown:(id)sender event:(UIEvent*)event {
	NSInteger segmentIndex = [self segmentIndexForEvent:event];
	
	if(!self.momentary && self.selectedSegmentIndex != segmentIndex) {
		[self sendActionsForControlEvents:UIControlEventValueChanged];
	}
	
	self.highlightedSegmentIndex = segmentIndex;
	self.initiallySelectedSegmentIndex = segmentIndex;
	
	if(!self.momentary) {
		self.selectedSegmentIndex = segmentIndex;
	}
	
	if(segmentIndex != UISegmentedControlNoSegment) {
		[self setNeedsLayout];
		[self setNeedsDisplay];
	}
}

- (void)controlDidDragInside:(id)sender event:(UIEvent*)event {
	if(self.momentary) {
		NSInteger segmentIndex = [self segmentIndexForEvent:event];
		
		if(segmentIndex != self.highlightedSegmentIndex) {
			self.highlightedSegmentIndex = segmentIndex == self.initiallySelectedSegmentIndex ?
				segmentIndex :
				UISegmentedControlNoSegment;
			
			[self setNeedsLayout];
			[self setNeedsDisplay];
		}
	} else {
		self.highlightedSegmentIndex = UISegmentedControlNoSegment;
	}
}

- (void)controlDidCancel:(id)sender event:(UIEvent*)event {
	self.highlightedSegmentIndex = UISegmentedControlNoSegment;
	self.initiallySelectedSegmentIndex = UISegmentedControlNoSegment;
	
	if(self.momentary) {
		self.selectedSegmentIndex = UISegmentedControlNoSegment;
	}
}

- (void)controlDidTouchUpInside:(id)sender event:(UIEvent*)event {
	if(self.momentary &&
	   self.highlightedSegmentIndex != UISegmentedControlNoSegment) {
		[self sendActionsForControlEvents:UIControlEventValueChanged];
	}

	[self controlDidCancel:sender event:event];
}

- (void)applicationDidChangeStatusBar:(NSNotification*)notification {
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	[self updateForInterfaceOrientation:orientation];
	
	[self sizeToFit];
}

- (void)updateForInterfaceOrientation:(UIInterfaceOrientation)orientation {
	const NSInteger capWidth = [self segmentCapWidth];
	
	if(self.interfaceStyle == SFGraphicsInterfaceStyleGraphite) {
		if(UIInterfaceOrientationIsPortrait(orientation)) {
			self.backgroundImage = [[UIImage imageNamed:@"graphiteBarButtonBackground.png"]
				stretchableImageWithLeftCapWidth:capWidth topCapHeight:0.0];
			self.highlightedBackgroundImage = [[UIImage imageNamed:@"graphiteDoneBarButtonBackgroundHighlighted.png"]
				stretchableImageWithLeftCapWidth:capWidth topCapHeight:0.0];
			self.selectedBackgroundImage = [[UIImage imageNamed:@"graphiteDoneBarButtonBackground.png"]
				stretchableImageWithLeftCapWidth:capWidth topCapHeight:0.0];
		} else {
			self.backgroundImage = [[UIImage imageNamed:@"graphiteMiniBarButtonBackground.png"]
				stretchableImageWithLeftCapWidth:capWidth topCapHeight:0.0];
			self.highlightedBackgroundImage = [[UIImage imageNamed:@"graphiteMiniDoneBarButtonBackgroundHighlighted.png"]
				stretchableImageWithLeftCapWidth:capWidth topCapHeight:0.0];
			self.selectedBackgroundImage = [[UIImage imageNamed:@"graphiteMiniDoneBarButtonBackground.png"]
				stretchableImageWithLeftCapWidth:capWidth topCapHeight:0.0];
		}
	}
	
	if(self.interfaceStyle == SFGraphicsInterfaceStyleDocumentSearch) {
		if(UIInterfaceOrientationIsPortrait(orientation)) {
			self.backgroundImage = [[UIImage imageNamed:@"documentSearchButtonBackground.png"]
				stretchableImageWithLeftCapWidth:capWidth topCapHeight:0.0];
			self.highlightedBackgroundImage = [[UIImage imageNamed:@"documentSearchButtonBackgroundHighlighted.png"]
				stretchableImageWithLeftCapWidth:capWidth topCapHeight:0.0];
			self.selectedBackgroundImage = [[UIImage imageNamed:@"documentSearchButtonBackgroundHighlighted.png"]
				stretchableImageWithLeftCapWidth:capWidth topCapHeight:0.0];
		} else {
			self.backgroundImage = [[UIImage imageNamed:@"documentSearchSmallButtonBackground.png"]
				stretchableImageWithLeftCapWidth:capWidth topCapHeight:0.0];
			self.highlightedBackgroundImage = [[UIImage imageNamed:@"documentSearchSmallButtonBackgroundHighlighted.png"]
				stretchableImageWithLeftCapWidth:capWidth topCapHeight:0.0];
			self.selectedBackgroundImage = [[UIImage imageNamed:@"documentSearchSmallButtonBackgroundHighlighted.png"]
				stretchableImageWithLeftCapWidth:capWidth topCapHeight:0.0];
		}
	}
	
	[self setNeedsLayout];
	[self setNeedsDisplay];
}

- (NSInteger)segmentIndexForEvent:(UIEvent*)event {
	CGPoint location = [[[event allTouches] anyObject] locationInView:self];
	
	NSInteger highlightedSegmentIndex = UISegmentedControlNoSegment;
	
	for(NSInteger segmentIndex = 0; segmentIndex < self.items.count; ++segmentIndex) {
		if(CGRectContainsPoint([self rectForSegmentAtIndex:segmentIndex], location)) {
			highlightedSegmentIndex = segmentIndex;
			
			break;
		}
	}
	
	return highlightedSegmentIndex;
}

@end
