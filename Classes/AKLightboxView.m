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

#import "AKLightboxView.h"
#import "AKLightboxView+Private.h"

#import "AKLightboxProgressView.h"

#import <ImageIO/ImageIO.h>
#import <QuartzCore/QuartzCore.h>

@implementation AKLightboxView

@dynamic barsHidden;
@synthesize imageContentType = _imageContentType;
@dynamic imageURL;
@dynamic captionText;
@dynamic navigationItem;
@dynamic interfaceOrientation;
@synthesize scrollView = _scrollView;
@synthesize imageView = _imageView;
@synthesize navigationBar = _navigationBar;
@synthesize toolbar = _toolbar;
@synthesize captionLabel = _captionLabel;
@synthesize progressView = _progressView;
@synthesize imageProperties = _imageProperties;
@synthesize imageSize = _imageSize;
@synthesize previewSize = _previewSize;
@synthesize statusBarFrame = _statusBarFrame;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
		[self initIvars];
		[self initScrollView];
		[self initImageView];
		[self initNavigationBar];
		[self initToolbar];
		[self initCaptionLabel];
		[self initProgressIndicator];
		[self initGestureRecognizers];
	}

    return self;
}

- (id)initWithCoder:(NSCoder*)coder {
    if(self = [super initWithCoder:coder]) {
		[self initIvars];
		[self initScrollView];
		[self initImageView];
		[self initNavigationBar];
		[self initToolbar];
		[self initCaptionLabel];
		[self initProgressIndicator];
		[self initGestureRecognizers];
	}

    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter]
		removeObserver:self
		name:UIApplicationDidChangeStatusBarFrameNotification
		object:nil];

	if(_imageSource) { CFRelease(_imageSource); }


	self.navigationItem = nil;
	
	self.navigationBar.delegate = nil;
	
	
	self.scrollView.delegate = nil;
	
	
	
	self.imageURL = nil;

}

#pragma mark -
#pragma mark AKLightboxView

- (NSURL*)imageURL {
	return _imageURL;
}

- (void)setImageURL:(NSURL*)imageURL {
	if(imageURL != self.imageURL) {
		_imageURL = [imageURL copy];
		
		_needsToLoadImage = YES;
		[self setNeedsLayout];
	}
}

- (NSString*)captionText {
	return self.captionLabel.text;
}

- (void)setCaptionText:(NSString*)captionText {
	if(![[self captionText] isEqualToString:captionText]) {
		self.captionLabel.text = captionText;
		[self setNeedsLayout];
	}
}

- (UINavigationItem*)navigationItem {
	return _navigationItem;
}

- (void)setNavigationItem:(UINavigationItem*)navigationItem {
	if(navigationItem != self.navigationItem) {
		_navigationItem = navigationItem;
		
		if(navigationItem) {
			[[self navigationBar] pushNavigationItem:navigationItem animated:NO];
		}
	}
}

- (UIInterfaceOrientation)interfaceOrientation {
	return _interfaceOrientation;
}

- (void)setInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if(interfaceOrientation != self.interfaceOrientation) {
		_interfaceOrientation = interfaceOrientation;
		_needsToUpdateZoomScales = YES;
		[self setNeedsLayout];
	}
}

#pragma mark -
#pragma mark UIView

