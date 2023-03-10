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

#import "AKLanguagePicker.h"
#import "AKLanguagePicker+Private.h"

#import "AKArchive.h"
#import "AKArchive+Private.h"

#import "AKArticleView.h"
#import "AKArticleView+Private.h"

#import "SFSegmentedControl.h"

#import "NSURL+Wikipedia.h"
#import "UIButton+Graphite.h"
#import "UINavigationController+Additions.h"
#import "UILabel+Graphite.h"

#import <MobileCoreServices/MobileCoreServices.h>

@implementation AKLanguagePicker

#pragma mark -
#pragma mark Construction & Destruction

+ (id)viewController {
	return [[self alloc] initWithStyle:UITableViewStyleGrouped];
}

- (id)initWithStyle:(UITableViewStyle)style {
	if((self = [super initWithStyle:style])) {
		self.hidesBottomBarWhenPushed = YES;
	
		self.pickerMode = AKLanguagePickerModeDefault;
		self.allowsModeSelection = YES;
		
		self.languagesOffset = 0.0;
		self.chaptersOffset = 0.0;
	}

    return self;
}


#pragma mark -
#pragma mark AKLanguagePicker

- (IBAction)done:(id)sender {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[[self delegate] languagePickerShouldDismiss:self animated:YES];
	} else if([self isInBookmarkPicker]) {
		// We also call done through our root view controller to
		// ensure proper user defaults updates
		[(id)[[self navigationController] rootViewController] done:sender];
	} else {
		[[self navigationController] dismissViewControllerAnimated:YES completion:nil];
	}
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Put the switcher on the top left if needed
	if(self.allowsModeSelection) {
		self.title = [[self articleView] articleTitle];
	} else {
		self.title = self.pickerMode == AKLanguagePickerModeDefault ?
			NSLocalizedString(@"LANGUAGEPICKER_NAVIGATIONITEM_SHORTTITLE", @"") :
			NSLocalizedString(@"CHAPTERPICKER_NAVIGATIONITEM_SHORTTITLE", @"");
	}
		
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		self.doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
		self.navigationItem.rightBarButtonItem = self.doneButtonItem;
	}

	if(self.allowsModeSelection) {
		NSArray* items = @[
			[UIImage imageNamed:@"languagesButtonItemHighlighted"],
			[UIImage imageNamed:@"TOCButtonItemHighlighted"]];

		UISegmentedControl* segmentedControl = [[UISegmentedControl alloc] initWithItems:items];

		segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;

		[segmentedControl
			addTarget:self
			action:@selector(togglePickerMode:)
			forControlEvents:UIControlEventValueChanged];
		
		UIBarButtonItem* segmentedControlItem = [[UIBarButtonItem alloc]
			initWithCustomView:segmentedControl];
		self.navigationItem.leftBarButtonItem = segmentedControlItem;
	
		// Restore the previous mode
		AKLanguagePickerMode pickerMode = [[NSUserDefaults standardUserDefaults]
			integerForKey:@"AKLanguagePickerMode"];
	
		self.pickerMode = pickerMode;
	}
	
	if(self.pickerMode == AKLanguagePickerModeDefault) {
		[self showLanguages];
	} else {
		[self showChapters];
	}

	[[self tableView] reloadData];
	[self restoreChapterContentOffsetIfNeeded];
	
	if(!self.showsPlaceholderView) {
		self.contentSizeForViewInPopover = CGSizeMake(320.0, self.tableView.contentSize.height);
	}
}

