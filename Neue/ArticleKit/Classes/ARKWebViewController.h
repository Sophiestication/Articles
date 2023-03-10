//
//  ARKWebViewController.h
//  Articles
//
//  Created by Sophia Teutschler on 23.12.11.
//  Copyright (c) 2011 Sophiestication Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ARKWebViewController;

@protocol ARKWebViewControllerDelegate<NSObject>

- (void)webViewController:(ARKWebViewController*)webViewController shouldLoadArticleWithURL:(NSURL*)URL;

@end

@interface ARKWebViewController : UIViewController

@property(nonatomic, weak) id<ARKWebViewControllerDelegate> delegate;
@property(nonatomic, readonly) UIScrollView* scrollView;

@property(nonatomic, copy) NSURL* representedURL;

- (void)loadArticleIfNeeded;
- (void)prepareForReuse;

@end