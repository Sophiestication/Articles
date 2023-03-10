//
//  UIView+Additions.h
//  Magical Weather
//
//  Created by Sophia Teutschler on 22.07.11.
//  Copyright 2011 Sophiestication Software. All rights reserved.
//

#import <UIKit/UIKit.h>

UIImage* SFImageFromView(UIView* view);

@interface UIView(Additions)

- (id)superviewOfClass:(Class)viewClass;

@end