- (void)viewDidUnload {
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	//[self updateButtonItemsForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
	[[self navigationController] setNavigationBarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	[self storeChapterContentOffsetIfNeeded];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	UIViewController* parentViewController = [[self articleView] parentViewController];
	
	if(parentViewController && [parentViewController respondsToSelector:@selector(shouldAutorotateToInterfaceOrientation:)]) {
		return [parentViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
	}

	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

	[self updateButtonItemsForOrientation:toInterfaceOrientation];
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
    if(self.pickerMode == AKLanguagePickerModeDefault) {
		return self.languages.count;
	} else {
		return 1;
	}
	
	return 0;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
	if(self.pickerMode == AKLanguagePickerModeDefault) {
		NSDictionary* section = [[self languages] objectAtIndex:sectionIndex];
		return [[section objectForKey:@"items"] count];
	} else {
		return [[self chapters] count];
	}
	
	return 0;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
	if(self.pickerMode == AKLanguagePickerModeDefault) {
		NSDictionary* section = [[self languages] objectAtIndex:sectionIndex];
		NSArray* items = [section objectForKey:@"items"];
		
		if(items.count > 0 || self.languages.count == 1) {
			return [section objectForKey:@"title"];
		}
	}
	
	return nil;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	 if(self.pickerMode == AKLanguagePickerModeDefault) {
		static NSString* identifier = @"language";
    
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
		if(!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
		}
		
		NSDictionary* section = [[self languages] objectAtIndex:
			[indexPath section]];
		NSDictionary* language = [[section objectForKey:@"items"]
			objectAtIndex:[indexPath row]];

		cell.textLabel.text = [language objectForKey:@"language"];

		NSString* languageCode = [language objectForKey:@"languageCode"];
		cell.accessoryType = [[self currentLanguageCode] isEqual:languageCode] ?
			UITableViewCellAccessoryCheckmark :
			UITableViewCellAccessoryNone;
	
		return cell;
	}
	
	if(self.pickerMode == AKLanguagePickerModeTOC) {
		UITableViewCell* cell = nil;
		
		NSDictionary* chapter = [[self chapters] objectAtIndex:[indexPath row]];
		
		NSString* text = [chapter objectForKey:@"text"];
		NSString* number = [chapter objectForKey:@"number"];
		NSInteger level = [[chapter objectForKey:@"level"] integerValue];
		
		if(level == 0) {
			static NSString* identifier = @"chapterHeader";
    
			cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
			if(!cell) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
			
				cell.textLabel.textColor = [UIColor colorWithRed:69.0 / 256.0 green:90.0 / 256.0 blue:119.0 / 256.0 alpha:1.0];
				cell.textLabel.highlightedTextColor = [UIColor whiteColor];
				
				//cell.textLabel.font = [UIFont systemFontOfSize:17.0];
			}
			
			// text = [NSString stringWithFormat:@"%@ %@", number, text];
		} else {
			static NSString* identifier = @"chapter";
    
			cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
			if(!cell) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
				
				//cell.textLabel.font = [UIFont systemFontOfSize:17.0];
			}
		}

		cell.textLabel.text = text;
		cell.detailTextLabel.text = number;
		cell.indentationLevel = level;
		
		if(level == 1) {
			cell.textLabel.textColor = [UIColor darkTextColor];
		}
		
		if(level == 2) {
			cell.textLabel.textColor = [UIColor darkGrayColor];
		}
		
		if(level >= 3) {
			cell.textLabel.textColor = [UIColor grayColor];
		}

		return cell;
	}
	
	return nil;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	if(self.pickerMode == AKLanguagePickerModeDefault) {
		// Load the selected language
		NSDictionary* section = [[self languages] objectAtIndex:
			[indexPath section]];
		NSDictionary* language = [[section objectForKey:@"items"]
			objectAtIndex:[indexPath row]];
		
		// TODO
		// self.articleView.preferredContentOffset = CGPointZero;
		
		NSURL* articleURL = [[language objectForKey:@"URL"] wikipediaURLByFixingScheme];
		[[self articleView] webView:(id)[[self articleView] webView] shouldHandleArticleURL:articleURL options:nil];
		
		// Update the recently used languages
		NSString* languageCode = [language objectForKey:@"languageCode"];

		NSArray* recentWikipedias = [[NSUserDefaults standardUserDefaults]
			arrayForKey:@"AKLanguagePickerRecentlyPickedLanguages"];
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
			forKey:@"AKLanguagePickerRecentlyPickedLanguages"];
	} else {
		NSDictionary* chapter = [[self chapters] objectAtIndex:[indexPath row]];
		NSString* anchor = [chapter objectForKey:@"link"];
		
		if([anchor hasPrefix:@"#"]) {
			anchor = [anchor substringFromIndex:1];
		}
		
		[[[self articleView] webView] stringByEvaluatingJavaScriptFromString:
			[NSString stringWithFormat:@"window.location.hash = '%@'", anchor]];
	}

	[self done:tableView];
}

- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section {
	if(self.pickerMode == AKLanguagePickerModeTOC && self.chapters.count > 0) {
		return NSLocalizedString(@"CHAPTERPICKER_TABLEVIEW_FOOTER", @"");
	}
	
	return nil;
}

- (BOOL)tableView:(UITableView*)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath*)indexPath {
	return YES;
}

- (BOOL)tableView:(UITableView*)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath*)indexPath withSender:(id)sender {
	if(action == @selector(copy:)) {
		return YES;
	}
	
	return NO;
}

