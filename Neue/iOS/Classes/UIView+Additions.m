//
//  UIView+Additions.m
//  Magical Weather
//
//  Created by Sophia Teutschler on 22.07.11.
//  Copyright 2011 Sophiestication Software. All rights reserved.
//

#import "UIView+Additions.h"
#import <QuartzCore/QuartzCore.h>

UIImage* SFImageFromView(UIView* view) {
	UIImage* image = nil;
	
	UIGraphicsBeginImageContextWithOptions(
		[view bounds].size,
		view.opaque,
		view.window.screen.scale); {
		
		CGContextRef context = UIGraphicsGetCurrentContext();
		[[view layer] renderInContext:context];
		
		image = UIGraphicsGetImageFromCurrentImageContext();
	
	} UIGraphicsEndImageContext();
	
	return image;
}

@implementation UIView(Additions)

- (id)superviewOfClass:(Class)viewClass {
	UIView* superview = self.superview;
	
	if(superview) {
		if([superview isKindOfClass:viewClass]) {
			return superview;
		} else {
			return [superview superviewOfClass:viewClass];
		}
	}
	
	return nil;
}

@end