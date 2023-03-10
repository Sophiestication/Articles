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

#import "AKArticleView+Printing.h"
#import "AKArticleView+Private.h"

@implementation AKArticleView(Printing)

+ (BOOL)isPrintingAvailable {
	if([UIPrintInteractionController class]) {
		return [UIPrintInteractionController isPrintingAvailable];
	}
	
	return NO;
}

- (void)print:(id)sender {
	UIPrintInteractionController* controller = [UIPrintInteractionController sharedPrintController];

	UIPrintInfo* printInfo = [UIPrintInfo printInfo];
	printInfo.outputType = UIPrintInfoOutputGeneral;
	printInfo.jobName = self.articleTitle;
	printInfo.duplex = UIPrintInfoDuplexLongEdge;
    
	controller.printInfo = printInfo;
    controller.showsPageRange = YES;
 
    UIViewPrintFormatter* formatter = [[self webView] viewPrintFormatter];
    formatter.startPage = 0;
    controller.printFormatter = formatter;
	
	id completionHandler = ^(UIPrintInteractionController* printController, BOOL completed, NSError* error) {
		if(!completed && error){
            NSLog(@"Could not print document due to error in domain %@ with error code %u", [error domain], [error code]);
        }
    };
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		[controller presentAnimated:YES completionHandler:completionHandler];
	} else {
		[controller presentFromBarButtonItem:sender animated:YES completionHandler:completionHandler];
	}
}

@end