- (void)layoutSubviews {
	CGRect contentRect = self.bounds;
	CGRect scrollViewRect = contentRect;
	
	CGFloat barHeight = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad || UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ?
		44.0 :
		32.0;
	
	// Layout the navigation bar
	CGRect navigationBarRect = CGRectMake(
		CGRectGetMinX(contentRect),
		CGRectGetMinY(contentRect),
		CGRectGetWidth(contentRect),
		barHeight);
		
	if(![[UIApplication sharedApplication] isStatusBarHidden]) {
		CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
		UIInterfaceOrientation statusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
	
		if(UIInterfaceOrientationIsLandscape(statusBarOrientation)) {
			statusBarFrame = CGRectApplyAffineTransform(statusBarFrame, CGAffineTransformMakeRotation(-90.0 * M_PI / 180.0));
		}
	
		self.statusBarFrame = statusBarFrame;
	}
	
	CGFloat const statusBarHeight = MAX(20.0, CGRectGetHeight([self statusBarFrame]));
	navigationBarRect = CGRectOffset(navigationBarRect, 0.0, statusBarHeight);
	
	// Layout the toolbar and caption label
	static const CGFloat captionMargin = 5.0;
	
	BOOL toolbarHidden = self.captionLabel.text.length == 0;
	self.toolbar.hidden = toolbarHidden;
	
	CGSize captionLabelSize = CGSizeMake(
		CGRectGetWidth(contentRect) - captionMargin,
		CGRectGetHeight(contentRect));
	captionLabelSize = [[self captionLabel]
		sizeThatFits:captionLabelSize];
	
	CGFloat toolbarHeight = MAX(
		captionLabelSize.height,
		barHeight);

	CGRect toolbarRect = CGRectMake(
		CGRectGetMinX(contentRect),
		CGRectGetMaxY(contentRect) - toolbarHeight - captionMargin * 2.0,
		CGRectGetWidth(contentRect),
		toolbarHeight + captionMargin * 2.0);
		
	CGRect captionLabelRect = CGRectMake(
		floorf(CGRectGetMidX(toolbarRect) - captionLabelSize.width * 0.5),
		floorf(CGRectGetMidY(toolbarRect) - captionLabelSize.height * 0.5),
		captionLabelSize.width,
		captionLabelSize.height);
		
	// Layout the progress view
	static const CGFloat progressViewMargin = 10.0;
	
	CGSize progressViewSize = [[self progressView]
		sizeThatFits:contentRect.size];
		
	CGRect progressViewRect = CGRectMake(
		floorf(CGRectGetMidX(contentRect) - progressViewSize.width * 0.5),
		CGRectGetMinY(toolbarRect) - progressViewSize.height - progressViewMargin,
		progressViewSize.width,
		progressViewSize.height);
		
	if(self.barsHidden || toolbarHidden) {
		progressViewRect = CGRectOffset(progressViewRect, 0.0, CGRectGetHeight(toolbarRect));
	}
		
	// Update visibility
	CGFloat barAlpha = self.barsHidden ? 0.0 : 1.0;
	
	self.navigationBar.alpha = barAlpha;
	self.toolbar.alpha = barAlpha;
	self.captionLabel.alpha = barAlpha;
	
	// ...
	self.navigationBar.frame = navigationBarRect;
	self.toolbar.frame = toolbarRect;
	self.captionLabel.frame = captionLabelRect;
	self.progressView.frame = progressViewRect;
	
	if(_needsToUpdateZoomScales || CGRectEqualToRect(self.scrollView.frame, CGRectZero)) {
		self.scrollView.frame = scrollViewRect;
	}
	
	// Now layout the image view
	[self layoutImageView];
}

#pragma mark -
#pragma mark UIScrollViewDelegate

- (UIView*)viewForZoomingInScrollView:(UIScrollView*)scrollView {
	return self.imageView;
}

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
	[self setNeedsLayout];
}

- (void)scrollViewDidZoom:(UIScrollView*)scrollView {
//	[self layoutImageView];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView*)view {
}

- (void)scrollViewDidEndZooming:(UIScrollView*)scrollView withView:(UIView*)view atScale:(float)scale {
}

#pragma mark -
#pragma mark UINavigationBarDelegate

- (BOOL)navigationBar:(UINavigationBar*)navigationBar shouldPushItem:(UINavigationItem*)item {
	return YES;
}

- (void)navigationBar:(UINavigationBar*)navigationBar didPushItem:(UINavigationItem*)item {
}

#pragma mark -
#pragma mark UIGestureRecognizer

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
	// NSLog(@"%@", otherGestureRecognizer);
	return YES;
}

- (void)handleTapGesture:(UIGestureRecognizer*)gestureRecognizer {
	[self setBarsHidden:![self barsHidden] animated:YES];
}

