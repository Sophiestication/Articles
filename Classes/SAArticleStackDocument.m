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

#import "SAArticleStackDocument.h"

#import "SAArticle.h"
#import "SAArticleStack.h"
#import "SAArticleStackItem.h"
#import "SAArticleStackItemImage.h"

@implementation SAArticleStackDocument

@dynamic articleStack;

#pragma mark -
#pragma mark Construction & Destruction

- (id)initWithArticleStack:(SAArticleStack*)articleStack {
	if(self = [super init]) {
		_articleStack = articleStack;
	}
	
	return self;
}


#pragma mark -
#pragma mark SAArticleStackDocument

- (SAArticleStack*)articleStack {
	return _articleStack;
}

#pragma mark -
#pragma mark SFDocument

- (NSString*)title {
	NSString* title = self.articleStack.selectedItem.article.title;
	
	if(title.length == 0) {
		title = NSLocalizedString(@"UNTITLED_NAVIGATIONITEM_TITLE", @"");
	}
	
	return title;
}

- (NSString*)subtitle {
	return self.articleStack.selectedItem.article.articleURL;
}

- (UIImage*)imageForSize:(CGSize)size {
	SAArticleStackItemImage* stackImage = self.articleStack.selectedItem.image;

	if([[stackImage rasterBuild] integerValue] < 1) { // TODO
		return nil;
	}
	
	if(stackImage.interfaceIdiom && (UIUserInterfaceIdiom)[[stackImage interfaceIdiom] integerValue] != UI_USER_INTERFACE_IDIOM()) {
		return nil;
	}

	return stackImage.image;
}

@end
