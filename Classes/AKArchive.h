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
#import "AKArchiveDelegate.h"

extern NSString* const AKArchiveWillStartLoadingNotification;
extern NSString* const AKArchiveDidFinishLoadingNotification;

typedef enum {
	AKArchiveTypeAny = 0,
	AKArchiveTypePermanent = 1,
	AKArchiveTypeCache = 2
} AKArchiveType;

@interface AKArchive : NSObject {
@private
	NSURL* _archiveURL;
	NSURL* _articleURL;
	NSURL* _temporaryURL;
	
	NSArray* _images;
	NSArray* _tables;
	NSArray* _languages;
	NSArray* _chapters;
	
	BOOL _loading;
	BOOL _loadingImages;
	BOOL _cancelled;
	
	float _progress;
	float _documentLoadProgress;
	float _documentParseProgress;
	float _imageLoadProgress;

	NSOperation* _archiveOperation;
	NSArray* _downloadOperations;
	NSOperationQueue* _operationQueue;
}

@property(nonatomic, weak) id<AKArchiveDelegate> delegate;

@property(nonatomic, readonly, copy) NSURL* archiveURL;
@property(nonatomic, readonly, copy) NSURL* articleURL;

@property(weak, nonatomic, readonly) NSURL* documentURL;

@property(nonatomic, readonly, getter=isLoading) BOOL loading;
@property(nonatomic, readonly, getter=isLoadingImages) BOOL loadingImages;

@property(nonatomic, readonly, getter=isCancelled) BOOL cancelled;

@property(nonatomic) float progress;

+ (AKArchive*)archiveForArticle:(NSURL*)articleURL archiveType:(AKArchiveType)archiveType;

- (id)initWithContentsOfURL:(NSURL*)archiveURL;

- (void)loadArchive;
- (void)loadArchiveIfNeeded;

- (void)reloadArchive;
- (void)deleteArchive;

- (void)stopLoading;

- (NSDictionary*)imageInfoForID:(NSString*)imageID;
- (NSDictionary*)tableInfoForID:(NSString*)tableID;

- (NSData*)imageDataForID:(NSString*)imageID;

@end