- (void)tableView:(UITableView*)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath*)indexPath withSender:(id)sender {
	if(action != @selector(copy:)) { return; }
	
	if(self.pickerMode == AKLanguagePickerModeDefault) {
		// Load the selected language
		NSDictionary* section = [[self languages] objectAtIndex:
			[indexPath section]];
		NSDictionary* language = [[section objectForKey:@"items"]
			objectAtIndex:[indexPath row]];
		
		NSURL* articleURL = [[language objectForKey:@"URL"] wikipediaURLByFixingScheme];
		if(!articleURL) { return; }
		
		NSArray* pasteboardItems = [NSArray arrayWithObjects:
			[NSDictionary dictionaryWithObject:articleURL forKey:(id)kUTTypeURL],
			[NSDictionary dictionaryWithObject:[articleURL absoluteString] forKey:(id)kUTTypeUTF8PlainText],
			nil];
		[[UIPasteboard generalPasteboard] setItems:pasteboardItems];
	} else {
		NSDictionary* chapter = [[self chapters] objectAtIndex:[indexPath row]];
		
		NSString* anchor = [chapter objectForKey:@"link"];
		if(anchor.length <= 0) { return; }
		
		NSURL* articleURL = [[[self articleView] articleURL] wikipediaURLByFixingScheme];
		if(!articleURL) { return; }
		
		NSURL* anchorURL = [NSURL URLWithString:[[articleURL absoluteString] stringByAppendingString:anchor]];
		if(!anchorURL) { return; }
		
		NSArray* pasteboardItems = [NSArray arrayWithObjects:
			[NSDictionary dictionaryWithObject:anchorURL forKey:(id)kUTTypeURL],
			[NSDictionary dictionaryWithObject:[anchorURL absoluteString] forKey:(id)kUTTypeUTF8PlainText],
			nil];
		[[UIPasteboard generalPasteboard] setItems:pasteboardItems];
	}
}

#pragma mark -
#pragma mark Private

- (BOOL)isInBookmarkPicker {
	return [[self navigationController] rootViewController] != self || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

- (void)togglePickerMode:(id)sender {
	if(self.pickerMode == AKLanguagePickerModeDefault) {
		self.languagesOffset = self.tableView.contentOffset.y;
		[self showChapters];
	} else {
		self.chaptersOffset = self.tableView.contentOffset.y;
		[self showLanguages];
	}
	
	[[self tableView] reloadData];
	
	if(self.pickerMode == AKLanguagePickerModeDefault) {
		self.tableView.contentOffset = CGPointMake(0.0, self.languagesOffset);
	} else {
		self.tableView.contentOffset = CGPointMake(0.0, self.chaptersOffset);
	}
	
	[[self tableView] flashScrollIndicators];
	
	[[NSUserDefaults standardUserDefaults]
		setInteger:[self pickerMode]
		forKey:@"AKLanguagePickerMode"];
}

- (void)loadLanguagesIfNeeded {
	if(!self.languages) {
		// Declare some languages to hide
		NSSet* hiddenLanguages = [NSSet setWithObjects:
			@"zh-yue",
			@"zh-min-nan",
			nil];

		// Prepare all available languages
		NSMutableArray* availableLanguagesSection = [NSMutableArray array];
		NSMutableDictionary* languageCodeToLanguageInfo = [NSMutableDictionary dictionary];
		
		// Also add the currently visible article to the selection too
		NSArray* allLanguages = self.archive.languages;
		
		if(self.articleView.articleURL) {
			allLanguages = [allLanguages arrayByAddingObject:
				[[[self articleView] articleURL] absoluteString]];
		
			self.currentLanguageCode = [[[self articleView] articleURL] wikipediaLanguageCode];
		}
		
		// Is this the only available language?
		if(allLanguages.count == 1) {
			self.languages = nil;
			return;
		}

		// ...
		for(NSString* languageURLString in allLanguages) {
			NSURL* languageURL = [NSURL URLWithString:languageURLString];
			
			NSString* languageCode = [languageURL wikipediaLanguageCode];
			NSString* language = [self displayNameForLanguageCode:languageCode];
			
			if(language.length > 0 && ![hiddenLanguages containsObject:languageCode]) {
				NSDictionary* languageInfo = [NSDictionary dictionaryWithObjectsAndKeys:
					language, @"language",
					languageCode, @"languageCode",
					languageURL, @"URL",
					nil];
				[availableLanguagesSection addObject:languageInfo];
				
				[languageCodeToLanguageInfo setObject:languageInfo forKey:languageCode];
			}
		}
		
		// Now sort by display name
		NSArray* sortDescriptors = [NSArray arrayWithObjects:
			[[NSSortDescriptor alloc] initWithKey:@"language" ascending:YES],
			nil];
		[availableLanguagesSection sortUsingDescriptors:sortDescriptors];
		
		// Check for recently picked languages
		NSArray* recentlyPickedLanguages = [[NSUserDefaults standardUserDefaults]
			valueForKey:@"AKLanguagePickerRecentlyPickedLanguages"];
			
		NSMutableArray* recentlyPickedLanguagesSection = [NSMutableArray array];
		
		for(NSString* languageCode in recentlyPickedLanguages) {
			NSDictionary* languageInfo = [languageCodeToLanguageInfo objectForKey:languageCode];
			
			if(languageInfo) {
				[recentlyPickedLanguagesSection addObject:languageInfo];
			}
		}
		
		// Check for all commonly used languages
		NSArray* commonLanguages = [NSArray arrayWithObjects:
			@"en",
			@"de",
			@"fr",
			@"it",
			@"pt",
			@"nl",
			@"ru",
			@"pl",
			@"es",
			@"ja",
			nil];
		
		NSMutableArray* commonLanguagesSection = [NSMutableArray array];
		
		for(NSString* languageCode in commonLanguages) {
			NSDictionary* languageInfo = [languageCodeToLanguageInfo objectForKey:languageCode];
			
			if(languageInfo) {
				[commonLanguagesSection addObject:languageInfo];
			}
		}
		
		// Wrap all up
		NSMutableArray* sections = [NSMutableArray arrayWithCapacity:3];
		
		if(recentlyPickedLanguagesSection.count > 0) {
			[sections addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				recentlyPickedLanguagesSection, @"items",
				NSLocalizedString(@"RECENTLYPICKED_LANGUAGES_SECTION_TITLE", @""), @"title",
				nil]];
		}
		
		[sections addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			commonLanguagesSection, @"items",
			NSLocalizedString(@"COMMON_LANGUAGES_SECTION_TITLE", @""), @"title",
			nil]];

		[sections addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			availableLanguagesSection, @"items",
			// @"", @"title",
			nil]];

		self.languages = sections;
	}
}

