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
#define kSelectedLanguage		@"kSelectedLanguage"


#import "ContainerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UIImage+ChangeColor.h"
#import "SettingsViewController.h"


@interface ContainerViewController () <AVSpeechSynthesizerDelegate>

@property (weak, nonatomic) IBOutlet UIView *menuView;
@property (weak, nonatomic) IBOutlet UIView *equalizerView;

@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet UIButton *playPauseButton;
@property (nonatomic, weak) IBOutlet UIButton *settingsButton;

@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;
@property (nonatomic, strong) NSString *utteranceString;

@property (nonatomic, strong) NSArray *languageCodes;
@property (nonatomic, strong) NSDictionary *languageDictionary;

@property (strong, nonatomic) NSDictionary *paragraphAttributes;

@property (nonatomic, strong) UIPasteboard *pasteBoard;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *equalizerViewHeightConstraint;

@end


@implementation ContainerViewController
{
	BOOL _paused;
	BOOL _volumeViewExpanded;
	NSUserDefaults *_defaults;
	NSString *_selectedLanguage;
}

#pragma mark - View life cycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	_volumeViewExpanded = YES;
	[self adjustEqualizerViewHeight];
	_defaults = [NSUserDefaults standardUserDefaults];
	_paused = YES;
	self.pasteBoard = [UIPasteboard generalPasteboard];
	self.pasteBoard.persistent = YES;
	[self configureUI];
	self.textView.text = @"Hit the play button above to start your text. Pause it at any time. Resume it at any time. ";
	self.textView.attributedText = [[NSAttributedString alloc] initWithString:self.textView.attributedText.string attributes:self.paragraphAttributes];
	NSLog (@"[AVSpeechSynthesisVoice speechVoices]: %@\n", [AVSpeechSynthesisVoice speechVoices]);
	[self selectedLanguage];
	self.synthesizer = [[AVSpeechSynthesizer alloc]init];
	self.synthesizer.delegate = self;
}



- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self selectedLanguage];
}


#pragma mark - State Restoration

- (NSString *)selectedLanguage
{
	_selectedLanguage = [_defaults objectForKey:kSelectedLanguage];
	
	if ([_selectedLanguage isKindOfClass:[NSNull class]]) {
		
		_selectedLanguage = @"en-US";
		[_defaults setObject:_selectedLanguage forKey:kSelectedLanguage];
		[_defaults synchronize];
		
	} else {
		
		_selectedLanguage = [_defaults objectForKey:kSelectedLanguage];
		
	}
	
	NSLog (@"_selectedLanguage: %@\n", _selectedLanguage);
	return _selectedLanguage;
}


#pragma mark - Speech

- (IBAction)pasteAndSpeechText:(UIPasteboard *)pasteboard
{
	[self.textView resignFirstResponder];
	
	self.textView.text = [self.pasteBoard string];
	
	if (![self.textView.text isEqualToString:@""]) {
		
		AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:self.textView.text];
		utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:_selectedLanguage];
		utterance.rate = 0.07;
		utterance.pitchMultiplier = 1.0;
		utterance.volume = 0.5;
		utterance.preUtteranceDelay = 0.3f;
		utterance.postUtteranceDelay = 0.3f;
		
		if (_paused == YES) {
			[self.playPauseButton setImage:kPause forState:UIControlStateNormal];
			[self.synthesizer continueSpeaking];
			_paused = NO;
			
		} else {
			[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
			[self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
			_paused = YES;
			
		}
		
		if (self.synthesizer.isSpeaking == NO) {
			[self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryWord];
			[self.synthesizer speakUtterance:utterance];
			
		}
		
	} else {
		
		NSString *title = @"No Text to speech";
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

- (IBAction)resetButtonTapped:(id)sender
{
	NSLog(@"Reset Button Tapped");
	[self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
	[self pasteAndSpeechText:self.pasteBoard];
}


- (IBAction)equalizerButtonTappped:(id)sender
{
	[self adjustEqualizerViewHeight];
}


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
}


#pragma mark - NSAttributedString

- (NSDictionary *)paragraphAttributes
{
	if ( _paragraphAttributes == nil) {
		
		UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
		
		NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		paragraphStyle.firstLineHeadIndent = 0.0f;
		paragraphStyle.lineSpacing = 5.0f;
		paragraphStyle.paragraphSpacing = 10.0f;
		paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
		
		_paragraphAttributes = @{ NSFontAttributeName: font, NSParagraphStyleAttributeName: paragraphStyle, NSForegroundColorAttributeName: [UIColor darkTextColor] };
	}
	
	return _paragraphAttributes;
}


#pragma mark - Show volumeView when user touches speakerIcon

- (void)adjustEqualizerViewHeight
{
	if (_volumeViewExpanded == NO) {
		self.equalizerViewHeightConstraint.constant = 60;
		_volumeViewExpanded = YES;
	} else {
		self.equalizerViewHeightConstraint.constant = 0;
		_volumeViewExpanded = NO;
	}
	
	CGFloat duration = 0.3f;
	CGFloat delay = 0.3f;
	[UIView animateWithDuration:duration delay:delay options: UIViewAnimationOptionCurveEaseInOut animations:^{
		
		[self.view layoutIfNeeded];
		
	} completion:^(BOOL finished) { }];
}


#pragma mark - Configure UI

- (void)configureUI
{
	self.menuView.backgroundColor = [UIColor colorWithRed:0.396 green:0.675 blue:0.82 alpha:1];
	self.equalizerView.backgroundColor = [UIColor colorWithRed:0.137 green:0.271 blue:0.424 alpha:1];
	float cornerRadius = self.playPauseButton.bounds.size.height/2;
	self.playPauseButton.layer.cornerRadius = cornerRadius;
	self.settingsButton.layer.cornerRadius = cornerRadius;
	
	//Image View
	[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
	[self.settingsButton setImage:kSettings forState:UIControlStateNormal];
	
}


@end
