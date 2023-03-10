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

#import "SAScopeBarSegmentedControl.h"

#import "UIButton+Graphite.h"
#import "UILabel+Graphite.h"

@implementation SAScopeBarSegmentedControl

@dynamic segments;
@synthesize segmentLabels = _segmentLabels;
@dynamic selectedSegmentIndex;
@dynamic highlightedSegmentIndex;
@dynamic showsCalloutButton;
@synthesize calloutIndicatorView = _calloutIndicatorView;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
		// Init some Ivars
		self.selectedSegmentIndex = 0;
		self.highlightedSegmentIndex = -1;
		self.showsCalloutButton = NO;
		
		self.contentMode = UIViewContentModeRedraw;
		
		// Init the indicator image
		UIImageView* calloutIndicatorView = [[UIImageView alloc] initWithImage:nil];
		
		calloutIndicatorView.image = [UIImage imageNamed:@"scopeBarDisclosureIndicator.png"];
		calloutIndicatorView.highlightedImage = [UIImage imageNamed:@"scopeBarDisclosureIndicatorHighlighted.png"];
		
		[calloutIndicatorView sizeToFit];
		
		self.calloutIndicatorView = calloutIndicatorView;
		
		// Listen for control events
		[self addTarget:self action:@selector(controlDidTouchDown:event:) forControlEvents:UIControlEventTouchDown];
		[self addTarget:self action:@selector(controlDidDragInside:event:) forControlEvents:UIControlEventTouchDragInside|UIControlEventTouchDragEnter];
		[self addTarget:self action:@selector(controlDidCancel:event:) forControlEvents:UIControlEventTouchCancel|UIControlEventTouchUpOutside|UIControlEventTouchDragExit];
		[self addTarget:self action:@selector(controlDidTouchUpInside:event:) forControlEvents:UIControlEventTouchUpInside];
	}

    return self;
}

- (void)dealloc {
	self.segments = nil;

}

#pragma mark -
#pragma mark SAScopeBarSegmentedControl

- (NSArray*)segments {
	return _segments;
}

- (void)setSegments:(NSArray*)segments {
	if(segments != _segments) {
		_segments = [segments copy];
		
		[self updateSegmentLabels];
		[self setNeedsDisplay];
		[self setNeedsLayout];
	}
}

- (NSInteger)selectedSegmentIndex {
	return _selectedSegmentIndex;
}

- (void)setSelectedSegmentIndex:(NSInteger)selectedSegmentIndex {
	if(self.selectedSegmentIndex != selectedSegmentIndex) {
		_selectedSegmentIndex = selectedSegmentIndex;
		[self setNeedsDisplay];
		[self setNeedsLayout];
	}
}

- (NSInteger)highlightedSegmentIndex {
	return _highlightedSegmentIndex;
}

- (void)setHighlightedSegmentIndex:(NSInteger)highlightedSegmentIndex {
	if(self.highlightedSegmentIndex != highlightedSegmentIndex) {
		_highlightedSegmentIndex = highlightedSegmentIndex;
		[self setNeedsDisplay];
		[self setNeedsLayout];
	}
}

- (BOOL)showsCalloutButton {
	return _showsCalloutButton;
}

- (void)setShowsCalloutButton:(BOOL)showsCalloutButton {
	if(self.showsCalloutButton != showsCalloutButton) {
		_showsCalloutButton = showsCalloutButton;
		[self setNeedsDisplay];
		[self setNeedsLayout];
	}
}

#pragma mark -
#pragma mark UIView

