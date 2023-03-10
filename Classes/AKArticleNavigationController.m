    //
//  AKArticleNavigationController.m
//  Articles
//
//  Created by Sophia Teutschler on 18.06.10.
//  Copyright 2010 Sophia Teutschler. All rights reserved.
//

#import "AKArticleNavigationController.h"

#import "AKChapterPicker.h"
#import "AKLanguagePicker.h"

@implementation AKArticleNavigationController

@synthesize options = _options;
@synthesize languagePicker = _languagePicker;
@synthesize chapterPicker = _chapterPicker;

#pragma mark -
#pragma mark Construction & Destruction

+ (id)viewController {
	return [[[self alloc] initWithNibName:nil bundle:nil] autorelease];
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
	if(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
	}
	
	return self;
}

- (void)dealloc {
	self.languagePicker = nil;
	self.chapterPicker = nil;

	self.options = nil;

	[super dealloc];
}

#pragma mark -
#pragma mark AKArticleNavigationController

- (void)presentArticleNavigationWithOptions:(NSDictionary*)options {
	self.options = options;
	
	UIViewController* viewController = [options objectForKey:@"parentViewController"];
	[viewController presentModalViewController:self animated:YES];
}

- (void)dismissArticleNavigation {
	[self dismissModalViewControllerAnimated:YES];
}

- (void)showLanguagePicker:(id)sender {
	if(!self.languagePicker) {
		AKLanguagePicker* languagePicker = [AKLanguagePicker viewController];
	
		languagePicker.archive = [[self options] objectForKey:@"archive"];
		languagePicker.articleView = [[self options] objectForKey:@"articleView"];
	
		self.languagePicker = languagePicker;
	}

	self.viewControllers = [NSArray arrayWithObject:[self languagePicker]];
}

- (void)showChapterPicker:(id)sender {
	if(!self.chapterPicker) {
		AKChapterPicker* chapterPicker = [AKChapterPicker viewController];
	
		chapterPicker.archive = [[self options] objectForKey:@"archive"];
		chapterPicker.articleView = [[self options] objectForKey:@"articleView"];
	
		self.chapterPicker = chapterPicker;
	}

	self.viewControllers = [NSArray arrayWithObject:[self chapterPicker]];
}

#pragma mark -
#pragma mark UIViewController

- (void)loadView {
	[super loadView];
	
	// ...
	self.wantsFullScreenLayout = YES;
	self.navigationBarHidden = NO;
	self.navigationBar.barStyle = UIBarStyleDefault;
	self.toolbarHidden = YES;
	
	// ...
	if(NO) {
		[self showLanguagePicker:nil];
	} else {
		[self showChapterPicker:nil];
	}
}

- (void)viewDidUnload {
	[super viewDidUnload];
	
	self.languagePicker = nil;
	self.chapterPicker = nil;
}

@end