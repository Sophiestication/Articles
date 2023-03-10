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

#import "AKLightboxViewController.h"

@interface AKLightboxViewController()<UIPopoverControllerDelegate>

@property(weak, nonatomic, readonly) AKLightboxView* lightboxView;

@property(nonatomic, strong) UIBarButtonItem* shareButtonItem;
@property(nonatomic, strong) UIBarButtonItem* doneButtonItem;

@property(nonatomic, strong) NSDictionary* options;

@property(nonatomic, strong) UIView* transitionView;
@property(nonatomic, strong) AKLightboxOverlayView* transitionOverlayView;

@property(nonatomic, strong) SFDownloadOperation* downloadOperation;

@property(nonatomic, strong) UIActionSheet* visibleActionSheet;
@property(nonatomic, strong) UIPrintInteractionController* visiblePrintInteractionController;
@property(nonatomic, strong) UIPopoverController* activitiesPopoverController;

- (UIImage*)imageRepresentationForView:(UIView*)view;

- (void)downloadImageAtURL:(NSURL*)imageURL toURL:(NSURL*)localImageURL;

- (BOOL)isPrintingAvailable;

@end