- (void)handleDoubleTapGesture:(UIGestureRecognizer*)gestureRecognizer {
	if(self.scrollView.minimumZoomScale == self.scrollView.maximumZoomScale) { return; }
	
	CGFloat newScale = 0.0;
	
	if(self.scrollView.zoomScale == self.scrollView.maximumZoomScale) {
		newScale = self.scrollView.minimumZoomScale; // [self preferredZoomScale];
	} else {
		newScale = self.scrollView.maximumZoomScale;
	}
	
	CGPoint zoomCenter = [gestureRecognizer locationInView:[self imageView]];
	CGRect zoomRect = [self zoomRectForScale:newScale withCenter:zoomCenter];

	[[self scrollView] zoomToRect:zoomRect animated:YES];
}

- (void)handleRotationGesture:(UIRotationGestureRecognizer*)gestureRecognizer {
	self.scrollView.clipsToBounds = NO; // make sure the content won't clip
	
	CGPoint point = [gestureRecognizer locationInView:self.superview];
	
	if(gestureRecognizer.state == UIGestureRecognizerStateBegan) {
		_draggingStartingPoint = point;
		_draggingStartingTransform = self.transform;
	}
	
	if(gestureRecognizer.state == UIGestureRecognizerStateBegan ||
	   gestureRecognizer.state == UIGestureRecognizerStateChanged) {
		CGAffineTransform transform = _draggingStartingTransform;
		
		transform = CGAffineTransformTranslate(
			transform,
			_draggingStartingPoint.x - point.x,
			_draggingStartingPoint.y - point.y);

		transform = CGAffineTransformRotate(
			transform,
			[gestureRecognizer rotation]);
		
		self.transform = transform;
	}

	if(gestureRecognizer.state == UIGestureRecognizerStateEnded ||
	   gestureRecognizer.state == UIGestureRecognizerStateFailed ||
	   gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
		id animations = ^() {
			self.transform = _draggingStartingTransform;
		};
		
		[UIView
			animateWithDuration:0.3
			delay:0.0
			options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
			animations:animations
			completion:nil];
	}
}

#pragma mark -
#pragma mark Private

- (BOOL)barsHidden {
	return _barsHidden;
}

- (void)setBarsHidden:(BOOL)barsHidden {
	[self setBarsHidden:barsHidden animated:NO];
}

- (void)setBarsHidden:(BOOL)barsHidden animated:(BOOL)animated {
	if(barsHidden != self.barsHidden) {
		_barsHidden = barsHidden;
		[self setNeedsLayout];
		
		UIStatusBarAnimation statusBarAnimation = animated ?
			UIStatusBarAnimationFade :
			UIStatusBarAnimationNone;
		[[UIApplication sharedApplication]
			setStatusBarHidden:barsHidden
			withAnimation:statusBarAnimation];
		
		if(animated) {
			CGFloat duration = 0.3;
			
			[UIView transitionWithView:self
				duration:duration
				options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction
				animations:^{
					[self layoutIfNeeded];
				} completion:^(BOOL finished) {
				}];
		}
	}
}

- (void)initIvars {
	self.opaque = YES;
	self.backgroundColor = [UIColor blackColor];
	
	self.interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
	
	self.barsHidden = YES;
	
	_needsToLoadImage = NO;
	_needsToUpdateZoomScales = NO;
	
	_previewScale = -1.0;
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(applicationDidChangeStatusBarFrame:)
		name:UIApplicationDidChangeStatusBarFrameNotification
		object:nil];
}

- (void)initScrollView {
	UIScrollView* scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
	
	scrollView.showsHorizontalScrollIndicator = NO;
	scrollView.showsVerticalScrollIndicator = NO;
	
	scrollView.bouncesZoom = YES;
	
	scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
	
	scrollView.opaque = self.opaque;
	scrollView.backgroundColor = self.backgroundColor;
	
	self.scrollView.clipsToBounds = NO; // needed for rotation gesture
	
//	scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;

	scrollView.delegate = self;
	
	self.scrollView = scrollView;
	[self addSubview:scrollView];
}

- (void)initImageView {
	UIImageView* imageView = [[UIImageView alloc] initWithImage:nil];
	
//	imageView.frame = CGRectZero;
//	imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;

	imageView.userInteractionEnabled = NO;

	self.imageView = imageView;
	[[self scrollView] addSubview:imageView];
}

