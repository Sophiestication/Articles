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

#import "AKArchiveController.h"

#import "AKArchive.h"
#import "AKArchive+Private.h"

#import "NSArray+Additions.h"
#import "NSURL+Wikipedia.h"

@implementation AKArchiveController

@synthesize loadingArchives = _loadingArchives;
@synthesize livingArchives = _livingArchives;
@synthesize operationQueue = _operationQueue;
@synthesize maintanceOperation = _maintanceOperation;

#pragma mark -
#pragma mark Construction & Destruction
 
+ (AKArchiveController*)sharedController {
	static dispatch_once_t once;
    static AKArchiveController* sharedArchiveController;
	
    dispatch_once(&once, ^{
		sharedArchiveController = [[self alloc] init];
	});

    return sharedArchiveController;
}

- (id)init {
	if((self = [super init])) {
		self.loadingArchives = [NSMutableDictionary dictionary];
		self.livingArchives = [NSMutableSet set];
		self.operationQueue = [[NSOperationQueue alloc] init];
	}
	
	return self;
}

- (void)dealloc {
	[[self operationQueue] cancelAllOperations];
}

#pragma mark -
#pragma mark AKArchiveController

- (AKArchive*)archiveForArticleURL:(NSURL*)articleURL {
	AKArchive* archive;

	@synchronized(self.loadingArchives) {
		archive = [[self loadingArchives] objectForKey:articleURL];
	}

	return archive;
}

- (void)addArchive:(AKArchive*)archive {
	if(!archive) { return; }

	NSMutableDictionary* loadingArchives = self.loadingArchives;

	@synchronized(loadingArchives) {
		[loadingArchives
			setObject:archive
			forKey:[archive articleURL]];
	}

	archive.operationQueue = self.operationQueue;
}

- (void)removeArchive:(AKArchive*)archive {
	NSMutableDictionary* loadingArchives = self.loadingArchives;

	@synchronized(loadingArchives) {
		[loadingArchives removeObjectForKey:[archive articleURL]];
	}

	archive.operationQueue = nil;
}

- (void)installOrUpdateSupportFiles:(NSFileManager*)fileManager {
	// Make the support folder first
	NSString* supportFolderPath = [[self supportFolderURL] path];
	BOOL shouldRemoveCacheFolder = NO;
	
	if([fileManager fileExistsAtPath:supportFolderPath]) {
		[fileManager removeItemAtPath:supportFolderPath error:nil];
		shouldRemoveCacheFolder = YES;
	}
	
	if(shouldRemoveCacheFolder) {
		NSString* cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)
			firstObject]
			stringByAppendingPathComponent:@"ArticleKit/"];
		[fileManager removeItemAtPath:cachePath error:nil];
	}
}

- (void)deleteOutdatedCacheFilesIfNeeded:(NSFileManager*)fileManager bookmarkedArticleURLStrings:(NSArray*)bookmarkedArticleURLStrings {
	NSString* cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)
		firstObject]
		stringByAppendingPathComponent:@"ArticleKit/"];
		
	NSMutableSet* bookmarkedCacheFolders = [NSMutableSet setWithCapacity:[bookmarkedArticleURLStrings count]];
	
	for(NSString* articleURLString in bookmarkedArticleURLStrings) {
    	if(!articleURLString) { continue; }

		NSURL* articleURL = [NSURL URLWithString:articleURLString];
        
        if(!articleURL) {
        	NSLog(@"Could not create URL from string: %@", articleURLString);
            continue;
        }

		NSString* cacheFolder = [articleURL wikipediaID];
		if(cacheFolder.length > 0) { [bookmarkedCacheFolders addObject:cacheFolder]; }
	}
	
	NSDirectoryEnumerator* enumerator = [fileManager enumeratorAtPath:cachePath];
	NSString* subitem = nil;
	
	while((subitem = [enumerator nextObject])) {
		if([enumerator level] > 1) { continue; }

		NSString* subitemPath = [cachePath stringByAppendingPathComponent:subitem];

		if([bookmarkedCacheFolders containsObject:subitem]) {
			continue;
		}
		
		NSDictionary* fileAttributes = [enumerator directoryAttributes];
		
		if([fileAttributes objectForKey:NSFileType] == NSFileTypeDirectory) {
			NSTimeInterval modificationDate = [[fileAttributes objectForKey:NSFileModificationDate] timeIntervalSinceNow];
			
			static NSTimeInterval const cacheExpirationTimeInterval = 3.0 * 24.0 * 60.0 * 60.0; // 3 days
			
			if(-modificationDate >= cacheExpirationTimeInterval) {
				NSURL* archiveURL = [NSURL fileURLWithPath:subitemPath];
				[self performSelectorOnMainThread:@selector(deleteArchiveAtURL:) withObject:archiveURL waitUntilDone:YES];
			}
		}
	}
}

