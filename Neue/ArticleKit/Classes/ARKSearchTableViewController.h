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
#import "CoreMediaWiki.h"

@protocol ARKSearchTableViewControllerDelegate;
@class WIKPage;

@interface ARKSearchTableViewController : UITableViewController

@property(nonatomic, weak) id<ARKSearchTableViewControllerDelegate> delegate;

@property(nonatomic, getter=isDocumentSearchEnabled) BOOL documentSearchEnabled; // TODO
@property(nonatomic, getter=isTitleMatchingEnabled) BOOL titleMatchingEnabled;

@property(nonatomic, copy) NSArray* mediaWikis;

@property(nonatomic) NSString* searchText;
- (void)setSearchText:(NSString*)searchText animated:(BOOL)animated;

@end

@protocol ARKSearchTableViewControllerDelegate<NSObject>

@optional
- (void)searchTableViewController:(ARKSearchTableViewController*)viewController didSelectPage:(WIKPage*)page;
- (BOOL)searchTableViewController:(ARKSearchTableViewController*)viewController shouldPresentActivityViewControllerForPage:(WIKPage*)page;

@end