- (void)showLanguages {
	self.pickerMode = AKLanguagePickerModeDefault;
	
	SFSegmentedControl* segmentedControl = (id)self.navigationItem.leftBarButtonItem.customView;
	segmentedControl.selectedSegmentIndex = 0;

	[self loadLanguagesIfNeeded];
		
	BOOL showPlaceholder = self.languages.count == 0;
	
	if(showPlaceholder) {
		self.placeholderView.imageView.image = [UIImage imageNamed:@"languagesPlaceholder.png"];
		self.placeholderView.textLabel.text = NSLocalizedString(@"LANGUAGEPICKER_PLACEHOLDER_TITLE", @"");
			
		NSString* language = [self displayNameForLanguageCode:[self currentLanguageCode]];
		self.placeholderView.detailTextLabel.text = [NSString stringWithFormat:
			NSLocalizedString(@"LANGUAGEPICKER_PLACEHOLDER_DESCRIPTION", @""),
			self.articleView.articleTitle,
			language];
			
		[[self placeholderView] setNeedsLayout];
	}
	
	self.showsPlaceholderView = showPlaceholder;
}

- (void)loadChaptersIfNeeded {
	if(!self.chapters) {
		NSArray* allChapters = self.archive.chapters;
		
		NSMutableArray* chapters = [NSMutableArray arrayWithCapacity:[allChapters count]];
		
		for(NSDictionary* chapter in allChapters) {
			// First check if the chapter is visible in our article view
			NSString* anchor = [chapter objectForKey:@"link"];
			
			if([anchor hasPrefix:@"#"]) {
				anchor = [anchor substringFromIndex:1];
			}
			
			NSString* javascript = [NSString stringWithFormat:
				// @"window.getComputedStyle(document.getElementById('%@'), null).getPropertyValue('display')",
				@"document.getElementById('%@') == null || document.getElementById('%@').getBoundingClientRect().height <= 0",
				anchor,
				anchor];
			NSString* displayProperty = [[[self articleView] webView]
				stringByEvaluatingJavaScriptFromString:javascript];
				
			if([displayProperty isEqualToString:@"true"]) {
				continue; // Skip this chapter
			}
			
			// Retrieve the chapter classes
			NSArray* chapterClasses = [[chapter objectForKey:@"class"]
				componentsSeparatedByString:@" "];
				
			NSInteger level = 0;
			static NSString* const TOCLevelPrefix = @"toclevel-";
			
			for(NSString* chapterClass in chapterClasses) {
				if([chapterClass hasPrefix:TOCLevelPrefix]) {
					NSString* levelString = [chapterClass substringFromIndex:[TOCLevelPrefix length]];
					level = [levelString integerValue] - 1;
				
					break;
				}
			}
			
			level = MAX(level, 0);
			
			// Now make a new chapter info object
			NSDictionary* chapterInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInteger:level], @"level",
				[chapter objectForKey:@"link"], @"link",
				[chapter objectForKey:@"text"], @"text",
				[chapter objectForKey:@"number"], @"number",
				nil];
			[chapters addObject:chapterInfo];
		}
		
		self.chapters = chapters;
	}
}

