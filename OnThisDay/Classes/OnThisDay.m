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

#import "OnThisDay.h"
#import "OnThisDay+Private.h"

#import "SDCalendarViewController.h"

#import "ArticleKit.h"
#import "AKArchiveController.h"

#import "SFNetworkReachability.h"

#import "SDWikipediaYearImporter.h"

#import "NSArray+Additions.h"

@implementation OnThisDay

@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize window = _window;
@synthesize calendarViewController = _calendarViewController;
@synthesize networkReachability = _networkReachability;

#pragma mark -
#pragma mark Construction & Destruction

+ (void)initialize {
	if(self == [OnThisDay class]) {
		// Load the default values for the user defaults
		NSString* userDefaultsPath = [[NSBundle mainBundle]
			pathForResource:@"Defaults" 
			ofType:@"plist"];
		NSDictionary* userDefaults = [NSDictionary dictionaryWithContentsOfFile:userDefaultsPath];
    
		// Set them in the standard user defaults
		[[NSUserDefaults standardUserDefaults] registerDefaults:userDefaults];
	}
}

#pragma mark - UIApplicationDelegate

- (void)applicationDidFinishLaunching:(UIApplication*)application {
	[[BITHockeyManager sharedHockeyManager]
		configureWithBetaIdentifier:@"5795304f504c36de957c9b0d0879aa9c"
		liveIdentifier:@"163b2272fdc86ae39eb866ed0ff81e15"
        delegate:self];
	[[BITHockeyManager sharedHockeyManager] startManager];
	
	[[[BITHockeyManager sharedHockeyManager]
		crashManager] setCrashManagerStatus:BITCrashManagerStatusAutoSend];

//	// Import the events for the whole year
//	SDWikipediaYearImporter* importer = [[SDWikipediaYearImporter alloc] initWithManagedObjectContext:[self managedObjectContext]];
//	[importer import];
//	
//	return;
	
    // Delete the legacy cache database
	NSFileManager* fileManager = [NSFileManager defaultManager];
    
    NSURL* legacyCacheFile = [fileManager URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
	legacyCacheFile = [legacyCacheFile URLByAppendingPathComponent:@"OnThisDay.sqlite"];
    
	if([legacyCacheFile checkResourceIsReachableAndReturnError:nil]) {
    	[fileManager removeItemAtURL:legacyCacheFile error:nil];
    }

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
		[fileManager removeItemAtPath:cachePath error:nil];
		
		// Update the feature property
		[[NSUserDefaults standardUserDefaults]
			setObject:@"2.3"
			forKey:@"AKFeature"];
	}
	
	// Clean up ArticleKit if needed
	[[AKArchiveController sharedController] beginMaintanceIfNeeded:nil];
	
	// Register for network reachability notifications
	SFNetworkReachability* networkReachability = [SFNetworkReachability reachabilityForInternetConnection];
	
	[networkReachability startNotifer];
	
	self.networkReachability = networkReachability;
	
	// Display the current date if needed
	NSDate* lastUsedDate = [[NSUserDefaults standardUserDefaults]
		objectForKey:@"SDLastUsedDate"];
	NSTimeInterval interval = -[lastUsedDate timeIntervalSinceNow];
	
	if(!lastUsedDate || interval >= (60.0 * 60.0 * 0.5)) {
		[[NSUserDefaults standardUserDefaults]
			setObject:nil
			forKey:@"SDSelectedDate"];
	}

	CGRect applicationFrame = [[UIScreen mainScreen] bounds];
	UIWindow* window = [[UIWindow alloc] initWithFrame:applicationFrame];
	window.backgroundColor = [UIColor blackColor];
	self.window = window;

	// Make the main view controller
	self.calendarViewController = [SDCalendarViewController viewController];
	self.calendarViewController.managedObjectContext = self.managedObjectContext;
	
	self.window.rootViewController = self.calendarViewController;
	
	[[self window] makeKeyAndVisible];
}

- (void)applicationWillTerminate:(UIApplication*)application {
	[self applicationDidEnterBackground:application];
	
	// Make the window background black to prevent bleeding views while quiting
	self.window.backgroundColor = [UIColor blackColor];
}

- (void)applicationDidEnterBackground:(UIApplication*)application {
	// Stop listening to network events
	[[self networkReachability] stopNotifer];
	
	// Update the last used date
	[[NSUserDefaults standardUserDefaults]
		setObject:[NSDate date]
		forKey:@"SDLastUsedDate"];
	
	// Store all pending changes
    NSError* error = nil;

	NSManagedObjectContext* managedObjectContext = self.managedObjectContext;

	if(managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
			// Handle error
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			exit(-1);  // Fail
        } 
	}
}

- (void)applicationWillEnterForeground:(UIApplication*)application {
	// Start looking for network events again
	[[self networkReachability] startNotifer];
}

- (void)applicationSignificantTimeChange:(UIApplication*)application {
	[[self calendarViewController] showToday:application];
}

#pragma mark - Core Data

- (NSManagedObjectContext*)managedObjectContext {
    if(!_managedObjectContext) {
         NSPersistentStoreCoordinator* coordinator = self.persistentStoreCoordinator;
   
		if(coordinator) {
			_managedObjectContext = [[NSManagedObjectContext alloc] init];
			[_managedObjectContext setPersistentStoreCoordinator:coordinator];
		}
    }

    return _managedObjectContext;
}

- (NSManagedObjectModel*)managedObjectModel {
    if(!_managedObjectModel) {
		_managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    }

    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator*)persistentStoreCoordinator {
    if(!_persistentStoreCoordinator) {
		// Make a new persistent store coordinator
		_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
		
		// Add the bookmarks store
		NSError* error = nil;
        
        NSURL* eventCacheURL = [[NSFileManager defaultManager]
        	URLForDirectory:NSCachesDirectory
            inDomain:NSUserDomainMask
            appropriateForURL:nil
            create:YES
            error:&error];
		eventCacheURL = [eventCacheURL URLByAppendingPathComponent:@"OnThisDay.sqlite"];

		NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
			[NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
			nil];
		
		if(![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:eventCacheURL options:options error:&error]) {
			NSLog(@"%@", error);
		}
	}

    return _persistentStoreCoordinator;
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

@end
