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

#import "ARKSearchTableViewController.h"

#import "ARKSearchResultTableViewCell.h"
#import "ARKLoadingFooterView.h"

#import "ARKHTMLMarkupFormatter.h"

#import "ARKImageRenderController.h"
#import "ARKImageRenderController+MediaWiki.h"

#import "ARKRepresentativeImageRenderer.h"
#import "ARKImagePlaceholderRenderer.h"

#import "SUIDataSourceController.h"
#import "SUIRecentlyUsedObjectCache.h"

#import "NSCache+Images.h"
#import "NSString+Additions.h"

@interface ARKSearchTableViewController()

@property(nonatomic, strong) NSMapTable* pageQueriesByMediaWiki;
@property(nonatomic, strong) SUIDataSourceController* dataSourceController;
@property(nonatomic, strong) ARKHTMLMarkupFormatter* HTMLMarkupFormatter;

@property(nonatomic, strong) ARKImageRenderController* imageRenderController;
@property(nonatomic, strong) NSMutableSet* representativeImagesInProgress;
@property(nonatomic, strong) SUIRecentlyUsedObjectCache* recentlyUsedRepresentativeImages;
@property(nonatomic, strong) UIImage* genericRepresentativeImage;

@property(nonatomic, strong) ARKLoadingFooterView* loadingFooterView;

@property(nonatomic, strong) NSMapTable* mediaWikiErrors;
@property(nonatomic, strong) UILabel* noSearchResultsLabel;

@end

@implementation ARKSearchTableViewController

@dynamic mediaWikis;

#pragma mark - Construction & Destruction

- (id)init {
	return [self initWithStyle:UITableViewStylePlain];
}

- (id)initWithStyle:(UITableViewStyle)style {
    if((self = [super initWithStyle:style])) {
		self.pageQueriesByMediaWiki = [NSMapTable strongToStrongObjectsMapTable];
		self.mediaWikiErrors = [NSMapTable weakToStrongObjectsMapTable];

		self.dataSourceController = [[SUIDataSourceController alloc] init];
		self.imageRenderController = [[ARKImageRenderController alloc] init];

		self.representativeImagesInProgress = [NSMutableSet set];
		self.recentlyUsedRepresentativeImages = [[SUIRecentlyUsedObjectCache alloc] initWithMaximumNumberOfObjects:20];
    }

    return self;
}

#pragma mark - ARKSearchTableViewController

- (NSArray*)mediaWikis {
	return [[self dataSourceController] objects];
}

- (void)setMediaWikis:(NSArray*)mediaWikis {
	[[self dataSourceController] setObjects:mediaWikis];

	for(WIKPageQuery* query in [[self pageQueriesByMediaWiki] objectEnumerator]) {
		[query cancel];
	}
	[[self pageQueriesByMediaWiki] removeAllObjects];

	if(self.searchText.length > 0) { [self updateSearchResults]; }
}

- (void)setSearchText:(NSString*)searchText {
	[self setSearchText:searchText animated:NO];
}

