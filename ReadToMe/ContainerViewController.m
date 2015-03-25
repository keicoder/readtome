//
//  ViewController.m
//  ReadToMe
//
//  Created by jun on 3/23/15.
//  Copyright (c) 2015 keicoder. All rights reserved.
//

#define debug					1
#define kBackgroundColor		[UIColor colorWithRed:0.286 green:0.58 blue:0.753 alpha:1]
#define kWhiteColor				[UIColor whiteColor]
#define kPause					[UIImage imageNamed:@"pause"]
#define kPlay					[UIImage imageNamed:@"play"]
#define kSettings				[UIImage imageNamed:@"settings"]
#define kPlayInset				UIEdgeInsetsMake(0, 6, 0, 0)
#define kPauseInset				UIEdgeInsetsMake(0, 0, 0, 0)


#import "ContainerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UIImage+ChangeColor.h"


@interface ContainerViewController () <AVSpeechSynthesizerDelegate>

@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
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
	_paused = YES;
	[self configureUI];
}


#pragma mark - Speech

- (IBAction)pasteAndSpeech:(id)sender
{
	if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
	
	[self.textView resignFirstResponder];
	self.textView.text = @"";
	
	UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
	pasteBoard.persistent = YES;
	
	if (pasteBoard != nil) {
		
		__weak UITextView *textView = self.textView;
		
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			
			textView.text = [pasteBoard string];
			self.utteranceString = textView.text;
			
			if (_paused == YES) {
				self.playPauseButton.imageEdgeInsets = kPlayInset;
				[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
				[self.synthesizer continueSpeaking];
				_paused = NO;
			} else {
				self.playPauseButton.imageEdgeInsets = kPauseInset;
				[self.playPauseButton setImage:kPause forState:UIControlStateNormal];
				_paused = YES;
				[self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
			}
			
			if (self.synthesizer.speaking == NO) {
				
				AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:self.utteranceString];
				utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"];
				[utterance setRate:0.09];
				utterance.preUtteranceDelay = 0.2f;
				utterance.postUtteranceDelay = 0.2f;
				
				self.synthesizer = [[AVSpeechSynthesizer alloc]init];
				self.synthesizer.delegate = self;
				[self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryWord];
				[self.synthesizer speakUtterance:utterance];
			}
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
	if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
	[self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
	UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[self.textView.text] applicationActivities:nil];
	[self presentViewController:activityVC animated:YES completion:nil];
}



#pragma mark - AVSpeechSynthesizerDelegate

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer willSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance
{
	if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
//	NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:utterance.speechString];
//	[mutableAttributedString addAttribute:NSForegroundColorAttributeName value:[UIColor orangeColor] range:characterRange];
//	self.textView.attributedText = mutableAttributedString;
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
	if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
	[self.playPauseButton setImage:kPause forState:UIControlStateNormal];
	_paused = YES;
	NSLog(@"Playback finished");
}


#pragma mark - Configure UI

- (void)configureUI
{
	float cornerRadius = self.playPauseButton.bounds.size.height/2;
	
	self.playPauseButton.layer.cornerRadius = cornerRadius;
	self.settingsButton.layer.cornerRadius = cornerRadius;
	
	//Image View
	self.playPauseButton.backgroundColor = kBackgroundColor;
	[self.playPauseButton setImage:kPause forState:UIControlStateNormal];
	self.settingsButton.backgroundColor = kBackgroundColor;
	[self.settingsButton setImage:kSettings forState:UIControlStateNormal];
	
}


@end
