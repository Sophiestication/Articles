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

#import "NearbyItemsViewController.h"
#import "NearbyItemsViewController+Private.h"

#import "WikiPlacemark.h"
#import "WikiPlacemark+UIAdditions.h"

#import "Articles.h"

#import "MKGeometry+Additions.h"
#import "NSArray+Additions.h"
#import "NSLocale+Additions.h"
#import "NSString+Additions.h"
#import "UIButton+Additions.h"
#import "UINavigationController+Additions.h"

#import "MKMapView+Additions.h"

#import "SFNetworkActivity.h"
#import "SFWindow.h"

#import "GeoNamesAPI+Private.h"

#import <QuartzCore/QuartzCore.h>
#import <AddressBookUI/ABAddressFormatting.h>

@implementation NearbyItemsViewController

#pragma mark -
#pragma mark Construction & Destruction

+ (id)viewController {
	return [[self alloc] initWithNibName:@"NearbyItemsViewController" bundle:nil]; 
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
	if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		self.title = NSLocalizedString(@"NEARBYITEMS_NAVIGATIONITEM_TITLE", @"");
		
		self.contentSizeForViewInPopover = CGSizeMake(540.0, 480.0);
		
		_animateAnnotationViews = NO;
		_shouldZoomToCurrentLocation = YES;
		_tracksUserLocation = NO;
		_userDidChangeRegion = NO;
		_initialLocationUpdatePending = YES;
		_shouldSelectAnnotationFromUserDefaults = NO;
		
		self.hidesBottomBarWhenPushed = YES;
		
		_minimumAccuracy = 500.0; // 500 meters
        
        _numberOfTransactions = 0;
	}
	
	return self;
}

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"mapView.userLocation.location"];
	
	// Store to user defaults
	[self storeToUserDefaults];
	
	[self cancelAllTransactions];
	
	self.mapView.delegate = nil;
	
    
}

#pragma mark -
#pragma mark NearbyItemsViewController

- (IBAction)done:(id)sender {
	// Store to user defaults
	[self storeToUserDefaults];
	
	// Cancel all currently running lookup transactions
	[self cancelAllTransactions];
    
    if(_numberOfTransactions > 0) {
        SFNetworkActivityStopped();
    }
	
	// Make sure we no longer receive delegate notifications
	self.mapView.delegate = nil;

	// We also call done through our root view controller to
	// ensure proper user defaults updates
	[(id)[[self navigationController] rootViewController] done:sender];
}

- (IBAction)showWikipediaPicker:(id)sender {
	WikipediaPicker* picker = [WikipediaPicker viewController];
	
	picker.delegate = self;
	picker.selectedWikipedia = self.geonames.preferredLanguage;
	
	picker.navigationItem.prompt = nil;
	
	[[self navigationController] pushViewController:picker animated:YES];
}

#pragma mark -
#pragma mark NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
	[self showUserLocationIfNeeded];
	_initialLocationUpdatePending = NO;
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	[self initGeonamesIfNeeded];

	self.userTrackingButtonItem = [[MKUserTrackingBarButtonItem alloc] initWithMapView:[self mapView]];
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		self.navigationItem.rightBarButtonItems = @[ self.doneButtonItem, self.userTrackingButtonItem ];
	} else {
		self.navigationItem.rightBarButtonItem = self.userTrackingButtonItem;
	}

	// Setup the map view
	self.mapView.delegate = self;
	self.mapView.showsUserLocation = YES;
	
//	self.mapView.mapType = MKMapTypeHybrid + 1;
	
	[self addObserver:self forKeyPath:@"mapView.userLocation.location" options:0 context:NULL];
	
	// Setup the scope bar
	NSString* languageCode = self.geonames.preferredLanguage;
	NSString* language = [WikipediaPicker displayNameForLanguageCode:languageCode];
	[[self scopeBar] setTitle:language forState:UIControlStateNormal];
	
	// Restore our viewport region and annotaions from defaults
	[self restoreFromUserDefaults];
}

