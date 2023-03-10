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

#import "AKLightboxControllerDelegate.h"
#import "SFDownloadOperationDelegate.h"

@class AKLightboxView;
@class AKLightboxOverlayView;
@class SFDownloadOperation;

extern NSString* const AKLightboxWillShowNotification;
extern NSString* const AKLightboxWillHideNotification;

@interface AKLightboxViewController : UIViewController<UIActionSheetDelegate, UIPrintInteractionControllerDelegate, SFDownloadOperationDelegate> {
@private
	UIBarButtonItem* _shareButtonItem;
	UIBarButtonItem* _doneButtonItem;
	NSDictionary* _options;
	UIStatusBarStyle _previousStatusBarStyle;
	UIView* _transitionView;
	AKLightboxOverlayView* _transitionOverlayView;
	SFDownloadOperation* _downloadOperation;
}

+ (AKLightboxViewController*)viewController;

@property(nonatomic, weak) id<AKLightboxControllerDelegate> delegate;

- (void)presentPreviewInViewController:(UIViewController*)parentViewController withOptions:(NSDictionary*)options animated:(BOOL)animated;
- (void)dismissPreviewAnimated:(BOOL)animated;

- (IBAction)share:(id)sender;
- (IBAction)print:(id)sender;
- (IBAction)done:(id)sender;

@end
