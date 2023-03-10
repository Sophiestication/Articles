//
//  ARKPersistentStoreController.m
//  Articles
//
//  Created by Sophia Teutschler on 24.12.11.
//  Copyright (c) 2011 Sophiestication Software. All rights reserved.
//

#import "ARKPersistentStoreController.h"
#import "ARKPersistentStoreController+Private.h"

#import "ARKHistory.h"
#import "ARKHistoryItem.h"

#import "NSString+Additions.h"

@implementation ARKPersistentStoreController

NSString* const ARKPersistentStoreControllerDidFinishLoadingNotification = @"ARKPersistentStoreControllerDidFinishLoading";

@synthesize ready = ready_;

@synthesize initializationCompletion = initializationCompletion_;
@synthesize managedDocument = managedDocument_;

#pragma mark - Construction & Destruction

+ (ARKPersistentStoreController*)sharedPersistentStoreController {
	static dispatch_once_t once;
    static ARKPersistentStoreController* sharedPersistentStoreController;
	
    dispatch_once(&once, ^{
		sharedPersistentStoreController = [[self alloc] init];
	});

    return sharedPersistentStoreController;
}

- (id)init {
	if((self = [super init])) {
		self.ready = NO;
	}
	
	return self;
}

#pragma mark - ARKPersistentStoreController

#pragma mark - Private

- (void)initManagedDocumentIfNeeded {
	if(self.managedDocument) { return; }
	
	// persistent store coordinator
	NSURL* applicationDocumentsURL = [[[NSFileManager defaultManager]
		URLsForDirectory:NSDocumentDirectory
		inDomains:NSUserDomainMask] lastObject];
	NSString* documentName = @"ArticleKit";
	NSURL* documentURL = [applicationDocumentsURL URLByAppendingPathComponent:documentName];
    
	UIManagedDocument* managedDocument = [[UIManagedDocument alloc] initWithFileURL:documentURL];
   
	NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
		(id)kCFBooleanTrue, NSMigratePersistentStoresAutomaticallyOption,
		(id)kCFBooleanTrue, NSInferMappingModelAutomaticallyOption,
		nil];
	
	managedDocument.persistentStoreOptions = options;
	
	self.managedDocument = managedDocument;
	
	if([[NSFileManager defaultManager] fileExistsAtPath:[documentURL path]]) {
		[managedDocument openWithCompletionHandler:^(BOOL success) {
			if(!success) {
				NSLog(@"Could not open ArticleKit document.");
			} else {
				self.ready = YES;
				[self performSelector:@selector(postDidFinishLoadingNotification)
					withObject:nil
					afterDelay:0.0];
			}
		}];
	} else {
		[self initDefaultConfiguration];
		
		[managedDocument saveToURL:documentURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
			if (!success) {
				NSLog(@"Could not save ArticleKit document.");
			} else {
				// TODO
			}
		}];
		
		self.ready = YES;
		[self performSelector:@selector(postDidFinishLoadingNotification)
			withObject:nil
			afterDelay:0.0];
	}
}

- (void)initDefaultConfiguration {
/*	NSManagedObjectContext* managedObjectContext = self.managedDocument.managedObjectContext;
	
	[managedObjectContext performBlockAndWait:^() {
		ARKHistory* history = [NSEntityDescription
			insertNewObjectForEntityForName:@"History"
			inManagedObjectContext:managedObjectContext];
			
		history.identifier = [NSString stringWithUUID];
		
		// TODO
		ARKHistoryItem* newHistoryItem = [NSEntityDescription
			insertNewObjectForEntityForName:@"HistoryItem"
			inManagedObjectContext:managedObjectContext];
		
		newHistoryItem.creationDate = [NSDate date];
		
		history.selectedHistoryItem = newHistoryItem;
	}];*/
}

- (void)postDidFinishLoadingNotification {
	[[NSNotificationCenter defaultCenter]
		postNotificationName:ARKPersistentStoreControllerDidFinishLoadingNotification
		object:self
		userInfo:nil];

	if(self.initializationCompletion) {
		((void (^)(void))[self initializationCompletion])();
		self.initializationCompletion = nil;
	}
}

@end