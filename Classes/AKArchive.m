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
#import "AKArchive+Private.h"

#import "AKArchiveController.h"

#import "AKArchiveOperation.h"
#import "AKDownloadOperation.h"

#import "AKArticleView+Private.h"

#import "NSArray+Additions.h"
#import "NSString+Additions.h"
#import "NSURL+Wikipedia.h"

@implementation AKArchive

NSString* const AKArchiveWillStartLoadingNotification = @"AKArchiveWillStartLoadingNotification";
NSString* const AKArchiveDidFinishLoadingNotification = @"AKArchiveDidFinishLoadingNotification";

@synthesize delegate = _delegate;
@synthesize archiveURL = _archiveURL;
@synthesize articleURL = _articleURL;
@synthesize temporaryURL = _temporaryURL;
@synthesize images = _images;
@synthesize tables = _tables;
@synthesize languages = _languages;
@synthesize chapters = _chapters;
@dynamic documentURL;
@synthesize loading = _loading;
@synthesize loadingImages = _loadingImages;
@synthesize cancelled = _cancelled;
@synthesize progress = _progress;
@synthesize archiveOperation = _archiveOperation;
@synthesize operationQueue = _operationQueue;
@synthesize downloadOperations = _downloadOperations;
@synthesize documentLoadProgress = _documentLoadProgress;
@synthesize documentParseProgress = _documentParseProgress;
@synthesize imageLoadProgress = _imageLoadProgress;

#pragma mark -
#pragma mark Construction & Destruction

+ (AKArchive*)archiveForArticle:(NSURL*)articleURL archiveType:(AKArchiveType)archiveType {
	if(!articleURL) { return nil; }
	
	articleURL = [articleURL wikipediaURLByFixingScheme];
	
	// Make a new archive if needed
	AKArchive* archive = [[AKArchiveController sharedController]
		archiveForArticleURL:articleURL];
		
	if(!archive) {
		NSURL* archiveURL = [self archiveURLForArticle:articleURL archiveType:archiveType];
		
		archive = [[AKArchive alloc] initWithContentsOfURL:archiveURL];
		archive.articleURL = articleURL;
	}
	
	return archive;
}

- (id)initWithContentsOfURL:(NSURL*)archiveURL {
	if((self = [super init])) {
		self.loading = NO;
		self.loadingImages = NO;
		self.cancelled = NO;
		
		self.progress = 0.0;
		self.documentLoadProgress = 0.0;
		self.documentParseProgress = 0.0;
		self.imageLoadProgress = 0.0;

		self.archiveURL = archiveURL;
		
		NSDictionary* infoPlist = [NSDictionary dictionaryWithContentsOfURL:
			[NSURL URLWithString:@"Info.plist" relativeToURL:archiveURL]];
		
		NSString* articleURLString = [infoPlist objectForKey:@"articleURL"];
		self.articleURL = articleURLString ?
			[NSURL URLWithString:articleURLString] :
			nil;
		
		self.images = [infoPlist objectForKey:@"images"];
		self.tables = [infoPlist objectForKey:@"tables"];
		self.languages = [infoPlist objectForKey:@"languages"];
		self.chapters = [infoPlist objectForKey:@"chapters"];
		
		NSMutableSet* livingArchives = [[AKArchiveController sharedController] livingArchives];

		@synchronized(livingArchives) {
			[livingArchives addObject:[NSValue valueWithNonretainedObject:self]];
		}
	}
	
	return self;
}

- (void)dealloc {
	[self cancelAllDownloadOperations];
    
    NSMutableSet* livingArchives = [[AKArchiveController sharedController] livingArchives];

	@synchronized(livingArchives) {
		[livingArchives removeObject:[NSValue valueWithNonretainedObject:self]];
	}
}

#pragma mark -
#pragma mark AKArticleArchive

- (NSURL*)documentURL {
	NSURL* documentURL = [NSURL URLWithString:@"index.html" relativeToURL:[self archiveURL]];
	return documentURL;
}

