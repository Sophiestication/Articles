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

#import "WIKPredicate.h"
#import "WIKToken.h"
#import "WIKPredicateFormatter.h"

@interface WIKPredicate()

+ (NSRegularExpression*)sharedTokenizer;

@property(nonatomic, readwrite, copy) NSArray* tokens;
@property(nonatomic, readwrite, copy) NSString* predicateFormat;

@end

@implementation WIKPredicate

#pragma mark - WIKSearchPredicate

+ (instancetype)predicateWithFormat:(NSString*)format {
	if(format.length == 0) { return nil; }

	NSMutableArray* tokens = [NSMutableArray array];
	
	NSRegularExpression* tokenizer = [self sharedTokenizer];
	NSRange range = NSMakeRange(0, [format length]);
	
	// NSCharacterSet* noneUppercaseCharacters = [[NSCharacterSet uppercaseLetterCharacterSet] invertedSet];
	
	[tokenizer enumerateMatchesInString:format options:0 range:range usingBlock:^(NSTextCheckingResult* match, NSMatchingFlags flags, BOOL* stop) {
		NSString* string = [format substringWithRange:[match range]];
		
		// BOOL isUppercaseString = [string rangeOfCharacterFromSet:noneUppercaseCharacters].location == NSNotFound;
		// BOOL isShortString = string.length <= 2;
		
		WIKToken* newToken = [WIKToken tokenForString:string];

		// newToken.approximateMatchingEnabled = !isUppercaseString && !isShortString;
		// newToken.prefixMatchingEnabled = isUppercaseString;
		
		[tokens addObject:newToken];
	}];
	
	WIKPredicate* predicate = [[self alloc] init];
	
	predicate.tokens = tokens;
	predicate.predicateFormat = format;
	
	return predicate;
}

- (void)setTitleMatchingEnabled:(BOOL)titleMatchingEnabled {
	for(WIKToken* token in self.tokens) { token.titleMatchingEnabled = titleMatchingEnabled; }
}

- (void)setApproximateMatchingEnabled:(BOOL)approximateMatchingEnabled {
	for(WIKToken* token in self.tokens) { token.approximateMatchingEnabled = approximateMatchingEnabled; }
}

#pragma mark - NSObject

- (NSString*)description {
	return [NSString stringWithFormat:@"%@ {format = %@}",
		[super description],
		[self predicateFormat]];
}

- (NSString*)debugDescription {
	return [NSString stringWithFormat:@"%@ {format = %@, query = %@}",
		[super description],
		[self predicateFormat],
		[WIKPredicateFormatter queryStringForPredicate:self]];
}

- (NSUInteger)hash {
	return [[self predicateFormat] hash];
}

- (BOOL)isEqual:(id)object {
	if(self == object) { return YES; }
	if(!object) { return NO; }
	if(![object isKindOfClass:[WIKPredicate class]]) { return NO; }

	WIKPredicate* otherPredicate = object;

	NSArray* otherTokens = otherPredicate.tokens;
	if([[self tokens] isEqualToArray:otherTokens]) { return YES; }

	return NO;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone*)zone {
	WIKPredicate* predicate = [[[self class] allocWithZone:zone] init];

	predicate.tokens = self.tokens;
	predicate.predicateFormat = self.predicateFormat;

	return predicate;
}

#pragma mark - Private

+ (NSRegularExpression*)sharedTokenizer {
	static NSRegularExpression* _wik_sharedTokenizer = nil;
    static dispatch_once_t _wik_sharedTokenizerOnce;

    dispatch_once(&_wik_sharedTokenizerOnce, ^{
		_wik_sharedTokenizer = [[NSRegularExpression alloc]
			initWithPattern:@"(\"[^\"]+\"|'[^']+')|([^\\s,]+)"
			options:NSRegularExpressionDotMatchesLineSeparators
			error:nil];
    });

    return _wik_sharedTokenizer;
}

@end
