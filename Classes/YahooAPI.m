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

#import "YahooAPI.h"
#import	"YahooAPI+Private.h"

#import "NSArray+Additions.h"

@implementation YahooAPI

@synthesize applicationID = _applicationID;
@synthesize transactionDelegate = _transactionDelegate;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithApplicationID:(NSString*)applicationID {
	if(self = [super init]) {
		self.applicationID = applicationID;
	}
	
	return self;
}


#pragma mark -
#pragma mark Spelling Suggestions

- (RKTransaction*)suggestSpellingForString:(NSString*)string options:(NSDictionary*)options {
	// First check if we have a valid string
	if(string.length <= 0) {
		return nil;
	}
	
	// Now prepare the transaction
	NSString* method = [NSString stringWithFormat:@"http://query.yahooapis.com/v1/public/yql"];
	
    string = [string stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSString* query = [NSString stringWithFormat:@"select * from search.spelling where query=\"%@\"", string];
    
	NSMutableDictionary* parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		@"json", @"format",
        @"true", @"diagnostics",
        [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], @"q",
		// [self applicationID], @"appid",
		nil];
	if(options) {
		[parameters addEntriesFromDictionary:options];
	}
		
	NSURL* URL = [NSURL URLWithString:method parameters:parameters];
	
	RKTransaction* transaction = [RKTransaction transactionWithURL:URL];

	transaction.resultFormatter = [YahooAPISpellingSuggestionResultFormatter formatter];
	transaction.delegate = self.transactionDelegate;
	
	return transaction;
}

@end

#pragma mark -
#pragma mark YahooAPISpellingSuggestionResultFormatter

@implementation YahooAPISpellingSuggestionResultFormatter

- (id)formatResultData:(NSData*)resultData error:(NSError**)error response:(NSURLResponse*)response {
	NSDictionary* resultDictionary = [super formatResultData:resultData error:error response:response];
	NSString* spellingSuggestion = nil;
	
	if([resultDictionary respondsToSelector:@selector(valueForKeyPath:)]) {
		NSNumber* count = [resultDictionary valueForKeyPath:@"ysearchresponse.count"];
		
		if([count respondsToSelector:@selector(integerValue)] && [count integerValue] > 0) {
			NSArray* resultSet = [resultDictionary valueForKeyPath:@"ysearchresponse.resultset_spell"];
			
			if([resultSet respondsToSelector:@selector(firstObject)]) {
				NSDictionary* result = [resultSet firstObject];
				
				if([result respondsToSelector:@selector(objectForKey:)]) {
					spellingSuggestion = [result objectForKey:@"suggestion"];
				}
			}
		}
	}
	
	if(!spellingSuggestion) {
		spellingSuggestion = @"";
	}
	
	return spellingSuggestion;
}

@end
