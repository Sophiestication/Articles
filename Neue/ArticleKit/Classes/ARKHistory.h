//
//  ARKHistory.h
//  Articles
//
//  Created by Sophia Teutschler on 25.06.13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ARKHistoryItem;

@interface ARKHistory : NSManagedObject

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSNumber * selectedItemIndex;
@property (nonatomic, retain) NSSet *historyItems;
@end

@interface ARKHistory (CoreDataGeneratedAccessors)

- (void)addHistoryItemsObject:(ARKHistoryItem *)value;
- (void)removeHistoryItemsObject:(ARKHistoryItem *)value;
- (void)addHistoryItems:(NSSet *)values;
- (void)removeHistoryItems:(NSSet *)values;

@end
