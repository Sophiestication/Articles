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

#import "NSURL+REST.h"

@implementation NSURL(RESTfulKit)

+ (NSURL*)URLWithString:(NSString*)URLString parameters:(NSDictionary*)parameters {
	return [self URLWithString:URLString parameters:parameters arraySeparator:@","];
}

+ (NSURL*)URLWithString:(NSString*)URLString parameters:(NSDictionary*)parameters arraySeparator:(NSString*)arraySeparator {
	NSString* parametersString = @"";
	NSInteger keyIndex = 0;
	
	for(NSString* key in parameters) {
		id value = [parameters objectForKey:key];
		
		// Comma separate the values if we have a collection
		if([value isKindOfClass:[NSArray class]]) {
			value = [value componentsSeparatedByString:arraySeparator];
		}
		
		// Determine if we can convert to a string value first
		NSString* stringValue = nil;
		
		if([value respondsToSelector:@selector(stringValue)]) {
			stringValue = [value stringValue];
		} else if([value isKindOfClass:[NSDate class]]) {
			// TODO: Might be a good idea to use the ISO 8601 format instead of UNIX timestamp
			NSTimeInterval timeInterval = [value timeIntervalSince1970];
			stringValue = [NSString stringWithFormat:@"%f", timeInterval];
		} else {
			stringValue = value;
		}

		// Double check to see if this is really a string
		NSAssert1([stringValue isKindOfClass:[NSString class]], @"Invalid URL parameter: %@", value);
		
		// URL escape both key and string value regarding RFC 1738 3.3
		NSString* escapedKey = (id)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
			kCFAllocatorDefault,
			(CFStringRef)key,
			NULL,
			(CFStringRef)@";:@&=/+",
			 kCFStringEncodingUTF8));
		
		NSString* escapedStringValue = (id)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
			kCFAllocatorDefault,
			(CFStringRef)stringValue,
			NULL,
			(CFStringRef)@";:@&=/+",
			 kCFStringEncodingUTF8));
		
		// Add the key value pair to our parameters string	
		parametersString = [parametersString stringByAppendingFormat:@"%@%@%@%@",
			keyIndex > 0 ? @"&" : @"?",
			escapedKey,
			escapedStringValue.length > 0 ? @"=" : @"",
			escapedStringValue];
			
		++keyIndex;
	}
	
	NSString* newURLString = [URLString stringByAppendingString:parametersString];

	return [NSURL URLWithString:newURLString];
}

- (NSDictionary*)parameters {
	NSString* parameterString = [self query];
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	
	for(NSString* s in [parameterString componentsSeparatedByString:@"&"]) {
		NSArray* parameter = [s componentsSeparatedByString:@"="];

		if(parameter.count > 0) {
			id key = [parameter objectAtIndex:0];
			id value = nil;
			
			if(parameter.count > 1) {
				value = [parameter objectAtIndex:1];
				
				if([value respondsToSelector:@selector(stringByReplacingPercentEscapesUsingEncoding:)]) {
					NSString* decodedValue = [(NSString*)value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
					
					if(!decodedValue) {
						decodedValue = [(NSString*)value stringByReplacingPercentEscapesUsingEncoding:NSUTF16StringEncoding];
					}
					
					if(decodedValue) {
						value = decodedValue;
					}
				}
			} else {
				value = [NSNull null];
			}
			
			if(value == nil) {
				value = [NSNull null];
			}
			
			[parameters setObject:value forKey:key];
		}
	}
	
	return parameters;
}

@end
