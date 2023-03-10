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

#import <Foundation/Foundation.h>

#import "SAArticleStackItemImage.h"
#import "SAArticleStackItem.h"
#import "SAArticleStack.h"
#import "SAArticle.h"

#import "SAArticleStackDocument.h"

#import "ArticleKit.h"

@interface SAArticleStackController : NSObject {
@private
	NSManagedObjectContext* _managedObjectContext;
	NSArray* _stacks;
	SAArticleStack* _selectedStack;
	NSArray* _selectedStackItems;
	AKArticleView* _articleView;
}

@property(nonatomic, strong) NSManagedObjectContext* managedObjectContext;

@property(nonatomic, strong) NSArray* stacks;
@property(nonatomic, strong) SAArticleStack* selectedStack;
@property(nonatomic, readonly, copy) NSArray* selectedStackItems;

@property(nonatomic, strong) AKArticleView* articleView;

- (void)refresh;
- (void)save;

- (void)navigateToArticle:(SAArticle*)article;
- (void)didNavigateToArticleURL:(NSURL*)articleURL;

- (BOOL)canNavigateBack;
- (SAArticleStackItem*)navigateBack;

- (BOOL)canNavigateForward;
- (SAArticleStackItem*)navigateForward;

- (SAArticleStack*)addNewArticleStack;
- (void)deleteArticleStack:(SAArticleStack*)articleStack;

- (SAArticleStack*)navigateToArticleURLInNewPageIfNeeded:(NSURL*)articleURL;

@end
