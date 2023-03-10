//
//  SFPiledViewController.h
//  Articles
//
//  Created by Sophia Teutschler on 29.01.12.
//  Copyright (c) 2012 Sophiestication Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SFPiledViewControllerDataSource<NSObject>

@required


@end

@protocol SFPiledViewControllerDelegate<NSObject>
@end

@interface SFPiledViewController : UIViewController<UIScrollViewDelegate>

@property(nonatomic, weak) id<SFPiledViewControllerDataSource> dataSource;
@property(nonatomic, weak) id<SFPiledViewControllerDelegate> delegate;

- (UIViewController*)dequeueReuseableViewControllerWithIdentifier:(NSString*)identifier;

@end