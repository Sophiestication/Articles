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
#import <ImageIO/ImageIO.h>

@class AKLightboxProgressView;

@interface AKLightboxView : UIView<UIScrollViewDelegate, UINavigationBarDelegate, UIGestureRecognizerDelegate> {
@private
	BOOL _barsHidden;
	BOOL _needsToLoadImage;
	BOOL _needsToUpdateZoomScales;
	UIScrollView* _scrollView;
	NSDictionary* _imageProperties;
	UINavigationBar* _navigationBar;
	UIToolbar* _toolbar;
	UILabel* _captionLabel;
	UINavigationItem* _navigationItem;
	NSString* _imageContentType;
	NSURL* _imageURL;
	UIInterfaceOrientation _interfaceOrientation;
	AKLightboxProgressView* _progressView;
	CGImageSourceRef _imageSource;
	CGSize _imageSize;
	CGSize _previewSize;
	CGFloat _previewScale;
	
	CGPoint _draggingStartingPoint;
	CGAffineTransform _draggingStartingTransform;
}

@property(nonatomic, copy) NSString* imageContentType;
@property(nonatomic, copy) NSURL* imageURL;

@property(nonatomic, copy) NSString* captionText;
@property(nonatomic, strong) UINavigationItem* navigationItem;

@property(nonatomic) UIInterfaceOrientation interfaceOrientation;

@end