- (void)viewDidUnload {
	// Store to user defaults
	[self storeToUserDefaults];
	
	// Cancel all currently running lookup transactions
	[self cancelAllTransactions];
	
	self.geonames = nil;
    
	// Release some objects
	self.mapView.delegate = nil;
	self.mapView = nil;
	self.scopeBar = nil;
	self.doneButtonItem = nil;
	
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	self.mapView.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	// Store to user defaults
	[self storeToUserDefaults];
	
	[self cancelAllTransactions];
	self.mapView.delegate = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

	if(self.view.window) { return; }

	// Store to user defaults
	[self storeToUserDefaults];
	
	// Cancel all currently running lookup transactions
	[self cancelAllTransactions];
	
	self.geonames = nil;
    
	// Release some objects
	self.mapView.delegate = nil;
	self.mapView = nil;
	self.scopeBar = nil;
	self.doneButtonItem = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
     if(self.navigationController.parentViewController) {
		return [[[self navigationController] parentViewController] shouldAutorotateToInterfaceOrientation:interfaceOrientation];
	}
	
	return YES;
}

#pragma mark -
#pragma mark MKMapViewDelegate

- (void)mapView:(MKMapView*)mapView regionWillChangeAnimated:(BOOL)animated {
	// Cancel location tracking
	if(_userDidChangeRegion) {
		_initialLocationUpdatePending = NO;
	}

	// Cancel the reload timer
	[NSObject cancelPreviousPerformRequestsWithTarget:self
		selector:@selector(reloadArticlesForCurrentRegion)
		object:nil];
	
	// Also cancel the current transaction
	if(self.currentTransaction) {
		self.currentTransaction.delegate = nil;
		[[self currentTransaction] cancel];
		self.currentTransaction = nil;
	}    
}

- (void)mapView:(MKMapView*)mapView regionDidChangeAnimated:(BOOL)animated {
	_userDidChangeRegion = YES;
	
	// Remove unneeded annotations
	if(!_initialLocationUpdatePending) {
		[self purgeDenseAnnotations];
	}
	
	// Schedule the reload articles timer
	[self performSelector:@selector(reloadArticlesForCurrentRegion)
		withObject:nil
		afterDelay:0.75];
}

- (MKAnnotationView*)mapView:(MKMapView*)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
	if(annotation == mapView.userLocation) {
		return nil;
	}

	static NSString* const annotationIdentifier = @"article";
	MKPinAnnotationView* annotationView = (id)[mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
	
	if(!annotationView) {
		annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
		
		annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		annotationView.canShowCallout = YES;
	}
	
	annotationView.animatesDrop = _animateAnnotationViews;

	return annotationView;
}

- (void)mapView:(MKMapView*)mapView didAddAnnotationViews:(NSArray*)views {
	for(MKAnnotationView* view in views) {
		id<MKAnnotation> annotation = view.annotation;
        
		if(annotation == mapView.userLocation) {
			[self showUserLocationIfNeeded];
			[self reverseGeocodeIfNeeded];
		}
	}
	
	// ...
	if(_shouldSelectAnnotationFromUserDefaults) {
		NSString* selectedPlacemarkTitle = [[NSUserDefaults standardUserDefaults]
			objectForKey:@"nearbyItemsSelection"];
		
		if(selectedPlacemarkTitle) {
			for(MKAnnotationView* view in views) {
				if([[view annotation] isKindOfClass:[WikiPlacemark class]] &&
				   SFEqualStrings([(WikiPlacemark*)[view annotation] title], selectedPlacemarkTitle)) {
					[[self mapView] selectAnnotation:[view annotation] animated:NO];
					
					break;
				}
			}
		}
		
		_shouldSelectAnnotationFromUserDefaults = NO;
	}
	
//	_animateAnnotationViews = YES;
}

- (void)mapView:(MKMapView*)mapView annotationView:(MKAnnotationView*)view calloutAccessoryControlTapped:(UIControl*)control {
	id<MKAnnotation> annotation = view.annotation;
	
	if([annotation isKindOfClass:[WikiPlacemark class]]) {
		WikiPlacemark* wikiPlacemark = (id)annotation;
		
		[[Articles self] openArticleURL:[wikiPlacemark wikipediaURL]];
		
		[self done:control];
	}
}

