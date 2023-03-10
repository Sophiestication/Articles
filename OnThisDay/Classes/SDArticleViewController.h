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

#import <UIKit/UIKit.h>
#import "ArticleKit.h"

@class AKShadowView;

@interface SDArticleViewController : UIViewController<AKArticleViewDelegate>

@property(nonatomic, strong) IBOutlet AKArticleView* articleView;

@property(nonatomic, strong) IBOutlet UINavigationBar* navigationBar;
@property(nonatomic, strong) IBOutlet UILabel* titleLabel;

@property(nonatomic, strong) IBOutlet UIToolbar* toolbar;
@property(nonatomic, strong) IBOutlet UIBarButtonItem* doneButtonItem;
@property(nonatomic, strong) IBOutlet UIBarButtonItem* navigateBackButtonItem;
@property(nonatomic, strong) IBOutlet UIBarButtonItem* navigateForwardButtonItem;
@property(nonatomic, strong) IBOutlet UIBarButtonItem* reloadButtonItem;
@property(nonatomic, strong) IBOutlet UIBarButtonItem* stopButtonItem;
@property(nonatomic, strong) IBOutlet UIBarButtonItem* actionsButtonItem;
@property(nonatomic, strong) IBOutlet UIBarButtonItem* contentsButtonItem;

@property(nonatomic, strong) IBOutlet UIActivityIndicatorView* activityIndicatorView;

@property(nonatomic) BOOL shouldDisplayBanner;

+ (id)viewController;

- (IBAction)done:(id)sender;

- (IBAction)navigateBack:(id)sender;
- (IBAction)navigateForward:(id)sender;

- (IBAction)reload:(id)sender;
- (IBAction)stop:(id)sender;

- (IBAction)openSafari:(id)sender;
- (IBAction)openArticles:(id)sender;

- (IBAction)showActionSheet:(id)sender;

- (IBAction)showTableOfContents:(id)sender;

- (IBAction)openArticlesWebsite:(id)sender;

- (void)loadArticle:(NSURL*)articleURL;

@end
