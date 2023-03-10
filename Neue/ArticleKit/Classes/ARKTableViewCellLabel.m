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

#import "ARKTableViewCellLabel.h"

@interface ARKTableViewCellLabel()

@property(nonatomic, copy) NSAttributedString* highlightedAttributedText;
@property(nonatomic) BOOL shouldHyphenate;

@end

@implementation ARKTableViewCellLabel

#pragma mark - Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
		self.contentMode = UIViewContentModeRedraw;
		self.backgroundColor = [UIColor whiteColor];

		NSUInteger majorVersionNumber = [[[UIDevice currentDevice] systemVersion] integerValue];
		self.shouldHyphenate = majorVersionNumber < 7;
    }

    return self;
}

#pragma mark - ARKTableViewCellLabel

- (void)setAttributedText:(NSAttributedString*)attributedText {
	if([[self attributedText] isEqualToAttributedString:attributedText]) { return; }

	_attributedText = [[self applyDefaultStylesToAttributedString:attributedText] copy];
	self.highlightedAttributedText = nil;

	[self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)highlighted {
	if(self.highlighted == highlighted) { return; }

	_highlighted = highlighted;
	[self setNeedsDisplay];
}

#pragma mark - UIView

- (CGSize)sizeThatFits:(CGSize)size {
	return size;
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];

	NSAttributedString* attributedText = self.attributedText;

	if(self.highlighted) {
		[self updateHighlightedAttributedTextIfNeeded];
		attributedText = self.highlightedAttributedText;
	}

	CGRect contentRect = self.bounds;
	[attributedText drawInRect:contentRect];
}

#pragma mark - Private

- (NSAttributedString*)applyDefaultStylesToAttributedString:(NSAttributedString*)attributedString {
	if(!attributedString) { return nil; }

	NSMutableAttributedString* newAttributedString = [attributedString mutableCopy];

	// set a hyphenation factor if needed
	NSMutableParagraphStyle* paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	paragraphStyle.hyphenationFactor = self.shouldHyphenate ? 1.0 : 0.0;
	paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;

	NSDictionary* attributes = @{
		NSParagraphStyleAttributeName: paragraphStyle,
		NSForegroundColorAttributeName: [UIColor grayColor] };

	[newAttributedString addAttributes:attributes range:NSMakeRange(0, [newAttributedString length])];

	return newAttributedString;
}

- (void)updateHighlightedAttributedTextIfNeeded {
	if(self.highlightedAttributedText) { return; }

	NSMutableAttributedString* highlightedAttributedText = [[self attributedText] mutableCopy];

	[highlightedAttributedText
		addAttribute:NSForegroundColorAttributeName
		value:[[UIColor whiteColor] colorWithAlphaComponent:0.75]
		range:NSMakeRange(0, [highlightedAttributedText length])];

	self.highlightedAttributedText = highlightedAttributedText;
}

@end
