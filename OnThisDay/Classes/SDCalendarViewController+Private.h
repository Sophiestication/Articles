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

#import "SDCalendarViewController.h"

@class SDDay;
@class SDEvent;

@interface SDCalendarViewController()

@property(nonatomic, strong) UIImageView* progressIndicator;
@property(nonatomic, strong) UIImageView* transitionView;

@property(nonatomic, copy) NSDate* previousDate;
@property(nonatomic, copy) NSDate* selectedDate;
@property(nonatomic, copy) NSDate* nextDate;

@property(nonatomic, strong) AKWebCustomizer* webCustomizer;

@property(nonatomic, strong) WikipediaAPI* wikipediaAPI;
@property(nonatomic, strong) NSOperationQueue* operationQueue;

@property(nonatomic, strong) NSDictionary* displayRelatedUserDefaults;
@property(nonatomic, strong) id metadataForLongPressGesture;

@property(nonatomic, getter=isTransitioningToNewDay) BOOL transitioningToNewDay;
@property(nonatomic, strong) SDDay* dayNeedingContentUpdate;

- (void)initProgressIndicatorIfNeeded;

- (CGRect)messageViewRect;

- (void)showErrorIfNeeded:(NSError*)error;
- (void)hideMessageView;

- (void)updateContentOffsetForCurrentDay;

- (void)selectDate:(NSDate*)date;
- (void)updateWithDay:(SDDay*)day;

- (void)fadeInCalendarContents;
- (void)clearCalendarContents;

- (SDDay*)dayForDate:(NSDate*)date;

- (void)importForDate:(NSDate*)date;
- (BOOL)isImportingEventsForDate:(NSDate*)date;

- (void)loadMoreForGroupWithID:(NSInteger)groupID;
- (NSString*)markupForEvent:(SDEvent*)event;

- (void)hideTransitionView;

- (CGRect)scrollIndicatorRect;
- (void)updateScrollIndicatorForWebView:(UIWebView*)webView;

- (NSDate*)todayDate;

@end
