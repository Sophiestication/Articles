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

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#import "RESTfulKit.h"

extern NSString* const WPMatchingArticlesKey;
extern NSString* const WPArticleTitleKey;
extern NSString* const WPArticleSummaryKey;
extern NSString* const WPSearchResultOffsetKey;
extern NSString* const WPSpellingSuggestionKey;
extern NSString* const WPPageLimitOption;
extern NSString* const WPContinuePagingOffsetOption;
extern NSString* const WPNumberOfArticlesKey;

typedef NS_ENUM(NSUInteger, WPSearchScope) {
	WPSearchScopeContent,
	WPSearchScopeTitle
};

@interface WikipediaAPI : NSObject

@property(nonatomic, copy) NSString* preferredLanguage;
@property(nonatomic, weak) id<RKTransactionDelegate> transactionDelegate;

@property(weak, nonatomic, readonly) NSString* baseURLString;

- (RKTransaction*)autocompleteArticleTitle:(NSString*)searchString options:(NSDictionary*)options;
- (RKTransaction*)findArticlesByString:(NSString*)searchString scope:(WPSearchScope)scope options:(NSDictionary*)options;

- (RKTransaction*)articleForTitle:(NSString*)articleTitle options:(NSDictionary*)options;
- (RKTransaction*)articleForURL:(NSURL*)articleURL options:(NSDictionary*)options;

- (NSURL*)featuredArticleURLForDate:(NSDate*)date options:(NSDictionary*)options;

- (NSURL*)filePathForResourceURL:(NSURL*)resourceURL options:(NSDictionary*)options;

- (NSURL*)thumbnailURLWithWidth:(CGFloat)imageWidth forURL:(NSURL*)URL;
// - (NSURL*)thumbnailURLForThumbnail:(NSURL*)thumbnailURL ofSize:(NSInteger)thumbnailSize;

- (NSURL*)articleURLForTitle:(NSString*)articleTitle;
- (NSURL*)randomArticleURL;

- (NSURL*)eventURLForDate:(NSDate*)date;

@end