- (void)initNavigationBar {
	UINavigationBar* navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectZero];
	
	navigationBar.barStyle = UIBarStyleBlack;
	navigationBar.translucent = YES;
	
	navigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
	
	navigationBar.delegate = self;
	
	self.navigationBar = navigationBar;
	[self insertSubview:navigationBar aboveSubview:[self scrollView]];
}

- (void)initToolbar {
	UIToolbar* toolbar = [[UIToolbar alloc] initWithFrame:CGRectZero];
	
	toolbar.barStyle = UIBarStyleBlack;
	toolbar.translucent = YES;
	
	toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin;
	
	toolbar.userInteractionEnabled = NO;
	
	self.toolbar = toolbar;
	[self insertSubview:toolbar aboveSubview:[self scrollView]];
}

- (void)initCaptionLabel {
	UILabel* captionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	
	captionLabel.textAlignment = NSTextAlignmentCenter;
	
	captionLabel.textColor = [UIColor whiteColor];
	captionLabel.font = [UIFont systemFontOfSize:14.0];
	
	captionLabel.backgroundColor = [UIColor clearColor];
	captionLabel.opaque = NO;
	
	captionLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
	captionLabel.shadowOffset = CGSizeMake(0.0, -1.0);
	
	captionLabel.numberOfLines = 0;
	
	self.captionLabel = captionLabel;
	[self insertSubview:captionLabel aboveSubview:[self toolbar]];
}

- (void)initProgressIndicator {
	AKLightboxProgressView* progressView = [[AKLightboxProgressView alloc] initWithFrame:CGRectZero];
	
	progressView.style = AKLightboxProgressViewStyleDetermined;
	progressView.progress = 0.0;
	
	progressView.hidden = YES;
	
	self.progressView = progressView;
	[self insertSubview:progressView belowSubview:[self toolbar]];
}

- (void)initGestureRecognizers {
	// Double tap to zoom
	UITapGestureRecognizer* doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] init];
	
	doubleTapGestureRecognizer.numberOfTapsRequired = 2;
	[doubleTapGestureRecognizer addTarget:self action:@selector(handleDoubleTapGesture:)];
	
	[[self scrollView] addGestureRecognizer:doubleTapGestureRecognizer];
	
	// Single tap to show/hide bars
	UITapGestureRecognizer* tapGestureRecognizer = [[UITapGestureRecognizer alloc] init];
	
	[tapGestureRecognizer addTarget:self action:@selector(handleTapGesture:)];
	[tapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
	
	[[self scrollView] addGestureRecognizer:tapGestureRecognizer];
	
//	// Rotate
//	UIRotationGestureRecognizer* rotationGestureRecognizer = [[[UIRotationGestureRecognizer alloc] init] autorelease];
//	
//	rotationGestureRecognizer.delegate = self;
//	[rotationGestureRecognizer addTarget:self action:@selector(handleRotationGesture:)];
//	
//	[[self scrollView] addGestureRecognizer:rotationGestureRecognizer];
}

- (void)layoutImageView {
	// Load the image if needed
	if(_needsToLoadImage) {
		[self loadImageWithURL:[self imageURL]];
	}
	
	// Adjust the zoom scales if needed
	if(_needsToUpdateZoomScales) {
		_needsToUpdateZoomScales = NO;
		
		UIScrollView* scrollView = self.scrollView;
		
		CGSize imageSize = self.previewSize;
		CGSize scrollViewSize = scrollView.bounds.size;
		
		CGFloat newScale = scrollView.zoomScale;
		
		if(scrollView.zoomScale == scrollView.minimumZoomScale) {
			CGFloat ratio = MIN(scrollViewSize.width, scrollViewSize.height) / MAX(scrollViewSize.width, scrollViewSize.height);
			newScale *= ratio;
		}
		
		CGFloat scaleX = scrollViewSize.width / imageSize.width;
		CGFloat scaleY = scrollViewSize.height / imageSize.height;
	
		CGFloat newMinimumScale = MIN(scaleX, scaleY);
		CGFloat newMaximumScale = MAX(newMinimumScale, 1.0);
	
//		NSLog(@"MIN(%f, %f) == %f", scaleX, scaleY, newMinimumScale);
	
		[scrollView setMinimumZoomScale:newMinimumScale];
		[scrollView setMaximumZoomScale:MAX(1.0, newMaximumScale)];
		[scrollView setZoomScale:newScale];
	}
	
	// Layout the image view
	if(!self.scrollView.zooming) {
		CGRect imageViewRect = self.imageView.frame;

		if(CGRectGetWidth(imageViewRect) < CGRectGetWidth(self.scrollView.bounds)) {
			imageViewRect.origin.x = (CGRectGetWidth(self.scrollView.bounds) - CGRectGetWidth(imageViewRect)) * 0.5;
		} else {
			imageViewRect.origin.x = 0.0;
		}
		
		if(CGRectGetHeight(imageViewRect) < CGRectGetHeight(self.scrollView.bounds)) {
			imageViewRect.origin.y = (CGRectGetHeight(self.scrollView.bounds) - CGRectGetHeight(imageViewRect)) * 0.5;
		} else {
			imageViewRect.origin.y = 0.0;
		}
		
		self.imageView.frame = imageViewRect;
	}
}

