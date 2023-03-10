//
//  AKChapterPicker.h
//  Articles
//
//  Created by Sophia Teutschler on 18.06.10.
//  Copyright 2010 Sophia Teutschler. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AKArchive;
@class AKArticleView;

@interface AKChapterPicker : UITableViewController {
@private
	AKArchive* _archive;
	AKArticleView* _articleView;
}

@property(nonatomic, retain) AKArchive* archive;
@property(nonatomic, retain) AKArticleView* articleView;

+ (id)viewController;

- (IBAction)done:(id)sender;

@end