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

#import "WIKImage.h"
#import "WIKImageRepresentation.h"

#import "NSString+Additions.h"

@interface WIKImage()

@property(nonatomic, copy) NSString* name;
@property(nonatomic, strong) WIKImageRepresentation* representation;
@property(nonatomic, strong) WIKImageRepresentation* thumbnailRepresentation;

@end

@implementation WIKImage

#pragma mark - Construction & Destruction

- (id)initWithName:(NSString*)name representation:(WIKImageRepresentation*)representation thumbnailRepresentation:(WIKImageRepresentation*)thumbnailRepresentation {
	if((self = [super init])) {
		self.name = name;
		self.representation = representation;
		self.thumbnailRepresentation = thumbnailRepresentation;
	}
	
	return self;
}

#pragma mark - WIKImage

- (WIKImageRepresentation*)representationForWidth:(CGFloat)imageWidth {
	BOOL isSVGImage = !WIKIsRasterImageTypeIdentifier(self.representation.typeIdentifier);
	if(!isSVGImage && self.representation.size.width <= imageWidth) { return self.representation; }
	
	WIKImageRepresentation* thumbnailRepresentation = self.thumbnailRepresentation;
	
	CGSize thumbnailSize = thumbnailRepresentation.size;
	CGFloat imageRatio = thumbnailSize.height / thumbnailSize.width;
	CGSize newThumbnailSize = CGSizeMake(imageWidth, ceilf(imageWidth * imageRatio));
	
	NSURL* newThumbnailURL = [self
		thumbnailURLForSize:newThumbnailSize
		forURL:[thumbnailRepresentation URL]];
	
	WIKImageRepresentation* newThumbnailRepresentation = [[WIKImageRepresentation alloc]
		initWithURL:newThumbnailURL
		size:newThumbnailSize
		typeIdentifier:[thumbnailRepresentation typeIdentifier]];
	
	return newThumbnailRepresentation;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
	if(self == object) { return YES; }
	if(![object isKindOfClass:[self class]]) { return NO; }
	return [[self representation] isEqual:[object representation]];
}

- (NSUInteger)hash {
	return [[self representation] hash];
}

- (NSString*)description {
	return [NSString stringWithFormat:@"%@ %@",
		[super description],
		[self name]];
}

#pragma mark -

+ (NSRegularExpression*)sharedThumbnailSizeRegularExpression {
	static NSRegularExpression* _wik_sharedThumbnailSizeRegularExpression = nil;
    static dispatch_once_t _wik_sharedThumbnailSizeRegularExpressionOnce;

    dispatch_once(&_wik_sharedThumbnailSizeRegularExpressionOnce, ^{
		_wik_sharedThumbnailSizeRegularExpression = [NSRegularExpression
			regularExpressionWithPattern:@"^\\d+px-"
			options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators
			error:nil];
    });

    return _wik_sharedThumbnailSizeRegularExpression;
}

- (NSURL*)thumbnailURLForSize:(CGSize)imageSize forURL:(NSURL*)URL {
	NSString* fileName = [URL lastPathComponent];
	
	CGFloat size = imageSize.width; // MAX(imageSize.width, imageSize.height);
	
	NSString* imageWidthString = [NSString stringWithFormat:@"%ldpx-", (long)size];
	NSString* newFileName = [[[self class] sharedThumbnailSizeRegularExpression]
		stringByReplacingMatchesInString:fileName
		options:0
		range:NSMakeRange(0, [fileName length])
		withTemplate:imageWidthString];
	
	NSURL* newURL = [URL URLByDeletingLastPathComponent];
	newURL = [newURL URLByAppendingPathComponent:newFileName];
	
	return newURL;
}

@end
