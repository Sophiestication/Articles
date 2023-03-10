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

#import "AKArticleView+Debug.h"
#import "AKArticleView+Private.h"

@implementation AKArticleView(Debug)

- (void)dumpDocument {
	// Retrieve the persistent store path
	NSString* dumpFilesPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)
		objectAtIndex:0];
	// dumpFilesPath = [dumpFilesPath stringByAppendingPathComponent:@"debug"];
	
	// Create the application support folder if needed
	NSFileManager* fileManager = [[NSFileManager alloc] init];
	
	if(![fileManager fileExistsAtPath:dumpFilesPath]) {
		[fileManager createDirectoryAtPath:dumpFilesPath withIntermediateDirectories:YES attributes:nil error:nil];
	}
	
	// ...
	NSURL* articleURL = [self articleURL];

	NSString* string = [articleURL relativeString];
	string = [string stringByReplacingPercentEscapesUsingEncoding:NSUTF32StringEncoding];
	articleURL = string ? [NSURL URLWithString:string] : articleURL;

	NSString* dumpFile = [[articleURL path] lastPathComponent];
	dumpFile = [dumpFile stringByAppendingPathExtension:@"html"];
	dumpFile = [dumpFilesPath stringByAppendingPathComponent:dumpFile];
	
	[fileManager removeItemAtPath:dumpFile error:nil];
	
	// ...
	NSString* markup = [[self webView] stringByEvaluatingJavaScriptFromString:@"document.documentElement.outerHTML"];
	
	markup = [markup stringByReplacingOccurrencesOfString:@"x-articlekit-resource://" withString:@"../Web/"];
	
	NSLog(@"Dump article at %@", dumpFile);
	
	[markup writeToFile:dumpFile atomically:NO encoding:NSUTF8StringEncoding error:nil];
}

@end