- (void)loadImageWithURL:(NSURL*)imageURL {
	// Load a preview image
	CGImageSourceRef imageSource = CGImageSourceCreateWithURL(
		(__bridge CFURLRef)imageURL,
		(CFDictionaryRef)NULL);

	NSDictionary* options = nil;
	
	if(self.imageContentType) {
		options = [NSDictionary dictionaryWithObjectsAndKeys:
			[self imageContentType], (id)kCGImageSourceTypeIdentifierHint,
			nil];
	}

	_imageProperties = (id)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(
		imageSource,
		0,
		(__bridge CFDictionaryRef)options));
	
	if(!_imageProperties) {
		NSLog(@"Could not retrieve properties for image %@", imageURL);
		
		if(imageSource) { CFRelease(imageSource); }
		
		return;
	}
		
	self.imageSize = CGSizeMake(
		[[[self imageProperties] objectForKey:(id)kCGImagePropertyPixelWidth] integerValue],
		[[[self imageProperties] objectForKey:(id)kCGImagePropertyPixelHeight] integerValue]);
	
	// Check if this is a animated GIF
	NSDictionary* GIFProperties = [[self imageProperties]
		objectForKey:(id)kCGImagePropertyGIFDictionary];
	
	if(GIFProperties) {
		[self loadAnimatedImage:imageSource];
	} else {
		[self loadRegularImage:imageSource];
	}
	
	_imageSource = imageSource;
	
	[[self imageView] sizeToFit];
	[self updateScrollViewContentSize];
	
	_needsToLoadImage = NO;
}

- (void)loadAnimatedImage:(CGImageSourceRef)imageSource {
	UIImageView* imageView = self.imageView;
		
	NSArray* frames = [self imagesForSource:imageSource];
	imageView.animationImages = frames;
	
	NSDictionary* GIFProperties = [[self imageProperties]
		objectForKey:(id)kCGImagePropertyGIFDictionary];
	float delay = [[GIFProperties objectForKey:(id)kCGImagePropertyGIFDelayTime] floatValue];
	
	if(delay > 0.0) {
		imageView.animationDuration += frames.count * delay;
	}

	[imageView sizeToFit];
	
	CGSize imageSize = imageView.bounds.size;
	self.previewSize = imageSize;
	
	[imageView startAnimating];
	
	imageView.backgroundColor = [UIColor whiteColor];
}