- (void)showChapters {
	self.pickerMode = AKLanguagePickerModeTOC;
	
	SFSegmentedControl* segmentedControl = (id)self.navigationItem.leftBarButtonItem.customView;
	segmentedControl.selectedSegmentIndex = 1;

	[self loadChaptersIfNeeded];
		
	BOOL showPlaceholder = self.chapters.count == 0;
	
	if(showPlaceholder) {
		self.placeholderView.imageView.image = [UIImage imageNamed:@"TOCPlaceholder.png"];
		self.placeholderView.textLabel.text = NSLocalizedString(@"CHAPTERPICKER_PLACEHOLDER_TITLE", @"");
			
		self.placeholderView.detailTextLabel.text = [NSString stringWithFormat:
			NSLocalizedString(@"CHAPTERPICKER_PLACEHOLDER_DESCRIPTION", @""),
			self.articleView.articleTitle];
	
		[[self placeholderView] setNeedsLayout];
	}
	
	self.showsPlaceholderView = showPlaceholder;
}

- (NSString*)displayNameForLanguageCode:(NSString*)languageCode {
	NSString* displayName = [[NSLocale currentLocale]
		displayNameForKey:NSLocaleLanguageCode
		value:languageCode];
	return displayName;
}

- (void)updatePromptForStatusBarOrientation:(UIInterfaceOrientation)statusBarOrientation {
}

- (void)updateButtonItemsForOrientation:(UIInterfaceOrientation)orientation {
	if([self isInBookmarkPicker]) { return; }

	UISegmentedControl* segmentedControl = (UISegmentedControl*)self.navigationItem.leftBarButtonItem.customView;
	if(!segmentedControl) { return; }

	if(UIInterfaceOrientationIsPortrait(orientation)) {
		[segmentedControl setImage:[UIImage imageNamed:@"languagesButtonItemHighlighted"] forSegmentAtIndex:0];
		[segmentedControl setImage:[UIImage imageNamed:@"TOCButtonItemHighlighted"] forSegmentAtIndex:1];
	} else {
		[segmentedControl setImage:[UIImage imageNamed:@"smallLanguagesButtonItemHighlighted"] forSegmentAtIndex:0];
		[segmentedControl setImage:[UIImage imageNamed:@"smallTOCButtonItemHighlighted"] forSegmentAtIndex:1];
	}
}

- (void)storeChapterContentOffsetIfNeeded {
	if(self.pickerMode != AKLanguagePickerModeTOC) { return; }
	
	NSDictionary* defaults = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithDouble:[[self tableView] contentOffset].y], @"contentOffset",
		[[[self articleView] articleURL] absoluteString], @"articleURL",
		nil];
	
	[[NSUserDefaults standardUserDefaults] setObject:defaults forKey:@"AKLanguagePickerTOCOffset"];
}

- (void)restoreChapterContentOffsetIfNeeded {
	if(self.pickerMode != AKLanguagePickerModeTOC) { return; }
	
	NSDictionary* defaults = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"AKLanguagePickerTOCOffset"];
	
	if(defaults) {
		NSURL* articleURL = [NSURL URLWithString:[defaults objectForKey:@"articleURL"]];
		
		if([[[self articleView] articleURL] isEqual:articleURL]) {
			CGPoint newContentOffset = CGPointMake(
				0.0,
				[[defaults objectForKey:@"contentOffset"] doubleValue]);
			self.tableView.contentOffset = newContentOffset;
		}
	}
}

- (void)restoreFromUserDefaults:(NSDictionary*)userDefaults inSelection:(NSArray*)selection {
//	self.userDefaults = userDefaults;
}

@end
