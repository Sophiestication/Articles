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

#import "SAReadLaterTableViewCellContentView.h"

@implementation SAReadLaterTableViewCellContentView

@dynamic text;
@dynamic markedTextRange;
@synthesize highlighted = _highlighted;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
		self.opaque = YES;
		self.backgroundColor = [UIColor whiteColor];
		self.contentMode = UIViewContentModeRedraw;
		self.highlighted = NO;
		self.clipsToBounds = NO;
		
		self.text = @"";
		self.markedTextRange = NSMakeRange(0, 0);
	}

    return self;
}

- (void)dealloc {
	self.text = nil;
	
	if(_frame) { CFRelease(_frame); }
	if(_framesetter) { CFRelease(_framesetter); }

}

#pragma mark -
#pragma mark SAReadLaterTableViewCellContentView

- (NSString*)text {
	return _text;
}

- (void)setText:(NSString*)text {
	if(_text != text) {
		_text = text;
		
		if(_framesetter) { CFRelease(_framesetter), _framesetter = NULL; }
		if(_frame) { CFRelease(_frame), _frame = NULL; }
		
		[self setNeedsDisplay];
	}
}

- (NSRange)markedTextRange {
	return _markedTextRange;
}

- (void)setMarkedTextRange:(NSRange)markedTextRange {
	_markedTextRange = markedTextRange;
	
	if(_framesetter) { CFRelease(_framesetter), _framesetter = NULL; }
	if(_frame) { CFRelease(_frame), _frame = NULL; }
	
	[self setNeedsDisplay];
}

- (BOOL)isHighlighted {
	return _highlighted;
}

- (void)setHighlighted:(BOOL)highlighted {
	if(highlighted != self.highlighted) {
		_highlighted = highlighted;
		
		self.opaque = !highlighted;
		self.backgroundColor = highlighted ?
			[UIColor clearColor] :
			[UIColor whiteColor];
		
		if(_framesetter) { CFRelease(_framesetter), _framesetter = NULL; }
		if(_frame) { CFRelease(_frame), _frame = NULL; }

		[self setNeedsDisplay];
	}
}

#pragma mark -
#pragma mark UIView

- (void)setFrame:(CGRect)frame {
	if(!CGRectEqualToRect(frame, [self frame])) {
		[super setFrame:frame];
		
		if(_frame) { CFRelease(_frame), _frame = NULL; }
		[self setNeedsDisplay];
	}
}

- (CGSize)sizeThatFits:(CGSize)size {
	CGSize textSize = CGSizeMake(size.width - 20.0, size.height);
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, CGRectMake(0.0, 0.0, textSize.width, textSize.height));
	
	CTFrameRef frame = CTFramesetterCreateFrame( 
		[self reuseableFramesetter],
		CFRangeMake(0, [[self text] length]),
		path,
		NULL);

	CGRect frameRect = [self boundingRectForFrame:frame];
	
	CFRelease(path);
	CFRelease(frame);
		
	return CGSizeMake(size.width, CGRectGetHeight(frameRect) + 20.0);
}

- (void)drawRect:(CGRect)rect {
	[[self backgroundColor] set];
	UIRectFill(rect);

	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	CGContextTranslateCTM(context, 0.0, CGRectGetHeight([self bounds]) + 10.0);
	CGContextScaleCTM(context, 1.0, -1.0);

	CGContextSetTextPosition(context, 0.0, 0.0);
	
	// Draw the marker rects
	if(!self.highlighted) {
		NSArray* markerRects = [self boundingRectsForRange:[self markedTextRange] inFrame:[self reuseableFrame]];

		for(NSValue* markerRectValue in markerRects) {
			CGRect markerRect = [markerRectValue CGRectValue];
			//markerRect = CGRectInset(markerRect, -4.0, 0.0);
			
			BOOL lastMarker = markerRectValue == [markerRects lastObject];
			UIImage* markerImage = [self markerImageForRect:markerRect lastMarker:lastMarker];
			
			const CGFloat padding = 4.0;
			
			CGRect markerImageRect = CGRectMake(
				floorf(CGRectGetMinX(markerRect) - padding),
				floorf(CGRectGetMidY(markerRect) - markerImage.size.height * 0.5),
				ceilf(CGRectGetWidth(markerRect) + padding * 3.0),
				ceilf(markerImage.size.height));
			
//			if(CGRectGetMinX(markerImageRect) < 0) {
//				markerImageRect.origin.x = 0.0;
//				markerImageRect.size.width -= padding;
//			}
				
			[markerImage drawInRect:markerImageRect];
		}
	}

	// Now the text content
	CTFrameDraw([self reuseableFrame], context);
}

#pragma mark -
#pragma mark Private

- (CTFramesetterRef)reuseableFramesetter {
	if(!_framesetter) {
		NSAttributedString* string = [self newAttributedString];
		_framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)string);
		
	}
	
	return _framesetter;
}