- (void)loadArchive {
	if(self.loading) { return; }
    if(self.loadingImages) { return; }

	self.cancelled = NO;

	self.documentLoadProgress = 0.0;
	self.documentParseProgress = 0.0;
	self.imageLoadProgress = 0.0;
	self.progress = 0.0;
	
	// Send out the will start notification
	[self postArchiveWillStartLoadingNotification];
	[AKArticleView postNetworkActivityWillStartNotification];
	
	// Add this archive to the loading archives container
	[[AKArchiveController sharedController] addArchive:self];
	
	// Download and parse the wiki html file
	AKArchiveOperation* operation = [[AKArchiveOperation alloc] init];
	
	operation.delegate = self;
	operation.articleURL = self.articleURL;
	operation.archiveURL = self.archiveURL;

	NSOperation* maintanceOperation = [[AKArchiveController sharedController] maintanceOperation];
	
	if(maintanceOperation) {
		[operation addDependency:maintanceOperation];
	}
	
	[[self operationQueue] addOperation:operation];
	self.archiveOperation = operation;
	
	// Update the loading states
	self.loading = YES;
	self.loadingImages = NO;
	
	// Update our total progress
	[self updateProgress];
}

- (void)loadArchiveIfNeeded {
	NSURL* documentURL = [self documentURL];
	NSError* error;

    if([documentURL checkResourceIsReachableAndReturnError:&error]) {
    	[self loadImagesIfNeeded];
    } else {
    	[self loadArchive];
    }
}

- (void)reloadArchive {
	NSURL* archiveURL = self.archiveURL;
	NSError* error;

	if([archiveURL checkResourceIsReachableAndReturnError:&error]) {
		NSFileManager* fileManager = [[NSFileManager alloc] init];

		if(![fileManager removeItemAtURL:archiveURL error:&error]) {
			NSLog(@"Could not remove archive: %@", error);
		}
	}
	
	// Remove the URL fragment when reloading
	NSURL* articleURL = self.articleURL;
	
	if([[articleURL fragment] length] > 0) {
		NSString* baseURLString = [[[articleURL scheme]
			stringByAppendingString:@"://"]
			stringByAppendingString:[articleURL host]];
		NSURL* baseURL = [NSURL URLWithString:baseURLString];

		NSURL* newArticleURL = [baseURL URLByAppendingPathComponent:[articleURL path]];

		self.articleURL = newArticleURL;
	}
	
	// Now load the archive
	[self loadArchiveIfNeeded];
}

- (void)deleteArchive {
	NSError* error = nil;
	BOOL result = [[NSFileManager defaultManager]
		removeItemAtPath:[[self archiveURL] path]
		error:&error];
        
    if(!result) {
    	NSLog(@"Could not remove item at path %@: %@", [self articleURL], [error localizedDescription]);
    }
}

- (void)stopLoading {
	self.cancelled = YES;

	if(self.archiveOperation) {
		[[self archiveOperation] cancel];
	}

	for(AKDownloadOperation* downloadOperation in self.downloadOperations) {
		[downloadOperation cancel];
	}
    
    self.loading = self.loadingImages = NO;
}

- (NSDictionary*)imageInfoForID:(NSString*)imageID {
	for(NSDictionary* imageInfo in self.images) {
		if([[imageInfo objectForKey:@"id"] isEqualToString:imageID]) {
			return imageInfo;
		}
	}
	
	return nil;
}

- (NSDictionary*)tableInfoForID:(NSString*)tableID {
	for(NSDictionary* tableInfo in self.tables) {
		if([[tableInfo objectForKey:@"id"] isEqualToString:tableID]) {
			return tableInfo;
		}
	}
	
	return nil;
}

- (NSData*)imageDataForID:(NSString*)imageID {
	NSURL* previewURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@Large", imageID]
		relativeToURL:[self archiveURL]];
	
	if(![[NSFileManager defaultManager] fileExistsAtPath:[previewURL path]]) {
		previewURL = [NSURL URLWithString:imageID
			relativeToURL:[self archiveURL]];
	}
		
	if(![[NSFileManager defaultManager] fileExistsAtPath:[previewURL path]]) {
		return nil;
	}
	
	NSData* imageData = [NSData dataWithContentsOfMappedFile:[previewURL path]];
	
	return imageData;
}

