//
//  ARKInitialize.h
//  Articles
//
//  Created by Sophia Teutschler on 24.12.11.
//  Copyright (c) 2011 Sophiestication Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "ArticleKitDefines.h"

ARTICLEKIT_EXTERN void ARKInitializeIfNeeded(id completion);
ARTICLEKIT_EXTERN NSManagedObjectContext* ARKGetManagedObjectContext(void);