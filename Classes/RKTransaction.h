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

#import "RKTransactionDelegate.h"
#import "RKResultFormatter.h"
#import "RKCachePolicy.h"

#import "NSURL+REST.h"
#import "NSURLResponse+REST.h"

@interface RKTransaction : NSObject {
@private
	id<RKResultFormatter> _resultFormatter;
	id<RKCachePolicy> _cachePolicy;
	NSURLConnection* _connection;
	NSURLRequest* _request;
	NSURLResponse* _response;
	long long _expectedContentLength;
	unsigned long long _numberOfBytesTransferred;
	NSMutableData* _responseData;
	NSOutputStream* _responseStream;
	BOOL _succeeded;
	id _result;
	NSError* _error;
	id _userInfo;
}

+ (RKTransaction*)transactionWithURLRequest:(NSURLRequest*)request;
+ (RKTransaction*)transactionWithURL:(NSURL*)URL;

- (id)initWithURLRequest:(NSURLRequest*)request;

- (void)begin;
- (void)cancel;

@property(nonatomic, weak) id<RKTransactionDelegate> delegate;

@property(nonatomic, strong) id<RKResultFormatter> resultFormatter;
@property(nonatomic, strong) id<RKCachePolicy> cachePolicy;

@property(nonatomic, readonly, strong) NSURLRequest* request;
@property(nonatomic, readonly, strong) NSURLResponse* response;

@property(nonatomic, readonly) long long expectedContentLength;
@property(nonatomic, readonly) unsigned long long numberOfBytesTransferred;

@property(nonatomic, readonly) BOOL succeeded;
@property(nonatomic, readonly, strong) id result;
@property(nonatomic, readonly, strong) NSError* error;

@property(nonatomic, strong) id userInfo;

@end