- (void)setSearchText:(NSString*)searchText animated:(BOOL)animated {
	if(SFEEqualStrings(searchText, self.searchText)) { return; }
	if(self.searchText.length == 0 && searchText.length == 0) { return; }

	NSString* previousSearchText = self.searchText;
	previousSearchText = [previousSearchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	BOOL searchTextWasEmpty = previousSearchText.length == 0;
	_searchText = [searchText copy];

	[self updateTableFooterViewForSearchTextChange];

	if(searchTextWasEmpty) {
		[self updateSearchResults];
	} else {
		[self scheduleSearchResultUpdate];
	}
}

- (void)setTitleMatchingEnabled:(BOOL)titleMatchingEnabled {
	if(self.titleMatchingEnabled == titleMatchingEnabled) { return; }

	_titleMatchingEnabled = titleMatchingEnabled;

	[self removeAllSearchResults];
	[self updateSearchResults];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

	[[self tableView]
		registerClass:[ARKSearchResultTableViewCell class]
		forCellReuseIdentifier:[[self class] mediaWikiSearchResultItemReuseIdentifier]];
	[[self tableView]
		registerClass:[UITableViewCell class]
		forCellReuseIdentifier:[[self class] regularItemReuseIdentifier]];

	self.tableView.rowHeight = [ARKSearchResultTableViewCell preferredHeight];
	
	CGRect tableFooterRect = CGRectMake(0.0, 0.0, 0.0, 60.0);
	self.loadingFooterView = [[ARKLoadingFooterView alloc] initWithFrame:tableFooterRect];

	[self initNoSearchResultsLabelIfNeeded];

	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		UILongPressGestureRecognizer* longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didRecognizeLongPressGesture:)];
		[[self tableView] addGestureRecognizer:longPressGestureRecognizer];
	}

	self.HTMLMarkupFormatter = [[ARKHTMLMarkupFormatter alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self updateTableFooterViewAnimated:NO];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	[self layoutNoSearchResultsLabel];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	[[self recentlyUsedRepresentativeImages] removeAllObjects];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
	return self.dataSourceController.objects.count;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	NSArray* items = [[self dataSourceController] objectsAtSectionIndex:section];
	return items.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	id object = [[self dataSourceController] objectForRowAtIndexPath:indexPath];

	if([self isMediaWikiSearchResultItem:object]) {
		ARKSearchResultTableViewCell* cell = [tableView
			dequeueReusableCellWithIdentifier:[[self class] mediaWikiSearchResultItemReuseIdentifier]
			forIndexPath:indexPath];

		[self configureMediaWikiSearchResultCell:cell forRowAtIndexPath:indexPath];

		return cell;
	}
	
	UITableViewCell* cell = [tableView
		dequeueReusableCellWithIdentifier:[[self class] regularItemReuseIdentifier]
		forIndexPath:indexPath]; // TODO find what caused this path in first place

	return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
	WIKPage* page = [[self dataSourceController] objectForRowAtIndexPath:indexPath];
	if(page) { [self renderRepresentativeImageForPageIfNeeded:page]; }
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	WIKPage* page = [[self dataSourceController] objectForRowAtIndexPath:indexPath];
	if(!page) { return; }
	
	if([[self delegate] respondsToSelector:@selector(searchTableViewController:didSelectPage:)]) {
		[[self delegate] searchTableViewController:self didSelectPage:page];
	}
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
	[self updateTableFooterViewAnimated:NO];
}

- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		[[UIApplication sharedApplication]
			sendAction:@selector(resignFirstResponder)
			to:nil
			from:self
			forEvent:nil];
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(BOOL)decelerate	{
	if(!decelerate) { [self loadNextSearchResultBatchIfNeeded]; }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView*)scrollView {
	[self loadNextSearchResultBatchIfNeeded];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView*)scrollView {
	[self loadNextSearchResultBatchIfNeeded];
}

#pragma mark - Private

+ (NSString*)regularItemReuseIdentifier { return @"regular"; }

+ (NSString*)mediaWikiSearchResultItemReuseIdentifier { return @"mediaWikiItem"; }
- (BOOL)isMediaWikiSearchResultItem:(id)object { return [object isKindOfClass:[WIKPage class]]; }

- (void)scheduleSearchResultUpdate {
	NSTimeInterval delay = 0.3;

	SEL selector = @selector(updateSearchResults);

	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:selector object:nil];
	[self performSelector:selector withObject:nil afterDelay:delay];
}

