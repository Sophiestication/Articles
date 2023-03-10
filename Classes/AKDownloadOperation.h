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

@protocol AKDownloadOperationDelegate;

@interface AKDownloadOperation : NSObject<NSURLConnectionDelegate, NSURLConnectionDataDelegate> {
@private
	NSURL* _remoteURL;
	NSURL* _localURL;
	NSURL* _temporaryURL;
	id _userInfo;
	NSURLConnection* _connection;
	NSOutputStream* _outputStream;
	NSError* _error;
	long long _expectedContentLength;
	unsigned long long _numberOfBytesTransferred;
	float _progress;
}

@property(nonatomic, copy) NSURL* remoteURL;
@property(nonatomic, copy) NSURL* localURL;

@property(nonatomic, strong) id userInfo;

@property(nonatomic, weak) id<AKDownloadOperationDelegate> delegate;

@property(nonatomic, readonly, strong) NSError* error;
@property(nonatomic, readonly) float progress;

- (void)start;
- (void)cancel;

@end

@protocol AKDownloadOperationDelegate<NSObject>

- (void)downloadOperationDidFinish:(AKDownloadOperation*)downloadOperation;
- (void)downloadOperation:(AKDownloadOperation*)downloadOperation didFailWithError:(NSError*)error;

@end
