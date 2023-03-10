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

#import "AKLockOrientationView.h"
#import "AKLockOrientationView+Private.h"

#import "AKArticleView.h"
#import	"AKArticleView+Private.h"

#import "AKLockOrientationArrowView.h"

#import "AudioFX.h"

@implementation AKLockOrientationView

#pragma mark - Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
		[self initIvars];
		[self initSubviews];
	}

    return self;
}

- (void)dealloc {
	self.articleView = nil;
}

#pragma mark -
#pragma mark UIView

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect bounds = self.bounds;
	
	CGSize backgroundSize = [[self backgroundView]
		sizeThatFits:bounds.size];
	CGRect backgroundRect = CGRectMake(
		CGRectGetMinX(bounds),
		CGRectGetMaxY(bounds) - backgroundSize.height,
		backgroundSize.width,
		backgroundSize.height);
	self.backgroundView.frame = backgroundRect;
	
	CGSize arrowViewSize = [[self arrowView]
		sizeThatFits:CGSizeMake(NSIntegerMax, NSIntegerMax)];
	CGSize lockViewSize = [[self lockView]
		sizeThatFits:CGSizeMake(NSIntegerMax, NSIntegerMax)];

	CGSize textLabelSize = [[self textLabel]
		sizeThatFits:bounds.size];
		
	CGRect arrowViewRect = CGRectMake(
		CGRectGetMinX(bounds) + 10.0,
		CGRectGetMaxY(bounds) - arrowViewSize.height - 10.0,
		arrowViewSize.width,
		arrowViewSize.height);
	
	CGRect lockViewRect = CGRectMake(
		CGRectGetMaxX(arrowViewRect) - lockViewSize.width + 7.0,
		CGRectGetMaxY(arrowViewRect) - lockViewSize.height - 5.0,
		lockViewSize.width,
		lockViewSize.height);
		
	CGRect textLabelRect = CGRectMake(
		CGRectGetMaxX(lockViewRect) + 10.0,
		floorf(CGRectGetMidY(arrowViewRect) - textLabelSize.height * 0.5),
		CGRectGetWidth(bounds) - CGRectGetMaxX(lockViewRect) - 10.0,
		textLabelSize.height);
		
	self.arrowView.frame = arrowViewRect;
	self.lockView.frame = lockViewRect;
	self.textLabel.frame = textLabelRect;
	
	self.lockView.alpha = self.orientationLocked ? 1.0 : 0.0;
}

#pragma mark -
#pragma mark AKLockOrientationArrowViewDelegate

- (void)lockOrientationArrowView:(AKLockOrientationArrowView*)arrowView didChangeOrientation:(BOOL)pointingDown {
	[self updateTextLabels];
	
	_pulledDown = !pointingDown;
}

#pragma mark - Private

- (void)initIvars {
	self.userInteractionEnabled = NO;

//	self.opaque = YES;
//	self.backgroundColor = [UIColor colorWithRed:0.369 green:0.451 blue:0.565 alpha:1.000];
	
	self.opaque = NO;
	self.backgroundColor = [UIColor clearColor];
	
	_pulledDown = NO;
	_tracking = YES;

	self.orientationLocked = [[NSUserDefaults standardUserDefaults] objectForKey:@"AKPreferredInterfaceOrientation"] != nil;
}

