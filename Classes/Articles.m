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

#import "Articles.h"

#import "ArticleViewController.h"
#import "ArticleKit.h"

#import "SAArticle.h"
#import "SABookmark.h"
#import "SABookmarkGroup.h"

#import "SFWindow.h"
#import "SFNavigationController.h"
#import "SFGeometryValueTransformer.h"
#import "SFImageValueTransformer.h"
#import "SFNetworkActivity.h"
#import "SFDemoViewController.h"

#import "NSArray+Additions.h"
#import "NSString+Additions.h"
#import "NSURL+Additions.h"

#import "RESTfulKit.h"

#import <MobileCoreServices/MobileCoreServices.h>

@implementation Articles

@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

@synthesize window = _window;
@synthesize articleViewController = _articleViewController;

#pragma mark -
#pragma mark Construction & Destruction

+ (Articles*)self {
	return (Articles*)[[UIApplication sharedApplication] delegate];
}

+ (void)initialize {
	if(self == [Articles class]) {
		// Load the default values for the user defaults
		NSString* userDefaultsPath = [[NSBundle mainBundle]
			pathForResource:@"Defaults" 
			ofType:@"plist"];
		NSDictionary* userDefaults = [NSDictionary dictionaryWithContentsOfFile:userDefaultsPath];
    
		// Set them in the standard user defaults
		[[NSUserDefaults standardUserDefaults] registerDefaults:userDefaults];
	}
}


#pragma mark - Articles

- (IBAction)openArticleURL:(NSURL*)articleURL {
	if([articleURL isArticlesURL]) {
		if([self application:[UIApplication sharedApplication] handleSearchURLIfNeeded:articleURL]) { return; }
		
		NSString* resourceSpecifier = [articleURL resourceSpecifier];
		if(resourceSpecifier.length == 0) { return; }
        
        NSString* wikipediaURLString = [NSString stringWithFormat:@"http:%@", resourceSpecifier];
		
		// remove the .m. for mobile redirects from the host string
		NSString* host = [articleURL host];
		NSMutableArray* hostStrings = [[host componentsSeparatedByString:@"."] mutableCopy];
		
		NSUInteger stringIndex = [hostStrings indexOfObjectPassingTest:^BOOL(NSString* string, NSUInteger index, BOOL* stop) {
			return [string caseInsensitiveCompare:@"m"] == NSOrderedSame;
		}];
		
		if(stringIndex != NSNotFound) {
			[hostStrings removeObjectAtIndex:stringIndex];
			
			NSString* newHost = [hostStrings componentsJoinedByString:@"."];
			wikipediaURLString = [wikipediaURLString stringByReplacingOccurrencesOfString:host withString:newHost];
		}
		
		articleURL = [NSURL URLWithString:wikipediaURLString];
	}
	
	self.articleViewController.searchDisplayController.searchBar.text = @"";
	
	BOOL animated = !self.articleViewController.presentedViewController;
	[[self articleViewController] loadArticle:articleURL animated:animated];
}

- (IBAction)openArticleURLInNewTab:(NSURL*)articleURL {
	[self openArticleURL:articleURL]; // TODO
}

- (IBAction)save:(id)sender {
    NSError* error = nil;
	NSManagedObjectContext* managedObjectContext = self.managedObjectContext;

	if(managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
			// Handle error
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			exit(-1);  // FAIL
        } 
    }
}

