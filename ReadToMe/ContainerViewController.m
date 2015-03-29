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
#define kVolumeSliderValue		@"kVolumeSliderValue"
#define kPitchSliderValue		@"kPitchSliderValue"
#define kRateSliderValue		@"kRateSliderValue"

#import "ContainerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UIImage+ChangeColor.h"
#import "SettingsViewController.h"
#import "LanguagePickerViewController.h"
#import "ListViewController.h"


@interface ContainerViewController () <AVSpeechSynthesizerDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *equalizerViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *menuView;
@property (weak, nonatomic) IBOutlet UIView *equalizerView;
@property (weak, nonatomic) IBOutlet UILabel *volumeLabel;
@property (weak, nonatomic) IBOutlet UILabel *pitchLabel;
@property (weak, nonatomic) IBOutlet UILabel *rateLabel;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;
@property (weak, nonatomic) IBOutlet UISlider *pitchSlider;
@property (weak, nonatomic) IBOutlet UISlider *rateSlider;

@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;

@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;
@property (nonatomic, strong) AVSpeechUtterance *utterance;
@property (nonatomic, strong) NSString *utteranceString;

@property (nonatomic, strong) NSArray *languageCodes;
@property (nonatomic, strong) NSDictionary *languageDictionary;

@property (strong, nonatomic) NSDictionary *paragraphAttributes;

@property (nonatomic, strong) UIPasteboard *pasteBoard;

@end


@implementation ContainerViewController
{
	BOOL _paused;
	BOOL _equalizerViewExpanded;
	NSUserDefaults *_defaults;
	CGFloat _volumeSliderValue;
	CGFloat _pitchSliderValue;
	CGFloat _rateSliderValue;
}

#pragma mark - View life cycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_equalizerViewExpanded = NO;
	[self configureUI];
	
	self.synthesizer = [[AVSpeechSynthesizer alloc]init];
	self.synthesizer.delegate = self;
	self.pasteBoard = [UIPasteboard generalPasteboard];
	self.pasteBoard.persistent = YES;
	self.textView.text = @"Hit the play button above to start your text. Pause it at any time. Resume it at any time. Stop it at any time.";
	self.textView.attributedText = [[NSAttributedString alloc] initWithString:self.textView.attributedText.string attributes:self.paragraphAttributes];
	
	_defaults = [NSUserDefaults standardUserDefaults];
	_paused = YES;
	
	[self selectedLanguage];
	[self volumeSliderValue];
	[self pitchSliderValue];
	[self rateSliderValue];
	
	
	
	[self addNotificationObserver];
}



- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self selectedLanguage];
	NSLog (@"self.selectedLanguage: %@\n", self.selectedLanguage);
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


- (CGFloat)volumeSliderValue
{
	_volumeSliderValue = [_defaults floatForKey:kVolumeSliderValue];
	
	self.volumeSlider.value = _volumeSliderValue;
	NSLog (@"_volumeSliderValue: %f\n", _volumeSliderValue);
	return _volumeSliderValue;
}


- (CGFloat)pitchSliderValue
{
	_pitchSliderValue = [_defaults floatForKey:kPitchSliderValue];
	
	self.pitchSlider.value = _pitchSliderValue;
	NSLog (@"_pitchSliderValue: %f\n", _pitchSliderValue);
	return _pitchSliderValue;
}


- (CGFloat)rateSliderValue
{
	_rateSliderValue = [_defaults floatForKey:kRateSliderValue];
	
	self.rateSlider.value = _rateSliderValue;
	NSLog (@"_rateSliderValue: %f\n", _rateSliderValue);
	return _rateSliderValue;
}


#pragma mark - Speech

