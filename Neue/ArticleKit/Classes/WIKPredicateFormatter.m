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

#import "WIKPredicateFormatter.h"

#import "WIKPredicate.h"
#import "WIKToken.h"

@implementation WIKPredicateFormatter

+ (NSString*)queryStringForPredicate:(WIKPredicate*)predicate {
	if(!predicate) { return nil; }

	NSArray* tokens = predicate.tokens;
	NSMutableArray* expressionStrings = [NSMutableArray arrayWithCapacity:[tokens count]];
	
	for(WIKToken* token in tokens) {
		NSString* newExpressionString = [self queryExpressionStringForToken:token];
		if(newExpressionString.length == 0) { continue; }
		
		[expressionStrings addObject:newExpressionString];
	}
	
	NSString* string = [expressionStrings componentsJoinedByString:@" "];
	return string;
}

+ (NSString*)queryExpressionStringForToken:(WIKToken*)token {
	NSString* string = token.string;
	
	if(token.titleMatchingEnabled) {
		if(![string hasPrefix:WIKSearchTokenTitleMatchingExpressionString]) {
			string = [WIKSearchTokenTitleMatchingExpressionString stringByAppendingString:string];
		}
	}
	
	if(token.prefixMatchingEnabled) {
		if(![string hasSuffix:WIKSearchTokenPrefixMatchingExpressionString]) {
			string = [string stringByAppendingString:WIKSearchTokenPrefixMatchingExpressionString];
		}
	}

	if(token.approximateMatchingEnabled) {
		if(string.length > 2 && ![string hasSuffix:WIKSearchTokenApproximateMatchingExpressionString]) {
			NSString* approximateString = [string stringByAppendingString:WIKSearchTokenApproximateMatchingExpressionString];
			// string = [NSString stringWithFormat:@"(%@ OR %@)", string, approximateString];
			string = approximateString;
		}
	}
	
	return string;
}

@end

#pragma mark -

NSString* const WIKSearchTokenTitleMatchingExpressionString = @"intitle:";
NSString* const WIKSearchTokenApproximateMatchingExpressionString = @"~";
NSString* const WIKSearchTokenPrefixMatchingExpressionString = @"*";
