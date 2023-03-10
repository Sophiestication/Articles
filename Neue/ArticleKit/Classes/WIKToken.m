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

#import "WIKToken.h"

@implementation WIKToken

#pragma mark - WIKToken

+ (instancetype)tokenForString:(NSString*)string {
	WIKToken* token = [[self alloc] init];
	
	token.string = string;
	
	token.titleMatchingEnabled = NO;
	token.approximateMatchingEnabled = YES;
	
	return token;
}

#pragma mark - NSObject

- (NSString*)description {
	return [NSString stringWithFormat:@"%@ {string = %@}",
		[super description],
		[self string]];
}

- (NSUInteger)hash {
	return [[self string] hash];
}

- (BOOL)isEqual:(id)object {
	if(self == object) { return YES; }
	if(!object) { return NO; }
	if(![object isKindOfClass:[WIKToken class]]) { return NO; }

	WIKToken* otherToken = object;

	return [[self string] isEqualToString:[otherToken string]] &&
		self.titleMatchingEnabled == otherToken.titleMatchingEnabled &&
		self.approximateMatchingEnabled == otherToken.approximateMatchingEnabled;
}

@end