- (void)updateSearchResults {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:nil];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(removeAllSearchResults) object:nil];

	NSString* searchText = self.searchText;

	WIKPredicate* predicate = [WIKPredicate predicateWithFormat:searchText];
	[predicate setTitleMatchingEnabled:[self isTitleMatchingEnabled]];
	[predicate setApproximateMatchingEnabled:YES];

	if(predicate.tokens.count == 0) {
		[self cancelAllPageQueries];
		[self removeAllSearchResults];

		[[self tableView] reloadData];
		[self scrollTableViewToTop];

		[self updateTableFooterViewForSearchTextChange];

		return;
	}

	BOOL shouldRemoveSearchResultsAfterDelay = NO;

	NSMapTable* pageQueriesByMediaWiki = self.pageQueriesByMediaWiki;

	for(WIKMediaWiki* mediaWiki in self.mediaWikis) {
		WIKPageQuery* previousQuery = [pageQueriesByMediaWiki objectForKey:mediaWiki];
		if(previousQuery && [[previousQuery predicate] isEqual:predicate]) { continue; }

		[previousQuery cancel];

		WIKPageQuery* query = [WIKPageQuery queryForPredicate:predicate mediaWiki:mediaWiki completion:^(WIKPageQuery* query, NSArray* pages, NSError* error) {
			WIKPageQuery* currentQuery = [pageQueriesByMediaWiki objectForKey:mediaWiki];
			if(currentQuery != query) { return; }

			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(removeAllSearchResults) object:nil];

			if(!query.continuing) {
				[[self dataSourceController] setObjects:nil forObject:mediaWiki];
				[self scrollTableViewToTop];
				if(error) { [[self tableView] reloadData]; }
			}

			if(error) {
				[self setError:error forMediaWiki:mediaWiki animated:NO];
			} else {
				[self addPages:pages forMediaWiki:mediaWiki animated:NO];
			}
		}];

		if(query) {
			[[self pageQueriesByMediaWiki] setObject:query forKey:mediaWiki];
			[query fetchNext];
		} else {
			[[self pageQueriesByMediaWiki] removeObjectForKey:mediaWiki];
		}

		shouldRemoveSearchResultsAfterDelay = YES;
	}

	if(shouldRemoveSearchResultsAfterDelay) {
		[self performSelector:@selector(removeAllSearchResults) withObject:nil afterDelay:0.75];
	}

	[[self tableView] reloadData];
	[self updateTableFooterViewForSearchTextChange];
}

- (void)cancelAllPageQueries {
	for(WIKPageQuery* query in [[self pageQueriesByMediaWiki] objectEnumerator]) {
		[query cancel];
	}

	[[self pageQueriesByMediaWiki] removeAllObjects];
}

- (void)removeAllSearchResults {
	[self scrollTableViewToTop];

	for(WIKMediaWiki* mediaWiki in self.mediaWikis) {
		[[self dataSourceController] setObjects:nil forObject:mediaWiki];
	}

	[[self tableView] reloadData];
	[self updateTableFooterViewForSearchTextChange];
}

- (void)addPages:(NSArray*)pages forMediaWiki:(WIKMediaWiki*)mediaWiki animated:(BOOL)animated {
	SUIDataSourceController* dataSourceController = self.dataSourceController;

	NSMutableArray* newItems = [[dataSourceController objectsForObject:mediaWiki] mutableCopy];
	if(!newItems) { newItems = [NSMutableArray arrayWithCapacity:[pages count]]; }

	[newItems addObjectsFromArray:pages];
	[dataSourceController setObjects:newItems forObject:mediaWiki];
	
	[[self mediaWikiErrors] removeObjectForKey:mediaWiki];

	for(WIKPage* page in pages) { // preload the representative image property
		[self loadRepresentativeImageForPageIfNeeded:page];
	}

	UITableView* tableView = self.tableView;

//	[tableView beginUpdates];
//
//		NSArray* insertedIndexPaths = [dataSourceController indexPathsForObjects:pages inObject:mediaWiki];
//		[tableView insertRowsAtIndexPaths:insertedIndexPaths withRowAnimation:UITableViewRowAnimationNone];
//
//	[tableView endUpdates];

	[tableView reloadData];

	if(pages.count == 0) {
		[self updateTableFooterViewForSearchTextChange];
	}

	[self updateTableFooterViewAnimated:animated];
}

- (void)setError:(NSError*)error forMediaWiki:(WIKMediaWiki*)mediaWiki animated:(BOOL)animated {
	[[self mediaWikiErrors] setObject:error forKey:mediaWiki];
	[self updateTableFooterViewForSearchTextChange];
	[self updateTableFooterViewAnimated:animated];
}

- (void)loadRepresentativeImageForPageIfNeeded:(WIKPage*)page {
	WIKProperty* representativeImage = page.representativeImage;
	if(representativeImage.status == WIKPropertyStatusLoaded) { return; }

	__weak WIKPage* weakPage = page;

	[representativeImage loadValueWithCompletionHandler:^(id value, NSError* error) {
		[self renderRepresentativeImageForPageIfNeeded:weakPage];
	}];
}