- (void)initSubviews {
	// Init the arrow view
	AKLockOrientationArrowView* arrowView = [[AKLockOrientationArrowView alloc] initWithFrame:CGRectZero];
	
	arrowView.opaque = YES;
	arrowView.backgroundColor = self.backgroundColor;
	
	arrowView.contentMode = UIViewContentModeScaleAspectFit;
	arrowView.delegate = self;
	
//	[self insertSubview:arrowView aboveSubview:backgroundView];
	[self addSubview:arrowView];
	self.arrowView = arrowView;
	
	// Init the lock view
	UIImage* lockImage = [UIImage imageNamed:@"lockOrientation.png"];
	UIImageView* lockView = [[UIImageView alloc] initWithImage:lockImage];
	
	lockView.contentMode = UIViewContentModeScaleAspectFit;
	
	[self insertSubview:lockView aboveSubview:arrowView];
	self.lockView = lockView;
	
	// Init the text label
	UILabel* textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	
	textLabel.opaque = NO;
	textLabel.backgroundColor = [UIColor clearColor];
	
	textLabel.opaque = YES;
	textLabel.backgroundColor = self.backgroundColor;
	
	textLabel.font = [UIFont boldSystemFontOfSize:14.0]; //15.0];
	textLabel.textColor = [UIColor whiteColor];
	
	textLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
	textLabel.shadowOffset = CGSizeMake(0.0, -1.0);
	
	textLabel.textAlignment = NSTextAlignmentLeft;
	
	textLabel.numberOfLines = 2;
	textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
	
//	[self insertSubview:textLabel aboveSubview:backgroundView];
	[self addSubview:textLabel];
	self.textLabel = textLabel;
	
	[self updateTextLabels];
}

- (void)updateForContentSize:(CGSize)contentSize animated:(BOOL)animated {
	if(!self.articleView.webCustomizer.scrollView.dragging) {
		if(contentSize.height <= 1.0) {
			self.textLabel.text = self.orientationLocked ?
				NSLocalizedString(@"AKPullDownToUnlock", @"") :
				NSLocalizedString(@"AKPullDownToLock", @"");
			[[self arrowView] pointDownwardAnimated:NO];
		}
	
		return;
	}

	if(contentSize.height <= [self pullDownHeight]) {
		[[self arrowView] pointDownwardAnimated:animated];
	} else {
		[[self arrowView] pointUpwardAnimated:animated];
	}
}

- (void)updateTextLabels {
	if(self.arrowView.pointingDown) {
		if(self.articleView.webCustomizer.scrollView.dragging || !self.textLabel.text) {
			self.textLabel.text = self.orientationLocked ?
				NSLocalizedString(@"AKPullDownToUnlock", @"") :
				NSLocalizedString(@"AKPullDownToLock", @"");
		}
	} else {
		self.textLabel.text = self.orientationLocked ?
			NSLocalizedString(@"AKReleaseToUnlock", @"") :
			NSLocalizedString(@"AKReleaseToLock", @"");
	}
	
	[self setNeedsLayout];
}

- (void)playSoundNamed:(NSString*)soundName {
	NSString* soundFile = [[NSBundle bundleForClass:[self class]]
		pathForResource:soundName ofType:@"wav"];

	[AudioFX playAtPath:soundFile];
}

- (void)webView:(UIWebView*)webView didEndScrollingAtOffset:(CGPoint)contentOffset {
	_tracking = NO;
	
	if(-contentOffset.y >= [self pullDownHeight] && _pulledDown) {
		self.orientationLocked = !self.orientationLocked;
		
		if(self.orientationLocked) {
			[self playSoundNamed:@"lock"];
		} else {
			[self playSoundNamed:@"unlock"];
		}
		
		// ...
		NSNumber* preferredInterfaceOrientations = [[NSUserDefaults standardUserDefaults] objectForKey:@"AKPreferredInterfaceOrientation"];

		if(preferredInterfaceOrientations) {
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"AKPreferredInterfaceOrientation"];
		} else {
			UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
			[[NSUserDefaults standardUserDefaults] setObject:@(interfaceOrientation) forKey:@"AKPreferredInterfaceOrientation"];
		}

		if([UIViewController respondsToSelector:@selector(attemptRotationToDeviceOrientation)]) {
			[UIViewController attemptRotationToDeviceOrientation];
		}
	}
	
	_pulledDown = NO;
}

- (CGFloat)pullDownHeight {
	CGFloat pullDownHeight = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ?
		90.0 :
		60.0;
	
	pullDownHeight += self.articleView.contentInset.top;
	
	return pullDownHeight;
}

@end
