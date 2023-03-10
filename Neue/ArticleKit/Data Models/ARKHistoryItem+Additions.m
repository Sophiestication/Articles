//
//  ARKHistoryItem+Additions.m
//  Articles
//
//  Created by Sophia Teutschler on 27.06.13.
//
//

#import "ARKHistoryItem+Additions.h"

@implementation ARKHistoryItem(Additions)

@dynamic articleURL;

- (NSURL*)articleURL {
	NSString* URLString = self.identifier;
	if(URLString.length == 0) { return nil; }

	NSURL* URL = [NSURL URLWithString:URLString];
	return URL;
}

@end