#pragma mark -
#pragma mark RKTransactionDelegate

- (void)transactionDidFinish:(RKTransaction*)transaction withResult:(id)result {
	if(transaction == self.currentTransaction) {		
		[self operationDidParseGeonamesResultData:result];
		
		if(_needsToReloadArticles) {
			_needsToReloadArticles = NO;
			[self reloadArticlesForCurrentRegion];
		}
	}
	
	--_numberOfTransactions;
    
    if(_numberOfTransactions == 0) {
        SFNetworkActivityStopped();
    }
}

- (void)transaction:(RKTransaction*)transaction didFailWithError:(NSError*)error {
	if(transaction == self.currentTransaction) {
		self.currentTransaction = nil;
	}
	
	--_numberOfTransactions;
    
    if(_numberOfTransactions == 0) {
        SFNetworkActivityStopped();
    }
}

#pragma mark -
#pragma mark WikipediaPickerDelegate

- (void)wikipediaPickerController:(WikipediaPicker*)picker didFinishPickingLanguageCode:(NSString*)languageCode {
	if(![languageCode isEqualToString:[[self geonames] preferredLanguage]]) {
		NSString* language = [WikipediaPicker displayNameForLanguageCode:languageCode];
		[[self scopeBar] setTitle:language forState:UIControlStateNormal];

		self.geonames.preferredLanguage = languageCode;
		
		// Make sure the delegate is set. We might have set it on viewWillDisappear:
		self.mapView.delegate = self;
		
		// Clear the map and reload with the new language set
		[[self mapView] removeAnnotations:[[self mapView] annotations]];
		self.visibleAnnotations = [NSArray array];
		
		[self reloadArticlesForCurrentRegion];
	}
}

#pragma mark -
#pragma mark Private

- (void)initGeonamesIfNeeded {
	if(self.geonames) { return; }

	GeoNamesAPI* geonames = [[GeoNamesAPI alloc] init];

	geonames.transactionDelegate = self;

	// Make sure we only use en or de as language code
	NSString* languageCode = [[NSUserDefaults standardUserDefaults]
		objectForKey:@"nearbyItemsPreferredLanguage"];
		
	if(languageCode.length == 0) {
		languageCode = [[NSLocale autoupdatingCurrentLocale] preferredLanguageCode];
	}	

	geonames.preferredLanguage = languageCode;

	self.geonames = geonames;
}

- (void)reloadArticlesForCurrentRegion {
	if(self.currentTransaction) {
		_needsToReloadArticles = YES;
		return;
	}
	
    if(_numberOfTransactions == 0) {
        SFNetworkActivityStarted();
	}
    
    ++_numberOfTransactions;

	MKCoordinateRegion region = self.mapView.region;
	
	RKTransaction* transaction = [[self geonames] wikipediaArticlesWithinRegion:region];
	self.currentTransaction = transaction;
	[transaction begin];
}

- (void)reverseGeocodeIfNeeded {
}

- (void)restoreFromUserDefaults {
	_shouldSelectAnnotationFromUserDefaults = YES;
	
	// Restore the view region
	NSDictionary* regionDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"nearbyItemsViewRegion"];
	
	if(regionDictionary) {
		_userDidChangeRegion = NO;
		self.mapView.region = SFCoordinateRegionFromDictionary(regionDictionary);
	}
	
	// Restore the visible annotations if needed
	if(regionDictionary) {
		NSArray* geonamesDictionaries = [[NSUserDefaults standardUserDefaults] arrayForKey:@"nearbyItemsViewAnnotations"];
		NSMutableArray* visiblePlacemarks = [NSMutableArray array];
		
		for(NSDictionary* geonamesDictionary in geonamesDictionaries) {
			WikiPlacemark* placemark = [[WikiPlacemark alloc] initWithGeonamesDictionary:geonamesDictionary];
			[visiblePlacemarks addObject:placemark];
		}
		
		if(visiblePlacemarks.count > 0) {
			// We don't want to animate annotation views
			_animateAnnotationViews = NO;
			
			[[self mapView] addAnnotations:visiblePlacemarks];
			[self purgeDenseAnnotations];
		}
	}

	// ...
	self.mapView.userTrackingMode = [[NSUserDefaults standardUserDefaults] integerForKey:@"nearbyItemsUserTrackingMode"];
}

