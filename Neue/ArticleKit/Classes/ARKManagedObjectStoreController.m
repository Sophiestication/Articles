//
//  ARKManagedObjectStoreController.m
//  Articles
//
//  Created by Sophia Teutschler on 26.06.13.
//
//

#import "ARKManagedObjectStoreController.h"

@implementation ARKManagedObjectStoreController

#pragma mark - Construction & Destruction

+ (void)requestManagedObjectContextOfType:(ARKManagedObjectStoreType)storeType completion:(void (^)(NSManagedObjectContext* managedObjectContext, NSError* error))completion {
	if(!completion) { return; }

	NSOperationQueue* operationQueue = [NSOperationQueue currentQueue];

	 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		ARKManagedObjectStoreController* controller = [[self alloc] init];

		NSError* error;
		NSManagedObjectContext* managedObjectContext = [controller loadManagedObjectContextOfType:storeType error:&error];

		[operationQueue addOperationWithBlock:^() {
			completion(managedObjectContext, error);
		}];
	 });
}

#pragma mark - Private

- (NSManagedObjectContext*)loadManagedObjectContextOfType:(ARKManagedObjectStoreType)storeType error:(NSError* __autoreleasing *)error {
	NSString* bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];

	NSFileManager* fileManager = [[NSFileManager alloc] init];

	NSString* const storeIdentifier = [self preferredStoreIdentifierForType:storeType];

	NSURL* applicationSupportURL = [fileManager
		URLForDirectory:NSApplicationSupportDirectory
		inDomain:NSUserDomainMask
		appropriateForURL:nil
		create:YES
		error:nil];
	applicationSupportURL = [applicationSupportURL URLByAppendingPathComponent:bundleIdentifier];

	NSURL* localURL = [applicationSupportURL URLByAppendingPathComponent:storeIdentifier];
	NSURL* cloudURL = nil; // [fileManager URLForUbiquityContainerIdentifier:nil]; // Enable iCloud for the LOLs
	NSURL* transactionLogURL = [cloudURL URLByAppendingPathComponent:@"transaction_logs_v3"];

	// Make sure the support directory exists
	[fileManager createDirectoryAtURL:applicationSupportURL withIntermediateDirectories:YES attributes:nil error:nil];

	NSDictionary* options = @{
		NSMigratePersistentStoresAutomaticallyOption: @(YES),
		NSInferMappingModelAutomaticallyOption: @(YES) };

	if(cloudURL) { // we do have iCloud
		NSMutableDictionary* newOptions = [NSMutableDictionary dictionaryWithDictionary:options];

		[newOptions setObject:[bundleIdentifier stringByAppendingString:@".3"] forKey:NSPersistentStoreUbiquitousContentNameKey];
		[newOptions setObject:transactionLogURL forKey:NSPersistentStoreUbiquitousContentURLKey];

		options = newOptions;
	} else {
		NSLog(@"Ubiquity container URL is not available.");
	}

	NSManagedObjectModel* managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
	NSPersistentStoreCoordinator* persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];

	NSError* privateError;

	if(![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:localURL options:options error:&privateError]) {
		NSLog(@"Could not add persistent store: %@, %@", privateError, [privateError userInfo]);
		if(error) { *error = privateError; }

		return nil;
	}

	NSManagedObjectContext* managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];

	managedObjectContext.mergePolicy = [[NSMergePolicy alloc] initWithMergeType:NSMergeByPropertyObjectTrumpMergePolicyType];
	managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator;

	return managedObjectContext;
}

- (NSString*)preferredStoreIdentifierForType:(ARKManagedObjectStoreType)storeType {
	if(storeType == ARKManagedObjectStoreTypeHistory) { return @"history"; }

	[NSException raise:NSInvalidArgumentException format:@"Unsupported managed object store type specified."];
	return nil;
}

@end