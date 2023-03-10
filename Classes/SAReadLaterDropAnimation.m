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

#import "SAReadLaterDropAnimation.h"

#import "SAReadLaterTableViewCellContentView.h"
#import "Articles.h"

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <objc/objc.h>

@implementation SAReadLaterDropAnimation

+ (SAReadLaterDropAnimation*)dropWithOptions:(NSDictionary*)options {
	SAReadLaterDropAnimation* dropAnimation = [[self alloc] init];
	
	[dropAnimation performSelector:@selector(dropWithOptions:)
		withObject:options
		afterDelay:0.2];
	
	return dropAnimation;
}


- (void)dropWithOptions:(NSDictionary*)options {
	UIView* sourceView = [options objectForKey:@"sourceView"];
	UIView* parentView = [[options objectForKey:@"viewController"] view];
	
	NSArray* rects = [options objectForKey:@"rects"];
	
	CGRect boundingRect = CGRectZero;
	
	for(NSValue* rect in rects) {
		if(CGRectEqualToRect(boundingRect, CGRectZero)) {
			boundingRect = [rect CGRectValue];
		} else {
			boundingRect = CGRectUnion(boundingRect, [rect CGRectValue]);
		}
	}
	
	if(CGRectEqualToRect(boundingRect, CGRectZero)) {
		boundingRect = CGRectFromString([options objectForKey:@"boundingRect"]);
	}
	
	boundingRect = [sourceView convertRect:boundingRect fromView:nil];
	
	CGRect sourceViewRect = sourceView.bounds;
	
	UIEdgeInsets contentEdgeInsets = [[options objectForKey:@"contentEdgeInsets"] UIEdgeInsetsValue];
	sourceViewRect = UIEdgeInsetsInsetRect(sourceViewRect, contentEdgeInsets);
	
	boundingRect = CGRectIntersection(boundingRect, sourceViewRect);
	
	UIImage* sourceImage = [self
		imageFromRects:rects
		boundingRect:boundingRect
		inView:sourceView];
		
	UIImageView* snippedView = [[UIImageView alloc] initWithImage:sourceImage];
	snippedView.frame = [sourceView convertRect:boundingRect toView:parentView];
	
//	snippedView.backgroundColor = [UIColor whiteColor];
//	snippedView.opaque = YES;
	
	snippedView.layer.shouldRasterize = YES;
	snippedView.layer.rasterizationScale = parentView.window.screen.scale;
	
	_snippedView = snippedView;
	[parentView addSubview:snippedView];
	[parentView bringSubviewToFront:snippedView];
	
	_options = options;
	
	SEL animationSelector = [_options objectForKey:@"destinationView"] ?
		@selector(performDropAnimation:) :
		@selector(performZoomAnimation:);
	[self performSelector:animationSelector
		withObject:self
		afterDelay:0.0];
}

- (UIImage*)imageFromRects:(NSArray*)rects boundingRect:(CGRect)boundingRect inView:(UIView*)view {
	UIImage* image = nil;
	
	rects = [self prepareImageRects:rects forView:view];
	
	UIGraphicsBeginImageContextWithOptions(boundingRect.size, NO, 0.0); {
		CGContextRef context = UIGraphicsGetCurrentContext();
		
		CGContextTranslateCTM(context, -CGRectGetMinX(boundingRect), -CGRectGetMinY(boundingRect));
		[[view layer] renderInContext:context];
		
		image = UIGraphicsGetImageFromCurrentImageContext();
	} UIGraphicsEndImageContext();
	
	UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale); {
		for(NSValue* rectValue in rects) {
			CGRect rect = [rectValue CGRectValue]; // [view convertRect:[rectValue CGRectValue] fromView:nil];
			
			if(CGRectEqualToRect(rect, CGRectZero)) {
				continue;
			}

			rect = CGRectOffset(rect, -CGRectGetMinX(boundingRect), -CGRectGetMinY(boundingRect));
			
			CGRect subImageRect = CGRectApplyAffineTransform(rect, CGAffineTransformMakeScale(image.scale, image.scale));
			CGImageRef subImage = CGImageCreateWithImageInRect([image CGImage], subImageRect);
			
			[[UIImage imageWithCGImage:subImage scale:image.scale orientation:UIImageOrientationUp]
				drawInRect:rect];
			
			CGImageRelease(subImage);
		}
		
		image = UIGraphicsGetImageFromCurrentImageContext();
	} UIGraphicsEndImageContext();
	
	return image;
}

