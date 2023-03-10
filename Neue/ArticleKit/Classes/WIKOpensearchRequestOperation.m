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

#import "WIKOpensearchRequestOperation.h"

#import "WIKMediaWiki.h"
#import "WIKMediaWikiClient.h"

#import "DDXMLElementAdditions.h"

@implementation WIKOpensearchRequestOperation

+ (instancetype)opensearchRequestOperationWithString:(NSString*)searchString
	mediaWiki:(WIKMediaWiki*)mediaWikit
	completion:(void (^)(WIKOpensearchRequestOperation* operation, NSArray* resultSet, NSError* error))completion
	factory:(WIKPage* (^)(NSString* title, NSString* summary, NSURL* URL, BOOL hasRepresentativeImage))factory {
	
	NSDictionary* parameters = @{
		@"action": @"opensearch",
		@"search": searchString,
		@"format": WIKMediaWikiXMLFormatParameterValue,
		@"limit": @(6)
	};
	
	id privateSuccess = ^(WIKOpensearchRequestOperation* operation, DDXMLDocument* responseObject) {
		NSArray* resultSet = [operation resultsFromResponseObject:responseObject factory:factory];
		if(completion) { completion(operation, resultSet, nil); }
	};
	
	id privateFailure = ^(WIKOpensearchRequestOperation* operation, NSError* error) {
		if(completion) { completion(operation, nil, error); }
	};

	NSURLRequest* request = [[mediaWikit client] APIRequestWithParameters:parameters];

//	NSLog(@"Request %@", [[request URL] absoluteString]);

	WIKOpensearchRequestOperation* operation = [(WIKOpensearchRequestOperation*)[self alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:privateSuccess failure:privateFailure];
	
	return operation;
}

- (NSArray*)resultsFromResponseObject:(DDXMLDocument*)responseObject factory:(WIKPage* (^)(NSString* title, NSString* summary, NSURL* URL, BOOL hasRepresentativeImage))factory {
	NSMutableArray* result = [NSMutableArray arrayWithCapacity:5];
	
	NSArray* items = [[[responseObject rootElement]
		elementForName:@"Section"]
		elementsForName:@"Item"];

	for(DDXMLElement* item in items) {
		NSString* title = [[item elementForName:@"Text"] stringValue];
		if(title.length == 0) { continue; }

		NSString* summary = [[item elementForName:@"Description"] stringValue];

		NSString* URLString = [[item elementForName:@"Url"] stringValue];
		NSURL* URL = URLString.length > 0 ?
			[NSURL URLWithString:URLString] : nil;

		NSString* representativeImageURLString = [[[item elementForName:@"Image"]
			attributeForName:@"source"] stringValue];
		BOOL hasRepresentativeImage = representativeImageURLString.length > 0;

		WIKPage* resultItem = factory(title, summary, URL, hasRepresentativeImage);
		if(resultItem) { [result addObject:resultItem]; }
	}
	
	return result;
}

@end