#pragma mark -
#pragma mark Private

+ (NSURL*)archiveURLForArticle:(NSURL*)articleURL archiveType:(AKArchiveType)archiveType {
	if(!articleURL) { return nil; }

	NSFileManager* fileManager = [[NSFileManager alloc] init];

	articleURL = [articleURL wikipediaURLByFixingScheme];

	NSURL* applicationCacheURL = [fileManager
		URLForDirectory:NSCachesDirectory
		inDomain:NSUserDomainMask
		appropriateForURL:nil
		create:YES
		error:nil];
	applicationCacheURL = [applicationCacheURL
		URLByAppendingPathComponent:@"ArticleKit"
		isDirectory:YES];

	NSString* archiveName = [self archiveNameForURL:articleURL];
	NSURL* archiveURL = [applicationCacheURL URLByAppendingPathComponent:archiveName isDirectory:YES];

	return archiveURL;
}

+ (NSString*)archiveNameForURL:(NSURL*)URL {
	NSString* wikipediaIdentifier = [URL wikipediaID];

	NSUInteger const maximumFileNameLength = 255; // HFS+ limitations
	NSUInteger identifierLength = wikipediaIdentifier.length;

	if(identifierLength > maximumFileNameLength) {
		NSMutableArray* archiveNameComponents = [NSMutableArray arrayWithCapacity:2];
		NSRange range = NSMakeRange(0, 0);

		do {
			NSUInteger rangeLength = identifierLength - range.location;
			rangeLength = MIN(rangeLength, maximumFileNameLength);

			range.length = rangeLength;

			NSString* substring = [wikipediaIdentifier substringWithRange:range];
			[archiveNameComponents addObject:substring];

			range.location = NSMaxRange(range);
		} while(range.location < identifierLength);

		NSString* archiveName = [NSString pathWithComponents:archiveNameComponents];
		return archiveName;
	}

	return wikipediaIdentifier;
}

- (void)archiveOperation:(AKArchiveOperation*)archiveOperation didFinishWithInfoPlist:(NSDictionary*)infoPlist {
	// Update the article URL in case we got a redirect
	self.archiveURL = archiveOperation.archiveURL;
	
	if(![[self articleURL] isEqual:[archiveOperation articleURL]]) {
		// Remove the archive entry with the old article URL
		[[AKArchiveController sharedController] removeArchive:self];
		
		// Update the archive URL and entry in our archive controller
		self.articleURL = archiveOperation.articleURL;
		[[AKArchiveController sharedController] addArchive:self];
	}
	
	// Update the table infos
	self.tables = [infoPlist objectForKey:@"tables"];

	// Keep the image descriptions for later
	self.images = [infoPlist objectForKey:@"images"];
	
	// Also keep the Wikipedia language links
	self.languages = [infoPlist objectForKey:@"languages"];
	
	// And the Chapters (Table of Contents)
	self.chapters = [infoPlist objectForKey:@"chapters"];

	// Start downloading all missing images
	[self loadImagesIfNeeded];
	
	// Update the loading states
	self.loading = NO;
	self.loadingImages = self.downloadOperations.count > 0;
	
	// Now update the info.plist
	[self saveInfoPlist];
	
	// Dump our table markup if needed
	if(NO) {
		for(NSDictionary* table in self.tables) {
			[self dumpTable:table];
		}
	}
	
	// First update the progress
	[self updateProgress];
	
	// Notify our delegate
	if([[self delegate] respondsToSelector:@selector(archive:didLoadArticle:)]) {
		[[self delegate] archive:self didLoadArticle:[self documentURL]];
	}
	
	// Are we still downloading images?
	if(!self.loadingImages) {
		// Remove this from the loading archives container
		[[AKArchiveController sharedController] removeArchive:self];
		
		// Cleanup temp files
		[self cleanupTemporaryFilesIfNeeded];
		
		// Post the did finish loading notification
		[self postArchiveDidFinishLoadingNotification];
		[AKArticleView postNetworkActivityDidEndNotification];
        
        // Tell our delegate
        if([[self delegate] respondsToSelector:@selector(archiveDidFinishLoading:)]) {
			[[self delegate] archiveDidFinishLoading:self];
		}
	}
	
	// ...
	self.archiveOperation = nil;
}

