//
//  OpenSourceLicencesViewController.m
//  ReadToMe
//
//  Created by jun on 4/2/15.
//  Copyright (c) 2015 keicoder. All rights reserved.
//

#import "OpenSourceLicencesViewController.h"

@interface OpenSourceLicencesViewController ()

@property (weak, nonatomic) IBOutlet UIView *menuView;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end


@implementation OpenSourceLicencesViewController

#pragma mark - View life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureUI];
	[self updateTextViewsText];
}


- (void)updateTextViewsText
{
	self.textView.text = @"FACEBOOK/POP LICENSE\n\nBSD License\n\nFor Pop software\n\nCopyright (c) 2014, Facebook, Inc. All rights reserved.\n\nRedistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:\n\n* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.\n\n* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.\n\n* Neither the name Facebook nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.\n\nTHIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS AS IS AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.";
}


#pragma mark - Button Action Methods

- (IBAction)returnButtonTapped:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Configure UI

- (void)configureUI
{
	self.menuView.backgroundColor = [UIColor colorWithRed:0.204 green:0.596 blue:0.859 alpha:1];
}


@end
