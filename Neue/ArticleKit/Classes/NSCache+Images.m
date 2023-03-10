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

#import "NSCache+Images.h"

@implementation NSCache(Images)

+ (instancetype)sharedImageCache {
	static dispatch_once_t wik_sharedImageCacheOnce;
    static NSCache* wik_sharedImageCache;
	
    dispatch_once(&wik_sharedImageCacheOnce, ^{
		wik_sharedImageCache = [[self alloc] init];
	});

    return wik_sharedImageCache;
}

- (void)setImage:(UIImage*)image forKey:(NSString*)key {
	if(!image) { return; }

	CGSize size = image.size;

	CGFloat scale = image.scale;
	scale = MAX(scale, 1.0);

	NSUInteger cost = size.width * size.height * scale * 4.0;

	[self setObject:image forKey:key cost:cost];
}

@end
