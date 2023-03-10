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

#import "SABookmarkActivity.h"

#import "BookmarkDetailViewController.h"
#import "BookmarkDetailViewDelegate.h"

@interface SABookmarkActivity()<BookmarkDetailViewDelegate>

@property(nonatomic, copy) NSURL* articleURL;
@property(nonatomic, strong) UIViewController* activityContentViewController;

@end

@implementation SABookmarkActivity

#pragma mark - UIActivity

- (NSString*)activityType { return @"com.sophiestication.activity.bookmark"; }
- (NSString*)activityTitle { return NSLocalizedString(@"SHEETBUTTON_ADD_BOOKMARK", nil); }
- (UIImage*)activityImage { return [UIImage imageNamed:@"bookmarkActivity"]; }

- (BOOL)canPerformWithActivityItems:(NSArray*)activityItems { return [self articleURLFromActivityItems:activityItems] != nil; }

- (void)prepareWithActivityItems:(NSArray*)activityItems {
	self.articleURL = [self articleURLFromActivityItems:activityItems];

	if(self.activityBlock) { return; } // we rely on a custom container view

	BookmarkDetailViewController* viewController = (id)self.activityViewControllerBlock([self articleURL]);
	if(!viewController) { return; }

	viewController.delegate = self;

	UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
	self.activityContentViewController = navigationController;
}

- (UIViewController*)activityViewController {
	return self.activityContentViewController;
}

- (void)performActivity {
	[super performActivity];
	self.activityBlock([self articleURL]);
}

#pragma mark - Private

- (NSURL*)articleURLFromActivityItems:(NSArray*)activityItems {
	for(id item in activityItems) {
		if(![item isKindOfClass:[NSURL class]]) { continue; }
		return item;
	}

	return nil;
}

#pragma mark - BookmarkDetailViewDelegate

- (BOOL)bookmarkDetailViewControllerShouldDismiss:(BookmarkDetailViewController*)viewController {
	[self activityDidFinish:YES];
	return NO;
}

@end