- (void)renderRepresentativeImageForPageIfNeeded:(WIKPage*)page {
	WIKProperty* representativeImage = page.representativeImage;
	if(representativeImage.status != WIKPropertyStatusLoaded) { return; }

	BOOL hasRepresentativeImage = representativeImage.value != nil;
	if(!hasRepresentativeImage) { return; }

	NSString* cacheIdentifier = [self representativeImageCacheIdentifierForPage:page];
	if([[self representativeImagesInProgress] containsObject:cacheIdentifier]) { return; } // rendering in progress?

	UIImage* renderedImage = [[self recentlyUsedRepresentativeImages] objectForKey:cacheIdentifier];
	if(renderedImage) { return; }

	BOOL renderingInProgress = [[self imageRenderController] renderRepresentativeImageForArticleIfNeeded:page completion:^(UIImage* renderedImage, NSError* error) {
		if(error) {
			[[self recentlyUsedRepresentativeImages] setObject:error forKey:cacheIdentifier];
		} else {
			if(!renderedImage) {
				if(!self.genericRepresentativeImage) { self.genericRepresentativeImage = [ARKRepresentativeImageRenderer genericImage]; }
				renderedImage = self.genericRepresentativeImage;
			}

			[[self recentlyUsedRepresentativeImages] setObject:renderedImage forKey:cacheIdentifier];
		}

		[[self representativeImagesInProgress] removeObject:cacheIdentifier];

		[self reloadCellForResultItemIfNeeded:page animated:YES];
	}];

	if(renderingInProgress) {
		[[self representativeImagesInProgress] addObject:cacheIdentifier];
	}
}

- (void)reloadCellForResultItemIfNeeded:(WIKPage*)page animated:(BOOL)animated {
	NSIndexPath* indexPath = [[self dataSourceController] indexPathForObject:page inObject:[page mediaWiki]];
	if(!indexPath) { return; }

	if(animated) {
		NSArray* indexPathsForVisibleRows = [[self tableView] indexPathsForVisibleRows];
		if(![indexPathsForVisibleRows containsObject:indexPath]) { return; }
	}

//	UITableViewRowAnimation rowAnimation = animated ? UITableViewRowAnimationFade : UITableViewRowAnimationNone;
//	[[self tableView] reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:rowAnimation];

	ARKSearchResultTableViewCell* cell = (id)[[self tableView] cellForRowAtIndexPath:indexPath];
	[self configureRepresentativeImageForCell:cell page:page animated:animated];
}

- (void)configureMediaWikiSearchResultCell:(ARKSearchResultTableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
	WIKPage* page = [[self dataSourceController] objectForRowAtIndexPath:indexPath];
	if(!page) { return; }

	NSString* title = page.title.value;
	cell.textLabel.text = [[self HTMLMarkupFormatter] stringFromString:title error:nil];

	NSString* summary = page.summary.value;
	cell.summaryTextLabel.attributedText = [[self HTMLMarkupFormatter] attributedStringFromString:summary error:nil];
	
	[self configureRepresentativeImageForCell:cell page:page animated:NO];
}

- (void)configureRepresentativeImageForCell:(ARKSearchResultTableViewCell*)cell page:(WIKPage*)page animated:(BOOL)animated {
	WIKProperty* representativeImage = page.representativeImage;
	WIKPropertyStatus representativeImageStatus = representativeImage.status;

	BOOL hasRepresentativeImage =
		representativeImageStatus == WIKPropertyStatusLoaded &&
		representativeImage.value == nil;

	if(hasRepresentativeImage) {
		cell.imagePreviewShown = NO;
		return;
	}

	NSString* cacheIdentifier = [self representativeImageCacheIdentifierForPage:page];
	UIImage* renderedImage = [[self recentlyUsedRepresentativeImages] objectForKey:cacheIdentifier];

	BOOL hasError =
		[renderedImage isKindOfClass:[NSError class]] ||
		representativeImageStatus == WIKPropertyStatusFailed;

	if(hasError) {
		[[cell imagePreviewView] setErrorIndicatorShown:YES animated:animated];
	} else {
		[[cell imagePreviewView] setErrorIndicatorShown:NO animated:animated];
		[[cell imagePreviewView] setImage:renderedImage animated:animated];
	}

	cell.imagePreviewShown = YES;
}

