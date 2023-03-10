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

#import "AKArchive.h"

#import "AKArchiveOperation.h"
#import "AKDownloadOperation.h"

@interface AKArchive()<AKArchiveOperationDelegate, AKDownloadOperationDelegate>

@property(nonatomic, readwrite, copy) NSURL* archiveURL;
@property(nonatomic, readwrite, copy) NSURL* articleURL;
@property(nonatomic, readwrite, copy) NSURL* temporaryURL;

@property(nonatomic, readwrite, strong) NSArray* images;
@property(nonatomic, readwrite, strong) NSArray* tables;
@property(nonatomic, readwrite, strong) NSArray* languages;
@property(nonatomic, readwrite, strong) NSArray* chapters;

@property(nonatomic, strong) NSOperation* archiveOperation;
@property(nonatomic, strong) NSArray* downloadOperations;
@property(atomic, strong) NSOperationQueue* operationQueue;

@property(nonatomic, readwrite, getter=isLoading) BOOL loading;
@property(nonatomic, readwrite, getter=isLoadingImages) BOOL loadingImages;
@property(nonatomic, readwrite, getter=isCancelled) BOOL cancelled;

@property(nonatomic) float documentLoadProgress;
@property(nonatomic) float documentParseProgress;
@property(nonatomic) float imageLoadProgress;

+ (NSURL*)archiveURLForArticle:(NSURL*)articleURL archiveType:(AKArchiveType)archiveType;

- (void)loadImagesIfNeeded;
- (void)saveInfoPlist;
- (void)cleanupTemporaryFilesIfNeeded;
- (void)updateTotalCacheSize:(NSNumber*)fileSize;

- (void)updateProgress;
- (void)updateDocumentLoadProgress:(NSNumber*)documentLoadProgress;
- (void)updateDocumentParseProgress:(NSNumber*)documentParseProgress;
- (void)updateImageLoadProgress;

- (void)postArchiveWillStartLoadingNotification;
- (void)postArchiveDidFinishLoadingNotification;

- (void)dumpTable:(NSDictionary*)tableInfo;

@end
