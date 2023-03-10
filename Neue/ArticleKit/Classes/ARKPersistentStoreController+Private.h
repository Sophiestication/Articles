//
//  ARKPersistentStoreController+Private.h
//  Articles
//
//  Created by Sophia Teutschler on 24.12.11.
//  Copyright (c) 2011 Sophiestication Software. All rights reserved.
//

#import "ARKPersistentStoreController.h"

@interface ARKPersistentStoreController()

@property(nonatomic, readwrite, strong) UIManagedDocument* managedDocument;

- (void)initManagedDocumentIfNeeded;
- (void)initDefaultConfiguration;

- (void)postDidFinishLoadingNotification;

@end