//
//  ARKHistory+Additions.h
//  Articles
//
//  Created by Sophia Teutschler on 25.06.13.
//
//

#import "ARKHistory.h"

@interface ARKHistory(Additions)

+ (ARKHistory*)historyForIdentifier:(NSString*)identifier managedObjectContext:(NSManagedObjectContext*)managedObjectContext error:(NSError* __autoreleasing*)error;

@end