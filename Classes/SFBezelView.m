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

#import "SFBezelView.h"
#import "SFBezelView+Private.h"

@implementation SFBezelView

@synthesize delegate = _delegate;
@synthesize imageView = _imageView;
@synthesize textLabel = _textLabel;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
	frame.size = [[self class] bezelViewSize];

    if((self = [super initWithFrame:frame])) {
		[self initIvars];
		[self initImageView];
		[self initTextLabel];
		
		[self layoutIfNeeded];
    }

    return self;
}

- (void)dealloc {
	self.delegate = nil;


}

#pragma mark -
#pragma mark SFBezelView

+ (CGSize)bezelViewSize {
	return CGSizeMake(160.0, 160.0);
}

- (BOOL)isVisible {
	return _visible;
}

- (void)setVisible:(BOOL)visible {
	[self setVisible:visible animated:NO];
}

- (void)setVisible:(BOOL)visible animated:(BOOL)animated {
	if(visible != self.visible) {
		if(animated) {
			[UIView beginAnimations:@"bezelViewAnimation" context:NULL];
			
			[UIView setAnimationDuration:visible ? 0.25 : 0.75];
			[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
			
			[UIView setAnimationDelegate:self];
			[UIView setAnimationWillStartSelector:@selector(visibilityAnimationWillStart:context:)];
			[UIView setAnimationDidStopSelector:@selector(visibilityAnimationDidStop:finished:context:)];
		} else {
			[self delegateSelectorIfNeeded:visible ?
				@selector(bezelViewWillAppear:) :
				@selector(bezelViewWillDisappear:)];
		}
	
		_visible = visible;
		[self setNeedsLayout];
		
		if(animated) {
			[self layoutIfNeeded];
			
			[UIView commitAnimations];
		} else {
			[self delegateSelectorIfNeeded:visible ?
				@selector(bezelViewDidAppear:) :
				@selector(bezelViewDidDisappear:)];
		}
	}
}

#pragma mark -
#pragma mark UIView

- (CGSize)sizeThatFits:(CGSize)size {
	return [[self class] bezelViewSize];
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	
	static const CGFloat cornerRadius = 10.0;
	
	CGContextRef context = UIGraphicsGetCurrentContext(); 
	
	CGContextBeginPath(context); {
   
		CGContextMoveToPoint(context, CGRectGetMinX(rect) + cornerRadius, CGRectGetMinY(rect));
		CGContextAddArc(context, CGRectGetMaxX(rect) - cornerRadius, CGRectGetMinY(rect) + cornerRadius, cornerRadius, 3.0 * M_PI / 2.0, 0.0, 0.0);
		CGContextAddArc(context, CGRectGetMaxX(rect) - cornerRadius, CGRectGetMaxY(rect) - cornerRadius, cornerRadius, 0.0, M_PI / 2.0, 0.0);
		CGContextAddArc(context, CGRectGetMinX(rect) + cornerRadius, CGRectGetMaxY(rect) - cornerRadius, cornerRadius, M_PI / 2.0, M_PI, 0.0);
		CGContextAddArc(context, CGRectGetMinX(rect) +cornerRadius, CGRectGetMinY(rect) + cornerRadius, cornerRadius, M_PI, 3.0 * M_PI / 2.0, 0.0);
    
    } CGContextClosePath(context);
	
	[[UIColor colorWithWhite:0.0 alpha:0.6] set];
    CGContextFillPath(context);
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect backgroundRect = self.bounds;
	
	static const CGFloat imageWidth = 128.0;
	CGRect imageRect = CGRectMake(
		floorf(CGRectGetMidX(backgroundRect) - imageWidth * 0.5),
		floorf(CGRectGetMidY(backgroundRect) - imageWidth * 0.5),
		imageWidth,
		imageWidth);
		
	static const CGFloat textMargin = 10.0;
	
	CGSize textLabelSize = [[self textLabel]
		sizeThatFits:backgroundRect.size];
	
//	textLabelSize.width = MIN(
//		textLabelSize.width,
//		CGRectGetWidth(backgroundRect) - textMargin * 2.0);

	textLabelSize.width = CGRectGetWidth(backgroundRect) - textMargin * 2.0;
	
	CGFloat shadowTweak = 3.0;
	
	CGRect textLabelRect = CGRectMake(
		floorf(CGRectGetMidX(backgroundRect) - textLabelSize.width * 0.5),
		CGRectGetMaxY(backgroundRect) - textLabelSize.height - textMargin,
		textLabelSize.width,
		textLabelSize.height + shadowTweak);
	
	self.imageView.frame = imageRect;
	self.textLabel.frame = textLabelRect;
	
	self.alpha = self.visible ? 1.0 : 0.0;
}

#pragma mark -
#pragma mark Private

- (void)initIvars {
	self.opaque = NO;
	self.backgroundColor = [UIColor clearColor];
	self.clipsToBounds = NO;
	self.contentMode = UIViewContentModeRedraw;
	self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
	self.userInteractionEnabled = NO;
	self.visible = NO;
}

- (void)initImageView {
	UIImageView* imageView = [[UIImageView alloc] initWithImage:nil];
	
	imageView.contentMode = UIViewContentModeScaleAspectFit;
	
	self.imageView = imageView;
	[self addSubview:imageView];
}

- (void)initTextLabel {
	UILabel* textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	
	textLabel.font = [UIFont boldSystemFontOfSize:16.0];
	textLabel.textAlignment = NSTextAlignmentCenter;
	
	textLabel.text = @" ";
	textLabel.textColor = [UIColor whiteColor];

	textLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
	textLabel.shadowOffset = CGSizeMake(0.0, 1.0);
	
	textLabel.clipsToBounds = NO;
	textLabel.opaque = YES;
	textLabel.backgroundColor = [UIColor clearColor];
	
	self.textLabel = textLabel;
	[self insertSubview:textLabel aboveSubview:[self imageView]];
}

- (void)visibilityAnimationWillStart:(NSString*)animationID context:(void*)context {
	[self delegateSelectorIfNeeded:[self isVisible] ?
		@selector(bezelViewWillAppear:) :
		@selector(bezelViewWillDisappear:)];
}

- (void)visibilityAnimationDidStop:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context {
	if(![finished boolValue]) { return; }
	
	[self delegateSelectorIfNeeded:[self isVisible] ?
		@selector(bezelViewDidAppear:) :
		@selector(bezelViewDidDisappear:)];
}

- (void)delegateSelectorIfNeeded:(SEL)selector {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	if([[self delegate] respondsToSelector:selector]) {
		[[self delegate] performSelector:selector withObject:self];
	}
#pragma clang diagnostic pop
}

@end