- (CGSize)sizeThatFits:(CGSize)size {
	CGFloat const margin = 15.0;
	CGFloat width = 0.0;
	
	for(UILabel* segmentLabel in self.segmentLabels) {
		width += [segmentLabel sizeThatFits:size].width + margin * 2.0;
	}
	
	if(self.showsCalloutButton) {
		width += 10.0;
	}
	
	return CGSizeMake(MAX(width, 220.0), 30.0);
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	NSInteger segmentIndex = 0;
	
	for(UILabel* segmentLabel in self.segmentLabels) {
		CGRect segmentRect = [self rectForSegmentAtIndex:segmentIndex];
		
		CGSize labelSize = [segmentLabel sizeThatFits:segmentRect.size];
		
		if(self.showsCalloutButton && segmentIndex + 1 == self.segments.count) {
			labelSize.width = MIN(labelSize.width, CGRectGetWidth(segmentRect) - 16.0);
		}
		
		CGRect labelRect = CGRectMake(
			floorf(CGRectGetMidX(segmentRect) - labelSize.width * 0.5),
			floorf(CGRectGetMidY(segmentRect) - labelSize.height * 0.5),
			MIN(labelSize.width, CGRectGetWidth(segmentRect)),
			labelSize.height);
			
		BOOL highlighted =
			segmentIndex == self.selectedSegmentIndex ||
			segmentIndex == self.highlightedSegmentIndex;
		
		if(self.showsCalloutButton && segmentIndex + 1 == self.segments.count) {
			labelRect.origin.x -= 4.0;
			
			CGRect calloutIndicatorRect = self.calloutIndicatorView.frame;
			
			calloutIndicatorRect.origin.x = CGRectGetMaxX(labelRect) + 2.0;
			calloutIndicatorRect.origin.y = ceilf(CGRectGetMidY(labelRect) - CGRectGetHeight(calloutIndicatorRect) * 0.5);
			
			if(!highlighted) {
				calloutIndicatorRect.origin.y += 1.0;
			}
			
			self.calloutIndicatorView.frame = calloutIndicatorRect;
			
			self.calloutIndicatorView.hidden = NO;
			self.calloutIndicatorView.highlighted = highlighted;
			
			[self insertSubview:[self calloutIndicatorView] aboveSubview:segmentLabel];
		} else {
			self.calloutIndicatorView.hidden = YES;
		}
		
		segmentLabel.frame = labelRect;
			
		segmentLabel.highlighted = highlighted;
		
		if(segmentLabel.highlighted) {
			segmentLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:1.0 / 3.0];
			segmentLabel.shadowOffset = CGSizeMake(0.0, -1.0);
		} else {
			segmentLabel.shadowColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
			segmentLabel.shadowOffset = CGSizeMake(0.0, 1.0);
		}
			
		++segmentIndex;
	}
}

- (void)drawRect:(CGRect)rect {
	CGFloat const capWidth = 6.0;

	NSArray* segments = self.segments;

	CGRect bounds = self.bounds;
	CGFloat segmentWidth = floorf(CGRectGetWidth(bounds) / MAX(segments.count, 1));

	// Draw the control background
    UIImage* backgroundImage = [[UIImage imageNamed:@"graphiteBarButtonBackground.png"]
		stretchableImageWithLeftCapWidth:capWidth topCapHeight:0.0];
	
	CGRect backgroundRect = bounds;
	backgroundRect.size.width = segmentWidth * self.segments.count;

	[backgroundImage drawInRect:backgroundRect];

	// Now draw the selected segment if needed
	NSInteger selectedSegmentIndex = self.selectedSegmentIndex;
	NSInteger highlightedSegmentIndex = self.highlightedSegmentIndex;
	
	for(NSInteger segmentIndex = 0; segmentIndex < self.segments.count; ++segmentIndex) {
		UIImage* selectedBackgroundImage = nil;
	
		if(segmentIndex == highlightedSegmentIndex) {
			selectedBackgroundImage = [[UIImage imageNamed:@"graphiteDoneBarButtonBackgroundHighlighted.png"]
				stretchableImageWithLeftCapWidth:capWidth topCapHeight:0.0];
		} else if(segmentIndex == selectedSegmentIndex) {
			selectedBackgroundImage = [[UIImage imageNamed:@"graphiteBarButtonBackgroundSelected.png"]
				stretchableImageWithLeftCapWidth:capWidth topCapHeight:0.0];
		} else {
			continue;
		}
		
		CGContextSaveGState(UIGraphicsGetCurrentContext());
	
		CGRect clipRect = [self rectForSegmentAtIndex:segmentIndex];
		UIRectClip(clipRect);
		
		[[UIColor clearColor] set];
		UIRectFill(clipRect);
		
		CGRect selectedSegmentRect = clipRect;
		
		if(segmentIndex == 0) {
			selectedSegmentRect.size.width += capWidth;
		} else if(segmentIndex + 1 == self.segments.count) {
			selectedSegmentRect.size.width += capWidth;
			selectedSegmentRect.origin.x -= capWidth;
		} else {
			selectedSegmentRect.size.width += capWidth * 2.0;
			selectedSegmentRect.origin.x -= capWidth;
		}
		
		[selectedBackgroundImage drawInRect:selectedSegmentRect];
		
		CGContextRestoreGState(UIGraphicsGetCurrentContext());
	}
	
	// Draw the segment separators
	if(segments.count > 1) {
		UIImage* separatorImage = [UIImage imageNamed:@"scopeBarButtonSeparator.png"];
		
		for(NSInteger segmentIndex = 1; segmentIndex < segments.count; ++segmentIndex) {
			CGRect segmentRect = [self rectForSegmentAtIndex:segmentIndex];
			CGRect separatorRect = CGRectMake(
				CGRectGetMinX(segmentRect), CGRectGetMinY(segmentRect) + 0.0,
				separatorImage.size.width, CGRectGetHeight(segmentRect) - 1.0);
			BOOL selectedSeparator =
				segmentIndex == selectedSegmentIndex ||
				segmentIndex == selectedSegmentIndex + 1;
			[separatorImage
				drawInRect:separatorRect
				blendMode:kCGBlendModeNormal
				alpha:selectedSeparator ? 0.8 : 0.8];
		}
	}
}