- (void)deleteAllCacheFilesIfNeeded:(NSFileManager*)fileManager {
	NSString* cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)
		firstObject]
		stringByAppendingPathComponent:@"ArticleKit/"];
	
	unsigned long long fileSize = [self fileSizeOfItemAtPath:cachePath error:nil fileManager:fileManager];
	static unsigned long long const maximumCacheSize = 64 * 1024 * 1024; // 64MB
	
	// NSLog(@"Cache size: %f MB", fileSize / 1024.0 / 1024.0); // Crashes on device
	
	if(fileSize >= maximumCacheSize) {
		for(NSString* subitem in [fileManager enumeratorAtPath:cachePath]) {
			NSString* subitemPath = [cachePath stringByAppendingPathComponent:subitem];
			
			NSError* error = nil;
			NSDictionary* fileAttributes = [fileManager attributesOfItemAtPath:subitemPath error:&error];
			
			if(error) {
				NSLog(@"%@", error);
				return;
			}
			
			if([fileAttributes objectForKey:NSFileType] == NSFileTypeDirectory) {
				NSURL* archiveURL = [NSURL fileURLWithPath:subitemPath];
				[self performSelectorOnMainThread:@selector(deleteArchiveAtURL:) withObject:archiveURL waitUntilDone:NO];
			}
		}
	}
}

- (void)deleteArchiveAtURL:(NSURL*)archiveURL {
	if(![self isArchiveAtURLLoading:archiveURL] && ![self isArchiveAtURLLiving:archiveURL]) {
		NSLog(@"Delete outdated archive: %@", archiveURL);
		
		NSError* error = nil;
		
		if(![[NSFileManager defaultManager] removeItemAtPath:[archiveURL path] error:&error]) {
			NSLog(@"Could not remove item at path %@: %@", archiveURL, [error localizedDescription]);
		}
	}
}

- (NSURL*)supportFolderURL {
	NSString* supportFolderPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)
		firstObject]
		stringByAppendingPathComponent:@"ArticleKit/"];
	return [NSURL fileURLWithPath:supportFolderPath isDirectory:YES];
}

- (NSURL*)supportURLForFileNamed:(NSString*)supportFile {
	return [NSURL URLWithString:supportFile relativeToURL:[self supportFolderURL]];
}

- (NSURL*)bundleURLForFileNamed:(NSString*)supportFile {
	NSBundle* bundle = [NSBundle bundleForClass:[self class]];
	NSString* bundleFilePath = [bundle pathForResource:supportFile ofType:nil];
	return [NSURL fileURLWithPath:bundleFilePath];
}

- (unsigned long long)fileSizeOfItemAtPath:(NSString*)itemPath error:(NSError**)error fileManager:(NSFileManager*)fileManager {
	NSDictionary* itemInfo = [fileManager
		attributesOfItemAtPath:itemPath
		error:error];
	
	unsigned long long fileSize = [[itemInfo objectForKey:NSFileSize] unsignedLongLongValue];
	
	if([itemInfo objectForKey:NSFileType] == NSFileTypeDirectory) {
		for(NSString* subitem in [fileManager enumeratorAtPath:itemPath]) {
			NSString* subitemPath = [itemPath stringByAppendingPathComponent:subitem];
			fileSize += [self fileSizeOfItemAtPath:subitemPath error:error fileManager:fileManager];
		}
	}
	
	return fileSize;
}