- (CTFrameRef)reuseableFrame {
	if(!_frame) {
		CGRect textRect = CGRectInset([self bounds], 10.0, 0.0);
		
		CGMutablePathRef path = CGPathCreateMutable();
		CGPathAddRect(path, NULL, textRect);
	
		_frame = CTFramesetterCreateFrame( 
			[self reuseableFramesetter],
			CFRangeMake(0, [[self text] length]),
			path,
			NULL);
			
		CFRelease(path);
	}
	
	return _frame;
}

- (NSAttributedString*)newAttributedString {
	CTFontRef font = [self newFont];
	CTParagraphStyleRef paragraphStyle = [self newParagraphStyle];
	
	UIColor* textColor = self.highlighted ?
		[UIColor whiteColor] :
		[UIColor darkTextColor];
	
	NSDictionary* textStyle = [NSDictionary dictionaryWithObjectsAndKeys:
		(__bridge id)font, kCTFontAttributeName,
		(__bridge id)paragraphStyle, kCTParagraphStyleAttributeName,
		[textColor CGColor], kCTForegroundColorAttributeName,
		nil];
	
	CFRelease(font);
	CFRelease(paragraphStyle);
	
	NSString* string = [self text];
	NSMutableAttributedString* attributedString = [[NSMutableAttributedString alloc] initWithString:string attributes:textStyle];

	NSRange markedTextRange = self.markedTextRange;

	if(markedTextRange.length > 0 && markedTextRange.location + markedTextRange.length < string.length) {
		UIColor* markerColor = self.highlighted ?
			[UIColor whiteColor] :
			[UIColor darkTextColor]; // [UIColor colorWithRed:0.256 green:0.381 blue:0.609 alpha:1.0];
		
		NSDictionary* markedTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
			(id)[markerColor CGColor], kCTForegroundColorAttributeName,
//			(id)[NSNumber numberWithInteger:2.0], kCTUnderlineStyleAttributeName, // for easier debugging
			nil];
		[attributedString addAttributes:markedTextAttributes range:markedTextRange];
	}

	return attributedString;
}

- (CTFontRef)newFont {
	CTFontRef font = CTFontCreateWithName((CFStringRef)@"Georgia", 15.0, NULL);
	
	if(!font) {
		font = CTFontCreateWithName((CFStringRef)@"Helvetica", 14.0, NULL);
	}
	
	return font;
}

- (CTParagraphStyleRef)newParagraphStyle {
	static const CFIndex numberOfSettings = 6;

	CTLineBreakMode lineBreakMode = kCTLineBreakByWordWrapping;
	CTTextAlignment textAlignment = kCTNaturalTextAlignment;
	CGFloat indent = 0.0;
	CGFloat spacing = 0.0;
	CGFloat topSpacing = 0.0;
	CGFloat lineSpacing = 4.0;

	CTParagraphStyleSetting settings[6] = {
		{ kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), &textAlignment },
		{ kCTParagraphStyleSpecifierLineBreakMode, sizeof(CTLineBreakMode), &lineBreakMode },
		{ kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(CGFloat), &indent },
		{ kCTParagraphStyleSpecifierParagraphSpacing, sizeof(CGFloat), &spacing },
		{ kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(CGFloat), &topSpacing },
		{ kCTParagraphStyleSpecifierLineSpacing, sizeof(CGFloat), &lineSpacing }
	};
	
	CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings, numberOfSettings);
	
	return paragraphStyle;
}

- (CGRect)boundingRectForFrame:(CTFrameRef)frame {
    BOOL includeTrailingWhitespace = YES;
	
	CFArrayRef lines = CTFrameGetLines(frame);
    CFIndex lineCount = CFArrayGetCount(lines);
    
    if (lineCount > 0) {
        CGPoint lineOrigins[lineCount];
        CTFrameGetLineOrigins(frame, CFRangeMake(0, lineCount), lineOrigins);
        
        CGFloat minX, maxX, minY, maxY;
        CGFloat ascent, descent;
        double width;
        
        CTLineRef line = CFArrayGetValueAtIndex(lines, 0);
        minX = lineOrigins[0].x;
        width = CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
        maxX = minX + ( includeTrailingWhitespace? width : width - CTLineGetTrailingWhitespaceWidth(line));
        maxY = lineOrigins[0].y + ascent;
        minY = lineOrigins[0].y - descent;
        
        for (CFIndex lineIndex = 1; lineIndex < lineCount; lineIndex++) {
            CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
            width = CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
            CGPoint lineOrigin = lineOrigins[lineIndex];
            if (lineOrigin.x < minX)
                minX = lineOrigin.x;
            if (lineOrigin.x + width > maxX) {
                if (!includeTrailingWhitespace)
                    width -= CTLineGetTrailingWhitespaceWidth(line);
                CGFloat thisMaxX = lineOrigin.x + width;
                if (thisMaxX > maxX)
                    maxX = thisMaxX;
            }
            
            if (lineOrigins[lineIndex].y + ascent > maxY)
                maxY = lineOrigins[lineIndex].y + ascent;
            if (lineOrigins[lineIndex].y - descent < minY)
                minY = lineOrigins[lineIndex].y - descent;
        }

        return (CGRect){
            { minX, minY },
            { MAX(0, maxX - minX), MAX(0, maxY - minY) }
        };
    } else {
        return CGRectNull;
    }
}