- (void)storeToUserDefaults {
	// Store the state to user defaults
	if(self.mapView) {
		NSDictionary* regionDictionary = SFDictionaryFromCoordinateRegion(self.mapView.region);
		[[NSUserDefaults standardUserDefaults] setObject:regionDictionary forKey:@"nearbyItemsViewRegion"];
		
		// ...
		NSMutableArray* geonamesDictionaries = [NSMutableArray array];
	
		for(id<MKAnnotation> annotation in self.mapView.annotations) {
			if([annotation isKindOfClass:[WikiPlacemark class]]) {
				[geonamesDictionaries addObject:[(WikiPlacemark*)annotation geonamesDictionary]];
			}
		}
	
		[[NSUserDefaults standardUserDefaults] setObject:geonamesDictionaries forKey:@"nearbyItemsViewAnnotations"];
		
		// ...
		id<MKAnnotation> selectedAnnotation = [[[self mapView] selectedAnnotations] firstObject];
		
		if(selectedAnnotation && [selectedAnnotation isKindOfClass:[WikiPlacemark class]]) {
			NSString* placemarkTitle = [(WikiPlacemark*)selectedAnnotation title];
			[[NSUserDefaults standardUserDefaults] setObject:placemarkTitle forKey:@"nearbyItemsSelection"];
		} else {
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"nearbyItemsSelection"];
		}
	}
	
	[[NSUserDefaults standardUserDefaults] setInteger:[[self mapView] userTrackingMode] forKey:@"nearbyItemsUserTrackingMode"];
	[[NSUserDefaults standardUserDefaults] setObject:[[self geonames] preferredLanguage] forKey:@"nearbyItemsPreferredLanguage"];
}

- (BOOL)isAnnotation:(id<MKAnnotation>)annotation tooCloseToAnnotation:(id<MKAnnotation>)otherAnnotation {
   CGPoint annotationPoint = [[self mapView]
		convertCoordinate:[annotation coordinate]
		toPointToView:nil];
	CGPoint otherAnnotationPoint = [[self mapView]
		convertCoordinate:[otherAnnotation coordinate]
		toPointToView:nil];
   
	CGFloat deltaX = otherAnnotationPoint.x - annotationPoint.x;
    CGFloat deltaY = otherAnnotationPoint.y - annotationPoint.y;
    
	CGFloat const minDistance = 16.0;
	
	BOOL isTooClose = deltaX * deltaX + deltaY * deltaY < minDistance * minDistance;
	return isTooClose;
}

- (BOOL)isAnnotationTooCloseToAnyOtherMapViewAnnotation:(id<MKAnnotation>)annotation {
	for(id<MKAnnotation> otherAnnotation in self.mapView.annotations) {
		if ([self isAnnotation:annotation tooCloseToAnnotation:otherAnnotation]) {
			return YES;
		}
	}

	return NO;
}

- (void)purgeDenseAnnotations {
	NSArray* annotations = self.mapView.annotations;

	NSMutableArray* annotationsToRemove = [NSMutableArray arrayWithCapacity:
		[annotations count] * 0.5];
	
//	NSLog(@"%@", annotations);
	
	for(NSInteger i=0; i < annotations.count; ++i) {
		for(NSInteger j = i + 1; j < annotations.count; ++j) {
			id<MKAnnotation> annotation = [annotations objectAtIndex:i];
			id<MKAnnotation> otherAnnotation = [annotations objectAtIndex:j];
			
			if([self isAnnotation:annotation tooCloseToAnnotation:otherAnnotation]) {
				[annotationsToRemove addObject:annotation];
				break;
			}
		}
	}
	
	[[self mapView] removeAnnotations:annotationsToRemove];
}

