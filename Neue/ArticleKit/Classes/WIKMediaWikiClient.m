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

#import "WIKMediaWikiClient.h"
#import "WIKQueryEnumerator.h"

NSString* const WIKErrorDomain = @"com.sophiestication.CoreMediaWiki";

@interface WIKMediaWikiClient()
@end

NSString* const WIKMediaWikiQueryAction = @"query";

NSString* const WIKMediaWikiActionParameterKey = @"action";
NSString* const WIKMediaWikiFormatParameterKey = @"format";
NSString* const WIKMediaWikiPropertiesParameterKey = @"prop";
NSString* const WIKMediaWikiImagePropertiesParameterKey = @"iiprop";
NSString* const WIKMediaWikiTitlesParameterKey = @"titles";
NSString* const WIKMediaWikiRequestIdentifierParameterKey = @"requestid";

NSString* const WIKMediaWikiInfoProperty = @"info";
NSString* const WIKMediaWikiPageInfoProperty = @"pageprops";
NSString* const WIKMediaWikiPageImageProperty = @"pageimages";
NSString* const WIKMediaWikiExtractsProperty = @"extracts";
NSString* const WIKMediaWikiImageInfoProperty = @"imageinfo";
NSString* const WIKMediaWikiImagesProperty = @"images";
NSString* const WIKMediaWikiCoordinatesProperty = @"coordinates";

NSString* const WIKMediaWikiURLImageProperty = @"url";
NSString* const WIKMediaWikiSizeImageProperty = @"size";
NSString* const WIKMediaWikiMIMETypeImageProperty = @"mime";
NSString* const WIKMediaWikiThumbnailMIMETypeImageProperty = @"thumbmime";

NSString* const WIKMediaWikiJSONFormatParameterValue = @"json";
NSString* const WIKMediaWikiXMLFormatParameterValue = @"xml";

@implementation WIKMediaWikiClient

#pragma mark - Construction & Destruction

- (id)initWithBaseURL:(NSURL*)URL {
	if((self = [super initWithBaseURL:URL])) {
	}
	
	return self;
}

#pragma mark - WIKMediaWikiClient

- (NSURLRequest*)APIRequestWithParameters:(NSDictionary*)parameters {
	NSURLRequest* request = [self requestWithMethod:@"GET" path:@"/w/api.php" parameters:parameters];
	return request;
}

