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

@class AKArchive;

@interface AKArchiveController : NSObject 

@property(atomic, strong) NSMutableDictionary* loadingArchives;
@property(atomic, strong) NSMutableSet* livingArchives;
@property(atomic, strong) NSOperationQueue* operationQueue;
@property(atomic, strong) NSOperation* maintanceOperation;

+ (AKArchiveController*)sharedController;

- (AKArchive*)archiveForArticleURL:(NSURL*)articleURL;

- (void)addArchive:(AKArchive*)archive;
- (void)removeArchive:(AKArchive*)archive;

- (void)installOrUpdateSupportFiles:(NSFileManager*)fileManager;

- (void)deleteOutdatedCacheFilesIfNeeded:(NSFileManager*)fileManager bookmarkedArticleURLStrings:(NSArray*)bookmarkedArticleURLStrings;
- (void)deleteArchiveAtURL:(NSURL*)archiveURL;

- (NSURL*)supportFolderURL;

- (NSURL*)supportURLForFileNamed:(NSString*)supportFile;
- (NSURL*)bundleURLForFileNamed:(NSString*)supportFile;

- (unsigned long long)fileSizeOfItemAtPath:(NSString*)itemPath error:(NSError**)error fileManager:(NSFileManager*)fileManager;

- (void)beginMaintanceIfNeeded:(NSManagedObjectContext*)managedObjectContext;
- (void)maintance:(NSDictionary*)options;

- (BOOL)isArchiveAtURLLoading:(NSURL*)archiveURL;
- (BOOL)isArchiveAtURLLiving:(NSURL*)archiveURL;

- (NSArray*)articleBookmarkURLsInContext:(NSManagedObjectContext*)managedObjectContext;

@end
