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

#import "WIKPage.h"
#import "WIKPage+Private.h"

#import "WIKMediaWiki.h"

#import "WIKProperty.h"
#import "WIKProperty+Construction.h"
#import "WIKProperty+Mutating.h"

@implementation WIKPage

#pragma mark - Construction & Destruction

- (id)initWithIdentifier:(NSString*)identifier mediaWiki:(WIKMediaWiki*)mediaWiki {
	if((self = [super init])) {
		self.identifier = identifier;
		self.mediaWiki = mediaWiki;
	}

	return self;
}

#pragma mark - WIKPage

- (WIKProperty*)URL {
	if(!_URL) { _URL = [self newPropertyForSelector:_cmd]; }
	return _URL;
}

- (WIKProperty*)title {
	if(!_title) { _title = [self newPropertyForSelector:_cmd]; }
	return _title;
}

- (WIKProperty*)summary {
	if(!_summary) { _summary = [self newPropertyForSelector:_cmd]; }
	return _summary;
}

- (WIKProperty*)images {
	if(!_images) { _images = [self newPropertyForSelector:_cmd]; }
	return _images;
}

- (WIKProperty*)representativeImage {
	if(!_representativeImage) { _representativeImage = [self newPropertyForSelector:_cmd]; }
	return _representativeImage;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
	if(self == object) { return YES; }
	if(![object isKindOfClass:[self class]]) { return NO; }

	return [[self identifier] isEqual:[object identifier]] &&
		   [[self mediaWiki] isEqual:[object mediaWiki]];
}

- (NSUInteger)hash {
//	#define WIKUINT_BIT (CHAR_BIT * sizeof(NSUInteger))
//	#define WIKUINTROTATE(val, howmuch) ((((NSUInteger)val) << howmuch) | (((NSUInteger)val) >> (WIKUINT_BIT - howmuch)))
//
//	return WIKUINTROTATE([[self identifier] hash], WIKUINT_BIT / 2) ^ [[self mediaWiki] hash];

	return [[self identifier] hash] ^ [[self mediaWiki] hash]; // clearer and good enough in this case
}

- (NSString*)description {
	return [NSString stringWithFormat:@"%@ %@",
		[super description],
		[self identifier]];
}

#pragma mark - Private

- (WIKProperty*)newPropertyForSelector:(SEL)selector {
	WIKProperty* property = [[WIKProperty alloc] initWithSelector:selector page:self];
	return property;
}

@end

#pragma mark - PropertyLoading

@implementation WIKPage(PropertyLoading)

+ (void)loadPropertiesIfNeeded:(NSArray*)propertyNames pages:(NSArray*)pages completion:(void (^)(NSError* error))completion {
	__block NSMutableSet* properties = [NSMutableSet set];
	__block BOOL loadingDidFail = NO;

	for(NSString* propertyName in propertyNames) {
		for(WIKProperty* property in [pages valueForKey:propertyName]) {
			WIKPropertyStatus status = property.status;
			if(status == WIKPropertyStatusLoaded || status == WIKPropertyStatusLoading) { continue; }

			[properties addObject:property];
		}
	}

	for(WIKProperty* property in properties) {
		[property loadValueWithCompletionHandler:^(id value, NSError* error) {
			if(loadingDidFail) { return; }
			
			if(error) {
				loadingDidFail = YES;
				completion(error);
			} else {
				[properties removeObject:property];
				if(properties.count == 0) { completion(nil); }
			}
		}];
	}

	if(properties.count == 0) {
		completion(nil);
	}
}

@end
