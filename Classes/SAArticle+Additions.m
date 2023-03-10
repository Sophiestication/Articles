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

#import "SAArticle+Additions.h"

#import "SAReadLaterBookmark.h"

#import "NSArray+Additions.h"
#import "NSURL+Wikipedia.h"

@implementation SAArticle(Additions)

+ (SAArticle*)articleForURL:(NSURL*)articleURL inContext:(NSManagedObjectContext*)managedObjectContext {
	// ...
	// articleURL = [articleURL canonicalWikipediaURL];
	
	// ...
	NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
	
	NSEntityDescription* entity = [NSEntityDescription
		entityForName:@"Article"
		inManagedObjectContext:managedObjectContext];
	[fetchRequest setEntity:entity];
	
	NSString* articleURLString = [articleURL absoluteString];
	NSPredicate* predicate = [NSPredicate predicateWithFormat:@"articleURL == %@", articleURLString];
	[fetchRequest setPredicate:predicate];
	
	[fetchRequest setFetchLimit:1];
	
	NSError* error = nil;
	NSArray* fetchResults = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
	
	
	if(error) {
		// TODO
	}
	
	if(fetchResults.count == 0) {
		SAArticle* newArticle = [NSEntityDescription
			insertNewObjectForEntityForName:@"Article"
			inManagedObjectContext:managedObjectContext];
		
		newArticle.articleURL = articleURLString;
		
		return newArticle;
	}
	
	return fetchResults.firstObject;
}

- (void)readLater:(NSDictionary*)options {
	self.unread = [NSNumber numberWithBool:YES];
	self.readLaterDate = [NSDate date];
	
	SAReadLaterBookmark* readLaterBookmark = self.readLater;
	
	if(!readLaterBookmark) {
		readLaterBookmark = [NSEntityDescription
			insertNewObjectForEntityForName:@"ReadLaterBookmark"
			inManagedObjectContext:[self managedObjectContext]];
			
		readLaterBookmark.article = self;
	}
	
	readLaterBookmark.text = [options objectForKey:@"text"];
    
    NSValue* targetTextRange = [options objectForKey:@"targetTextRange"];
    
    if(targetTextRange) {
		readLaterBookmark.targetTextRange = NSStringFromRange([targetTextRange rangeValue]);
    }
}

@end
