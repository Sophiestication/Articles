// AFKissXMLRequestOperation.h
//
// Copyright (c) 2011 Mattt Thompson (http://mattt.me/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>
#import "AFHTTPRequestOperation.h"

#import "DDXML.h"

/**
 `AFKissXMLRequestOperation` is a subclass of `AFHTTPRequestOperation` for downloading and working with XML response data using KissXML.
 
 ## Acceptable Content Types
 
 By default, `AFKissXMLRequestOperation` accepts the following MIME types, which includes the official standard, `application/xml`, as well as other commonly-used types:
 
 - `text/xml`
 - `text/html
 - `application/xhtml+xml`
 
 @warning `AFKissXMLRequestOperation` requires KissXML to also be added to the project. Please consult the KissXML documentation for details on how to add that library to your project.
 */
@interface AFKissXMLRequestOperation : AFHTTPRequestOperation {
@private
    DDXMLDocument *_responseXMLDocument;
    NSError *_XMLError;
}

///----------------------------
/// @name Getting Response Data
///----------------------------

/**
 A XML object constructed from the response data. If an error occurs while parsing, `nil` will be returned, and the `error` property will be set to the error.
 */
@property (readonly, nonatomic, retain) DDXMLDocument *responseXMLDocument;

///----------------------------------
/// @name Creating Request Operations
///----------------------------------

/**
 Creates and returns an `AFKissXMLRequestOperation` object and sets the specified success and failure callbacks.
 
 @param urlRequest The request object to be loaded asynchronously during execution of the operation
 @param success A block object to be executed when the operation finishes successfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the XML object created from the response data of request.
 @param failure A block object to be executed when the operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data as XML. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the error describing the network or parsing error that occurred.
 
 @return A new XML request operation
 */
+ (AFKissXMLRequestOperation *)XMLDocumentRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                              success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, DDXMLDocument *XMLDocument))success
                                                              failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, DDXMLDocument *XMLDocument))failure;

@end
