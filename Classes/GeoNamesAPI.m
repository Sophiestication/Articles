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

#import "GeoNamesAPI.h"
#import "GeoNamesAPI+Private.h"
#import "WikiPlacemark.h"

#import "MKMapView+Additions.h"

@implementation GeoNamesAPI

@synthesize preferredLanguage = _preferredLanguage;
@synthesize transactionDelegate = _transactionDelegate;

#pragma mark Construction & Destruction

- (id)init {
	if(self = [super init]) {
	}
	
	return self;
}


#pragma mark -
#pragma mark Reverse Geocoding

- (RKTransaction*)countrySubdivisionForCoordinate:(CLLocationCoordinate2D)coordinate {
	NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
		@"sophiestication", @"username",
		[NSNumber numberWithDouble:coordinate.latitude], @"lat",
		[NSNumber numberWithDouble:coordinate.longitude], @"lng",
		[self preferredLanguage], @"lang",
		nil];
	NSURL* URL = [NSURL URLWithString:@"http://sophiestication.geonames.net/countrySubdivisionJSON"
		parameters:parameters];
	
	RKTransaction* transaction = [RKTransaction transactionWithURL:URL];
	
	transaction.delegate = self.transactionDelegate;
	
	return transaction;
}

#pragma mark -
#pragma mark Wikipedia

- (RKTransaction*)wikipediaArticlesNearbyCoordinate:(CLLocationCoordinate2D)coordinate {
	NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
		@"sophiestication", @"username",
		[NSNumber numberWithDouble:coordinate.latitude], @"lat",
		[NSNumber numberWithDouble:coordinate.longitude], @"lng",
		[self preferredLanguage], @"lang", // preferredLanguage might be nil
		nil];
	NSURL* URL = [NSURL URLWithString:@"http://sophiestication.geonames.net/findNearbyWikipediaJSON"
		parameters:parameters];
	
	RKTransaction* transaction = [RKTransaction transactionWithURL:URL];
	
	transaction.resultFormatter = [GeoNamesWikipediaWithinRegionResultFormatter formatter];
	transaction.delegate = self.transactionDelegate;
	
	return transaction;
}

- (RKTransaction*)wikipediaArticlesWithinRegion:(MKCoordinateRegion)region {
	CGFloat const regionOffset = 0.5;

	CLLocationDegrees north = region.center.latitude + region.span.latitudeDelta * regionOffset;
	CLLocationDegrees east = region.center.longitude + region.span.longitudeDelta * regionOffset;
	CLLocationDegrees south = region.center.latitude - region.span.latitudeDelta * regionOffset;
	CLLocationDegrees west = region.center.longitude - region.span.longitudeDelta * regionOffset;
	
	NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
		@"sophiestication", @"username",
		[NSNumber numberWithDouble:north], @"north",
		[NSNumber numberWithDouble:east], @"east",
		[NSNumber numberWithDouble:south], @"south",
		[NSNumber numberWithDouble:west], @"west",
		[NSNumber numberWithInteger:75], @"maxRows",
		[self preferredLanguage], @"lang", // preferredLanguage might be nil
		nil];
	NSURL* URL = [NSURL URLWithString:@"http://sophiestication.geonames.net/wikipediaBoundingBoxJSON"
		parameters:parameters];
	
	RKTransaction* transaction = [RKTransaction transactionWithURL:URL];
	
	transaction.resultFormatter = [GeoNamesWikipediaWithinRegionResultFormatter formatter];
	transaction.delegate = self.transactionDelegate;
	
	return transaction;
}

@end

#pragma mark -
#pragma mark GeoNamesWikipediaWithinRegionResultFormatter

@implementation GeoNamesWikipediaWithinRegionResultFormatter

- (id)formatResultData:(NSData*)resultData error:(NSError**)error response:(NSURLResponse*)response {
	NSDictionary* resultDictionary = [super formatResultData:resultData error:error response:response];
	
	NSMutableArray* placemarks = [NSMutableArray array];
	
	for(NSDictionary* placemarkInfo in [resultDictionary objectForKey:@"geonames"]) {
		WikiPlacemark* placemark = [[WikiPlacemark alloc] initWithGeonamesDictionary:placemarkInfo];
		[placemarks addObject:placemark];
	}
	
	return placemarks;
}

@end
