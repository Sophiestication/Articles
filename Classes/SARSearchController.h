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

#import <Foundation/Foundation.h>

#import "ARKSearchTableViewController.h"
#import "CoreMediaWiki.h"

@protocol SASearchControllerDelegate;
@class SASearchBar;

@interface SARSearchController : NSObject

- (id)initWithSearchBar:(SASearchBar*)searchBar containerViewController:(UIViewController*)containerViewController;

@property(nonatomic, weak) id<SASearchControllerDelegate> delegate;

@property(nonatomic, getter=isActive) BOOL active;
- (void)setActive:(BOOL)active animated:(BOOL)animated completion:(void (^)(void))completion;

@property(nonatomic, copy) NSString* searchText;

@property(nonatomic, getter=isTitleMatchingEnabled) BOOL titleMatchingEnabled;
@property(nonatomic, copy) NSString* mediaWikiLanguageCode;

@property(nonatomic, readonly, strong) UIPopoverController* contentPopoverController;

@end

@protocol SASearchControllerDelegate<ARKSearchTableViewControllerDelegate>

@optional
- (void)searchControllerWillBeginSearch:(SARSearchController*)searchController;
- (void)searchControllerDidBeginSearch:(SARSearchController*)searchController;
- (void)searchControllerWillEndSearch:(SARSearchController*)searchController;
- (void)searchControllerDidEndSearch:(SARSearchController*)searchController;

@end
