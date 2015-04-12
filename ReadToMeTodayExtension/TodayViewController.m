//
//  TodayViewController.m
//  ReadToMeTodayExtension
//
//  Created by jun on 2015. 4. 12..
//  Copyright (c) 2015년 keicoder. All rights reserved.
//
#define debug 1


#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

@interface TodayViewController () <NCWidgetProviding>

@property (nonatomic, strong) UIPasteboard *pasteBoard;
@property (weak, nonatomic) IBOutlet UIButton *readToMeButton;
@property (weak, nonatomic) IBOutlet UILabel *readToMeLabel;

@end


@implementation TodayViewController

- (IBAction)readToMeButtonTapped:(id)sender
{
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
}


- (void)viewDidLoad {
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    [super viewWillAppear:animated];
    
    //PasteBoard
    if (self.pasteBoard == nil) {
        NSLog (@"self.pasteBoard is nil: %@\n", self.pasteBoard);
        self.pasteBoard = [UIPasteboard generalPasteboard];
        NSLog (@"self.pasteBoard is not nil: %@\n", self.pasteBoard);
    }
    self.pasteBoard.persistent = YES;
    [self checkToPasteText];
    [self.view layoutIfNeeded];
}


-(void)viewDidAppear:(BOOL)animated
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    [super viewDidAppear:animated];
    
    //[self checkToPasteText];
}



#pragma mark - Paste Text

- (void)checkToPasteText
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    if (self.pasteBoard.string == NULL || self.pasteBoard.string == nil || [self.pasteBoard.string  isEqualToString: @""]) {
        NSLog(@"self.pasteBoard.string is null");
    }
    else if ([self.pasteBoard.string isEqualToString:self.readToMeLabel.text]) {
        NSLog(@"self.pasteBoard.string and self.readToMeLabel.text are equal, so nothing happened");
        
    }
    else {
        NSLog(@"self.pasteBoard.string and self.readToMeLabel.text are not equal, so paste it to readToMeLabel");
        self.readToMeLabel.text = self.pasteBoard.string;
        NSLog(@"paste done");
    }
}


- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    //[self checkToPasteText];
    //[self.view layoutIfNeeded];
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData

    completionHandler(NCUpdateResultNewData);
}

@end
