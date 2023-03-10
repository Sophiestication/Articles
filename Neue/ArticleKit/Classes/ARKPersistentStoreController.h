//
//  ARKPersistentStoreController.h
//  Articles
//
//  Created by Sophia Teutschler on 24.12.11.
//  Copyright (c) 2011 Sophiestication Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

NSString* const ARKPersistentStoreControllerDidFinishLoadingNotification;

@interface ARKPersistentStoreController : NSObject

+ (ARKPersistentStoreController*)sharedPersistentStoreController;

@property(nonatomic, getter=isReady) BOOL ready;

@property(nonatomic, copy) id initializationCompletion;
@property(nonatomic, readonly, strong) UIManagedDocument* managedDocument;

@end