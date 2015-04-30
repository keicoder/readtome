//
//  TodayViewController.m
//  ReadToMeTodayExtension
//
//  Created by jun on 2015. 4. 12..
//  Copyright (c) 2015년 keicoder. All rights reserved.
//

#define debug 1

#define kSharedDefaultsSuiteName                @"group.com.keicoder.demo.readtome"
#define kTodayDocument                          @"kTodayDocument"
#define kIsTodayDocument                        @"kIsTodayDocument"


#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

@interface TodayViewController () <NCWidgetProviding>

@property (nonatomic, strong) UIPasteboard *pasteBoard;
@property (weak, nonatomic) IBOutlet UIButton *readToMeButton;
@property (weak, nonatomic) IBOutlet UILabel *readToMeLabel;

@end


@implementation TodayViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.pasteBoard == nil) {
        self.pasteBoard = [UIPasteboard generalPasteboard];
        self.pasteBoard.persistent = YES;
    }
    
    [self checkToPasteText];
    [self.view layoutIfNeeded];
}


#pragma mark - Paste Text

- (void)checkToPasteText
{
    if (!self.pasteBoard.string) {
        
        self.pasteBoard.string = @"Copy whatever you want to read, ReadToMe will read aloud for you.\n\nYou can play, pause or replay whenever you want.\n\nEnjoy reading!";
        self.readToMeLabel.text = self.pasteBoard.string;
        
    } else if ([self.pasteBoard.string isEqualToString:self.readToMeLabel.text]) {
        
        NSLog(@"self.pasteBoard.string and self.readToMeLabel.text are equal, so nothing happened");
        
    } else {
        
        self.readToMeLabel.text = self.pasteBoard.string;
        NSLog(@"Today widget paste done");
    }
}


- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler
{
    
    completionHandler(NCUpdateResultNewData);
}


- (IBAction)readToMeButtonTapped:(id)sender
{
    //Open URL
    UIResponder* responder = self;
    while ((responder = [responder nextResponder]) != nil)
    {
        NSLog(@"responder = %@", responder);
        if([responder respondsToSelector:@selector(openURL:)] == YES)
        {
            //Shared Defaults
            NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:kSharedDefaultsSuiteName];
            [sharedDefaults setObject:self.pasteBoard.string forKey:kTodayDocument];
            [sharedDefaults setBool:YES forKey:kIsTodayDocument];
            [sharedDefaults synchronize];
            
            [responder performSelector:@selector(openURL:) withObject:[NSURL URLWithString:@"readtome://"]];
        }
    }
}


@end