- (IBAction)revertToDefaults:(id)sender {
	NSManagedObjectContext* managedObjectContext = self.managedObjectContext;
	
	NSString* defaultsBookmarkFile = [[NSBundle mainBundle]
		pathForResource:@"Bookmarks" ofType:@"plist"];
	
	NSArray* bookmarkGroups = [[NSDictionary dictionaryWithContentsOfFile:defaultsBookmarkFile]
		objectForKey:@"groups"];
	
	NSInteger bookmarkGroupIndex = 1;

	for(NSDictionary* bookmarkGroup in bookmarkGroups) {
		SABookmarkGroup* managedBookmarkGroup = [NSEntityDescription
			insertNewObjectForEntityForName:@"BookmarkGroup"
			inManagedObjectContext:managedObjectContext];
		
		managedBookmarkGroup.title = [bookmarkGroup objectForKey:@"title"];
		managedBookmarkGroup.sortOrder = [NSNumber numberWithInteger:bookmarkGroupIndex];
		
		NSInteger bookmarkIndex = 1;
		
		for(NSDictionary* bookmark in [bookmarkGroup objectForKey:@"bookmarks"]) {
			SABookmark* managedBookmark = [NSEntityDescription
				insertNewObjectForEntityForName:@"Bookmark"
				inManagedObjectContext:managedObjectContext];
			
			managedBookmark.title = [bookmark objectForKey:@"title"];
			managedBookmark.sortOrder = [NSNumber numberWithInteger:bookmarkIndex];
			
			SAArticle* article = [NSEntityDescription
				insertNewObjectForEntityForName:@"Article"
				inManagedObjectContext:managedObjectContext];
			
			article.title = managedBookmark.title;
			article.articleURL =  [bookmark objectForKey:@"URL"];
			
			managedBookmark.article = article;
			
			[managedBookmarkGroup addSubitemsObject:managedBookmark];
			
			++bookmarkIndex;
		}
		
		++bookmarkGroupIndex;
	}
	
	NSArray* bookmarkItems = [[NSDictionary dictionaryWithContentsOfFile:defaultsBookmarkFile]
		objectForKey:@"items"];
		
	for(NSDictionary* bookmarkItem in bookmarkItems) {
		SABookmark* managedBookmark = [NSEntityDescription
			insertNewObjectForEntityForName:@"Bookmark"
			inManagedObjectContext:managedObjectContext];
		
		managedBookmark.title = [bookmarkItem objectForKey:@"title"];
		managedBookmark.sortOrder = [NSNumber numberWithInteger:bookmarkGroupIndex];
		
		SAArticle* article = [NSEntityDescription
			insertNewObjectForEntityForName:@"Article"
			inManagedObjectContext:managedObjectContext];
		
		article.title = managedBookmark.title;
		article.articleURL =  [bookmarkItem objectForKey:@"URL"];
		
		managedBookmark.article = article;
		
		++bookmarkGroupIndex;
	}
	
	[self save:sender];
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
#if defined (CONFIGURATION_PHONEBINARY)
	NSString* liveIdentifier = @"69d35a56dd912b0f6347664e04f5a91c";
#else
	NSString* liveIdentifier = @"2542d796e098d8501f39d2b48dd8c7fd";
#endif

#if defined (CONFIGURATION_PHONEBINARY)
	NSString* betaIdentifier = @"84716bcbd5ec4bd5fbab00ec56ed2eb2";
#else
	NSString* betaIdentifier = @"f47f35595f7e2608448956396e484983";
#endif

	[[BITHockeyManager sharedHockeyManager]
		configureWithBetaIdentifier:betaIdentifier
		liveIdentifier:liveIdentifier
        delegate:self];
	[[BITHockeyManager sharedHockeyManager] startManager];
	
	[[[BITHockeyManager sharedHockeyManager]
		crashManager] setCrashManagerStatus:BITCrashManagerStatusAutoSend];

//	NSLog(@"Running in Demo mode.");
//	
//	if([[NSDate date] compare:[NSDate dateWithString:@"2011-03-01 00:00:00 +0600"]] == NSOrderedDescending) {
//		exit(666);
//	}

//	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"WebKitShowDebugBorders"];

	// Register our image value transformer
	SFImageValueTransformer* imageTransformer = [[SFImageValueTransformer alloc] init];
	[NSValueTransformer setValueTransformer:imageTransformer forName:SFImageValueTransformerName];
	
	SFCGPointValueTransformer* pointTransformer = [[SFCGPointValueTransformer alloc] init];
	[NSValueTransformer setValueTransformer:pointTransformer forName:SFCGPointValueTransformerName];
	
	SFCGSizeValueTransformer* sizeTransformer = [[SFCGSizeValueTransformer alloc] init];
	[NSValueTransformer setValueTransformer:sizeTransformer forName:SFCGSizeValueTransformerName];
	
	SFCGRectValueTransformer* rectTransformer = [[SFCGRectValueTransformer alloc] init];
	[NSValueTransformer setValueTransformer:rectTransformer forName:SFCGRectValueTransformerName];
	
	// …
	srand([[NSDate date] timeIntervalSinceReferenceDate]);
	
	// Make sure to delete invalid cache files before the app finishes launching
	NSString* featureString = [[NSUserDefaults standardUserDefaults] objectForKey:@"AKFeature"];
	
	if(!featureString ||
	   [featureString isEqual:@"1.3"] ||
	   [featureString isEqual:@"1.3.1"] || 
	   [featureString isEqual:@"1.4"] || 
	   [featureString isEqual:@"2"]) {
		NSString* cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)
			firstObject]
			stringByAppendingPathComponent:@"ArticleKit/"];
		[[NSFileManager defaultManager] removeItemAtPath:cachePath error:nil];
		
		// Update the feature property
		[[NSUserDefaults standardUserDefaults]
			setObject:@"2.3"
			forKey:@"AKFeature"];
	}
	
