//
//  AKArticleNavigationController.h
//  Articles
//
//  Created by Sophia Teutschler on 18.06.10.
//  Copyright 2010 Sophia Teutschler. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SFNavigationController.h"

@class AKLanguagePicker;
@class AKChapterPicker;

@interface AKArticleNavigationController : UINavigationController {
@private
	NSDictionary* _options;
	AKLanguagePicker* _languagePicker;
	AKChapterPicker* _chapterPicker;
}

@property(nonatomic, retain) NSDictionary* options;

@property(nonatomic, retain) AKLanguagePicker* languagePicker;
@property(nonatomic, retain) AKChapterPicker* chapterPicker;

+ (id)viewController;

- (void)presentArticleNavigationWithOptions:(NSDictionary*)options;
- (void)dismissArticleNavigation;

- (void)showLanguagePicker:(id)sender;
- (void)showChapterPicker:(id)sender;

@end