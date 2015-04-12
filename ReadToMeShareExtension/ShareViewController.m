//
//  ShareViewController.m
//  ReadToMeShareExtension
//
//  Created by jun on 2015. 4. 11..
//  Copyright (c) 2015년 keicoder. All rights reserved.
//

#define kSharedDocument @"kSharedDocument"

#import "ShareViewController.h"


@interface ShareViewController ()

@property (nonatomic, strong) UIPasteboard *pasteBoard;

@end


@implementation ShareViewController



- (BOOL)isContentValid {
    // Do validation of contentText and/or NSExtensionContext attachments here
    
    return YES;
}

- (void)didSelectPost {
    
    //User Defaults
//    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.keicoder.demo.readtome"];
//    [sharedDefaults setObject:self.contentText forKey:kSharedDocument];
//    [sharedDefaults synchronize];
    
    //PasteBoard
    if (self.pasteBoard == nil) {
        self.pasteBoard = [UIPasteboard generalPasteboard];
    }
    self.pasteBoard.persistent = YES;
    [self.pasteBoard setString:self.contentText];
    
    //Open URL
    UIResponder* responder = self;
    while ((responder = [responder nextResponder]) != nil)
    {
        NSLog(@"responder = %@", responder);
        if([responder respondsToSelector:@selector(openURL:)] == YES)
        {
            [responder performSelector:@selector(openURL:) withObject:[NSURL URLWithString:@"readtome://"]];
        }
    }
    
    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
    
    //Open URL Not Working
//    NSURL *url = [NSURL URLWithString:@"readtome://"];
//    [self.extensionContext openURL:url completionHandler:^(BOOL success) {
//        NSLog(@"fun=%s after completion. success=%d", __func__, success);
//    }];
    
}

- (NSArray *)configurationItems {
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    return @[];
}

@end
