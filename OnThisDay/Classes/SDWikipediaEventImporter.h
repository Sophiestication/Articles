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

#import "SDWikipediaEventImporterDelegate.h"

NSString* const SDWikipediaEventImporterErrorDomain;

enum {
	SDWikipediaEventImporterErrorUnknown = -1,
	SDWikipediaEventImporterErrorCancelled = -2,
	SDWikipediaEventImporterErrorParserFailed = -3
};

@interface SDWikipediaEventImporter : NSOperation<NSURLConnectionDelegate> {
@private
	xmlParserCtxtPtr _parserContext;
	BOOL _waitingForInput;
}

@property(nonatomic, readonly, strong) NSURL* wikipediaURL;
@property(nonatomic, strong) id userInfo;
@property(nonatomic, weak) id<SDWikipediaEventImporterDelegate> delegate;

+ (SDWikipediaEventImporter*)eventImporterForURL:(NSURL*)wikipediaURL;

@end