- (void)beginMaintanceIfNeeded:(NSManagedObjectContext*)managedObjectContext {
	if(self.maintanceOperation) {
		return;
	}
	
	NSArray* articleURLs = [self articleBookmarkURLsInContext:managedObjectContext];
	NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
		articleURLs, @"bookmarkURLs",
		nil];
	
	NSOperation* maintanceOperation = [[NSInvocationOperation alloc]
		initWithTarget:self
		selector:@selector(maintance:)
		object:options];
	
	self.maintanceOperation = maintanceOperation;
	[[self operationQueue] addOperation:maintanceOperation];
}

- (void)maintance:(NSDictionary*)options {
//	NSLog(@"begin maintance");

	[[NSThread currentThread] setName:@"com.sophiestication.maintance-operation"];

	NS_DURING
		NSFileManager* fileManager = [[NSFileManager alloc] init];
		
		[self installOrUpdateSupportFiles:fileManager];
		
		NSArray* bookmarkURLs = [options objectForKey:@"bookmarkURLs"];
		[self deleteOutdatedCacheFilesIfNeeded:fileManager bookmarkedArticleURLStrings:bookmarkURLs];
//		[self deleteAllCacheFilesIfNeeded:fileManager];
		
	NS_HANDLER
		NSLog(@"Error in maintance operation: %@", localException);
	NS_ENDHANDLER

	[self performSelectorOnMainThread:@selector(maintanceOperationDidFinish)
		withObject:nil
		waitUntilDone:YES];
		
//	NSLog(@"finished maintance");
}

- (void)maintanceOperationDidFinish {
	// Cleanup
	self.maintanceOperation = nil;
}

- (BOOL)isArchiveAtURLLoading:(NSURL*)archiveURL {
	for(id archive in self.loadingArchives) {
		NSURL* otherArchiveURL = [archive isKindOfClass:[AKArchive class]] ?
			[archive archiveURL] :
			archive;
		
		if([archiveURL isEqual:otherArchiveURL]) {
			return YES;
		}
	}
	
	return NO;
}

- (BOOL)isArchiveAtURLLiving:(NSURL*)archiveURL {
	NSSet* livingArchives = self.livingArchives;

	@synchronized(livingArchives) {
		for(NSValue* archiveValue in livingArchives) {
			AKArchive* archive = (AKArchive*)[archiveValue nonretainedObjectValue];

			if([archiveURL isEqual:[archive archiveURL]]) {
				return YES;
			}
		}
	}
	
	return NO;
}

- (NSArray*)articleBookmarkURLsInContext:(NSManagedObjectContext*)managedObjectContext {
#if defined (CONFIGURATION_ARTICLEKIT)
	return [NSArray array];
#endif
    
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
	
	NSEntityDescription* entity = [NSEntityDescription
		entityForName:@"Article"
		inManagedObjectContext:managedObjectContext];
	[fetchRequest setEntity:entity];

	NSPredicate* predicate = [NSPredicate predicateWithFormat:@"unread == true || count(bookmarks) > 0"];
	[fetchRequest setPredicate:predicate];
	
	NSDictionary* propertyDescriptions =  [entity propertiesByName];
	
	NSArray* propertiesToFetch = [NSArray arrayWithObjects:
		[propertyDescriptions objectForKey:@"articleURL"],
		nil];
	[fetchRequest setPropertiesToFetch:propertiesToFetch];
	
	[fetchRequest setResultType:NSDictionaryResultType];
	
	[fetchRequest setReturnsDistinctResults:YES];
	
	NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
	
	NSArray* articleBookmarkURLS = [results valueForKey:@"articleURL"];
	
    if(!articleBookmarkURLS) {
    	return [NSArray array];
    }
    
	return articleBookmarkURLS;
}

@end