- (void)showUserLocationIfNeeded {
	if(self.tracksUserLocation) {
		_userDidChangeRegion = NO;
		
		if(_shouldZoomToCurrentLocation || _initialLocationUpdatePending) {
			[self zoomToUserLocation];
		} else {
			[self centerToUserLocation];
		}
	}
}

- (void)centerToUserLocation {
	CLLocation* location = self.mapView.userLocation.location;
	
	if(location) {
		[[self mapView] setCenterCoordinate:[location coordinate] animated:YES];
	}
}

- (void)zoomToUserLocation {
	CLLocation* location = self.mapView.userLocation.location;
		
	if(location) {
		CLLocationAccuracy accuracy = MAX(location.horizontalAccuracy, location.verticalAccuracy);
		accuracy = MAX(accuracy, _minimumAccuracy); // Usually 500 meters
		
		MKCoordinateRegion newRegion = MKCoordinateRegionMakeWithDistance([location coordinate], accuracy, accuracy);
		newRegion = [[self mapView] regionThatFits:newRegion];
		
		[[self mapView] setRegion:newRegion animated:YES];
	}
}

- (void)addWikiPlacemarksIfNeeded:(NSArray*)wikiPlacemarks {
	NSInteger const highWatermark = 100;
	NSInteger const lowWaterMark = 50;
	
	// add annotations from server to map
	NSArray* annotationsOnMap = [NSArray arrayWithArray:[[self mapView] annotations]];
   
	for(id<MKAnnotation> annotation in wikiPlacemarks) {
		if (![self isAnnotationTooCloseToAnyOtherMapViewAnnotation:annotation] &&
			![annotationsOnMap containsObject:annotation]) {
			
			[[self mapView] addAnnotation:annotation];
		}
	}

	// Remove annotations when over high water mark
	if([annotationsOnMap count] > highWatermark) {
		NSUInteger trimSize = lowWaterMark;

		for(id<MKAnnotation> annotation in annotationsOnMap) {
			// skip non-WikiPlacemark
			if(![annotation isKindOfClass:[WikiPlacemark class]]) {
				continue;
			}

			// Remove only if outside of curren region; don't touch remove user location
			if(![MKMapView isLocation:[annotation coordinate] inRegion:[[self mapView] region]] &&
				((WikiPlacemark*)annotation).serial < trimSize) {
				[[self mapView] removeAnnotation:annotation];
			}
		}
	}
	
	// Update the annotations ivar
	self.visibleAnnotations = wikiPlacemarks;
	
//	NSLog(@"placemarks: %i, visiblePlacemarks: %i, visibleAnnotations: %i", wikiPlacemarks.count, self.visibleAnnotations.count, self.mapView.annotations.count);
}

- (void)cancelAllTransactions {
	[NSObject cancelPreviousPerformRequestsWithTarget:self
		selector:@selector(reloadArticlesForCurrentRegion)
		object:nil];
	
	if(self.currentTransaction) {
		SFNetworkActivityStopped();
	}
	
	self.currentTransaction.delegate = nil;
	
	[[self currentTransaction] cancel];
	self.currentTransaction = nil;
}

- (void)parseGeonamesResultData:(NSData*)resultData {
	id<RKResultFormatter> formatter = [GeoNamesWikipediaWithinRegionResultFormatter formatter];
	
	id result = [formatter formatResultData:resultData error:nil response:nil];
	
	if(![[NSThread currentThread] isCancelled]) {
		[self performSelectorOnMainThread:@selector(operationDidParseGeonamesResultData:) withObject:result waitUntilDone:YES];
	}
}

- (void)operationDidParseGeonamesResultData:(id)result {
	_animateAnnotationViews = YES;
	[self addWikiPlacemarksIfNeeded:result];
	
	self.currentTransaction = nil;
	
	// ...
	if(!_initialLocationUpdatePending && NO) {
		if([result count] == 0) {
			_minimumAccuracy *= 4.0;
			[self zoomToUserLocation];
		} else {
			
		}
	}
}

@end
