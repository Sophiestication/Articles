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

#import "SFTableViewController.h"

@implementation SFTableViewController

@dynamic placeholderView;
@dynamic showsPlaceholderView;

#pragma mark -
#pragma mark Construction & Destruction

- (void)dealloc {
    _placeholderView = nil;
	_tableView2 = nil;
	
}

#pragma mark -
#pragma mark TableViewController

- (SFPlaceholderView*)placeholderView {
	if(!_placeholderView) {
		_placeholderView = [[SFPlaceholderView alloc] initWithFrame:CGRectZero];
	}
	
	return _placeholderView;
}

- (BOOL)showsPlaceholderView {
	return _placeholderView && self.view == _placeholderView; //_placeholderView != nil && !_placeholderView.hidden;
}

- (void)setShowsPlaceholderView:(BOOL)showsPlaceholderView {
	[self setShowsPlaceholderView:showsPlaceholderView animated:NO];
}

- (void)setShowsPlaceholderView:(BOOL)showsPlaceholderView animated:(BOOL)animated {
	if(self.showsPlaceholderView != showsPlaceholderView) {
		SFPlaceholderView* placeholderView = nil;
		
		if(showsPlaceholderView) {
			placeholderView = self.placeholderView;

			placeholderView.frame = self.tableView.frame;
			[placeholderView setNeedsLayout];

			[self placeholderView:placeholderView willAppearAnimated:animated];
		}

		if(animated) {
			// TODO
		}
		
		if(showsPlaceholderView) {
			_tableView2 = [self tableView];
			self.view = placeholderView;
		} else {
			if(_tableView2) {
				self.view = _tableView2;
				_tableView2 = nil;
			}
		}
		
		if(animated) {
			// TODO
		}
	}
}

- (void)placeholderView:(SFPlaceholderView*)placeholderView willAppearAnimated:(BOOL)animated {
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	
	_placeholderView = nil;
}

@end
