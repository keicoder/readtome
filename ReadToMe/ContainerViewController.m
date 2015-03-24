//
//  ViewController.m
//  ReadToMe
//
//  Created by jun on 3/23/15.
//  Copyright (c) 2015 keicoder. All rights reserved.
//

#define debug 1

#import "ContainerViewController.h"
#import <AVFoundation/AVFoundation.h>


@interface ContainerViewController () <AVSpeechSynthesizerDelegate>

@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet UIButton *playPauseButton;
@property (nonatomic, strong) NSString *utteranceString;
@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;

@end


@implementation ContainerViewController
{
	BOOL _paused;
}

#pragma mark - View life cycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	_paused = NO;
}



- (IBAction)playPauseButtonPressed:(UIButton *)sender
{
	[self.textView resignFirstResponder];
	
	if (_paused == NO) {
		[self.playPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
		[self.synthesizer continueSpeaking];
		_paused = YES;
	} else {
		[self.playPauseButton setTitle:@"Play" forState:UIControlStateNormal];
		_paused = NO;
		[self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
	}
	if (self.synthesizer.speaking == NO) {
		AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:self.textView.text];
		//utterance.rate = AVSpeechUtteranceMinimumSpeechRate;
		utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-au"];
		[self.synthesizer speakUtterance:utterance];
	}
}


#pragma mark - Speech

- (IBAction)pasteAndSpeech:(id)sender
{
	if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
	
	self.textView.text = @"";
	
	[self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
	
	UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
	pasteBoard.persistent = YES;
	
	if (pasteBoard != nil) {
		
		__weak UITextView *textView = self.textView;
		
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			
			textView.text = [pasteBoard string];
			self.utteranceString = textView.text;
			
			AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:self.utteranceString];
			utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"];
			[utterance setRate:0.09]; //AVSpeechUtteranceMinimumSpeechRate
			utterance.preUtteranceDelay = 0.2f;
			utterance.postUtteranceDelay = 0.2f;
			
			self.synthesizer = [[AVSpeechSynthesizer alloc]init];
			self.synthesizer.delegate = self;
			[self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryWord];
			[self.synthesizer speakUtterance:utterance];
		}];
		
	} else {
		
		NSString *title = @"No Text";
		NSString *message = @"There are no text to speech.";
		
		UIAlertController *sheet = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
		[sheet addAction:[UIAlertAction actionWithTitle:@"확인" style:UIAlertActionStyleDefault handler:^void (UIAlertAction *action) {
			NSLog(@"Tapped OK");
		}]];
		
		sheet.popoverPresentationController.sourceView = self.view;
		sheet.popoverPresentationController.sourceRect = self.view.frame;
		
		[self presentViewController:sheet animated:YES completion:nil];
	}
}


#pragma mark - Button Action Methods

- (IBAction)actionButtonPressed:(id)sender
{
	[self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
	
	UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[self.textView.text] applicationActivities:nil];
	[self presentViewController:activityVC animated:YES completion:nil];
}



#pragma mark - AVSpeechSynthesizerDelegate

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer willSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance
{
	NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:utterance.speechString];
	[mutableAttributedString addAttribute:NSForegroundColorAttributeName value:[UIColor orangeColor] range:characterRange];
	self.textView.attributedText = mutableAttributedString;
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance
{
	self.textView.attributedText = [[NSAttributedString alloc] initWithString:self.utteranceString];
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
	self.textView.attributedText = [[NSAttributedString alloc] initWithString:self.utteranceString];
}


@end