- (NSArray*)boundingRectsForRange2:(NSRange)range inFrame:(CTFrameRef)frame {
	CFArrayRef lines = CTFrameGetLines(frame);
	CFIndex numberOfLines = CFArrayGetCount(lines);
    
	NSMutableArray* rects = [NSMutableArray array];

	if(numberOfLines > 0) {
		CGPoint lineOrigins[numberOfLines];
		CTFrameGetLineOrigins(frame, CFRangeMake(0, numberOfLines), lineOrigins);

		for(CFIndex lineIndex=0; lineIndex<numberOfLines; ++lineIndex) {
			CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
			
			CFArrayRef glyphRuns = CTLineGetGlyphRuns(line);
			CFIndex numberOfGlyphRuns = CFArrayGetCount(glyphRuns);
			
			for(CFIndex glyphRunIndex=0; glyphRunIndex<numberOfGlyphRuns; ++glyphRunIndex) {
				CTRunRef glyphRun = CFArrayGetValueAtIndex(glyphRuns, glyphRunIndex);
				
				CFRange runRange = CTRunGetStringRange(glyphRun);
				
				if(NSLocationInRange(runRange.location, range)) {
//					CFRange intersectionRange = CFRangeMake(
//						MAX(range.location, runRange.location),
//						MIN(range.length, runRange.length));
//					
//					intersectionRange.location = 0; // TODO?
					
					CFRange intersectionRange = CFRangeMake(0, 0);
					
					CGRect rect = CTRunGetImageBounds(glyphRun, UIGraphicsGetCurrentContext(), intersectionRange);
					
					if(NSClassFromString(@"UIDocument")) {
						CGFloat offset = CTLineGetOffsetForStringIndex(line, runRange.location, NULL);
						rect.origin.x += offset;
					}
					
					rect.origin.x += 10.0; // padding
					rect.origin.y += lineOrigins[lineIndex].y;
					
					[rects addObject:[NSValue valueWithCGRect:rect]];
				}
			}
		}
	}
	
	return rects;
}

- (NSArray*)boundingRectsForRange:(NSRange)range inFrame:(CTFrameRef)frame {
	NSMutableArray* boundingRects = [NSMutableArray arrayWithCapacity:2];

	NSArray* lines = (__bridge NSArray*)CTFrameGetLines(frame);

	CGPoint origins[[lines count]]; // the origins of each line at the baseline
	CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), origins);

	NSUInteger lineIndex = 0;

	for(id lineObj in lines) {
    	CTLineRef line = (__bridge CTLineRef)lineObj;

    	for(id runObj in (__bridge NSArray *)CTLineGetGlyphRuns(line)) {
        	CTRunRef run = (__bridge CTRunRef)runObj;
        	CFRange runRange = CTRunGetStringRange(run);

			NSRange intersectionRange = NSIntersectionRange(NSMakeRange(runRange.location, runRange.length), range);
			if(intersectionRange.length == 0) { continue; }

			CGRect runBounds;

        	CGFloat ascent; // height above the baseline
        	CGFloat descent; // height below the baseline
        	runBounds.size.width = CTRunGetTypographicBounds(run, CFRangeMake(intersectionRange.location - runRange.location, intersectionRange.length), &ascent, &descent, NULL);
        	runBounds.size.height = ascent + descent;

			CGRect rect = CGRectZero;

			CFIndex stringIndex = intersectionRange.location + 1;

        	CGFloat xOffset = CTLineGetOffsetForStringIndex(line, stringIndex, NULL);
        	runBounds.origin.x = origins[lineIndex].x + rect.origin.x + xOffset;
        	runBounds.origin.y = origins[lineIndex].y + rect.origin.y;
        	runBounds.origin.y -= descent;

			[boundingRects addObject:[NSValue valueWithCGRect:runBounds]];
		}

		lineIndex++;
	}

	return boundingRects;
}

- (UIImage*)markerImageForRect:(CGRect)rect lastMarker:(BOOL)lastMarker {
	UIImage* image = nil;
	
	CGFloat width = CGRectGetWidth(rect);
	
	if(width >= 277.0) {
		image = lastMarker ?
			[UIImage imageNamed:@"hiliter_yellow1a-iPhone.png"] :
			[UIImage imageNamed:@"hiliter_yellow1b-iPhone.png"];
	} else if(width >= 182.0) {
		image = lastMarker ?
			[UIImage imageNamed:@"hiliter_yellow2a-iPhone.png"] :
			[UIImage imageNamed:@"hiliter_yellow2b-iPhone.png"];
	} else if(width >= 96.0) {
		image = lastMarker ?
			[UIImage imageNamed:@"hiliter_yellow3a-iPhone.png"] :
			[UIImage imageNamed:@"hiliter_yellow3b-iPhone.png"];
	} else {
		image = lastMarker ?
			[UIImage imageNamed:@"hiliter_yellow4a-iPhone.png"] :
			[UIImage imageNamed:@"hiliter_yellow4b-iPhone.png"];
	}
	
	return image;
}

@end
