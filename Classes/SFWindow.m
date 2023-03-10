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

#import "SFWindow.h"

@interface SFWindow()

@property(nonatomic, strong) UIImageView* topLeftBlinderView;
@property(nonatomic, strong) UIImageView* topRightBlinderView;
@property(nonatomic, strong) UIImageView* bottomLeftBlinderView;
@property(nonatomic, strong) UIImageView* bottomRightBlinderView;

@end

@implementation SFWindow

#pragma mark - Blinder Support

@synthesize blinderVisible = _blinderVisible;
@synthesize topLeftBlinderView = _topLeftBlinderView;
@synthesize topRightBlinderView = _topRightBlinderView;
@synthesize bottomLeftBlinderView = _bottomLeftBlinderView;
@synthesize bottomRightBlinderView = _bottomRightBlinderView;

- (void)setBlinderVisible:(BOOL)blinderVisible {
    [self setBlinderVisible:blinderVisible animated:NO];
}

- (void)setBlinderVisible:(BOOL)blinderVisible animated:(BOOL)animated {
    if(self.blinderVisible == blinderVisible) { return; }

    if(blinderVisible) {
        [self initBlinderViewsIfNeeded];
    }

    _blinderVisible = blinderVisible;
    [self setNeedsLayout];

    if(animated) {
        [UIView
            animateWithDuration:UINavigationControllerHideShowBarDuration
            animations:^() { [self layoutIfNeeded]; }
            completion:nil];
    }
}

- (void)initBlinderViewsIfNeeded {
    if(self.bottomLeftBlinderView) { return; }
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { return; } // no blinders needed

    UIImage* blinderImage = [UIImage imageNamed:@"corner-blinder"];

    CGImageRef blinderImageRef = [blinderImage CGImage];
    CGFloat blinderImageScale = [blinderImage scale];

    // bottom left blinder
    self.bottomLeftBlinderView = [[UIImageView alloc] initWithImage:blinderImage];

    // bottom right blinder (flipped left blinder)
    UIImage* bottomRightBlinderImage = [UIImage imageWithCGImage:blinderImageRef scale:blinderImageScale orientation:UIImageOrientationUpMirrored];

    self.bottomRightBlinderView = [[UIImageView alloc] initWithImage:bottomRightBlinderImage];

    // top left blinder (flipped left blinder)
    UIImage* topLeftBlinderImage = [UIImage imageWithCGImage:blinderImageRef scale:blinderImageScale orientation:UIImageOrientationRight];

    self.topLeftBlinderView = [[UIImageView alloc] initWithImage:topLeftBlinderImage];

    // top left blinder (flipped left blinder)
    UIImage* topRightBlinderImage = [UIImage imageWithCGImage:blinderImageRef scale:blinderImageScale orientation:UIImageOrientationDown];
    self.topRightBlinderView = [[UIImageView alloc] initWithImage:topRightBlinderImage];

    // self.topLeftBlinderView.backgroundColor = self.topRightBlinderView.backgroundColor = self.bottomLeftBlinderView.backgroundColor = self.bottomRightBlinderView.backgroundColor = [UIColor redColor];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutBlinderViews];
}

- (void)layoutBlinderViews {
    CGRect contentRect = self.bounds;
    CGRect statusBarRect = [[UIApplication sharedApplication] statusBarFrame];

    // bottom left
    CGRect bottomLeftBlinderViewRect = self.bottomLeftBlinderView.frame;
    bottomLeftBlinderViewRect.origin.x = CGRectGetMinX(contentRect);
    bottomLeftBlinderViewRect.origin.y = CGRectGetMaxY(contentRect) - CGRectGetHeight(bottomLeftBlinderViewRect);
    self.bottomLeftBlinderView.frame = bottomLeftBlinderViewRect;

    // bottom right
    CGRect bottomRightBlinderViewRect = self.bottomRightBlinderView.frame;
    bottomRightBlinderViewRect.origin.x = CGRectGetMaxX(contentRect) - CGRectGetWidth(bottomRightBlinderViewRect);
    bottomRightBlinderViewRect.origin.y = CGRectGetMaxY(contentRect) - CGRectGetHeight(bottomRightBlinderViewRect);
    self.bottomRightBlinderView.frame = bottomRightBlinderViewRect;

    // top left
    CGRect topLeftBlinderViewRect = self.topLeftBlinderView.frame;
    topLeftBlinderViewRect.origin.x = CGRectGetMinX(contentRect);
    topLeftBlinderViewRect.origin.y = CGRectGetMaxY(statusBarRect);
    self.topLeftBlinderView.frame = topLeftBlinderViewRect;

    // top right
    CGRect topRightBlinderViewRect = self.topRightBlinderView.frame;
    topRightBlinderViewRect.origin.x = CGRectGetMaxX(contentRect) - CGRectGetWidth(topRightBlinderViewRect);
    topRightBlinderViewRect.origin.y = CGRectGetMaxY(statusBarRect);
    self.topRightBlinderView.frame = topRightBlinderViewRect;

    CGFloat blinderAlpha = self.blinderVisible ? 1.0 : 0.0;
    self.topLeftBlinderView.alpha = self.topRightBlinderView.alpha = /*self.bottomLeftBlinderView.alpha = self.bottomRightBlinderView.alpha =*/ blinderAlpha;

    // hierarchy
    UIView* rootView = self.rootViewController.view;

    [self insertSubview:[self topLeftBlinderView] aboveSubview:rootView];
    [self insertSubview:[self topRightBlinderView] aboveSubview:rootView];
    [self insertSubview:[self bottomLeftBlinderView] aboveSubview:rootView];
    [self insertSubview:[self bottomRightBlinderView] aboveSubview:rootView];

    [self bringSubviewToFront:[self topLeftBlinderView]];
}

@end
