//
//  ViewController.m
//  ReadToMe
//
//  Created by jun on 3/23/15.
//  Copyright (c) 2015 keicoder. All rights reserved.
//

#import "ContainerViewController.h"

@interface ContainerViewController ()

@property (nonatomic, weak) IBOutlet UITextView *textView;

@end


@implementation ContainerViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)actionButtonPressed:(id)sender
{
	UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[self.textView.text] applicationActivities:nil];
	[self presentViewController:activityVC animated:YES completion:nil];
}


@end
