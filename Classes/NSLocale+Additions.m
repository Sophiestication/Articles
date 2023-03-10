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

#import "NSLocale+Additions.h"
#import "NSArray+Additions.h"

#import <objc/runtime.h>

@implementation NSLocale(Additions)

void* const SUIPreferredLanguageCodeAssocitatedObjectKey;

- (NSString*)preferredLanguageCode {
	NSString* languageCode = objc_getAssociatedObject(self, &SUIPreferredLanguageCodeAssocitatedObjectKey);
	if(languageCode) { return languageCode; }

	NSArray* availableLocalizations = [[NSBundle mainBundle] localizations];

	NSArray* preferredLocalizations = [NSBundle
		preferredLocalizationsFromArray:availableLocalizations
		forPreferences:@[ [self objectForKey:NSLocaleIdentifier] ]];

	languageCode = [preferredLocalizations firstObject];
	objc_setAssociatedObject(self, &SUIPreferredLanguageCodeAssocitatedObjectKey, languageCode, OBJC_ASSOCIATION_RETAIN);
	
	return languageCode;
}

@end