- (NSArray*)prepareImageRects:(NSArray*)rects forView:(UIView*)view {	
	NSMutableSet* distinctRects = [NSMutableSet setWithCapacity:[rects count]];
	
	for(NSValue* rectValue in rects) {
		CGRect rect = [view convertRect:[rectValue CGRectValue] fromView:nil];
		[distinctRects addObject:[NSValue valueWithCGRect:rect]];
	}
	
	NSComparator comparator = ^(id obj1, id obj2) {
		CGRect firstRect = [obj1 CGRectValue];
		CGRect secondRect = [obj2 CGRectValue];
		
		if(CGRectGetMinY(firstRect) < CGRectGetMinY(secondRect)) { return NSOrderedAscending; }
		if(CGRectGetMinY(firstRect) > CGRectGetMinY(secondRect)) { return NSOrderedDescending; }
		
		return NSOrderedSame;
	};
	NSArray* sortedRects = [[distinctRects allObjects] sortedArrayUsingComparator:comparator];
	
	NSMutableArray* offsets = [NSMutableArray array];
	
	[sortedRects enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL* stop) {
		NSNumber* offset = [NSNumber numberWithDouble:CGRectGetMinY([object CGRectValue])];
		
		if(![offsets containsObject:offset]) {
			[offsets addObject:offset];
		}
	}];

	NSMutableArray* newRects = [NSMutableArray arrayWithCapacity:[sortedRects count]];
	
	[sortedRects enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL* stop) {
		CGRect rect = [object CGRectValue];
		
		NSNumber* offset = [NSNumber numberWithDouble:CGRectGetMinY(rect)];
		NSInteger offsetIndex = [offsets indexOfObject:offset];
		
		if(offsetIndex + 1 < offsets.count) {
			CGFloat nextOffset = [[offsets objectAtIndex:offsetIndex + 1] doubleValue];
			rect.size.height = nextOffset - CGRectGetMinY(rect);
		}
		
		[newRects addObject:[NSValue valueWithCGRect:rect]];
	}];
	
	return newRects;
}

- (void)performDropAnimation:(id)sender {
	CGFloat totalAnimationDuration = 1.0;
	
	id raiseAnimation = ^{
		CALayer* snippedLayer = _snippedView.layer;
		
		snippedLayer.shadowOpacity = 1.0;
		snippedLayer.shadowRadius = 2.0;
		snippedLayer.shadowOffset = CGSizeMake(0.0, 1.0);
		
		_snippedView.transform = CGAffineTransformMakeScale(1.05, 1.05);
		
		_snippedView.alpha = 1.0;
		_highlightView.alpha = 1.0;
	};
	
	id raiseAnimationCompleted = ^(BOOL finished) {
		id  dropAnimation = ^{
			UIView* destinationView = [_options objectForKey:@"destinationView"];
			
			CGPoint destinationPoint = CGPointMake(
				CGRectGetMidX([destinationView bounds]),
				CGRectGetMidY([destinationView bounds]));
			destinationPoint = [[_snippedView superview] convertPoint:destinationPoint fromView:destinationView];
			
			CGRect snippedRect = _snippedView.frame;

			CGAffineTransform transform = CGAffineTransformMakeTranslation(
				destinationPoint.x - CGRectGetMidX(snippedRect),
				destinationPoint.y - CGRectGetMidY(snippedRect));
			transform = CGAffineTransformScale(transform, 0.125, 0.125);
			
			CGFloat rotation = 90.0;
			transform = CGAffineTransformRotate(transform, rotation * (M_PI / 180.0));
			
			_snippedView.transform = transform;
			_snippedView.alpha = 0.2;
			
			_highlightView.alpha = 0.0;
		};
	
		id dropAnimationCompleted = ^(BOOL animationFinished) {
			[_highlightView removeFromSuperview];
			[_snippedView removeFromSuperview];
		};
		
		[UIView
			animateWithDuration:totalAnimationDuration * 0.8
			delay:0.0
			options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveEaseOut
			animations:dropAnimation
			completion:dropAnimationCompleted];
	};
	
	_snippedView.alpha = 0.0;
	
	[UIView
		animateWithDuration:totalAnimationDuration * 0.2
		delay:0.175
		options:UIViewAnimationOptionCurveEaseIn
		animations:raiseAnimation
		completion:raiseAnimationCompleted];
}

- (void)performZoomAnimation:(id)sender {
	id zoomAnimation = ^{
		CALayer* snippedLayer = _snippedView.layer;
		
		snippedLayer.shadowOpacity = 1.0;
		snippedLayer.shadowRadius = 2.0;
		snippedLayer.shadowOffset = CGSizeMake(0.0, 1.0);
		
		CGRect screenRect = [[[_snippedView window] screen] bounds];
		
		CGPoint destinationPoint = CGPointMake(
			CGRectGetMidX(screenRect),
			CGRectGetMidY(screenRect));
		destinationPoint = [[_snippedView superview] convertPoint:destinationPoint fromView:nil];
			
		CGRect snippedRect = _snippedView.frame;
		
		CGAffineTransform transform = CGAffineTransformMakeTranslation(
			destinationPoint.x - CGRectGetMidX(snippedRect),
			destinationPoint.y - CGRectGetMidY(snippedRect));
		transform = CGAffineTransformScale(transform, 4.0, 4.0);
		
		_snippedView.transform = transform;
		
		_snippedView.alpha = 0.0;
		_highlightView.alpha = 1.0;
	};
	
	id zoomAnimationCompleted = ^(BOOL finished) {
		[_highlightView removeFromSuperview];
		[_snippedView removeFromSuperview];
	};
	
	[UIView
		animateWithDuration:1.0
		delay:0.05
		options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveEaseInOut
		animations:zoomAnimation
		completion:zoomAnimationCompleted];
}

@end
