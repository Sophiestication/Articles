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

#import "NSArray+Additions.h"

@implementation NSArray(Additions)

@dynamic firstObject;
@dynamic secondObject;
@dynamic thirdObject;
@dynamic fourthObject;
@dynamic fifthObject;

- (id)firstObject {
	if(self.count > 0) {
		return [self objectAtIndex:0];
	}
	
	return nil;
}

- (id)secondObject {
	if(self.count > 1) {
		return [self objectAtIndex:1];
	}
	
	return nil;
}

- (id)thirdObject {
	if(self.count > 2) {
		return [self objectAtIndex:2];
	}
	
	return nil;
}

- (id)fourthObject {
	if(self.count > 3) {
		return [self objectAtIndex:3];
	}
	
	return nil;
}

- (id)fifthObject {
	if(self.count > 4) {
		return [self objectAtIndex:4];
	}
	
	return nil;
}

+ (id)arrayWithObject:(id)object count:(NSUInteger)count {
	NSMutableArray* array = [NSMutableArray arrayWithCapacity:count];
	NSUInteger index = 0;
	
	for(; index < count; ++index) {
		[array addObject:object];
	}
	
	return array;
}

- (id)objectBeforeObject:(id)object {
	NSUInteger objectIndex = [self indexOfObject:object];
	
	if(objectIndex != NSNotFound && objectIndex > 0) {
		return [self objectAtIndex:objectIndex - 1];
	}
	
	return nil;
}

- (id)objectAfterObject:(id)object {
	NSUInteger objectIndex = [self indexOfObject:object];
	
	if(objectIndex != NSNotFound && objectIndex + 1 < self.count) {
		return [self objectAtIndex:objectIndex + 1];
	}
	
	return nil;
}

- (NSArray*)arrayByRemovingObject:(id)object {
    if(!object) {
		return [self copy];
	}
    
	NSMutableArray* newArray = [NSMutableArray arrayWithArray:self];
    
	[newArray removeObject:object];
    
	return newArray;
}

- (NSArray*)arrayByRemovingObjectsInArray:(NSArray*)array {
    NSMutableArray* newArray = [NSMutableArray arrayWithArray:self];
    
	[newArray removeObjectsInArray:array];
    
	return newArray;
}

- (NSArray*)arrayByReplacingObject:(id)object withObject:(id)replacementObject {
	NSInteger objectIndex = [self indexOfObject:object];
	
	if(objectIndex == NSNotFound) {
		return self;
	}
	
	NSMutableArray* newArray = [NSMutableArray arrayWithArray:self];
	
	[newArray replaceObjectAtIndex:objectIndex withObject:replacementObject];
	
	return newArray;
}

- (NSArray*)arrayByReplacingObjectAtIndex:(NSInteger)index withObject:(id)object {
	NSMutableArray* newArray = [NSMutableArray arrayWithArray:self];
	
	[newArray replaceObjectAtIndex:index withObject:object];
	
	return newArray;
}

- (NSArray*)arrayByMovingObjectAtIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destinationIndex {
	NSMutableArray* newArray = [NSMutableArray arrayWithArray:self];
	
	id object = [newArray objectAtIndex:sourceIndex];
	

	[newArray removeObjectAtIndex:sourceIndex];
	[newArray insertObject:object atIndex:destinationIndex];
	
	
	return newArray;
}

@end