- (AFHTTPRequestOperation*)performAction:(NSString*)action
	parameters:(NSDictionary*)parameters
	success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success
	failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure {
	
	NSMutableDictionary* newParameters = [parameters mutableCopy];
	newParameters[WIKMediaWikiActionParameterKey] = action; // action
	newParameters[WIKMediaWikiFormatParameterKey] = WIKMediaWikiJSONFormatParameterValue; // format
	
	id privateSuccess = ^(AFJSONRequestOperation* operation, id responseObject) {
		id JSON = [operation responseJSON];
		NSError* JSONError = [self detectErrorInJSONResult:JSON operation:operation];
		
		if(JSONError) {
			if(failure) { failure(operation, JSONError); }
		} else {
			if(success) { success(operation, JSON); }
		}
	};
	
	id privateFailure = ^(AFJSONRequestOperation* operation, NSError* error) {
		if(failure) { failure(operation, error); }
	};

	NSURLRequest* request = [self APIRequestWithParameters:newParameters];

	AFJSONRequestOperation* operation = [[AFJSONRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:privateSuccess failure:privateFailure];
	
	[self enqueueHTTPRequestOperation:operation];
	
	return operation;
}

- (WIKQueryEnumerator*)properties:(NSArray*)properties forPageTitles:(NSArray*)titles {
	return [self properties:properties forPageTitles:titles parameters:nil];
}

- (WIKQueryEnumerator*)properties:(NSArray*)properties forPageTitles:(NSArray*)titles parameters:(NSDictionary*)parameters {
	NSMutableDictionary* queryParameters = [NSMutableDictionary dictionary];

	queryParameters[WIKMediaWikiPropertiesParameterKey] = [self stringForParameterValues:properties];
	queryParameters[WIKMediaWikiTitlesParameterKey] = [self stringForParameterValues:titles];

	if([properties containsObject:WIKMediaWikiInfoProperty]) {
		queryParameters[@"inprop"] = @"url";
	}

	if([properties containsObject:WIKMediaWikiPageImageProperty]) {
		queryParameters[@"pithumbsize"] = @(64);
		queryParameters[@"pilimit"] = @(50); // 50 is the maximum limit according to media wiki
	}

	if([properties containsObject:WIKMediaWikiExtractsProperty]) {
		queryParameters[@"exintro"] = [NSNull null];
		queryParameters[@"exchars"] = @(240);
		queryParameters[@"exlimit"] = @(20); // 20 is the maximum limit according to media wiki
	}
	
	if(parameters) { [queryParameters addEntriesFromDictionary:parameters]; }
	
	WIKQueryEnumerator* enumerator = [[WIKQueryEnumerator alloc]
		initWithParameters:queryParameters
		client:self
		shouldContinue:YES];
	return enumerator;
}

- (WIKQueryEnumerator*)imagesNamed:(NSArray*)imageNames {
	if(imageNames.count == 0) { return nil; }
	
	NSArray* properties = @[
		WIKMediaWikiImageInfoProperty ];

	NSArray* imageProperties = @[
		WIKMediaWikiURLImageProperty,
		WIKMediaWikiSizeImageProperty,
		WIKMediaWikiMIMETypeImageProperty,
		WIKMediaWikiThumbnailMIMETypeImageProperty ];
	
	NSDictionary* parameters = @{
		WIKMediaWikiPropertiesParameterKey: [self stringForParameterValues:properties],
		WIKMediaWikiImagePropertiesParameterKey: [self stringForParameterValues:imageProperties],
		WIKMediaWikiTitlesParameterKey: [self stringForParameterValues:imageNames],
		@"iiurlwidth": @(64),
		@"iilimit": @(1) };
	
	BOOL shouldContinue = imageNames.count > 1; // media wiki api workaround: don't continue for a single image
	
	WIKQueryEnumerator* enumerator = [[WIKQueryEnumerator alloc]
		initWithParameters:parameters
		client:self
		shouldContinue:shouldContinue];
	
	return enumerator;
}

#pragma mark - Private

- (NSError*)detectErrorInJSONResult:(id)JSON operation:(AFJSONRequestOperation*)operation {
	NSDictionary* errorDictionary = [JSON valueForKeyPath:@"error"];
	if(!errorDictionary || ![errorDictionary isKindOfClass:[NSDictionary class]]) { return nil; }
	
	WIKErrorCode errorCode = WIKErrorUnknown;
	NSString* codeString = errorDictionary[@"code"];
	
	// search module error codes
	if([codeString isEqualToString:@"srreadapidenied"]) { errorCode = WIKErrorReadAccessDenied; }
	else if([codeString isEqualToString:@"srinvalidtitle"]) { errorCode = WIKErrorInvalidTitle; }
	else if([codeString isEqualToString:@"srnosearch"]) { errorCode = WIKErrorMissingSearchParameter; }
	else if([codeString isEqualToString:@"srsearch-text-disabled"]) { errorCode = WIKErrorTextSearchDisabled; }
	else if([codeString isEqualToString:@"srsearch-title-disabled"]) { errorCode = WIKErrorTitleSearchDisabled; }
	
	// user info
	NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
	
	NSString* infoString = errorDictionary[@"info"];
	if(infoString) { userInfo[NSLocalizedDescriptionKey] = infoString; }
	
	NSURL* URL = operation.request.URL;
	if(URL) { userInfo[NSURLErrorKey] = URL; }
	
	// the actual error object
	NSError* error = [NSError errorWithDomain:WIKErrorDomain code:errorCode userInfo:userInfo];
	return error;
}

- (NSString*)stringForParameterValues:(NSArray*)parameters {
	NSMutableArray* newParameters = [NSMutableArray arrayWithCapacity:[parameters count]];
	
	for(NSString* string in parameters) {
		NSString* escapedString = [string stringByReplacingOccurrencesOfString:@"|" withString:@"||"];
		[newParameters addObject:escapedString];
	}
	
	NSString* string = [newParameters componentsJoinedByString:@"|"];
	return string;
}

@end
