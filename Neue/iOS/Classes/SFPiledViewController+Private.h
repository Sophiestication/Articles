//
//  SFPiledViewController+Private.h
//  Articles
//
//  Created by Sophia Teutschler on 29.01.12.
//  Copyright (c) 2012 Sophiestication Software. All rights reserved.
//

#import "SFPiledViewController.h"

@interface SFPiledViewController()

@property(nonatomic, strong) NSMutableArray* visibleViewControllers;
@property(nonatomic, strong) NSMutableSet* reusableViewControllers;

- (void)enqueuReuseableViewController:(UIViewController*)viewController;

@end