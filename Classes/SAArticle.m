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

#import "SAArticle.h"

#import "SAArticleStackItem.h"
#import "SABookmark.h"
#import "SAReadLaterBookmark.h"

@implementation SAArticle 

@dynamic unread;
@dynamic thumbnailURL;
@dynamic title;
@dynamic lastUsedDate;
@dynamic articleURL;
@dynamic readLaterDate;
@dynamic bookmarks;
@dynamic readLater;
@dynamic stackItems;
@dynamic lastUsedDay;

- (void)dealloc {
	[self releaseObserversIfNeeded];
}

- (void)awakeFromInsert {
	[super awakeFromInsert];
    [self initObserversIfNeeded];
}

- (void)awakeFromFetch {
	[super awakeFromFetch];
    [self updateLastUsedDay];
    [self initObserversIfNeeded];
}

- (void)willTurnIntoFault {
	[self releaseObserversIfNeeded];
    [super willTurnIntoFault];
}

@end

@implementation SAArticle(LastUsedDate)

- (void)updateLastUsedDate {
	self.lastUsedDate = [NSDate date];
    [self updateLastUsedDay];
}

- (void)updateLastUsedDay {
	NSDate* lastUsedDate = [self lastUsedDate];
    
    if(!lastUsedDate) {
    	self.lastUsedDay = nil;
        return;
    }
    
    NSCalendar* calendar = [NSCalendar autoupdatingCurrentCalendar];

	NSDateComponents* components = [calendar
		components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
		fromDate:lastUsedDate];
	
    [components setHour:0];
	[components setMinute:0];
	[components setSecond:0];
    
    NSDate* lastUsedDay = [calendar dateFromComponents:components];
    self.lastUsedDay = lastUsedDay;
}

- (void)initObserversIfNeeded {
	[[NSNotificationCenter defaultCenter]
    	addObserver:self
        selector:@selector(applicationSignificantTimeChange:)
        name:UIApplicationSignificantTimeChangeNotification
        object:nil];
}

- (void)releaseObserversIfNeeded {
	[[NSNotificationCenter defaultCenter]
    	removeObserver:self
        name:UIApplicationSignificantTimeChangeNotification
        object:nil];
}

- (void)applicationSignificantTimeChange:(NSNotification*)notification {
	[self updateLastUsedDay];
}

@end
