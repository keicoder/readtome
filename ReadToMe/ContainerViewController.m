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


#import "ContainerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UIImage+ChangeColor.h"
#import "SettingsViewController.h"


@interface ContainerViewController () <AVSpeechSynthesizerDelegate>

@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet UIButton *playPauseButton;
@property (nonatomic, weak) IBOutlet UIButton *settingsButton;

@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;
@property (nonatomic, strong) NSString *utteranceString;

@property (nonatomic, strong) NSArray *languageCodes;
@property (nonatomic, strong) NSDictionary *languageDictionary;
@property (strong, nonatomic) NSString *selectedLanguage;

@property (strong, nonatomic) NSDictionary *paragraphAttributes;

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
	self.textView.attributedText = [[NSAttributedString alloc] initWithString:self.textView.attributedText.string attributes:self.paragraphAttributes];
}


#pragma mark - Speech

- (IBAction)pasteAndSpeech:(id)sender
{
	if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
	
	NSLog (@"[AVSpeechSynthesisVoice speechVoices]: %@\n", [AVSpeechSynthesisVoice speechVoices]);
	
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
				[self.playPauseButton setImage:kPause forState:UIControlStateNormal];
				[self.synthesizer continueSpeaking];
				_paused = NO;
			} else {
				[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
				_paused = YES;
				[self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
			}
			
			if (self.synthesizer.isSpeaking == NO) {
				
				self.synthesizer = [[AVSpeechSynthesizer alloc]init];
				self.synthesizer.delegate = self;
				
				AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:self.utteranceString];
				utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"];
				[utterance setRate:0.07];
				utterance.pitchMultiplier = 1.1; // higher pitch
				utterance.preUtteranceDelay = 0.2f;
				utterance.postUtteranceDelay = 0.2f;
				
				[self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryWord];
				[self.synthesizer speakUtterance:utterance];
			}
		}];
		
	} else if (pasteBoard == nil) {
		
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

- (IBAction)settingsButtonTapped:(id)sender
{
	NSLog(@"self.settingsButton Tapped");
	[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
	_paused = YES;
	[self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
	SettingsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingsViewController"];
	[self presentViewController:controller animated:YES completion:^{ }];
}


#pragma mark - AVSpeechSynthesizerDelegate

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer willSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance
{
	
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
	[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
	_paused = YES;
	NSLog(@"Playback finished");
}


#pragma mark - NSAttributedString

- (NSDictionary *)paragraphAttributes
{
	if ( _paragraphAttributes == nil) {
		
		UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
		
		NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		paragraphStyle.firstLineHeadIndent = 14.0f;
		paragraphStyle.lineSpacing = 6.0f;
		paragraphStyle.paragraphSpacing = 14.0f;
		paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
		
		NSShadow *shadow = [[NSShadow alloc] init];
		[shadow setShadowColor:[UIColor grayColor]];
		[shadow setShadowOffset:CGSizeMake(0, 0)];
		[shadow setShadowBlurRadius:0];
		
		_paragraphAttributes = @{ NSFontAttributeName: font, NSParagraphStyleAttributeName: paragraphStyle, NSForegroundColorAttributeName: [UIColor darkTextColor], NSShadowAttributeName: shadow };
	}
	
	return _paragraphAttributes;
}


#pragma mark - Configure UI

- (void)configureUI
{
	float cornerRadius = self.playPauseButton.bounds.size.height/2;
	self.playPauseButton.layer.cornerRadius = cornerRadius;
	self.settingsButton.layer.cornerRadius = cornerRadius;
	
	//Image View
	[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
	[self.settingsButton setImage:kSettings forState:UIControlStateNormal];
	
}


@end
