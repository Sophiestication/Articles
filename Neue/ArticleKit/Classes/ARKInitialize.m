//
//  ARKInitialize.m
//  Articles
//
//  Created by Sophia Teutschler on 24.12.11.
//  Copyright (c) 2011 Sophiestication Software. All rights reserved.
//

#import "ARKInitialize.h"

#import "ARKPersistentStoreController.h"
#import "ARKPersistentStoreController+Private.h"

void ARKInitializeIfNeeded(id completion) {
	ARKPersistentStoreController* persistentStoreController = [ARKPersistentStoreController sharedPersistentStoreController];
	persistentStoreController.initializationCompletion = completion;
	[persistentStoreController initManagedDocumentIfNeeded];
}

NSManagedObjectContext* ARKGetManagedObjectContext(void) {
	return [[[ARKPersistentStoreController sharedPersistentStoreController] managedDocument] managedObjectContext];
}