- (NSString*)representativeImageCacheIdentifierForPage:(WIKPage*)page {
	WIKMediaWiki* mediaWiki = page.mediaWiki;
	NSString* mediaWikiIdentifier = [[mediaWiki URL] resourceSpecifier];

	NSString* pageIdentifier = page.identifier;

	NSString* cacheIdentifier = [[pageIdentifier
		stringByAppendingString:mediaWikiIdentifier]
		stringByAppendingString:@"-representative-image"];
	return cacheIdentifier;
}

#pragma mark -

- (void)initNoSearchResultsLabelIfNeeded {
	if(self.noSearchResultsLabel) { return; }

	UILabel* noSearchResultsLabel = [[UILabel alloc] initWithFrame:CGRectZero];

	noSearchResultsLabel.text = NSLocalizedString(@"SEARCHBAR_NORESULTS_PLACEHOLDER_TITLE", nil);

	noSearchResultsLabel.font = [UIFont boldSystemFontOfSize:17.0];
	noSearchResultsLabel.textColor = [UIColor lightGrayColor];
	noSearchResultsLabel.textAlignment = NSTextAlignmentCenter;

	noSearchResultsLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;

	[noSearchResultsLabel sizeToFit];

	self.noSearchResultsLabel = noSearchResultsLabel;
	[[self tableView] addSubview:noSearchResultsLabel];
}

- (void)layoutNoSearchResultsLabel {
	if(!self.noSearchResultsLabel) { return; }

	CGRect contentRect = self.tableView.bounds;

	CGSize labelSize = [[self noSearchResultsLabel]
		sizeThatFits:contentRect.size];
	CGFloat tableViewCellHeight = [ARKSearchResultTableViewCell preferredHeight];

	CGFloat labelWidth = CGRectGetWidth(contentRect) - 20.0;
	labelWidth = MIN(labelWidth, labelSize.width);

	CGRect labelRect = self.noSearchResultsLabel.frame;

	labelRect.origin.y = round(tableViewCellHeight * 0.5 - labelSize.height * 0.5);
	labelRect.origin.x = round(CGRectGetWidth(contentRect) * 0.5 - labelWidth * 0.5);
	labelRect.size.width = labelWidth;

	self.noSearchResultsLabel.frame = labelRect;

	BOOL hasSearchText = [self hasSearchText];
	BOOL hasSearchResults = [[[self dataSourceController] objectsAtSectionIndex:0] count] > 0;
	BOOL pageQueryIsLoading = [self pageQueryIsLoading];

	self.noSearchResultsLabel.hidden = !(hasSearchText && !hasSearchResults && !pageQueryIsLoading);
}

#pragma mark -

- (BOOL)isTableFooterVisible {
	UITableView* tableView = self.tableView;
	
	ARKLoadingFooterView* footerView = (id)tableView.tableFooterView;
	if(!footerView) { return NO; }
	
	BOOL footerViewVisible = CGRectGetMaxY([tableView bounds]) >= CGRectGetMinY([footerView frame]);
	return footerViewVisible;
}

- (void)updateTableFooterViewAnimated:(BOOL)animated {
	BOOL tableFooterVisible = [self isTableFooterVisible];
	BOOL pageQueryIsLoading = [self pageQueryIsLoading];
	
	ARKLoadingFooterView* footerView = (id)self.tableView.tableFooterView;
	UIActivityIndicatorView* activityIndicatorView = footerView.activityIndicatorView;
	
	if(tableFooterVisible && pageQueryIsLoading) {
		[activityIndicatorView startAnimating];
	} else {
		[activityIndicatorView stopAnimating];
	}
	
	WIKMediaWiki* mediaWiki = [[self mediaWikis] lastObject];
	NSError* lastMediaWikiError = [[self mediaWikiErrors] objectForKey:mediaWiki];
	
	ARKLoadingFooterViewStyle viewStyle = lastMediaWikiError ?
		ARKLoadingFooterViewStyleFailure :
		ARKLoadingFooterViewStyleDefault;
		
	[footerView setLoadingFooterViewStyle:viewStyle animated:animated];
}