//	// For debugging
//	[[NSNotificationCenter defaultCenter]
//		addObserver:self 
//		selector:@selector(notificationCenterDidPostNotification:)
//		name:nil
//		object:nil];

	[[NSNotificationCenter defaultCenter]
		addObserver:self 
		selector:@selector(articleViewWillStartNetworkActivity:)
		name:AKArticleViewWillStartNetworkActivityNotification
		object:nil];
	[[NSNotificationCenter defaultCenter]
		addObserver:self 
		selector:@selector(articleViewDidEndNetworkActivity:)
		name:AKArticleViewDidEndNetworkActivityNotification
		object:nil];

	// ...
	[[AKArchiveController sharedController] beginMaintanceIfNeeded:[self managedObjectContext]];

	// Make a new window
	CGRect applicationFrame = [[UIScreen mainScreen] bounds];
	UIWindow* window;

	if([UICollectionView class]) {
		window = [[UIWindow alloc] initWithFrame:applicationFrame];
	} else {
		window = [[SFWindow alloc] initWithFrame:applicationFrame];
		[(SFWindow*)window setBlinderVisible:YES];
	}
	
	window.backgroundColor = [UIColor blackColor];
	self.window = window;
	
	// Setup the main view controllers
	ArticleViewController* articleViewController = [ArticleViewController viewController];
	articleViewController.managedObjectContext = self.managedObjectContext;
	self.articleViewController = articleViewController;
	
	window.rootViewController = articleViewController;
	
	// Now check if we have to launch a specific article
	NSURL* articleURL = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
	
	// articleURL = [NSURL URLWithString:@"x-articlekit://en.wikipedia.org/wiki/Painting#Painting_styles"];
	// articleURL = [NSURL URLWithString:@"wiki://en.wikipedia.org/wiki/P%C3%A9riph%C3%A9rique_(Paris)#Traffic_Priorities"];
	// articleURL = [NSURL URLWithString:@"wiki://en.wikipedia.org/wiki/Mutt_Williams"];
	// articleURL = [NSURL URLWithString:@"wiki://en.wikipedia.org/wiki/12345678901234567890"];
	// articleURL = [NSURL URLWithString:@"wiki://en.wikipedia.org/wiki/Art_Deco"];
    // articleURL = [NSURL URLWithString:@"x-articlekit://?search=vangogh&language=it&scope=content"];
	// articleURL = [NSURL URLWithString:@"x-articlekit://en.m.wikipedia.org/wiki/Art_Deco"];
	// articleURL = [NSURL URLWithString:@"x-articles://"];
	
	[[self window] makeKeyAndVisible];
	
	if(articleURL && ([articleURL isWikipediaURL] || [articleURL isArticlesURL])) {
		// [self openArticleURL:articleURL];
		
		[self performSelector:@selector(openArticleURL:)
			withObject:articleURL
			afterDelay:0.0];
	}

