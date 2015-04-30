//
//  ShareViewController.m
//  ReadToMeShareExtension
//
//  Created by jun on 2015. 4. 11..
//  Copyright (c) 2015년 keicoder. All rights reserved.
//

#define kSharedDefaultsSuiteName                @"group.com.keicoder.demo.readtome"
#define kSharedDocument                         @"kSharedDocument"
#define kIsSharedDocument                       @"kIsSharedDocument"


#import "ShareViewController.h"


@interface ShareViewController ()

@property (nonatomic, strong) UIPasteboard *pasteBoard;

@end


@implementation ShareViewController


- (BOOL)isContentValid
{
    return YES;
}


- (void)didSelectPost {
    
    //Open URL
    UIResponder* responder = self;
    while ((responder = [responder nextResponder]) != nil)
    {
        NSLog(@"responder = %@", responder);
        if([responder respondsToSelector:@selector(openURL:)] == YES)
        {
            //Shared Defaults
            NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:kSharedDefaultsSuiteName];
            [sharedDefaults setObject:self.contentText forKey:kSharedDocument];
            [sharedDefaults setBool:YES forKey:kIsSharedDocument];
            [sharedDefaults synchronize];
            
            //PasteBoard
            if (self.pasteBoard == nil) {
                self.pasteBoard = [UIPasteboard generalPasteboard];
                self.pasteBoard.persistent = YES;
            }
            
            [self.pasteBoard setString:self.contentText];
            
            [responder performSelector:@selector(openURL:) withObject:[NSURL URLWithString:@"readtome://"]];
        }
    }
    
    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}


- (NSArray *)configurationItems
{
    return @[];
}


@end
