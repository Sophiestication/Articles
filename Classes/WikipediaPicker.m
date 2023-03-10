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

#import "WikipediaPicker.h"
#import "WikipediaPicker+Private.h"

#import "UINavigationController+Additions.h"
#import "UIButton+Graphite.h"
#import "UILabel+Graphite.h"

#import "SFNavigationBar.h"

@implementation WikipediaPicker

@synthesize delegate = _delegate;
@synthesize selectedWikipedia = _selectedWikipedia;
@synthesize wikipedias = _wikipedias;
@synthesize recentWikipedias = _recentWikipedias;

#pragma mark -
#pragma mark Construction & Destruction

+ (id)viewController {
	return [[self alloc] initWithNibName:@"WikipediaPicker" bundle:nil];
}

+ (NSString*)displayNameForLanguageCode:(NSString*)languageCode {
	NSString* displayName = [[NSLocale currentLocale]
		displayNameForKey:NSLocaleLanguageCode
		value:languageCode];
	
	if(displayName.length <= 0) {
		displayName = languageCode;
	}
	
	return displayName;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		self.contentSizeForViewInPopover = CGSizeMake(320.0, 480.0);
	}
	
	return self;
}


#pragma mark -
#pragma mark WikipediaPickerController

- (IBAction)done:(id)sender {
	if(self.navigationController.rootViewController == self) {
		[self dismissViewControllerAnimated:YES completion:nil];
	} else {
		[[self navigationController] popViewControllerAnimated:YES];
	}
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	BOOL shouldUseGraphiteStyle = [self shouldUseGraphiteStyle];
	
	if([UIDocument class]) {
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
	}
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
	}
	
	// Put a done button in the navigation bar if needed
	if(!self.navigationController.backViewController) {
		UIBarButtonItem* doneButtonItem = nil;
		
		if(shouldUseGraphiteStyle) {
			UIButton* doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
			[doneButton addTarget:self action:@selector(done:) forControlEvents:UIControlEventTouchUpInside];
			
			doneButtonItem = [[UIBarButtonItem alloc]
				initWithCustomView:doneButton];
		} else {
			doneButtonItem = [[UIBarButtonItem alloc]
				initWithBarButtonSystemItem:UIBarButtonSystemItemDone
				target:self
				action:@selector(done:)];
		}
		
		self.navigationItem.rightBarButtonItem = doneButtonItem;
	}
	
	if(shouldUseGraphiteStyle) {
		UILabel* titleLabel = [UILabel graphiteNavigationBarLabelWithText:
			[[self navigationItem] title]];
		self.navigationItem.titleView = titleLabel;
	}
	
	// Set the navigation title and prompt
	[self updateForInterfaceOrientation:[self interfaceOrientation]];

	// Init the table contents
	NSString* wikipediasPath = [[NSBundle mainBundle]
		pathForResource:@"Wikipedias"
		ofType:@"plist"];
	self.wikipedias = [NSArray arrayWithContentsOfFile:wikipediasPath];
	
	// Load the recent wikipedias
	NSArray* recentWikipedias = [[NSUserDefaults standardUserDefaults]
		arrayForKey:@"AKRecentlyPickedWikipedias"];
	
	if(recentWikipedias && recentWikipedias.count > 0) {
		NSMutableArray* newWikipedias = [NSMutableArray array];
		
		NSDictionary* recents = [NSDictionary dictionaryWithObjectsAndKeys:
			@"WIKIPEDIA_GROUP_RECENTITEMS", @"group",
			recentWikipedias, @"items",
			nil];
		[newWikipedias addObject:recents];
		
		[newWikipedias addObjectsFromArray:[self wikipedias]];
		
		self.wikipedias = newWikipedias;
	}
	
	[[self tableView] reloadData];
}