//	Demo Disclaimer
//	SFDemoViewController* demoViewController = [SFDemoViewController demoController];
//	
//	[demoViewController present:articleViewController];
//	[demoViewController performSelector:@selector(dismiss:)
//		withObject:nil
//		afterDelay:2.0];
//	[[self window] makeKeyWindow];

//	NSLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);

	return YES;
}

- (void)applicationWillTerminate:(UIApplication*)application {
	// Save all pending changes
	[self save:application];
	
	// ...
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	// Make the window background black to prevent bleeding views while quiting
	self.window.backgroundColor = [UIColor blackColor];
}

- (void)applicationDidEnterBackground:(UIApplication*)application {
	// Save all pending changes
	[[NSUserDefaults standardUserDefaults] synchronize];
	[self save:application];
}

- (void)applicationWillEnterForeground:(UIApplication*)application {
}

- (BOOL)application:(UIApplication*)application handleOpenURL:(NSURL*)url {
	if([url isWikipediaURL] || [url isArticlesURL]) {
		[self openArticleURL:url];
		return YES;
	}
	
	return NO;
}

#pragma mark - Core Data

- (NSManagedObjectContext*)managedObjectContext {
    if(_managedObjectContext) { return _managedObjectContext; }

    NSPersistentStoreCoordinator* persistentStoreCoordinator = self.persistentStoreCoordinator;

    if(persistentStoreCoordinator) {
        NSManagedObjectContext* managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];

        managedObjectContext.mergePolicy = [[NSMergePolicy alloc] initWithMergeType:NSMergeByPropertyObjectTrumpMergePolicyType];

        [managedObjectContext performBlockAndWait:^{
            [managedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];
            [[NSNotificationCenter defaultCenter]
                addObserver:self
                selector:@selector(persistentStoreDidImportUbiquitousContentChanges:)
                name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                object:persistentStoreCoordinator];
        }];

        _managedObjectContext = managedObjectContext;
    }

    return _managedObjectContext;
}

- (NSManagedObjectModel*)managedObjectModel {
    if(_managedObjectModel) { return _managedObjectModel; }

    _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];

    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator*)persistentStoreCoordinator {
    if(_persistentStoreCoordinator) { return _persistentStoreCoordinator; }

    NSPersistentStoreCoordinator* persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    _persistentStoreCoordinator = persistentStoreCoordinator;

    NSString* bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];

//	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager* fileManager = [[NSFileManager alloc] init];
		NSError* error;
        
        NSString* const storeIdentifier = @"Articles";
		
		NSURL* applicationDocumentsDirectoryURL = [fileManager
			URLForDirectory:NSDocumentDirectory
			inDomain:NSUserDomainMask
			appropriateForURL:nil
			create:YES
			error:&error];
            
        if(!applicationDocumentsDirectoryURL) {
			NSLog(@"Could not retrieve documents directory URL: %@", [error localizedDescription]);

			if([[error domain] isEqualToString:NSCocoaErrorDomain] && [error code] == NSFileWriteFileExistsError) {
				applicationDocumentsDirectoryURL = [[[NSFileManager defaultManager]
					URLsForDirectory:NSDocumentDirectory
					inDomains:NSUserDomainMask] firstObject];

				error = nil;
				[fileManager removeItemAtURL:applicationDocumentsDirectoryURL error:&error];

				applicationDocumentsDirectoryURL = [fileManager
					URLForDirectory:NSDocumentDirectory
					inDomain:NSUserDomainMask
					appropriateForURL:nil
					create:YES
					error:nil];
			}
        }
            
        NSURL* localURL = [applicationDocumentsDirectoryURL URLByAppendingPathComponent:storeIdentifier];
        // NSURL* cloudURL = [fileManager URLForUbiquityContainerIdentifier:nil];
		NSURL* cloudURL = nil; // No iCloud for now
		NSURL* transactionLogURL = [cloudURL URLByAppendingPathComponent:@"transaction_logs"];

        NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
            (id)kCFBooleanTrue, NSMigratePersistentStoresAutomaticallyOption,
            (id)kCFBooleanTrue, NSInferMappingModelAutomaticallyOption,
            NSFileProtectionNone, NSPersistentStoreFileProtectionKey, // necessary?
            nil];

        if(cloudURL) { // we do have iCloud
            NSMutableDictionary* newOptions = [NSMutableDictionary dictionaryWithDictionary:options];

            [newOptions setObject:bundleIdentifier forKey:NSPersistentStoreUbiquitousContentNameKey];
            [newOptions setObject:transactionLogURL forKey:NSPersistentStoreUbiquitousContentURLKey];

            options = newOptions;
        }
		
		// check if we have to start with the defaults database
		BOOL shouldRevertToDefaults = NO;

		if(localURL && ![localURL checkResourceIsReachableAndReturnError:nil]) {
			shouldRevertToDefaults = YES;
		}
		
		// add the persistent store
        [persistentStoreCoordinator lock]; {

            if(![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:localURL options:options error:&error]) {
                NSLog(@"Could not add persistent store: %@, %@", error, [error userInfo]);
                abort();
            }

        } [persistentStoreCoordinator unlock];

