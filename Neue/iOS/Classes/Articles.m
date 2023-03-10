//
//  ARTAppDelegate.m
//  Articles
//
//  Created by Sophia Teutschler on 08.10.11.
//  Copyright (c) 2011 Sophiestication Software. All rights reserved.
//

#import "Articles.h"
#import "ArticleKit.h"

#import "ARKSearchTableViewController.h"

@interface Articles()<ARKSearchTableViewControllerDelegate>

@property(nonatomic, strong) ARKSearchTableViewController* searchTableViewController;
@property(nonatomic, strong) ARKReaderViewController* readerViewController;

@end

@implementation Articles

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidReceiveNotification:) name:nil object:nil];
	
	UIWindow* window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	ARKSearchTableViewController* searchTableViewController = [[ARKSearchTableViewController alloc] init];
	searchTableViewController.delegate = self;
	self.searchTableViewController = searchTableViewController;

	ARKReaderViewController* readerViewController = [[ARKReaderViewController alloc] init];
	self.readerViewController = readerViewController;
	
	UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:searchTableViewController];

	navigationController.navigationBarHidden = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
	navigationController.toolbarHidden = YES; //UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;

	window.rootViewController = navigationController;

	self.window = window;
	[window makeKeyAndVisible];

	return YES;
}

- (void)applicationWillResignActive:(UIApplication*)application {
}

- (void)applicationDidEnterBackground:(UIApplication*)application {
}

- (void)applicationWillEnterForeground:(UIApplication*)application {
}

- (void)applicationDidBecomeActive:(UIApplication*)application {
}

- (void)applicationWillTerminate:(UIApplication*)application {
}

#pragma mark - Private

- (void)applicationDidReceiveNotification:(NSNotification*)notification {
//	NSLog(@"%@", notification);
}

#pragma mark - 

- (void)searchTableViewController:(ARKSearchTableViewController*)viewController didSelectPage:(WIKPage*)page {
	NSURL* URL = [[page URL] value];
	[[self readerViewController] loadArticle:URL animated:NO];

	UINavigationController* navigationController = (id)self.window.rootViewController;
	[navigationController pushViewController:[self readerViewController] animated:YES];
}

@end