- (void)viewDidUnload {
	[super viewDidLoad];
	
	self.wikipedias = nil;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[[self navigationController] setNavigationBarHidden:NO animated:YES];
	
	// Scroll to the selected row
	NSIndexPath* selectedIndexPath = [self indexPathForLanguageCode:[self selectedWikipedia]];
	[[self tableView] scrollToRowAtIndexPath:selectedIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
     if(self.navigationController.parentViewController) {
		return [[[self navigationController] parentViewController] shouldAutorotateToInterfaceOrientation:interfaceOrientation];
	}
	
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self updateForInterfaceOrientation:toInterfaceOrientation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super	didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (BOOL)disablesAutomaticKeyboardDismissal {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { return YES; }
	return [super disablesAutomaticKeyboardDismissal];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.wikipedias.count;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
   return [[[[self wikipedias]
		objectAtIndex:section]
		objectForKey:@"items"]
		count];
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
	NSString* headerTitle = [[[self wikipedias]
		objectAtIndex:section]
		objectForKey:@"group"];
	
	if(headerTitle) {
		headerTitle = NSLocalizedString(headerTitle, @"");
	}
		
	return headerTitle;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString* identifier = @"regular";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
	if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
	NSString* languageCode = [self languageCodeForIndexPath:indexPath];
	NSString* language = [[NSLocale currentLocale]
		displayNameForKey:NSLocaleLanguageCode
		value:languageCode];
		
	cell.textLabel.text = language.length > 0 ?
		language :
		languageCode;
		
	cell.accessoryType = [languageCode isEqualToString:[self selectedWikipedia]] ?
		UITableViewCellAccessoryCheckmark :
		UITableViewCellAccessoryNone;
	
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	NSString* languageCode = [[[[self wikipedias]
		objectAtIndex:[indexPath section]]
		objectForKey:@"items"]
		objectAtIndex:[indexPath row]];
		
	if(languageCode) {
		NSArray* recentWikipedias = [[NSUserDefaults standardUserDefaults]
			arrayForKey:@"AKRecentlyPickedWikipedias"];
		NSMutableArray* newRecentWikipedias = recentWikipedias ?
			[NSMutableArray arrayWithArray:recentWikipedias] :
			[NSMutableArray arrayWithCapacity:1];
		
		if([newRecentWikipedias containsObject:languageCode]) {
			[newRecentWikipedias removeObject:languageCode];
		}
		
		[newRecentWikipedias insertObject:languageCode atIndex:0];
		
		NSInteger const maxNumberOfRecentItems = 3;
		
		if(newRecentWikipedias.count > maxNumberOfRecentItems) {
			newRecentWikipedias = (id)[newRecentWikipedias subarrayWithRange:NSMakeRange(0, maxNumberOfRecentItems)];
		}
		
		[[NSUserDefaults standardUserDefaults]
			setObject:newRecentWikipedias
			forKey:@"AKRecentlyPickedWikipedias"];
	}
	
	if([[self delegate] respondsToSelector:@selector(wikipediaPickerController:didFinishPickingLanguageCode:)]) {
		[[self delegate] wikipediaPickerController:self didFinishPickingLanguageCode:languageCode];
	}
	
	[self done:tableView];
}

#pragma mark -
#pragma mark Private

- (NSIndexPath*)indexPathForLanguageCode:(NSString*)languageCode {
	NSUInteger sectionIndex = 0;

	for(NSDictionary* group in self.wikipedias) {
		NSUInteger rowIndex = 0;
		
		for(NSString* item in [group objectForKey:@"items"]) {
			if([item isEqualToString:languageCode]) {
				return [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
			}
		
			++rowIndex;
		}
	
		++sectionIndex;
	}
	
	return nil;
}

- (NSString*)languageCodeForIndexPath:(NSIndexPath*)indexPath {
	NSString* languageCode = [[[[self wikipedias]
		objectAtIndex:[indexPath section]]
		objectForKey:@"items"]
		objectAtIndex:[indexPath row]];
	return languageCode;
}

- (void)updateForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if(UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
		self.navigationItem.title = NSLocalizedString(@"WIKIPEDIAPICKER_NAVIGATION_TITLE", @"");
		
		if(self.navigationController.backViewController.navigationItem.prompt.length > 0) {
			self.navigationItem.prompt = NSLocalizedString(@"WIKIPEDIAPICKER_NAVIGATION_PROMPT", @"");
		}
	} else {
		self.navigationItem.title = NSLocalizedString(@"WIKIPEDIAPICKER_NAVIGATION_PROMPT", @"");
		self.navigationItem.prompt = nil;
	}
	
	if([self shouldUseGraphiteStyle]) {
		// ...
		UIButton* doneButton = (id)self.navigationItem.rightBarButtonItem.customView;
		
		if(doneButton) {
			[doneButton
				setGraphiteStyle:UIBarButtonItemStyleDone
				miniBar:UIInterfaceOrientationIsLandscape(interfaceOrientation)
				systemItem:UIBarButtonSystemItemDone];
		}
		
		// ...
		UILabel* titleLabel = (id)self.navigationItem.titleView;
	
		if(titleLabel) {
			titleLabel.font = UIInterfaceOrientationIsPortrait(interfaceOrientation) ?
				[UIFont boldSystemFontOfSize:19.0] :
				[UIFont boldSystemFontOfSize:16.0];
				
			titleLabel.text = self.navigationItem.title;
				
			[titleLabel sizeToFit];
			
			self.navigationItem.titleView = titleLabel;
		}
	}
}

- (BOOL)shouldUseGraphiteStyle {
	UINavigationBar* navigationBar = self.navigationController.navigationBar;
	return [navigationBar isKindOfClass:[SFNavigationBar class]];
}

@end
