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

#import "SDWikipediaYearImporter.h"
#import "SDWikipediaYearImporter+Private.h"

#import "SDWikipediaEventImporter.h"

#import "WikipediaAPI.h"

#import "SDDay.h"
#import "SDDay+Additions.h"

@implementation SDWikipediaYearImporter

@synthesize managedObjectContext = _managedObjectContext;
@synthesize operationQueue = _operationQueue;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext {
	if(self = [super init]) {
		self.managedObjectContext = managedObjectContext;
		
		self.operationQueue = [[NSOperationQueue alloc] init];
		[[self operationQueue] setMaxConcurrentOperationCount:4];
	}
	
	return self;
}

- (void)dealloc {
	self.operationQueue = nil;
	self.managedObjectContext = nil;
}

#pragma mark -
#pragma mark SDWikipediaYearImporter

- (void)import {
	NSArray* localizations = [[NSBundle mainBundle] localizations];
	
	for(NSString* localization in localizations) {
		[self importLanguage:localization];
	}
	
//	do {
//		pool = [[NSAutoreleasePool alloc] init];
//		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
//		[pool release];
//	} while(1);
}

- (void)importLanguage:(NSString*)languageCode {
	// Now iterate over the whole year
	NSCalendar* gregorian = [NSCalendar currentCalendar];
	
	NSDate* firstDay = [gregorian dateFromComponents:[self firstDayComponents]];
	NSDate* currentDay = firstDay;
	
	NSDateComponents* nextDayComponent = [[NSDateComponents alloc] init];
	[nextDayComponent setDay:1];
	
	NSInteger currentYear = [[gregorian components:NSYearCalendarUnit fromDate:firstDay] year];
	
	WikipediaAPI* wikipediaAPI = [[WikipediaAPI alloc] init];
	
	wikipediaAPI.preferredLanguage = languageCode;
	
	do {
		// Import for the current day
		NSURL* eventURL = [wikipediaAPI eventURLForDate:currentDay];
	
		SDWikipediaEventImporter* importer = [SDWikipediaEventImporter eventImporterForURL:eventURL];
	
		importer.delegate = self;
		
		NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
			eventURL, @"URL",
			languageCode, @"language",
			currentDay, @"date",
			nil];
		importer.userInfo = userInfo;
	
		[[self operationQueue] addOperation:importer];
		
		// Go to the next day
		currentDay = [gregorian
			dateByAddingComponents:nextDayComponent
			toDate:currentDay
			options:0];
		
	} while([[gregorian components:NSYearCalendarUnit fromDate:currentDay] year] == currentYear);
}

#pragma mark -
#pragma mark SDWikipediaEventImporterDelegate

- (void)wikipediaEventImporter:(SDWikipediaEventImporter*)importer didFinishWithEventGroups:(NSArray*)eventGroups {
	NSDictionary* userInfo = importer.userInfo;
	
	SDDay* day = [SDDay
		dayForDate:[userInfo objectForKey:@"date"]
		language:[userInfo objectForKey:@"language"]
		wikipediaURL:[userInfo objectForKey:@"URL"]
		eventGroups:eventGroups
		managedObjectContext:[self managedObjectContext]];
	
	if(day) {
		NSError* error = nil;

		if(![[self managedObjectContext] save:&error]) {
			NSLog(@"%@", error);
		}
		
		[[self managedObjectContext] processPendingChanges];
	}
}

- (void)wikipediaEventImporter:(SDWikipediaEventImporter*)importer didFailWithError:(NSError*)error {
	NSLog(@"Event import did fail: %@", error);
}

#pragma mark -
#pragma mark Private

- (NSDateComponents*)firstDayComponents {
	NSDateComponents* dateComponents = [[NSDateComponents alloc] init];
		
	[dateComponents setSecond:0];
	[dateComponents setMinute:0];
	[dateComponents setHour:0];
	[dateComponents setDay:1];
	[dateComponents setMonth:1];
	[dateComponents setYear:2012]; // 2012 is a leap year
	
	return dateComponents;
}

@end
