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

#import "SFBadgedTableViewCell.h"

@implementation SFBadgedTableViewCell

@synthesize badgeAccessoryView = _badgeAccessoryView;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier {
    if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
		// Init the badge accessory view
		SFBadgeAccessoryView* badgeAccessoryView = [[SFBadgeAccessoryView alloc] initWithFrame:CGRectZero];
		[[self contentView] addSubview:badgeAccessoryView];
		_badgeAccessoryView = badgeAccessoryView;
	}

    return self;
}

- (void)dealloc {
	_badgeAccessoryView = nil;
}

#pragma mark -
#pragma mark UIView

- (void)layoutSubviews {
	[super layoutSubviews];

	// Are we currently editing?
	BOOL showsBadgeAccessoryView = !self.editing; //  || self.editingAccessoryType == UITableViewCellAccessoryNone;
	
	// Layout the badge accessory view
	CGRect contentRect = self.contentView.bounds;
	
	SFBadgeAccessoryView* badgeAccessoryView = self.badgeAccessoryView;

	CGSize badgeAccessorySize = [badgeAccessoryView sizeThatFits:contentRect.size];
	CGRect badgeAccessoryRect = CGRectMake(
		CGRectGetMaxX(contentRect) - badgeAccessorySize.width - 10.0, ceilf(CGRectGetMidY(contentRect) - badgeAccessorySize.height * 0.5),
		badgeAccessorySize.width, badgeAccessorySize.height);
	badgeAccessoryView.frame = badgeAccessoryRect;
	
	// We show/hide by altering the view's alpha value
	badgeAccessoryView.alpha = showsBadgeAccessoryView ? 1.0 : 0.0;

	// Adjust the text and detail text labels if needed
	if(showsBadgeAccessoryView) {
		CGRect textRect = self.textLabel.frame;
		CGRect intersection = CGRectIntersection(textRect, badgeAccessoryRect);
			
		if(CGRectGetWidth(intersection) > 0.0) {
			textRect.size.width = CGRectGetMinX(intersection) - CGRectGetMinX(textRect);
		}
		
		self.textLabel.frame = textRect;
		
		// Now the detail text label
		textRect = self.detailTextLabel.frame;
		intersection = CGRectIntersection(textRect, badgeAccessoryRect);
			
		if(CGRectGetWidth(intersection) > 0.0) {
			textRect.size.width = CGRectGetMinX(intersection) - CGRectGetMinX(textRect);
		}
		
		self.detailTextLabel.frame = textRect;
	}
	
	// Make sure that the badge view is always on top
	[[self contentView] bringSubviewToFront:badgeAccessoryView];
}

@end