- (void)loadRegularImage:(CGImageSourceRef)imageSource {
	NSNumber* hasAlphaChannel = [[self imageProperties]
		objectForKey:(id)kCGImagePropertyHasAlpha];
		
	if([hasAlphaChannel boolValue]) {
		self.imageView.backgroundColor = [UIColor whiteColor];
	}
	
	// Create the preview image
	static CGFloat const maximumPreviewSize = 2048.0; // in pixel
	
	CGImageRef previewImage = NULL;
	
	if(self.imageSize.width > maximumPreviewSize ||
	   self.imageSize.height > maximumPreviewSize) {
		NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInteger:maximumPreviewSize], (id)kCGImageSourceThumbnailMaxPixelSize,
			kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageAlways,
			nil];
		previewImage = CGImageSourceCreateThumbnailAtIndex(
			imageSource,
			0,
			(__bridge CFDictionaryRef)options);
	} else {
		NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInteger:maximumPreviewSize], (id)kCGImageSourceThumbnailMaxPixelSize,
			nil];
		previewImage = CGImageSourceCreateImageAtIndex(
			imageSource,
			0,
			(__bridge CFDictionaryRef)options);
	}
	
	if(!previewImage) {
		NSLog(@"Invalid preview image: %@", [self imageURL]);
	}
	
	self.previewSize = CGSizeMake(
		CGImageGetWidth(previewImage),
		CGImageGetHeight(previewImage));
	
	self.imageView.image = [UIImage imageWithCGImage:previewImage];
	CGImageRelease(previewImage);
}

- (NSArray*)imagesForSource:(CGImageSourceRef)imageSource {
	NSInteger numberOfFrames = CGImageSourceGetCount(imageSource);
	NSMutableArray* frames = [NSMutableArray arrayWithCapacity:numberOfFrames];
		
	for(NSInteger frameIndex=0; frameIndex<numberOfFrames; ++frameIndex) {
		CGImageRef frameImage = CGImageSourceCreateImageAtIndex(
			imageSource,
			frameIndex,
			(CFDictionaryRef)NULL);
			
		[frames addObject:[UIImage imageWithCGImage:frameImage]];
			
		CGImageRelease(frameImage);
	}
	
	return frames;
}

- (void)updatePreviewImageIfNeeded {
}

- (void)updateScrollViewContentSize {
	UIScrollView* scrollView = self.scrollView;

	scrollView.contentSize = self.previewSize;
	
	CGSize imageSize = self.previewSize;
	CGSize scrollViewSize = scrollView.bounds.size;
	
	CGFloat scaleX = scrollViewSize.width / imageSize.width;
	CGFloat scaleY = scrollViewSize.height / imageSize.height;
	
	CGFloat newMinimumScale = MIN(scaleX, scaleY);
	CGFloat newMaximumScale = MAX(newMinimumScale, 1.0);
	
//	NSLog(@"MIN(%f, %f) == %f", scaleX, scaleY, newMinimumScale);
	
	[scrollView setMinimumZoomScale:newMinimumScale];
	[scrollView setMaximumZoomScale:MAX(1.0, newMaximumScale)];
	[scrollView setZoomScale:newMinimumScale];
}

- (CGFloat)preferredZoomScale {
	CGSize imageSize = self.previewSize;
	CGSize scrollViewSize = self.scrollView.bounds.size;
	
	CGFloat scaleX = scrollViewSize.width / imageSize.width;
	CGFloat scaleY = scrollViewSize.height / imageSize.height;
	
	CGFloat newMinimumScale = MIN(scaleX, scaleY);
	
	return newMinimumScale;

}

- (CGRect)zoomRectForScale:(CGFloat)scale withCenter:(CGPoint)center {
    CGRect scrollViewRect = self.scrollView.frame;
	CGRect zoomRect = CGRectZero;
    
    // the zoom rect is in the content view's coordinates. 
    //    At a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
    //    As the zoom scale decreases, so more content is visible, the size of the rect grows.
    zoomRect.size.height = CGRectGetHeight(scrollViewRect) / scale;
    zoomRect.size.width = CGRectGetWidth(scrollViewRect) / scale;
    
    // choose an origin so as to get the right center.
    zoomRect.origin.x = center.x - CGRectGetWidth(zoomRect) * 0.5;
    zoomRect.origin.y = center.y - CGRectGetHeight(zoomRect) * 0.5;
    
	return zoomRect;
}

- (void)applicationDidChangeStatusBarFrame:(NSNotification*)notification {
	CGRect newStatusBarFrame = [[[notification userInfo] objectForKey:UIApplicationStatusBarFrameUserInfoKey] CGRectValue];
	
	if(CGRectGetWidth(newStatusBarFrame) == CGRectGetWidth([self statusBarFrame])) {
		[self setNeedsLayout];
	}
}

@end
