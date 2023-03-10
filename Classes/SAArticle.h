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

#import <CoreData/CoreData.h>

@class SAArticleStackItem;
@class SABookmark;
@class SAReadLaterBookmark;

@interface SAArticle :  NSManagedObject  
{
}

@property (nonatomic, strong) NSNumber * unread;
@property (nonatomic, strong) NSString * thumbnailURL;
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSDate * lastUsedDate;
@property (nonatomic, strong) NSString * articleURL;
@property (nonatomic, strong) NSDate * readLaterDate;
@property (nonatomic, strong) NSSet* bookmarks;
@property (nonatomic, strong) SAReadLaterBookmark * readLater;
@property (nonatomic, strong) NSSet* stackItems;
@property (nonatomic, strong) NSDate * lastUsedDay;

@end


@interface SAArticle (CoreDataGeneratedAccessors)
- (void)addBookmarksObject:(SABookmark *)value;
- (void)removeBookmarksObject:(SABookmark *)value;
- (void)addBookmarks:(NSSet *)value;
- (void)removeBookmarks:(NSSet *)value;

- (void)addStackItemsObject:(SAArticleStackItem *)value;
- (void)removeStackItemsObject:(SAArticleStackItem *)value;
- (void)addStackItems:(NSSet *)value;
- (void)removeStackItems:(NSSet *)value;

@end

@interface SAArticle (LastUsedDate)

- (void)updateLastUsedDate;
- (void)updateLastUsedDay;

- (void)initObserversIfNeeded;
- (void)releaseObserversIfNeeded;

@end