#pragma mark -
#pragma mark Private

- (void)updateSegmentLabels {
	NSMutableArray* segmentLabels = [NSMutableArray arrayWithCapacity:[[self segments] count]];
	NSInteger segmentIndex = 0;

	for(NSString* segment in self.segments) {
		UILabel* segmentLabel = nil;
		
		if([[self segmentLabels] count] > segmentIndex) {
			segmentLabel = [[self segmentLabels] objectAtIndex:segmentIndex];
		} else {
			segmentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
			[segmentLabel setGraphiteStyle];
			
			segmentLabel.adjustsFontSizeToFitWidth = NO;
			
			[self addSubview:segmentLabel];
		}
		
		[segmentLabel setText:segment];
		[segmentLabels addObject:segmentLabel];
		
		++segmentIndex;
	}
	
	for(UIView* subview in self.segmentLabels) {
		if(![segmentLabels containsObject:subview]) {
			[subview removeFromSuperview];
		}
	}
	
	self.segmentLabels = segmentLabels;
}

- (CGRect)rectForSegmentAtIndex:(NSInteger)segmentIndex {
	CGRect bounds = self.bounds;
	CGFloat segmentWidth = floorf(CGRectGetWidth(bounds) / MAX(self.segments.count, 1));
	
	CGRect segmentRect = CGRectMake(
		floorf(CGRectGetMinX(bounds) + segmentWidth * segmentIndex), CGRectGetMinY(bounds),
		segmentWidth, CGRectGetHeight(bounds));
		
	if(self.showsCalloutButton) {
		CGFloat const calloutImageWidth = 10.0;
		
		if(segmentIndex + 1 == self.segments.count) {
			segmentRect.origin.x -= calloutImageWidth;
			segmentRect.size.width += calloutImageWidth;
		} else {
			CGFloat offsetWidth = ceilf(calloutImageWidth / (self.segments.count - 1));
			
			if(segmentIndex != 0) {
				segmentRect.origin.x -= offsetWidth;
			}
			
			segmentRect.size.width -= offsetWidth;
		}
	}

	return segmentRect;
}

- (void)controlDidTouchDown:(id)sender event:(UIEvent*)event {
	CGPoint location = [[[event allTouches] anyObject] locationInView:self];
	
	self.highlightedSegmentIndex = -1;
	
	NSInteger selectedSegmentIndex = self.selectedSegmentIndex;
	
	for(NSInteger segmentIndex = 0; segmentIndex < self.segments.count; ++segmentIndex) {
		if(CGRectContainsPoint([self rectForSegmentAtIndex:segmentIndex], location)) {
			if(self.showsCalloutButton && segmentIndex + 1 == self.segments.count) {
				self.highlightedSegmentIndex = segmentIndex;
			} else {
				self.selectedSegmentIndex = segmentIndex;
				self.highlightedSegmentIndex = -1;
			}
		}
	}
	
	[self setNeedsLayout];
	
	if(self.selectedSegmentIndex != selectedSegmentIndex) {
		[self sendActionsForControlEvents:UIControlEventValueChanged];
	}
}

- (void)controlDidDragInside:(id)sender event:(UIEvent*)event {
	if(self.showsCalloutButton) {
		CGPoint location = [[[event allTouches] anyObject] locationInView:self];
		NSUInteger calloutSegmentIndex = self.segments.count - 1;
		
		self.highlightedSegmentIndex = CGRectContainsPoint([self rectForSegmentAtIndex:calloutSegmentIndex], location) ?
			calloutSegmentIndex :
			-1;
	} else {
		self.highlightedSegmentIndex = -1;
	}
	
	[self setNeedsLayout];
}

- (void)controlDidCancel:(id)sender event:(UIEvent*)event {
	self.highlightedSegmentIndex = -1;
	[self setNeedsLayout];
}

- (void)controlDidTouchUpInside:(id)sender event:(UIEvent*)event {
	if(self.showsCalloutButton) {
		CGPoint location = [[[event allTouches] anyObject] locationInView:self];
		NSUInteger calloutSegmentIndex = self.segments.count - 1;

		if(CGRectContainsPoint([self rectForSegmentAtIndex:calloutSegmentIndex], location)) {
			[self sendActionsForControlEvents:SAScopeBarEventTouchUpInsideCalloutButton];
		}
	}
	
	self.highlightedSegmentIndex = -1;
	
	[self setNeedsLayout];
}

@end
