//
//  SARReaderViewController.m
//  Articles
//
//  Created by Sophia Teutschler on 23.10.11.
//  Copyright (c) 2011 Sophiestication Software. All rights reserved.
//

#import "SARReaderViewController.h"

#import "ArticleKit.h"

@implementation SARReaderViewController

#pragma mark - Construction & Destruction

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    }

    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
/*	ARKArticleViewController* articleViewController = [[ARKArticleViewController alloc] initWithNibName:nil bundle:nil];
	
	[self addChildViewController:articleViewController];
	[[self view] addSubview:[articleViewController view]];
*/
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - Private

@end