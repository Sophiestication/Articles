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

#import <UIKit/UIKit.h>

#import "GeoNamesAPI.h"
#import "SAScopeBar.h"
#import "WikipediaPicker.h"

@interface NearbyItemsViewController : UIViewController<MKMapViewDelegate, RKTransactionDelegate, WikipediaPickerDelegate> {
@private
	BOOL _animateAnnotationViews;
	BOOL _shouldZoomToCurrentLocation;
	BOOL _tracksUserLocation;
	BOOL _initialLocationUpdatePending;
	BOOL _userDidChangeRegion;
	BOOL _shouldSelectAnnotationFromUserDefaults;
	BOOL _needsToReloadArticles;
    
    NSInteger _numberOfTransactions;
	
	CGFloat _minimumAccuracy;
}

@property(nonatomic, strong) IBOutlet MKMapView* mapView;
@property(nonatomic, strong) IBOutlet SAScopeBar* scopeBar;
@property(nonatomic, strong) IBOutlet UIBarButtonItem* doneButtonItem;
@property(nonatomic, strong) IBOutlet MKUserTrackingBarButtonItem* userTrackingButtonItem;

+ (id)viewController;

- (IBAction)done:(id)sender;
- (IBAction)showWikipediaPicker:(id)sender;

@end
