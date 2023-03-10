//
//  ARKHistoryItem.h
//  Articles
//
//  Created by Sophia Teutschler on 25.06.13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ARKHistory;

@interface ARKHistoryItem : NSManagedObject

@property (nonatomic, retain) NSDate * creationDate;
@property (nonatomic, retain) NSDate * lastVisitDate;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) ARKHistory *history;

@end
