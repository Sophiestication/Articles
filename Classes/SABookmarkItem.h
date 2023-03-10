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


@interface SABookmarkItem :  NSManagedObject  
{
}

@property (nonatomic, strong) NSDate * creationDate;
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSNumber * sortOrder;
@property (nonatomic, strong) NSString * chapter;
@property (nonatomic, strong) NSSet* subitems;
@property (nonatomic, strong) SABookmarkItem * superitem;

@end


@interface SABookmarkItem (CoreDataGeneratedAccessors)
- (void)addSubitemsObject:(SABookmarkItem *)value;
- (void)removeSubitemsObject:(SABookmarkItem *)value;
- (void)addSubitems:(NSSet *)value;
- (void)removeSubitems:(NSSet *)value;

@end

