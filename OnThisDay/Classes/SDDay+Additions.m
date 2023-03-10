//
// MIT License
//
// Copyright (c) 2009-2023 Sophiestication Software, Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

#import "SDDay+Additions.h"

#import "SDEventGroup.h"
#import "SDEvent.h"

// #import "NSData+GZIP.h"

@implementation SDDay(Additions)

+ (SDDay*)dayForDate:(NSDate*)date language:(NSString*)languageCode wikipediaURL:(NSURL*)wikipediaURL eventGroups:(NSArray*)eventGroups managedObjectContext:(NSManagedObjectContext*)managedObjectContext {
	// Make a new day object
	SDDay* day = [NSEntityDescription
		insertNewObjectForEntityForName:@"Day"
		inManagedObjectContext:managedObjectContext];
		
	NSDateComponents* dateComponents = [[NSCalendar currentCalendar] components:NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date];
	day.calendarDay = [NSNumber numberWithInteger:[dateComponents day]];
	day.calendarMonth = [NSNumber numberWithInteger:[dateComponents month]];
	
	day.creationDate = day.modificationDate = [NSDate date];
	day.language = languageCode;
	
//	day.wikipediaURL = [wikipediaURL absoluteString];
	
	// Now make the event groups for this day
	NSInteger groupSortOrder = 0;

	for(NSDictionary* group in eventGroups) {
		NSArray* eventInfos = [group objectForKey:@"events"];
		
		if(eventInfos.count == 0) {
			continue;
		}
		
		SDEventGroup* eventGroup = [NSEntityDescription
			insertNewObjectForEntityForName:@"EventGroup"
			inManagedObjectContext:managedObjectContext];
			
		eventGroup.title = [group objectForKey:@"title"];
		eventGroup.sortOrder = [NSNumber numberWithInteger:++groupSortOrder];
        eventGroup.kind = [group objectForKey:@"kind"];
		
		// Add all events to this group
		NSInteger eventSortOrder = 0;
		
		for(NSDictionary* eventInfo in eventInfos) {
			SDEvent* event = [NSEntityDescription
				insertNewObjectForEntityForName:@"Event"
				inManagedObjectContext:managedObjectContext];
			
//			if(YES) {
//				event.compressedMarkup = [[[eventInfo objectForKey:@"markup"] dataUsingEncoding:NSUTF8StringEncoding] compressUsingGZIP];
//			} else {
				event.markup = [eventInfo objectForKey:@"markup"];
//			}
			
			event.sortOrder = [NSNumber numberWithInteger:++eventSortOrder];
			
			[eventGroup addEventsObject:event];
		}
		
		[day addGroupsObject:eventGroup];
	}
	
	return day;
}

@end
