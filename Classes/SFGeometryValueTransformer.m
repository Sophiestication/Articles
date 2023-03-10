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

#import "SFGeometryValueTransformer.h"


NSString* const SFCGPointValueTransformerName = @"SFCGPointValueTransformer";

@implementation SFCGPointValueTransformer

+ (Class)transformedValueClass {
	return [NSValue class];
}

+ (BOOL)allowsReverseTransformation {
	return YES;
}

-(id)transformedValue:(id)value {
   if(value) {
		NSString* string = NSStringFromCGPoint([value CGPointValue]);
		return [string dataUsingEncoding:NSUTF8StringEncoding];
	}
	
	return nil;
}

- (id)reverseTransformedValue:(id)value {
	 if(value) {
		NSString* string = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
		return [NSValue valueWithCGPoint:CGPointFromString(string)];
	}
	
	return nil;
}

@end

#pragma mark -

NSString* const SFCGSizeValueTransformerName = @"SFCGSizeValueTransformer";

@implementation SFCGSizeValueTransformer

+ (Class)transformedValueClass {
	return [NSValue class];
}

+ (BOOL)allowsReverseTransformation {
	return YES;
}

-(id)transformedValue:(id)value {
   if(value) {
		NSString* string = NSStringFromCGSize([value CGSizeValue]);
		return [string dataUsingEncoding:NSUTF8StringEncoding];
	}
	
	return nil;
}

- (id)reverseTransformedValue:(id)value {
	 if(value) {
		NSString* string = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
		return [NSValue valueWithCGSize:CGSizeFromString(string)];
	}
	
	return nil;
}

@end

#pragma mark -

NSString* const SFCGRectValueTransformerName = @"SFCGRectValueTransformer";

@implementation SFCGRectValueTransformer

+ (Class)transformedValueClass {
	return [NSValue class];
}

+ (BOOL)allowsReverseTransformation {
	return YES;
}

-(id)transformedValue:(id)value {
   if(value) {
		NSString* string = NSStringFromCGRect([value CGRectValue]);
		return [string dataUsingEncoding:NSUTF8StringEncoding];
	}
	
	return nil;
}

- (id)reverseTransformedValue:(id)value {
	 if(value) {
		NSString* string = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
		return [NSValue valueWithCGRect:CGRectFromString(string)];
	}
	
	return nil;
}

@end