//		dispatch_async(dispatch_get_main_queue(), ^ {
            if(shouldRevertToDefaults) {
				[self revertToDefaults:nil];
			}
			
			// Persistent Store is ready
//		});
//	});

    return _persistentStoreCoordinator;
}

- (NSUInteger)application:(UIApplication*)application supportedInterfaceOrientationsForWindow:(UIWindow*)window {
	if(self.window == window) {
		NSNumber* preferredInterfaceOrientation = [[NSUserDefaults standardUserDefaults] objectForKey:@"AKPreferredInterfaceOrientation"];

		if(preferredInterfaceOrientation) {
			UIInterfaceOrientation interfaceOrientation = [preferredInterfaceOrientation integerValue];

			if(interfaceOrientation == UIInterfaceOrientationPortrait) { return UIInterfaceOrientationMaskPortrait; }
			if(interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) { return UIInterfaceOrientationMaskPortraitUpsideDown; }
			if(interfaceOrientation == UIInterfaceOrientationLandscapeLeft) { return UIInterfaceOrientationMaskLandscapeLeft; }
			if(interfaceOrientation == UIInterfaceOrientationLandscapeRight) { return UIInterfaceOrientationMaskLandscapeRight; }
		}
	}

	return UIInterfaceOrientationMaskAll;
}

#pragma mark - BITUpdateManagerDelegate
- (NSString*)customDeviceIdentifierForUpdateManager:(BITUpdateManager*)updateManager {
#ifndef CONFIGURATION_Distribution
	if([[UIDevice currentDevice] respondsToSelector:@selector(uniqueIdentifier)]) {
		return [[UIDevice currentDevice] performSelector:@selector(uniqueIdentifier)];
	}
#endif
	return nil;
}

#pragma mark - Private

- (void)articleViewWillStartNetworkActivity:(NSNotification*)notification {
	SFNetworkActivityStarted();
}

- (void)articleViewDidEndNetworkActivity:(NSNotification*)notification {
	SFNetworkActivityStopped();
}

- (void)persistentStoreDidImportUbiquitousContentChanges:(NSNotification*)notification {
	NSLog(@"Should merge changes.");
}

- (void)notificationCenterDidPostNotification:(NSNotification*)notification {
	NSLog(@"%@, %@", [notification name], [notification userInfo]);
}

- (BOOL)application:(UIApplication*)application handleSearchURLIfNeeded:(NSURL*)URL {
	if([[URL host] length] > 0) { return NO; }
    
    NSDictionary* URLParameters = [URL parameters];
	
    id searchText = [URLParameters objectForKey:@"search"];
    if(!searchText) { return NO; }
    
    [[self articleViewController] openFromURL:URL options:URLParameters];
    
	return YES;
}

@end
