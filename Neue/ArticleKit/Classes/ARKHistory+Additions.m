//
//  ARKHistory+Additions.m
//  Articles
//
//  Created by Sophia Teutschler on 25.06.13.
//
//

#import "ARKHistory+Additions.h"
#import "NSArray+Additions.h"

@implementation ARKHistory(Additions)

+ (ARKHistory*)historyForIdentifier:(NSString*)identifier managedObjectContext:(NSManagedObjectContext*)managedObjectContext error:(NSError* __autoreleasing*)error {
	__block ARKHistory* history;

	[managedObjectContext performBlockAndWait:^{
		NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"History"];

		NSPredicate* predicate = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
		[fetchRequest setPredicate:predicate];

		[fetchRequest setFetchLimit:1];

		history = [[managedObjectContext executeFetchRequest:fetchRequest error:error] firstObject];
	}];

	return history;
}

@end