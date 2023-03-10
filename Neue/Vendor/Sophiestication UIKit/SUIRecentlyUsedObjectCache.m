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

#import "SUIRecentlyUsedObjectCache.h"

@interface SUIRecentlyUsedObjectCache()

@property(nonatomic) NSUInteger maximumNumberOfObjects;

@property(nonatomic, strong) NSMapTable* objects;
@property(nonatomic, strong) NSMutableArray* recentlyUsedObjectKeys;

@end

@implementation SUIRecentlyUsedObjectCache

#pragma mark - Construction & Destruction

- (id)initWithMaximumNumberOfObjects:(NSUInteger)maximumNumberOfObjects {
	if((self = [super init])) {
		self.maximumNumberOfObjects = maximumNumberOfObjects;

		self.objects = [NSMapTable strongToStrongObjectsMapTable];
		self.recentlyUsedObjectKeys = [NSMutableArray arrayWithCapacity:maximumNumberOfObjects];
	}

	return self;
}

- (id)init {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

#pragma mark - SUIRecentlyUsedObjectCache

- (id)objectForKey:(id)key {
	id object = [[self objects] objectForKey:key];
	[self markObjectForKeyAsRecentlyUsed:key];
	return object;
}

- (void)setObject:(id)object forKey:(id)key {
	[[self objects] setObject:object forKey:key];
	[self markObjectForKeyAsRecentlyUsed:key];
}

- (void)removeAllObjects {
	[[self objects] removeAllObjects];
	[[self recentlyUsedObjectKeys] removeAllObjects];
}

#pragma mark - Private

- (void)markObjectForKeyAsRecentlyUsed:(id)key {
	NSMutableArray* recentKeys = self.recentlyUsedObjectKeys;
	[recentKeys removeObject:key];
	[recentKeys addObject:key];

	if(recentKeys.count > self.maximumNumberOfObjects) {
		NSRange range = NSMakeRange(0, recentKeys.count - self.maximumNumberOfObjects);
		[recentKeys removeObjectsInRange:range];
	}
}

@end