- (void)updateTableFooterViewForSearchTextChange {
	BOOL hasSearchText = [self hasSearchText];
	BOOL pageQueryIsLoading = [self pageQueryIsLoading];

	self.tableView.tableFooterView = hasSearchText || pageQueryIsLoading ?
		self.loadingFooterView : nil;

	[self updateTableFooterViewAnimated:NO];
}

#pragma mark -

- (BOOL)hasSearchText {
	WIKMediaWiki* mediaWiki = [[self mediaWikis] lastObject]; // it's always the last media wiki for now
	WIKPredicate* predicate = [(WIKPageQuery*)[[self pageQueriesByMediaWiki] objectForKey:mediaWiki] predicate];
	return predicate.tokens.count > 0;
}

- (BOOL)pageQueryIsLoading {
	WIKMediaWiki* mediaWiki = [[self mediaWikis] lastObject]; // it's always the last media wiki for now
	BOOL queryIsLoading = [[[self pageQueriesByMediaWiki] objectForKey:mediaWiki] canFetchNext];
	return queryIsLoading;
}

- (void)loadNextSearchResultBatchIfNeeded {
	if(![self isTableFooterVisible]) { return; }
	
	WIKMediaWiki* mediaWiki = [[self mediaWikis] lastObject];
	if(!mediaWiki) { return; }
	
	WIKPageQuery* query = [[self pageQueriesByMediaWiki] objectForKey:mediaWiki];
	[query fetchNext];
}

#pragma mark -

- (void)scrollTableViewToTop {
	UITableView* tableView = self.tableView;
	tableView.contentOffset = CGPointMake(0.0, -tableView.contentInset.top);
}

#pragma mark -

- (void)didRecognizeLongPressGesture:(UILongPressGestureRecognizer*)gestureRecognizer {
	if(gestureRecognizer.state != UIGestureRecognizerStateBegan) { return; }
	
	UITableView* tableView = self.tableView;
	CGPoint location = [gestureRecognizer locationInView:tableView];
	
	NSIndexPath* selectedIndexPath = [tableView indexPathForRowAtPoint:location];
	if(!selectedIndexPath) { return; }
	
	[tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
	
	WIKPage* page = [[self dataSourceController] objectForRowAtIndexPath:selectedIndexPath];
	
	if([[self delegate] respondsToSelector:@selector(searchTableViewController:shouldPresentActivityViewControllerForPage:)]) {
		BOOL shouldPresent = [[self delegate] searchTableViewController:self shouldPresentActivityViewControllerForPage:page];
		
		if(!shouldPresent) {
			return;
		}
	}
	
	NSMutableArray* items = [NSMutableArray array];
	
	NSURL* URL = page.URL.value;
	if(URL) { [items addObject:URL]; }
	
	UIActivityViewController* viewController = [[UIActivityViewController alloc]
		initWithActivityItems:items
		applicationActivities:nil];
	[self presentViewController:viewController animated:YES completion:nil];
}

#pragma mark -

- (void)dumpAttributedSummaryStrings {
	NSMutableArray* dump = [NSMutableArray array];

	[[[self dataSourceController] objectsAtSectionIndex:0] enumerateObjectsUsingBlock:^(WIKPage* page, NSUInteger index, BOOL* stop) {
		NSString* string = [[page summary] value];
		NSAttributedString* attributedString = [[self HTMLMarkupFormatter] attributedStringFromString:string error:nil];
		if(attributedString) { [dump addObject:attributedString]; }
	}];

	NSData* data = [NSKeyedArchiver archivedDataWithRootObject:dump];

	NSURL* URL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
	URL = [URL URLByAppendingPathComponent:@"dump.plist"];
	if(![data writeToURL:URL atomically:YES]) {
		NSLog(@"%@", URL);
	}
}

@end
