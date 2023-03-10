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

#import "RKTransaction.h"

@interface RKTransaction()

@property(nonatomic, readwrite, strong) NSURLConnection* connection;
@property(nonatomic, readwrite, strong) NSURLRequest* request;
@property(nonatomic, readwrite, strong) NSURLResponse* response;
@property(nonatomic, readwrite) long long expectedContentLength;
@property(nonatomic, readwrite) unsigned long long numberOfBytesTransferred;
@property(nonatomic, strong) NSMutableData* responseData;
@property(nonatomic, strong) NSOutputStream* responseStream;
@property(nonatomic, readwrite) BOOL succeeded;
@property(nonatomic, readwrite, strong) id result;
@property(nonatomic, readwrite, strong) NSError* error;

- (void)transactionShouldFinalizeWithConnection:(NSURLConnection*)connection error:(NSError*)error;

@end
