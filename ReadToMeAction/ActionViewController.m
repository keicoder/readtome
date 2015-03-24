//
//  ActionViewController.m
//  ReadToMeAction
//
//  Created by jun on 3/23/15.
//  Copyright (c) 2015 keicoder. All rights reserved.
//

#define debug 1

#import "ActionViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>


@interface ActionViewController () <AVSpeechSynthesizerDelegate>

@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, strong) NSString *utteranceString;
@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;

@end


@implementation ActionViewController


#pragma mark - View life cycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.textView.text = @"";
}


#pragma mark - AVSpeechSynthesizerDelegate

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer willSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance
{
	NSLog(@"%@ %@", [self class], NSStringFromSelector(_cmd));
	
	NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:utterance.speechString];
	[mutableAttributedString addAttribute:NSForegroundColorAttributeName value:[UIColor orangeColor] range:characterRange];
	self.textView.attributedText = mutableAttributedString;
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance
{
	NSLog(@"%@ %@", [self class], NSStringFromSelector(_cmd));
	
	self.textView.attributedText = [[NSAttributedString alloc] initWithString:self.utteranceString];
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
	NSLog(@"%@ %@", [self class], NSStringFromSelector(_cmd));
	
	self.textView.attributedText = [[NSAttributedString alloc] initWithString:self.utteranceString];
}


#pragma mark - Button Action Methods

- (IBAction)pasteAndReadButtonTapped:(id)sender
{
	if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
	
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


- (IBAction)doneButtonTapped:(id)sender
{
	// Return any edited content to the host app. This template doesn't do anything, so we just echo the passed in items.
	[self.extensionContext completeRequestReturningItems:self.extensionContext.inputItems completionHandler:nil];
	[self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
}


@end