- (void)archiveOperation:(AKArchiveOperation*)archiveOperation didFailLoadWithError:(NSError*)error {
	// Update the loading states
	self.loading = NO;
	self.loadingImages = NO;
	
	// Notify our delegate
	if([[self delegate] respondsToSelector:@selector(archive:didFailLoadWithError:)]) {
		[[self delegate] archive:self didFailLoadWithError:error];
	}
	
	// Remove this from the loading archives container
	[[AKArchiveController sharedController] removeArchive:self];
		
	// Cleanup temp files
	[self cleanupTemporaryFilesIfNeeded];
	
	// Update the progress anyways
	[self updateProgress];
		
	// Post the did finish loading notification
	[self postArchiveDidFinishLoadingNotification];
	[AKArticleView postNetworkActivityDidEndNotification];
	
	// ...
	self.archiveOperation = nil;
}

- (void)downloadOperationDidFinish:(AKDownloadOperation*)downloadOperation {
	// Remove this download from our queue
	self.downloadOperations = [[self downloadOperations] arrayByRemovingObject:downloadOperation];
	
	// Update our progress first
	[self updateImageLoadProgress];
	
	// Update the loading state if needed
	self.loadingImages = self.downloadOperations.count > 0;
	
	// Notify our delegate that we downloaded a image
	if([[self delegate] respondsToSelector:@selector(archive:didLoadImage:)]) {
		NSMutableDictionary* image = [NSMutableDictionary dictionaryWithDictionary:
			[downloadOperation userInfo]];
		
		if(downloadOperation.error) {
			[image setObject:(id)kCFBooleanTrue forKey:@"hadError"];
		} else {
			// Store the images file size
			/*NSDictionary* attributes = [[NSFileManager defaultManager]
				attributesOfItemAtPath:[[downloadOperation localURL] path]
				error:nil];
			
			NSNumber* fileSize = [attributes objectForKey:NSFileSize];
			[image setValue:fileSize forKey:@"size"];
			
			// Update the total file size
			[self updateTotalCacheSize:fileSize];*/
		}
		
		[[self delegate] archive:self didLoadImage:image];
	}
	
	// Check if we're done with downloading thumbnails
	if(self.downloadOperations.count == 0) {
		// Remove this from the loading archives container
		[[AKArchiveController sharedController] removeArchive:self];
		
		// Cleanup temp files
		[self cleanupTemporaryFilesIfNeeded];
		
		// Post the did finish loading notification
		[self postArchiveDidFinishLoadingNotification];
		[AKArticleView postNetworkActivityDidEndNotification];
        
        // Tell our delegate
        id delegate = self.delegate;

        if([delegate respondsToSelector:@selector(archiveDidFinishLoading:)]) {
			[delegate archiveDidFinishLoading:self];
		}
	}
}

- (void)downloadOperation:(AKDownloadOperation*)downloadOperation didFailWithError:(NSError*)error {
	BOOL userCancelled =
		error &&
		error.domain == NSURLErrorDomain &&
		error.code == NSURLErrorCancelled;
	
	if(!userCancelled) {
		NSLog(@"%@", error);
	}

	[self downloadOperationDidFinish:downloadOperation];
}

- (void)downloadOperation:(AKDownloadOperation*)downloadOperation didProgress:(NSNumber*)progress {
	[self updateImageLoadProgress];
}