- (IBAction)pasteAndSpeechText:(UIPasteboard *)pasteboard
{
	[self.textView resignFirstResponder];
	
	self.textView.text = [self.pasteBoard string];
	
	if (![self.textView.text isEqualToString:@""]) {
		
		self.utterance = [AVSpeechUtterance speechUtteranceWithString:self.textView.text];
		self.utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:self.selectedLanguage];
		self.utterance.rate = _rateSliderValue; //0.07;
		self.utterance.pitchMultiplier = _pitchSliderValue; //1.0;
		self.utterance.volume = _volumeSliderValue; //0.5;
		self.utterance.preUtteranceDelay = 0.3f;
		self.utterance.postUtteranceDelay = 0.3f;
		
		if (_paused == YES) {
			[self.playPauseButton setImage:kPause forState:UIControlStateNormal];
			[self.synthesizer continueSpeaking];
			_paused = NO;
			[self adjustStopButtonAlpha:1.0];
		} else {
			[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
			[self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
			_paused = YES;
			[self adjustStopButtonAlpha:0.0];
		}
		
		if (self.synthesizer.isSpeaking == NO) {
			[self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryWord];
			[self.synthesizer speakUtterance:self.utterance];
			[self adjustStopButtonAlpha:1.0];
		}
		
	} else {
		
		NSString *title = @"No Text to speech";
		NSString *message = @"There are no text to speech.";
		
		UIAlertController *sheet = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
		[sheet addAction:[UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:^void (UIAlertAction *action) {
			NSLog(@"Tapped OK");
		}]];
		
		sheet.popoverPresentationController.sourceView = self.view;
		sheet.popoverPresentationController.sourceRect = self.view.frame;
		
		[self presentViewController:sheet animated:YES completion:nil];
	}
}


#pragma mark - Button Action Methods

- (IBAction)listButtonTapped:(id)sender
{
	[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
	_paused = YES;
	[self adjustStopButtonAlpha:0.0];
	[self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
	ListViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"ListViewController"];
	[self presentViewController:controller animated:YES completion:^{ }];
}


- (IBAction)stopButtonTapped:(id)sender
{
	[self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
	[self adjustStopButtonAlpha:0.0];
	[self pasteAndSpeechText:self.pasteBoard];
}


- (IBAction)languageButtonTapped:(id)sender
{
	if (_equalizerViewExpanded == YES) {
		[self adjustEqualizerViewHeight];
	}
	[self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
	[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
	_paused = YES;
	[self adjustStopButtonAlpha:0.0];
	[self performSelector:@selector(showLanguagePickerView:) withObject:nil afterDelay:0.4];
}


- (void)showLanguagePickerView:(id)sender
{
	LanguagePickerViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"LanguagePickerViewController"];
	[self presentViewController:controller animated:YES completion:^{ }];
}


- (IBAction)equalizerButtonTappped:(id)sender
{
	[self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
	[self adjustEqualizerViewHeight];
	[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
	_paused = YES;
}


- (IBAction)settingsButtonTapped:(id)sender
{
	[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
	_paused = YES;
	[self adjustStopButtonAlpha:0.0];
	[self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
	SettingsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingsViewController"];
	[self presentViewController:controller animated:YES completion:^{ }];
}


#pragma mark - AVSpeechSynthesizerDelegate

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer willSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance
{
	self.utterance.volume = _volumeSliderValue;
	self.utterance.pitchMultiplier = _pitchSliderValue;
	self.utterance.rate = _rateSliderValue;
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
	[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
	[self adjustStopButtonAlpha:0.0];
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


#pragma mark - Slider value changed

- (IBAction)volumeSliderValueChanged:(UISlider *)sender
{
	NSLog (@"self.volumeSlider.value: %f\n", sender.value);
	[self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
	_paused = YES;
	[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
	[self adjustStopButtonAlpha:0.0];
	_volumeSliderValue = sender.value;
	[_defaults setFloat:sender.value forKey:kVolumeSliderValue];
	[_defaults synchronize];
	
}


- (IBAction)pitchSliderValueChanged:(UISlider *)sender
{
	NSLog (@"self.pitchSlider.value: %f\n", sender.value);
	[self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
	_paused = YES;
	[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
	[self adjustStopButtonAlpha:0.0];
	_pitchSliderValue = sender.value;
	[_defaults setFloat:sender.value forKey:kPitchSliderValue];
	[_defaults synchronize];
}


- (IBAction)rateSliderValueChanged:(UISlider *)sender
{
	NSLog (@"self.rateSlider.value: %f\n", self.rateSlider.value);
	[self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
	_paused = YES;
	[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
	[self adjustStopButtonAlpha:0.0];
	_rateSliderValue = sender.value;
	[_defaults setFloat:self.rateSlider.value forKey:kRateSliderValue];
	[_defaults synchronize];
}


#pragma mark - Listening Notification

- (void)addNotificationObserver
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPickedLanguageNotification:) name:@"DidPickedLanguageNotification" object:nil];
}


- (void)didPickedLanguageNotification:(NSNotification *)notification
{
	NSLog(@"DidPickedLanguageNotification Recieved");
	self.utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:self.selectedLanguage];
}



#pragma mark - Show stop button when speech started

- (void)adjustStopButtonAlpha:(CGFloat)alpha
{
	CGFloat duration = 0.25f;
	[UIView animateWithDuration:duration animations:^{
		self.stopButton.alpha = alpha;
	}completion:^(BOOL finished) { }];
}


#pragma mark - Show equalizer view when user touches equalizer button

- (void)adjustEqualizerViewHeight
{
	if (_equalizerViewExpanded == YES) {
		self.equalizerViewHeightConstraint.constant = 0.0;
		_equalizerViewExpanded = NO;
	} else {
		self.equalizerViewHeightConstraint.constant = 180.0;
		_equalizerViewExpanded = YES;
	}
	
	CGFloat duration = 0.3f;
	CGFloat delay = 0.3f;
	[UIView animateWithDuration:duration delay:delay options: UIViewAnimationOptionCurveEaseInOut animations:^{
		
		[self.view layoutIfNeeded];
		
		if (_equalizerViewExpanded == YES) {
			self.volumeLabel.alpha = 1.0;
			self.pitchLabel.alpha = 1.0;
			self.rateLabel.alpha = 1.0;
			self.volumeSlider.alpha = 1.0;
			self.pitchSlider.alpha = 1.0;
			self.rateSlider.alpha = 1.0;
			
		} else {
			self.volumeLabel.alpha = 0.0;
			self.pitchLabel.alpha = 0.0;
			self.rateLabel.alpha = 0.0;
			self.volumeSlider.alpha = 0.0;
			self.pitchSlider.alpha = 0.0;
			self.rateSlider.alpha = 0.0;
		}
		
	} completion:^(BOOL finished) { }];
}


#pragma mark - Configure UI

- (void)configureUI
{
	self.menuView.backgroundColor = [UIColor colorWithRed:0.161 green:0.502 blue:0.725 alpha:1];
	self.equalizerView.backgroundColor = [UIColor colorWithRed:0.204 green:0.596 blue:0.859 alpha:1];
	
	//Image View
	[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
	
	//Button
	self.stopButton.alpha = 0.0;
	
	//Equalizer View
	self.volumeLabel.alpha = 0.0;
	self.pitchLabel.alpha = 0.0;
	self.rateLabel.alpha = 0.0;
	self.volumeSlider.alpha = 0.0;
	self.pitchSlider.alpha = 0.0;
	self.rateSlider.alpha = 0.0;
}


@end
