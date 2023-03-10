//
//  ARKManagedObjectStoreController.h
//  Articles
//
//  Created by Sophia Teutschler on 26.06.13.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ARKManagedObjectStoreType) {
	ARKManagedObjectStoreTypeHistory = 0 << 16,
	ARKManagedObjectStoreTypeBookmarks = 1 << 16,
	ARKManagedObjectStoreTypeReadingList = 2 << 16
};

@interface ARKManagedObjectStoreController : NSObject

+ (void)requestManagedObjectContextOfType:(ARKManagedObjectStoreType)type completion:(void (^)(NSManagedObjectContext* managedObjectContext, NSError* error))completion;

@end