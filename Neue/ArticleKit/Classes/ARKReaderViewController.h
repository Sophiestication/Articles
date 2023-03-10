//
//  ARKReaderViewController.h
//  Articles
//
//  Created by Sophia Teutschler on 23.12.11.
//  Copyright (c) 2011 Sophiestication Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SUIPiledViewController.h"

@interface ARKReaderViewController : SUIPiledViewController

- (void)loadArticle:(NSURL*)articleURL animated:(BOOL)animated;

@end