- (void)loadImagesIfNeeded {
	if(self.cancelled) { return; }
    
    NSMutableArray* downloadOperations = [NSMutableArray array];
    
    for(NSDictionary* image in self.images) {
		// Do we have a remote URL for this image
		NSURL* imageURL = [self URLForImage:image];
		
		if(!imageURL) {
			NSLog(@"Missing URL for image %@", image);
			continue;
		}
		
		// Does the file exists already?
		NSURL* localImageURL = [NSURL URLWithString:
			[image objectForKey:@"id"]
			relativeToURL:[self archiveURL]];

		NSError* error;

		if(![localImageURL checkResourceIsReachableAndReturnError:&error]) {
			// Make a new download operation
			AKDownloadOperation* downloadOperation = [[AKDownloadOperation alloc] init];
		
			downloadOperation.localURL = localImageURL;
			downloadOperation.remoteURL = imageURL;
			
			downloadOperation.userInfo = image;
			
			downloadOperation.delegate = self;

			[downloadOperations addObject:downloadOperation];
            
        	[downloadOperation start];
    
		} else {
			// We already have this image cached
			if([[self delegate] respondsToSelector:@selector(archive:didLoadImage:)]) {
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.0), dispatch_get_main_queue(), ^{
					[[self delegate] archive:self didLoadImage:image];
				});
			}
		}
	}
	
	self.downloadOperations = downloadOperations;
	self.loadingImages = downloadOperations.count > 0;
    
    // Did we load the markup but missed out on the images?
	if(!self.loading && self.loadingImages) {
		// Send out the will start notification
		[self postArchiveWillStartLoadingNotification];
		[AKArticleView postNetworkActivityWillStartNotification];
		
		// Add this archive to the loading archives container
		[[AKArchiveController sharedController] addArchive:self];
	}
	
	// Update our total progress
	[self updateProgress];
}

- (NSURL*)URLForImage:(NSDictionary*)image {
	NSString* imageURLString = [image objectForKey:@"thumbnail"];

	if(imageURLString.length > 0) {
		return [[NSURL URLWithString:imageURLString] wikipediaURLByFixingScheme];
	}

	return nil;
}

- (void)cancelAllDownloadOperations {
	for(AKDownloadOperation* downloadOperation in self.downloadOperations) {
    	[downloadOperation cancel];
    }
    
    self.downloadOperations = nil;
}

- (void)saveInfoPlist {
	NSMutableDictionary* infoPlist = [NSMutableDictionary dictionary];
	
	[infoPlist setObject:[[self articleURL] absoluteString] forKey:@"articleURL"];
	[infoPlist setObject:[self images] forKey:@"images"];
	[infoPlist setObject:[self tables] forKey:@"tables"];
	[infoPlist setObject:[self languages] forKey:@"languages"];
	[infoPlist setObject:[self chapters] forKey:@"chapters"];
	
	NSURL* infoPlistURL = [[self archiveURL]
		URLByAppendingPathComponent:@"Info.plist"];

	if(![infoPlist writeToURL:infoPlistURL atomically:YES]) {
		NSLog(@"Could not save archive info.plist for %@ (%@)", [self archiveURL], [self articleURL]);
	}
}

- (void)cleanupTemporaryFilesIfNeeded {
	if(self.temporaryURL) {
		[[NSFileManager defaultManager]
			removeItemAtPath:[[self archiveURL] path]
			error:nil];
			
		NSError* error = nil;
		BOOL succeeded = [[NSFileManager defaultManager] 
			moveItemAtPath:[[self temporaryURL] path]
			toPath:[[self archiveURL] path]
			error:&error];
		
		if(!succeeded) {
			NSLog(@"%@", error);
		}
		
		self.temporaryURL = nil;
	}
}

- (void)updateTotalCacheSize:(NSNumber*)fileSize {
	unsigned long long totalFileSize = [[[NSUserDefaults standardUserDefaults]
		objectForKey:@"AKTotalCacheSize"]
		unsignedLongLongValue];
		
	totalFileSize += [fileSize unsignedLongLongValue];
	
	[[NSUserDefaults standardUserDefaults]
		setObject:[NSNumber numberWithLongLong:totalFileSize]
		forKey:@"AKTotalCacheSize"];
}

