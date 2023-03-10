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

#import "SUIDataSourceController.h"

@interface SUIDataSourceController()

@property(nonatomic, strong) NSMapTable* sectionItems;

@end

@implementation SUIDataSourceController

#pragma mark - SUIDataSourceController

- (void)setObjects:(NSArray*)objects {
	_objects = [objects copy];

	NSMapTable* newSectionItems = [NSMapTable strongToStrongObjectsMapTable];

	for(id sectionObject in objects) {
		NSArray* items = [[self sectionItems] objectForKey:sectionObject];
		if(items) { [newSectionItems setObject:items forKey:sectionObject]; }
	}

	self.sectionItems = newSectionItems;
}

- (void)setObjects:(NSArray*)objects forObject:(id)sectionObject {
	if(!objects) { [[self sectionItems] removeObjectForKey:sectionObject]; }
	[[self sectionItems] setObject:objects forKey:sectionObject];
}

- (NSArray*)objectsForObject:(id)sectionObject {
	return [[self sectionItems] objectForKey:sectionObject];
}

- (id)objectAtSectionIndex:(NSUInteger)sectionIndex {
	if(sectionIndex >= self.objects.count) { return nil; }
	return [[self objects] objectAtIndex:sectionIndex];
}

- (NSArray*)objectsAtSectionIndex:(NSUInteger)sectionIndex {
	if(sectionIndex >= self.objects.count) { return nil; }
	id sectionObject = [[self objects] objectAtIndex:sectionIndex];
	return [self objectsForObject:sectionObject];
}

- (NSIndexPath*)indexPathForObject:(id)object inObject:(id)sectionObject {
	NSUInteger sectionIndex = [[self objects] indexOfObject:sectionObject];
	if(sectionIndex == NSNotFound) { return nil; }

	NSArray* items = [self objectsForObject:sectionObject];
	
	NSUInteger rowIndex = [items indexOfObject:object];
	if(rowIndex == NSNotFound) { return nil; }

	NSIndexPath* indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
	return indexPath;
}

- (NSArray*)indexPathsForObjects:(NSArray*)objects inObject:(id)sectionObject {
	NSMutableArray* indexPaths = [NSMutableArray arrayWithCapacity:[objects count]];

	for(id object in objects) {
		NSIndexPath* indexPath = [self indexPathForObject:object inObject:sectionObject];
		if(indexPath) { [indexPaths addObject:indexPath]; }
	}

	return indexPaths;
}

- (id)objectForRowAtIndexPath:(NSIndexPath*)indexPath {
	NSArray* items = [self objectsAtSectionIndex:[indexPath section]];

	if(indexPath.row >= items.count) { return nil; }
	id object = [items objectAtIndex:[indexPath row]];

	return object;
}

@end
