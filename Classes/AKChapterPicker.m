//
//  AKChapterPicker.m
//  Articles
//
//  Created by Sophia Teutschler on 18.06.10.
//  Copyright 2010 Sophia Teutschler. All rights reserved.
//

#import "AKChapterPicker.h"
#import "AKChapterPicker+Private.h"

#import "AKArchive.h"
#import "AKArticleView.h"

@implementation AKChapterPicker

@synthesize archive = _archive;
@synthesize articleView = _articleView;

#pragma mark -
#pragma mark Construction & Destruction

+ (id)viewController {
	return [[[self alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
}

- (id)initWithStyle:(UITableViewStyle)style {
	if(self = [super initWithStyle:style]) {
    }

    return self;
}

- (void)dealloc {
	self.archive = nil;
	self.articleView = nil;

	[super dealloc];
}

#pragma mark -
#pragma mark WikipediaPickerController

- (IBAction)done:(id)sender {
	[[self navigationController] dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	// Set the navigation title and prompt
	[self updatePromptForStatusBarOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
	
	// Put the switcher on the top left
	NSArray* items = [NSArray arrayWithObjects:
		@"XXX",
		@"XXY",
		nil];
	UISegmentedControl* segmentedControl = [[[UISegmentedControl alloc] initWithItems:items] autorelease];
	
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentedControl.selectedSegmentIndex = 1;
	
	[segmentedControl
		addTarget:[self navigationController]
		action:@selector(showLanguagePicker:)
		forControlEvents:UIControlEventValueChanged];
	
	UIBarButtonItem* segmentedControlItem = [[[UIBarButtonItem alloc]
		initWithCustomView:segmentedControl] autorelease];
	self.navigationItem.leftBarButtonItem = segmentedControlItem;
	
	// Put a done button in the navigation bar
	UIBarButtonItem* doneButtonItem = [[[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemDone
		target:self
		action:@selector(done:)] autorelease];
	self.navigationItem.rightBarButtonItem = doneButtonItem;
	
	// Set the title
	self.navigationItem.title = [[self articleView] articleTitle];
}

- (void)viewDidUnload {
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[(UISegmentedControl*)[[[self navigationItem] leftBarButtonItem] customView] setSelectedSegmentIndex:1];
	
	[[self navigationController] setNavigationBarHidden:NO animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self updatePromptForStatusBarOrientation:toInterfaceOrientation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super	didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

- (UITableViewCell *)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString* identifier = @"regular";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
	if(!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
    }
	
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	[self done:tableView];
}

#pragma mark -
#pragma mark Private

- (void)updatePromptForStatusBarOrientation:(UIInterfaceOrientation)statusBarOrientation {
}

@end