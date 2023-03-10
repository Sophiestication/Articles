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

#import "WikiPlacemark.h"

@implementation WikiPlacemark

@dynamic feature;
@dynamic wikipediaURL;
@dynamic thumbnailURL;
@synthesize serial;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithGeonamesDictionary:(NSDictionary*)geonamesDictionary {
	if(self = [super init]) {
		_geonamesDictionary = geonamesDictionary;
		
		// Retrieve the placemarks coordinate
		CLLocationCoordinate2D coordinate;
		coordinate.latitude = [[geonamesDictionary objectForKey:@"lat"] doubleValue];
		coordinate.longitude = [[geonamesDictionary objectForKey:@"lng"] doubleValue];
		_coordinate = coordinate;
	}
	
	return self;
}


#pragma mark -
#pragma mark NSObject

- (NSUInteger)hash {
	return [[self title] hash];
}

- (BOOL)isEqual:(id)other {
	if([other isKindOfClass:[WikiPlacemark class]]) {
		WikiPlacemark* otherPlacemark = other;
		
		return [[otherPlacemark title] isEqualToString:[self title]];
	}
	
	if([other conformsToProtocol:@protocol(MKAnnotation)]) {
		id<MKAnnotation> otherAnnotation = other;
		
		return otherAnnotation.coordinate.latitude == self.coordinate.latitude &&
		       otherAnnotation.coordinate.longitude == self.coordinate.longitude;
	}
	
	return NO;
}

- (NSString*)description {
	return [NSString stringWithFormat:@"%@ {title = %@, coordinate = (%4.2f;%4.2f) }",
		[super description],
		[self title],
		self.coordinate.latitude,
		self.coordinate.longitude];
}

#pragma mark -
#pragma mark MKAnnotation

- (CLLocationCoordinate2D)coordinate {
	return _coordinate;
}

- (NSString*)title {
	return [_geonamesDictionary objectForKey:@"title"];
}

- (NSString*)subtitle {
	// return [_geonamesDictionary objectForKey:@"summary"];
	return nil;
}

#pragma mark -
#pragma mark WikiPlacemark

- (NSString*)feature {
	return [_geonamesDictionary objectForKey:@"feature"];
}

- (NSURL*)wikipediaURL {
	NSString* wikipediaURLString = [_geonamesDictionary objectForKey:@"wikipediaUrl"];

	if(wikipediaURLString) {
		if(![wikipediaURLString hasPrefix:@"http://"] ||
		   ![wikipediaURLString hasPrefix:@"https://"]) {
			wikipediaURLString = [@"http://" stringByAppendingString:wikipediaURLString];
		}
		
		NSURL* wikipediaURL = [NSURL URLWithString:wikipediaURLString];
		return wikipediaURL;
	}
	
	return nil;
}

- (NSURL*)thumbnailURL {
	NSString* thumbnailURLString = [_geonamesDictionary objectForKey:@"thumbnailImg"];

	if(thumbnailURLString) {
		return [NSURL URLWithString:thumbnailURLString];
	}
	
	return nil;
}

- (NSDictionary*)geonamesDictionary {
	return _geonamesDictionary;
}

@end
