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

#import "AFNetworking.h"
#import "ArticleKitDefines.h"

@class WIKQueryEnumerator;

NSString* const WIKMediaWikiQueryAction;

NSString* const WIKMediaWikiInfoProperty;
NSString* const WIKMediaWikiPageInfoProperty;
NSString* const WIKMediaWikiPageImageProperty;
NSString* const WIKMediaWikiExtractsProperty;
NSString* const WIKMediaWikiImageInfoProperty;
NSString* const WIKMediaWikiImagesProperty;
NSString* const WIKMediaWikiCoordinatesProperty;

NSString* const WIKMediaWikiJSONFormatParameterValue;
NSString* const WIKMediaWikiXMLFormatParameterValue;

@interface WIKMediaWikiClient : AFHTTPClient

- (NSURLRequest*)APIRequestWithParameters:(NSDictionary*)parameters;

- (AFHTTPRequestOperation*)performAction:(NSString*)action
	parameters:(NSDictionary*)parameters
	success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success
	failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure;

- (WIKQueryEnumerator*)properties:(NSArray*)properties forPageTitles:(NSArray*)titles;
- (WIKQueryEnumerator*)imagesNamed:(NSArray*)imageNames;

@end

ARTICLEKIT_EXTERN NSString* const WIKErrorDomain;

typedef NS_ENUM(NSUInteger, WIKErrorCode) {
	WIKErrorUnknown = 0,
	
	// Search Module
	WIKErrorReadAccessDenied,
	WIKErrorInvalidTitle,
	WIKErrorMissingSearchParameter,
	WIKErrorTextSearchDisabled,
	WIKErrorTitleSearchDisabled
};