- (void)updateProgress {
	float newProgress;

	if(self.loading || self.loadingImages) {
		newProgress =
			self.documentLoadProgress * 0.4 +
			self.documentParseProgress * 0.25 +
			self.imageLoadProgress * 0.35;
	} else {
		newProgress = 1.0;
	}

	newProgress = MAX(newProgress, 0.0);
	newProgress = MIN(newProgress, 1.0);
	
	if(newProgress != self.progress) {
		self.progress = newProgress;
		
		if([[self delegate] respondsToSelector:@selector(archive:didProgress:)]) {
			[[self delegate] archive:self didProgress:[self progress]];
		}
	}
}

- (void)updateDocumentLoadProgress:(NSNumber*)documentLoadProgress {
	self.documentLoadProgress = [documentLoadProgress floatValue];
	
	[self updateProgress];
}

- (void)updateDocumentParseProgress:(NSNumber*)documentParseProgress {
	self.documentLoadProgress = 1.0;
	self.documentParseProgress = [documentParseProgress floatValue];

	[self updateProgress];
}

- (void)updateImageLoadProgress {
	if(self.downloadOperations.count > 0) {
		float totalImageLoadProgress = 0.0;
		
		for(AKDownloadOperation* downloadOperation in self.downloadOperations) {
			totalImageLoadProgress += downloadOperation.progress;
		}
		
		NSUInteger numberOfImages = self.downloadOperations.count;
		
		if(self.images.count > self.downloadOperations.count) {
			totalImageLoadProgress += (float)self.images.count - numberOfImages;
			numberOfImages = self.images.count;
		}
		
		float newImageLoadProgress = totalImageLoadProgress / (float)numberOfImages;
		
		newImageLoadProgress = MAX(newImageLoadProgress, 0.0);
		newImageLoadProgress = MIN(newImageLoadProgress, 1.0);
		
		if(newImageLoadProgress > self.imageLoadProgress) {
			self.imageLoadProgress = newImageLoadProgress;
		}
	} else {
		self.imageLoadProgress = 1.0;
	}

	[self updateProgress];
}

- (void)postArchiveWillStartLoadingNotification {
//	NSLog(@"Will load %@", [self articleURL]);
	
	[[NSNotificationCenter defaultCenter]
		postNotificationName:AKArchiveWillStartLoadingNotification
		object:self
		userInfo:nil];
}

- (void)postArchiveDidFinishLoadingNotification {
//	NSLog(@"Did load %@", [self articleURL]);
	
	[[NSNotificationCenter defaultCenter]
		postNotificationName:AKArchiveDidFinishLoadingNotification
		object:self
		userInfo:nil];
}

- (void)dumpTable:(NSDictionary*)tableInfo {
	NSString* markup = [tableInfo objectForKey:@"markup"];
	NSString* HTMLString = [NSString stringWithFormat:
		@"<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"\n"
		@"\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n"
		@"<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">\n"
		@"<head>\n"
			@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"/>\n"
			@"<meta name=\"viewport\" content=\"user-scalable=no, width=device-width, initial-scale = 1.0\">\n"
			@"<link rel=\"stylesheet\" type=\"text/css\" href=\"x-articlekit-resource://articlekit.css\">\n"
			@"<link rel=\"stylesheet\" type=\"text/css\" href=\"x-articlekit-resource://table.css\">\n"
			@"<script type=\"text/javascript\" src=\"x-articlekit-resource://articlekit.js\"></script>\n"
		@"</head>\n"
		@"<body class=\"articlekit-tablesheet\">\n"
		@"%@\n"
		@"</body>\n"
		@"</html>",
	markup];
	
	NSString* file = [[tableInfo objectForKey:@"id"] stringByAppendingString:@".html"];
	NSString* path =  [[[self archiveURL] path] stringByAppendingPathComponent:file];
	
	NSError* error = nil;
	
	[HTMLString writeToFile:path
		atomically:YES
		encoding:NSUTF8StringEncoding
		error:&error];
	
	if(error) {
		NSLog(@"%@", error);
	}
}

@end
