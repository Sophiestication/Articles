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

#import "WIKPageDecoder.h"

#import "WIKMediaWikiClient.h"

#import "WIKImage.h"
#import "WIKImageRepresentation.h"

#import "WIKPage.h"

#import <CoreLocation/CoreLocation.h>

@interface WIKPageDecoder()

@property(nonatomic, strong) NSMutableDictionary* decodedPropertiesByTitle;

@property(nonatomic, strong) NSMutableDictionary* incompleteImages;
@property(nonatomic, strong) NSMutableDictionary* incompleteRepresentativeImages;

@property(nonatomic, strong) NSMutableDictionary* normalizedPageTitles;
@property(nonatomic, strong) NSMutableDictionary* denormalizedPageTitles;

@end

@implementation WIKPageDecoder

#pragma mark - Construction & Destruction

- (id)init {
	if((self = [super init])) {
		self.decodedPropertiesByTitle = [NSMutableDictionary dictionaryWithCapacity:10];

		self.incompleteImages = [NSMutableDictionary dictionary];
		self.incompleteRepresentativeImages = [NSMutableDictionary dictionary];
	
		self.normalizedPageTitles = [NSMutableDictionary dictionary];
		self.denormalizedPageTitles = [NSMutableDictionary dictionary];
	}

	return self;
}

#pragma mark - WIKPageDecoder

- (BOOL)decodeFragment:(id)fragment error:(NSError**)error {
	if(![fragment isKindOfClass:[NSDictionary class]]) { return NO; }

	[self updateNormalizedPageTitlesFromFragment:fragment];

	NSDictionary* pages = [fragment objectForKey:@"pages"];
	if(![pages isKindOfClass:[NSDictionary class]]) { return NO; } // TODO

	for(NSDictionary* page in [pages objectEnumerator]) {
		if(![self decodePage:page error:error]) {
			return NO;
		}
	}

	return YES;
}

- (NSDictionary*)propertiesForPage:(NSString*)page {
	@synchronized(self) {
		return [self mutablePropertiesForPage:page];
	}

	return nil;
}

- (NSSet*)imagesNeedingCompletion {
	@synchronized(self) {
		NSMutableSet* images = [NSMutableSet set];

		[images addObjectsFromArray:[[self incompleteImages] allKeys]];
		[images addObjectsFromArray:[[self incompleteRepresentativeImages] allKeys]];

		return images;
	}

	return nil;
}

#pragma mark - Page

- (BOOL)decodePage:(NSDictionary*)page error:(NSError**)error {
	NSString* title = [self objectForKey:@"title" ofClass:[NSString class] dictionary:page];
	if(title.length == 0) { return NO; } // we require a page title

	if([self isImageInfoFragment:page]) { return [self decodeImageInfoProperties:page error:error]; }

	NSMutableDictionary* newProperties = [NSMutableDictionary dictionaryWithCapacity:3];

	if(![self decodeTitlePropertyIfNeeded:page properties:newProperties  error:error]) { return NO; }
	if(![self decodeURLPropertyIfNeeded:page properties:newProperties  error:error]) { return NO; }
	if(![self decodeSummaryPropertyIfNeeded:page properties:newProperties  error:error]) { return NO; }

	if(![self decodeRepresentativeImagePropertyIfNeeded:page pageTitle:title error:error]) { return NO; }
	if(![self decodeCoordinatePropertyIfNeeded:page properties:newProperties error:error]) { return NO; }

	if(![self decodeImagesPropertyIfNeeded:page pageTitle:title error:error]) { return NO; }

	@synchronized(self) {
		NSMutableDictionary* properties = [[self decodedPropertiesByTitle] objectForKey:title];
		if(properties) { [newProperties addEntriesFromDictionary:properties]; }
		[[self decodedPropertiesByTitle] setObject:newProperties forKey:title];
	}

	return YES;
}

#pragma mark - WIKMediaWikiInfoProperty

- (BOOL)decodeTitlePropertyIfNeeded:(NSDictionary*)page properties:(NSMutableDictionary*)properties error:(NSError**)error {
	NSDictionary* pageInfo = [self objectForKey:WIKMediaWikiPageInfoProperty ofClass:[NSDictionary class] dictionary:page];

	NSString* title = [self objectForKey:@"displaytitle" ofClass:[NSString class] dictionary:pageInfo];
	if(title.length == 0) { title = [self objectForKey:@"title" ofClass:[NSString class] dictionary:page]; }

	if(title.length == 0) { return NO; }

	properties[WIKPropertyName(title)] = title;

	return YES;
}

- (BOOL)decodeURLPropertyIfNeeded:(NSDictionary*)page properties:(NSMutableDictionary*)properties error:(NSError**)error {
	NSString* URLString = [self objectForKey:@"fullurl" ofClass:[NSString class] dictionary:page];
	if(URLString.length == 0) { return YES; }

	NSURL* URL = [NSURL URLWithString:URLString];
	properties[WIKPropertyName(URL)] = URL;

	return YES;
}

