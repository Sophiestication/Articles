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
#import <libxml/tree.h>

@protocol AKArchiveOperationDelegate;

@interface AKArchiveOperation : NSOperation<NSURLConnectionDelegate> {
@private
	NSURL* _articleURL;
	NSURL* _archiveURL;
	xmlParserCtxtPtr _parserContext;
	long long _expectedContentLength;
	unsigned long long _numberOfBytesTransferred;
	BOOL _waitingForInput;
	BOOL _didPostFinishNotification;
	id __weak _delegate;
	NSMutableArray* _images;
	NSMutableSet* _imageNodesNeedingRelease;
	NSMutableArray* _tables;
	NSMutableArray* _languages;
	NSMutableArray* _TOC;
}

@property(nonatomic, copy) NSURL* articleURL;
@property(nonatomic, copy) NSURL* archiveURL;

@property(nonatomic, weak) id<AKArchiveOperationDelegate> delegate;

@end

@protocol AKArchiveOperationDelegate<NSObject>

- (void)archiveOperation:(AKArchiveOperation*)archiveOperation didFinishWithInfoPlist:(NSDictionary*)infoPlist;
- (void)archiveOperation:(AKArchiveOperation*)archiveOperation didFailLoadWithError:(NSError*)error;

- (void)updateDocumentLoadProgress:(NSNumber*)progress;
- (void)updateDocumentParseProgress:(NSNumber*)progress;

@end
