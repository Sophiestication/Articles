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

#import "NSURL+Wikipedia.h"
#import "NSURL+REST.h"
#import "NSString+Additions.h"

@implementation NSURL(Wikipedia)

- (BOOL)isWikipediaURL {
	return [[[self host] lowercaseString] hasSuffix:@"wikipedia.org"];
}

- (BOOL)isWikipediaFileURL {
	NSString* lastPathComponent = [[self path] lastPathComponent];

	if([lastPathComponent hasPrefix:@"File:"]) { return YES; }
	if([lastPathComponent hasPrefix:@"Datei:"]) { return YES; }
	if([lastPathComponent hasPrefix:@"Fichier:"]) { return YES; }
    if([lastPathComponent hasPrefix:@"Bestand:"]) { return YES; }
    if([lastPathComponent hasPrefix:@"Fil:"]) { return YES; }
    if([lastPathComponent hasPrefix:@"Ficheiro:"]) { return YES; }
    if([lastPathComponent hasPrefix:@"Fichier:"]) { return YES; }
	if([lastPathComponent hasPrefix:@"Tiedosto:"]) { return YES; }
    if([lastPathComponent hasPrefix:@"Archivo:"]) { return YES; }
    if([lastPathComponent hasPrefix:@"ფაილი:"]) { return YES; }
    if([lastPathComponent hasPrefix:@"ファイル:"]) { return YES; }
    if([lastPathComponent hasPrefix:@"Mynd:"]) { return YES; }
    if([lastPathComponent hasPrefix:@"קובץ:"]) { return YES; }
    if([lastPathComponent hasPrefix:@"پرونده"]) { return YES; }
    if([lastPathComponent hasPrefix:@"Файл:"]) { return YES; }
	if([lastPathComponent hasPrefix:@"파일:"]) { return YES; }
	
	if([[[self parameters] objectForKey:@"title"] length] > 0) {
		return YES;
	}
	
	NSString* extension = [[self path] pathExtension];
	
	if(SFEqualCaseInsensitiveStrings(extension, @"jpg") ||
	   SFEqualCaseInsensitiveStrings(extension, @"jpeg") ||
	   SFEqualCaseInsensitiveStrings(extension, @"png") ||
	   SFEqualCaseInsensitiveStrings(extension, @"svg")) {
		return YES;
	}
	
	return NO;
}

- (NSURL*)noneMobileWikipediaURL {
	if([[[self path] lastPathComponent] isEqualToString:@"mobileRedirect.php"]) {
		return self;
	}
	
	NSString* languageCode = [self wikipediaLanguageCode];
	NSString* newURLString = [NSString stringWithFormat:@"http://%@%@wikipedia.org/w/mobileRedirect.php?to=%@&expires_in_days=3650",
		languageCode ? languageCode : @"",
		languageCode ? @"." : @"",
		[[self absoluteString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	
	return [NSURL URLWithString:newURLString];
}

- (NSURL*)canonicalWikipediaURL {
	// Check if this is a redirect URL
	if([[[self path] lastPathComponent] isEqualToString:@"mobileRedirect.php"]) {
		NSString* canonicalURLString = [[self parameters] objectForKey:@"to"];
		
		if(canonicalURLString.length > 0) {
			// Return the actual wikipedia URL
			return [NSURL URLWithString:canonicalURLString];
		}
	}

	return self;
}

- (NSString*)wikipediaLanguageCode {
	NSURL* canonicalURL = [self canonicalWikipediaURL];
	
	NSString* host = [canonicalURL host];
	NSRange range = [host rangeOfString:@"."];
	
	if(range.location != NSNotFound) {
		NSString* languageCode = [host substringToIndex:range.location];
		return languageCode;
	}
	
	return nil;
}

- (NSString*)wikipediaID {
	NSURL* URL = [self canonicalWikipediaURL];

	NSString* wikipediaID = [URL resourceSpecifier];
    
    if([wikipediaID hasPrefix:@"//"]) {
        wikipediaID = [wikipediaID substringFromIndex:2];
    }
    
    wikipediaID = [wikipediaID
		stringByReplacingOccurrencesOfString:@"/"
		withString:@"_"];
	wikipediaID = [wikipediaID
		stringByReplacingOccurrencesOfString:@"."
		withString:@"_"];
	
	return wikipediaID;
}

- (NSString*)wikipediaTitle {
	NSString* pageString = [[self absoluteString] lastPathComponent];
	NSString* titleString = [pageString stringByReplacingOccurrencesOfString:@"_" withString:@" "];

	NSString* decodedTitleString = [titleString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	if(decodedTitleString.length > 0) { titleString = decodedTitleString; }

	return titleString;
}

- (NSURL*)wikipediaURLByFixingScheme {
	if(![self scheme]) {
		NSString* URLString = [@"http:" stringByAppendingString:[self resourceSpecifier]];
		return [NSURL URLWithString:URLString];
	}
	
	return self;
}

@end