#pragma mark - WIKMediaWikiPageInfoProperty

- (BOOL)decodeRepresentativeImagePropertyIfNeeded:(NSDictionary*)page pageTitle:(NSString*)pageTitle error:(NSError**)error {
	NSDictionary* pageInfo = [self objectForKey:WIKMediaWikiPageInfoProperty ofClass:[NSDictionary class] dictionary:page];

	NSString* pageImage = [self objectForKey:@"page_image" ofClass:[NSString class] dictionary:pageInfo];
	if(pageImage.length == 0) { return YES; }
	if([pageImage isEqualToString:@"Transparent_bar.svg"]) { return YES; } // ignore placeholders
	if([pageImage isEqualToString:@"Commons-logo.svg"]) { return YES; } // ignore wikicommons logos
	if([pageImage isEqualToString:@"Wikiquote-logo.svg"]) { return YES; } // ignore wikiquote logos

	pageImage = [@"File:" stringByAppendingString:pageImage]; // page_image title comes without prefix

	@synchronized(self) {
		NSMutableDictionary* incompleteRepresentativeImages = self.incompleteRepresentativeImages;
		[self appendObject:pageTitle forKey:pageImage dictionary:incompleteRepresentativeImages];
	}

	return YES;
}

#pragma mark - WIKMediaWikiExtractsProperty

- (BOOL)decodeSummaryPropertyIfNeeded:(NSDictionary*)page properties:(NSMutableDictionary*)properties error:(NSError**)error {
	NSString* summary = [self objectForKey:@"extract" ofClass:[NSString class] dictionary:page];

	if(summary) {
		properties[WIKPropertyName(summary)] = summary;
	}

	return YES;
}

#pragma mark - WIKImagesPropertyKey

- (BOOL)decodeImagesPropertyIfNeeded:(NSDictionary*)page pageTitle:(NSString*)pageTitle error:(NSError**)error {
	NSArray* images = [self objectForKey:WIKMediaWikiImagesProperty ofClass:[NSArray class] dictionary:page];
	if(images.count == 0) { return YES; }

	NSMutableArray* decodedImageNames = [NSMutableArray arrayWithCapacity:[images count]];

	for(NSDictionary* imageDictionary in images) {
		if(![imageDictionary isKindOfClass:[NSDictionary class]]) { continue; }

		NSString* name = [self objectForKey:@"title" ofClass:[NSString class] dictionary:imageDictionary];
		if(name.length == 0) { continue; }

		[decodedImageNames addObject:name];
	}

	@synchronized(self) {
		NSMutableDictionary* incompleteImages = self.incompleteImages;

		for(NSString* name in decodedImageNames) {
			[self appendObject:pageTitle forKey:name dictionary:incompleteImages];
		}
	}

	return YES;
}

#pragma mark - WIKMediaWikiImageInfoProperty

- (BOOL)isImageInfoFragment:(NSDictionary*)fragment {
	return
		[fragment objectForKey:@"imageinfo"] ||
		[fragment objectForKey:@"imagerepository"];
}

- (BOOL)decodeImageInfoProperties:(NSDictionary*)fragment error:(NSError**)error {
	NSDictionary* imageInfo = [[fragment objectForKey:@"imageinfo"] firstObject];
	
	NSString* name = fragment[@"title"];
	
	// native representation
	NSURL* URL = [self URLForKey:@"url" dictionary:imageInfo];
	
	NSString* MIMEType = imageInfo[@"mime"];
	NSString* UTI = [self UTIFromMIMEType:MIMEType];
	
	CGSize size = [self
		sizeForWidthValue:[imageInfo objectForKey:@"width"]
		heightValue:[imageInfo objectForKey:@"height"]];
		
	WIKImageRepresentation* representation = [[WIKImageRepresentation alloc]
		initWithURL:URL
		size:size
		typeIdentifier:UTI];
		
	// thumbnail representation
	URL = [self URLForKey:@"thumburl" dictionary:imageInfo];
	
	MIMEType = imageInfo[@"thumbmime"];
	UTI = [self UTIFromMIMEType:MIMEType];
	
	size = [self
		sizeForWidthValue:[imageInfo objectForKey:@"thumbwidth"]
		heightValue:[imageInfo objectForKey:@"thumbheight"]];
		
	WIKImageRepresentation* thumbnailRepresentation = [[WIKImageRepresentation alloc]
		initWithURL:URL
		size:size
		typeIdentifier:UTI];
	
	WIKImage* image = [[WIKImage alloc]
		initWithName:name
		representation:representation
		thumbnailRepresentation:thumbnailRepresentation];

	@synchronized(self) {
		NSString* denormalizedImageName = [[self denormalizedPageTitles] objectForKey:name];
		if(denormalizedImageName) { name = denormalizedImageName; }

		NSArray* pages = [[self incompleteRepresentativeImages] objectForKey:name];

		for(__strong NSString* page in pages) {
			NSMutableDictionary* properties = [self mutablePropertiesForPage:page];
			properties[WIKPropertyName(representativeImage)] = image;
		}

		pages = [[self incompleteImages] objectForKey:name];

		for(__strong NSString* page in pages) {
			NSMutableDictionary* properties = [self mutablePropertiesForPage:page];

			NSString* propertyKey = WIKPropertyName(images);
			NSMutableArray* images = properties[propertyKey];

			if(images) {
				[images addObject:image];
			} else {
				properties[propertyKey] = [NSMutableArray arrayWithObject:image];
			}
		}
	}
		
	return YES;
}

