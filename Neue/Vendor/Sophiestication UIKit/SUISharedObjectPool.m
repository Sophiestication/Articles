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

#import "SUISharedObjectPool.h"

@interface SUISharedObjectPool() {
	dispatch_semaphore_t _semaphore;
	NSMutableArray* _sharedObjects;
}

@property(nonatomic, copy) id (^factoryBlock)(void);

@end

@implementation SUISharedObjectPool

#pragma mark - Construction & Destruction

- (id)initWithFactoryBlock:(id (^)(void))factoryBlock maximumNumberOfObjects:(NSUInteger)maximumNumberOfObjects {
	if((self = [super init])) {
		self.factoryBlock = factoryBlock;

		_semaphore = dispatch_semaphore_create(maximumNumberOfObjects);
		_sharedObjects = [[NSMutableArray alloc] initWithCapacity:maximumNumberOfObjects];
	}

	return self;
}

#pragma mark - SUISharedObjectPool

- (void)dequeueSharedObjectWithinBlock:(void (^)(id object))block {
	dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER); {

		id object = [self dequeueSharedObject];
		block(object);
		[self enqueueSharedObject:object];

	} dispatch_semaphore_signal(_semaphore);
}

#pragma mark - Private

- (id)dequeueSharedObject {
	id sharedObject;

	@synchronized(_sharedObjects) {
		sharedObject = [_sharedObjects lastObject];

		if(sharedObject) {
			NSUInteger lastObjectIndex = _sharedObjects.count - 1;
			[_sharedObjects removeObjectAtIndex:lastObjectIndex];
		} else {
			sharedObject = self.factoryBlock();
		}
	}

	return sharedObject;
}

- (void)enqueueSharedObject:(id)sharedObject {
	@synchronized(_sharedObjects) {
		[_sharedObjects addObject:sharedObject];
	}
}

@end
