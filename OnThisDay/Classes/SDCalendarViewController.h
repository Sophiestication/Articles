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

#import "SDWikipediaEventImporter.h"
#import "AKWebCustomizer.h"

@class SDCalendarNavigationButton;
@class SDCalendarTitleView;
@class WikipediaAPI;

@interface SDCalendarViewController : UIViewController<UIWebViewDelegate, AKWebCustomizerDelegate, SDWikipediaEventImporterDelegate> {
@private
	id _backButton;
	id _forwardButton;
	SDCalendarTitleView* _titleView;
	UIButton* _infoButton;
	NSDate* _previousDate;
	NSDate* _selectedDate;
	NSDate* _nextDate;
	UIImageView* _overlayView;
	UIWebView* _webView;
	AKWebCustomizer* _webCustomizer;
	UIImageView* _progressIndicator;
	BOOL _progressIndicatorShown;
	WikipediaAPI* _wikipediaAPI;
	NSOperationQueue* _operationQueue;
	NSManagedObjectContext* _managedObjectContext;
	UIImageView* _transitionView;
	BOOL _shaking;
}

@property(nonatomic, strong) SDCalendarNavigationButton* backButton;
@property(nonatomic, strong) SDCalendarNavigationButton* forwardButton;
@property(nonatomic, strong) SDCalendarTitleView* titleView;

@property(nonatomic, strong) UIImageView* overlayView;
@property(nonatomic, strong) UIWebView* webView;

@property(nonatomic, strong) UIButton* infoButton;

@property(nonatomic) BOOL progressIndicatorShown;
- (void)setProgressIndicatorShown:(BOOL)progressIndicatorShown animated:(BOOL)animated;

@property(nonatomic, retain) NSManagedObjectContext* managedObjectContext;

+ (id)viewController;

- (IBAction)back:(id)sender;
- (IBAction)forward:(id)sender;

- (IBAction)showDay:(NSDate*)day;

- (IBAction)showToday:(id)sender;

- (IBAction)showDayPicker:(id)sender;
- (IBAction)showArticle:(id)sender;

- (IBAction)reload:(id)sender;

@end