- (NSString*)UTIFromMIMEType:(NSString*)MIMEType {
	if(MIMEType.length == 0) { return nil; }
	
	CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(
		kUTTagClassMIMEType,
		(__bridge CFStringRef)MIMEType,
		NULL);
		
	return (__bridge_transfer NSString*)UTI;
}

#pragma mark - WIKLocationPropertyKey

- (BOOL)decodeCoordinatePropertyIfNeeded:(NSDictionary*)page properties:(NSMutableDictionary*)properties error:(NSError**)error {
	NSArray* coordinates = [self objectForKey:WIKMediaWikiCoordinatesProperty ofClass:[NSArray class] dictionary:page];

	for(NSDictionary* coordinateDictionary in coordinates) {
		if(![coordinateDictionary isKindOfClass:[NSDictionary class]]) { continue; }
		if(![coordinateDictionary objectForKey:@"primary"]) { continue; } // only decode the primary coordinate

		NSNumber* latitude = [self numberForKey:@"lat" dictionary:coordinateDictionary];
		NSNumber* longitude = [self numberForKey:@"lon" dictionary:coordinateDictionary];

		if(!latitude || !longitude) { return NO; } // TODO

		CLLocation* location = [[CLLocation alloc]
			initWithLatitude:[latitude doubleValue]
			longitude:[longitude doubleValue]];
		properties[WIKPropertyName(location)] = location;

		break; // stop after decoding the primary coordinate
	}

	return YES;
}

#pragma mark - Private

- (void)updateNormalizedPageTitlesFromFragment:(NSDictionary*)fragment {
	NSArray* normalized = [self objectForKey:@"normalized" ofClass:[NSArray class] dictionary:fragment];
	if(!normalized) { return; }

	@synchronized(self) {
		for(NSDictionary* dictionary in normalized) {
			if(![dictionary isKindOfClass:[NSDictionary class]]) { continue; }

			NSString* from = [self objectForKey:@"from" ofClass:[NSString class] dictionary:dictionary];
			NSString* to = [self objectForKey:@"to" ofClass:[NSString class] dictionary:dictionary];

			if(from.length == 0 || to.length == 0) { continue; }

			[[self normalizedPageTitles] setObject:to forKey:from];
			[[self denormalizedPageTitles] setObject:from forKey:to];
		}
	}
}

- (NSMutableDictionary*)mutablePropertiesForPage:(NSString*)page {
	NSString* normalizedPage = [[self normalizedPageTitles] objectForKey:page];
	if(normalizedPage) { page = normalizedPage; }

	NSMutableDictionary* properties = [[self decodedPropertiesByTitle] objectForKey:page];
	return properties;
}

- (void)appendObject:(id)object forKey:(NSString*)key dictionary:(NSMutableDictionary*)dictionary {
	NSMutableArray* array = [dictionary objectForKey:key];
	if(!array) { array = [NSMutableArray arrayWithCapacity:1]; }

	[array addObject:object];

	[dictionary setObject:array forKey:key];
}

- (id)objectForKey:(NSString*)key ofClass:(Class)objectClass dictionary:(NSDictionary*)dictionary {
	id object = dictionary[key];
	if([object isKindOfClass:objectClass]) { return object; }
	return nil;
}

- (NSNumber*)numberForKey:(NSString*)key dictionary:(NSDictionary*)dictionary {
	id value = [dictionary objectForKey:key];

	if(!value) { return nil; }
	if([value isKindOfClass:[NSNumber class]]) { return value; }

	if([value respondsToSelector:@selector(stringValue)]) {
		value = [value stringValue];
	}

	if([value isKindOfClass:[NSString class]]) {
		NSScanner* scanner = [NSScanner scannerWithString:value];
		double number;

		if([scanner scanDouble:&number]) {
			return @(number);
		}
	}

	return nil;
}

- (NSURL*)URLForKey:(NSString*)key dictionary:(NSDictionary*)dictionary {
	NSString* URLString = [self objectForKey:key ofClass:[NSString class] dictionary:dictionary];
	if(URLString.length == 0) { return nil; }
	
	NSURL* URL = [NSURL URLWithString:URLString];
	return URL;
}

- (CGSize)sizeForWidthValue:(id)widthValue heightValue:(id)heightValue {
	CGFloat width = [widthValue doubleValue];
	CGFloat height = [heightValue doubleValue];

	return CGSizeMake(width, height);
}

@end
