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
#define kHasLaunchedOnce        @"kHasLaunchedOnce"
#define kBackgroundPlayValue	@"kBackgroundPlayValue"
#define kBackgroundOn			@"Background On"


#import "ContainerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UIImage+ChangeColor.h"
#import "SettingsViewController.h"
#import "LanguagePickerViewController.h"
#import "ListViewController.h"
#import <CoreData/CoreData.h>
#import "DocumentsForSpeech.h"
#import "DataManager.h"


@interface ContainerViewController () <AVSpeechSynthesizerDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *equalizerViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *saveAlertViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *menuView;
@property (weak, nonatomic) IBOutlet UIView *saveAlertView;
@property (weak, nonatomic) IBOutlet UILabel *saveAlertLabel;

@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIView *equalizerView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UILabel *volumeLabel;
@property (weak, nonatomic) IBOutlet UILabel *pitchLabel;
@property (weak, nonatomic) IBOutlet UILabel *rateLabel;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;
@property (weak, nonatomic) IBOutlet UISlider *pitchSlider;
@property (weak, nonatomic) IBOutlet UISlider *rateSlider;

@property (nonatomic, weak) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;

@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;
@property (nonatomic, strong) AVSpeechUtterance *utterance;
@property (nonatomic, strong) NSString *utteranceString;

@property (nonatomic, strong) NSArray *languageCodes;
@property (nonatomic, strong) NSDictionary *languageDictionary;

@property (strong, nonatomic) NSDictionary *paragraphAttributes;

@property (nonatomic, strong) UIPasteboard *pasteBoard;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end


@implementation ContainerViewController
{
	DocumentsForSpeech *_receivedDocument;
	BOOL _paused;
	BOOL _saveAlertViewExpanded;
	BOOL _equalizerViewExpanded;
	NSUserDefaults *_defaults;
	CGFloat _volumeSliderValue;
	CGFloat _pitchSliderValue;
	CGFloat _rateSliderValue;
	NSString *_backgroundPlayValue;
}


#pragma mark - View life cycle

- (void)setInitialData
{
	self.managedObjectContext = [DataManager sharedDataManager].managedObjectContext;
	
	self.synthesizer = [[AVSpeechSynthesizer alloc]init];
	self.synthesizer.delegate = self;
	self.pasteBoard = [UIPasteboard generalPasteboard];
	self.pasteBoard.persistent = YES;
	self.textView.text = @"Just copy text whatever you want, and hit the play button above to start your text. Pause it at any time. Resume it at any time. Stop it at any time.";
	self.textView.attributedText = [[NSAttributedString alloc] initWithString:self.textView.attributedText.string attributes:self.paragraphAttributes];
	
	_defaults = [NSUserDefaults standardUserDefaults];
	_paused = YES;
	_backgroundPlayValue = [_defaults objectForKey:kBackgroundPlayValue];
	
	_saveAlertViewExpanded = NO;
	self.saveAlertLabel.alpha = 0.0;
	_equalizerViewExpanded = NO;
}


- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[self configureUI];
	[self setInitialData]; //순서 바꾸지 말 것
    [self checkHasLaunchedOnce];
	[self addPickedLanguageObserver];
	[self addApplicationsStateObserver];
	[self addDidSelectDocumentForSpeechFromListViewObserver];
}



- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self selectedLanguage];
	[self volumeSliderValue];
	[self pitchSliderValue];
	[self rateSliderValue];
	[self pasteText];
}


-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}


#pragma mark - State Restoration

- (NSString *)selectedLanguage
{
    _selectedLanguage = [_defaults objectForKey:kSelectedLanguage];
	return _selectedLanguage;
}


- (CGFloat)volumeSliderValue
{
	_volumeSliderValue = [_defaults floatForKey:kVolumeSliderValue];
	self.volumeSlider.value = _volumeSliderValue;
	return _volumeSliderValue;
}


- (CGFloat)pitchSliderValue
{
	_pitchSliderValue = [_defaults floatForKey:kPitchSliderValue];
	self.pitchSlider.value = _pitchSliderValue;
	return _pitchSliderValue;
}


- (CGFloat)rateSliderValue
{
	_rateSliderValue = [_defaults floatForKey:kRateSliderValue];
	self.rateSlider.value = _rateSliderValue;
	return _rateSliderValue;
}


#pragma mark - Speech

- (IBAction)speechText:(id)sender
{
	self.utterance = [AVSpeechUtterance speechUtteranceWithString:self.textView.text];
	
	if (self.currentDocumentsForSpeech.language) {
		self.utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:self.currentDocumentsForSpeech.language];
		NSLog (@"self.currentDocumentsForSpeech.language: %@\n", self.currentDocumentsForSpeech.language);
	} else {
		self.utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:self.selectedLanguage];
		NSLog (@"self.selectedLanguage: %@\n", self.selectedLanguage);
	}
	
	if ([self.currentDocumentsForSpeech.volume floatValue]) {
		self.utterance.volume = [self.currentDocumentsForSpeech.volume floatValue]; //1.0;
		NSLog (@"[self.currentDocumentsForSpeech.volume floatValue]: %f\n", [self.currentDocumentsForSpeech.volume floatValue]);
	} else {
		self.utterance.volume = _volumeSliderValue; //1.0;
		NSLog (@"_volumeSliderValue: %f\n", _volumeSliderValue);
	}
	
	if ([self.currentDocumentsForSpeech.pitch floatValue]) {
		self.utterance.pitchMultiplier = [self.currentDocumentsForSpeech.pitch floatValue]; //1.0;
		NSLog (@"[self.currentDocumentsForSpeech.pitch floatValue]: %f\n", [self.currentDocumentsForSpeech.pitch floatValue]);
	} else {
		self.utterance.pitchMultiplier = _pitchSliderValue; //1.0;
		NSLog (@"_pitchSliderValue: %f\n", _pitchSliderValue);
	}
	
	if ([self.currentDocumentsForSpeech.rate floatValue]) {
		self.utterance.rate = [self.currentDocumentsForSpeech.rate floatValue]; //0.07;
		NSLog (@"[self.currentDocumentsForSpeech.rate floatValue]: %f\n", [self.currentDocumentsForSpeech.rate floatValue]);
	} else {
		self.utterance.rate = _rateSliderValue; //0.07;
		NSLog (@"_rateSliderValue: %f\n", _rateSliderValue);
	}
	
	self.utterance.preUtteranceDelay = 0.3f;
	self.utterance.postUtteranceDelay = 0.3f;
	
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
		[self.playPauseButton setImage:kPause forState:UIControlStateNormal];
		[self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryWord];
		[self.synthesizer speakUtterance:self.utterance];
	}
}


- (NSString *)pasteText
{
	self.textView.text = [self.pasteBoard string];
	return self.textView.text;
}


#pragma mark - Save Current Documents For Speech

- (IBAction)saveCurrentDocumentToCoreDataStack:(id)sender
{
	DocumentsForSpeech *documentsForSpeech = [NSEntityDescription insertNewObjectForEntityForName:@"DocumentsForSpeech" inManagedObjectContext:self.managedObjectContext];
	
	documentsForSpeech.language = _selectedLanguage;
	documentsForSpeech.volume = [NSNumber numberWithFloat:_volumeSliderValue];;
	documentsForSpeech.pitch = [NSNumber numberWithFloat:_pitchSliderValue];
	documentsForSpeech.rate = [NSNumber numberWithFloat:_rateSliderValue];
	
	documentsForSpeech.document = self.textView.text;
	
	NSString *firstLineForTitle = [self getFirstLineOfStringForTitle:documentsForSpeech.document];
	documentsForSpeech.documentTitle = firstLineForTitle;
	
	[self.managedObjectContext performBlock:^{
		NSError *error = nil;
		if ([self.managedObjectContext save:&error]) {
			NSLog (@"Save succeed");
		} else {
			NSLog(@"Error saving context: %@", error);
		}
	}];
	
	[self adjustSaveAlertViewHeight];
}


#pragma mark - 첫째 라인만 가져오기

- (NSString *)getFirstLineOfStringForTitle:(NSString *)aString
{
	NSString *trimmedString = nil;
	NSCharacterSet *charSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];    //공백 문자와 라인 피드문자 삭제
	trimmedString = [aString stringByTrimmingCharactersInSet:charSet];
	
	__block NSString *firstLine = nil;
	NSString *wholeText = trimmedString;
	[wholeText enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
		firstLine = [line copy];
		*stop = YES;
	}];
	
	if (firstLine.length == 0)
	{
		firstLine = @"No Title";
	}
	
	if (firstLine.length > 0)
	{
		__block NSString *trimmedTitle = nil;
		[firstLine enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {trimmedTitle = line; *stop = YES;}];
	}
	return firstLine;
}


#pragma mark - Show no text to speech alert

- (void)showNoTextToSpeechAlertTitle:(NSString *)aTitle withBody:(NSString *)aBody
{
	NSString *title = aTitle;
	NSString *message = aBody;
	
	UIAlertController *sheet = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
	[sheet addAction:[UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:^void (UIAlertAction *action) {
		NSLog(@"Tapped OK");
	}]];
	
	sheet.popoverPresentationController.sourceView = self.view;
	sheet.popoverPresentationController.sourceRect = self.view.frame;
	
	[self presentViewController:sheet animated:YES completion:nil];
}


#pragma mark - Button Action Methods

- (IBAction)listButtonTapped:(id)sender
{
	[self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
	[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
	_paused = YES;
	
	if (_equalizerViewExpanded == YES) {
		[self adjustEqualizerViewHeight];
		[self performSelector:@selector(showListView:) withObject:nil afterDelay:0.35];
	} else {
		[self performSelector:@selector(showListView:) withObject:nil afterDelay:0.0];
	}
}


- (void)showListView:(id)sender
{
	ListViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"ListViewController"];
	[self presentViewController:controller animated:YES completion:^{ }];
}


- (IBAction)resetButtonTapped:(id)sender
{
	[self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
	[self speechText:sender];
}


- (IBAction)actionButtonTapped:(id)sender
{
	[self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
	[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
	_paused = YES;
	
	if (_equalizerViewExpanded == YES) {
		[self adjustEqualizerViewHeight];
		[self performSelector:@selector(action:) withObject:nil afterDelay:0.35];
	} else {
		[self performSelector:@selector(action:) withObject:nil afterDelay:0.0];
	}
}


- (void)action:(id)sender
{
	NSLog(@"Action");
}


- (IBAction)languageButtonTapped:(id)sender
{
	[self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
	[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
	_paused = YES;
	
	if (_equalizerViewExpanded == YES) {
		[self adjustEqualizerViewHeight];
		[self performSelector:@selector(showLanguagePickerView:) withObject:nil afterDelay:0.35];
	} else {
		[self performSelector:@selector(showLanguagePickerView:) withObject:nil afterDelay:0.0];
	}
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
	[self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
	
	if (_equalizerViewExpanded == YES) {
		[self adjustEqualizerViewHeight];
		[self performSelector:@selector(showSettingsView:) withObject:nil afterDelay:0.35];
	} else {
		[self performSelector:@selector(showSettingsView:) withObject:nil afterDelay:0.0];
	}
	
}


- (void)showSettingsView:(id)sender
{
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
	[self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
	_paused = YES;
	[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
	_volumeSliderValue = sender.value;
	[_defaults setFloat:sender.value forKey:kVolumeSliderValue];
	[_defaults synchronize];
	
}


- (IBAction)pitchSliderValueChanged:(UISlider *)sender
{
	[self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
	_paused = YES;
	[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
	_pitchSliderValue = sender.value;
	[_defaults setFloat:sender.value forKey:kPitchSliderValue];
	[_defaults synchronize];
}


- (IBAction)rateSliderValueChanged:(UISlider *)sender
{
	[self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
	_paused = YES;
	[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
	_rateSliderValue = sender.value;
	[_defaults setFloat:self.rateSlider.value forKey:kRateSliderValue];
	[_defaults synchronize];
}


#pragma mark - 앱 처음 실행인지 체크 > Volume, Pitch, Rate 기본값 적용

- (void)checkHasLaunchedOnce
{
    if ([_defaults boolForKey:kHasLaunchedOnce] == YES) {
		
        NSLog (@"HasLaunchedOnce: %@\n", [_defaults boolForKey:kHasLaunchedOnce] ? @"YES" : @"NO");
		
    } else {
		
        NSLog (@"HasLaunchedOnce: %@\n", [_defaults boolForKey:kHasLaunchedOnce] ? @"YES" : @"NO");
        [_defaults setBool:YES forKey:kHasLaunchedOnce];
        _selectedLanguage = @"en-US";
        [_defaults setObject:_selectedLanguage forKey:kSelectedLanguage];
        [_defaults setFloat:1.0 forKey:kVolumeSliderValue];
        [_defaults setFloat:1.0 forKey:kPitchSliderValue];
        [_defaults setFloat:0.07 forKey:kRateSliderValue];
		[_defaults setObject:kBackgroundOn forKey:kBackgroundPlayValue];
        [_defaults synchronize];
    }
}


#pragma mark - Show saveAlertView view when user touches archive button

- (void)adjustSaveAlertViewHeight
{
	CGFloat duration = 0.2f;
	CGFloat delay = 0.0f;
	
	[UIView animateWithDuration:duration delay:delay options: UIViewAnimationOptionCurveEaseInOut animations:^{
		
		_saveAlertViewExpanded = YES;
		self.saveAlertViewHeightConstraint.constant = 40.0;
		[self.view layoutIfNeeded];
		self.saveAlertLabel.alpha = 1.0;
		self.saveAlertLabel.text = @"Saved";
		
	} completion:^(BOOL finished) {
		
		[UIView animateWithDuration:duration delay:0.5 options: UIViewAnimationOptionCurveEaseInOut animations:^{
			
			_saveAlertViewExpanded = NO;
			self.saveAlertViewHeightConstraint.constant = 0.0;
			[self.view layoutIfNeeded];
			self.saveAlertLabel.alpha = 0.0;
			
		} completion:nil];
	}];
}


#pragma mark - Show equalizer view when user touches equalizer button

- (void)adjustEqualizerViewHeight
{
	if (_equalizerViewExpanded == YES) {
		self.equalizerViewHeightConstraint.constant = 0.0;
		_equalizerViewExpanded = NO;
	} else {
		self.equalizerViewHeightConstraint.constant = 150.0;
		_equalizerViewExpanded = YES;
	}
	
	CGFloat duration = 0.25f;
	CGFloat delay = 0.0f;
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
	UIColor *viewColor = [UIColor colorWithRed:0.161 green:0.502 blue:0.725 alpha:1];
	self.menuView.backgroundColor = viewColor;
	self.bottomView.backgroundColor = viewColor;
	self.equalizerView.backgroundColor = [UIColor colorWithRed:0.204 green:0.596 blue:0.859 alpha:1];
	
	//Image View
	[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
	
	//Equalizer View
	self.volumeLabel.alpha = 0.0;
	self.pitchLabel.alpha = 0.0;
	self.rateLabel.alpha = 0.0;
	self.volumeSlider.alpha = 0.0;
	self.pitchSlider.alpha = 0.0;
	self.rateSlider.alpha = 0.0;
}


#pragma mark - Listening Notification

- (void)addDidSelectDocumentForSpeechFromListViewObserver
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceivedSelectDocumentsForSpeechNotification:) name:@"DidSelectDocumentsForSpeechNotification" object:nil];
}


- (void)didReceivedSelectDocumentsForSpeechNotification:(NSNotification *)notification
{
	if ([[notification name] isEqualToString:@"DidSelectDocumentsForSpeechNotification"])
	{
		NSLog(@"DidSelectDocumentsForSpeechNotification Recieved");
		NSDictionary *userInfo = notification.userInfo;
		_receivedDocument = [userInfo objectForKey:@"DidSelectDocumentsForSpeechNotificationKey"];
		NSLog (@"_receivedDocument: %@\n", _receivedDocument);
		self.currentDocumentsForSpeech = _receivedDocument;
		
		self.textView.text = self.currentDocumentsForSpeech.document;
		_selectedLanguage = self.currentDocumentsForSpeech.language;
		_volumeSliderValue = [self.currentDocumentsForSpeech.volume floatValue];
		_pitchSliderValue = [self.currentDocumentsForSpeech.pitch floatValue];
		_rateSliderValue = [self.currentDocumentsForSpeech.rate floatValue];
		
		//Slider Value
		self.volumeSlider.value = [self.currentDocumentsForSpeech.volume floatValue];
		self.pitchSlider.value = [self.currentDocumentsForSpeech.pitch floatValue];
		self.rateSlider.value = [self.currentDocumentsForSpeech.rate floatValue];
		
		NSLog (@"self.currentDocumentsForSpeech.createdDate: %@\n", self.currentDocumentsForSpeech.createdDate);
		NSLog (@"self.currentDocumentsForSpeech.language: %@\n", self.currentDocumentsForSpeech.language);
		NSLog (@"self.currentDocumentsForSpeech.volume: %f\n", [self.currentDocumentsForSpeech.volume floatValue]);
		NSLog (@"self.currentDocumentsForSpeech.pitch: %f\n", [self.currentDocumentsForSpeech.pitch floatValue]);
		NSLog (@"self.currentDocumentsForSpeech.rate: %f\n", [self.currentDocumentsForSpeech.rate floatValue]);
		
		NSLog (@"self.currentDocumentsForSpeech.isNewDocument: %@\n", self.currentDocumentsForSpeech.isNewDocument ? @"Yes" : @"No");
		NSLog (@"self.currentDocumentsForSpeech.savedDocument: %@\n", self.currentDocumentsForSpeech.savedDocument);
		NSLog (@"self.currentDocumentsForSpeech.dateString: %@\n", self.currentDocumentsForSpeech.dateString);
		NSLog (@"self.currentDocumentsForSpeech.dayString: %@\n", self.currentDocumentsForSpeech.dayString);
		NSLog (@"self.currentDocumentsForSpeech.monthString: %@\n", self.currentDocumentsForSpeech.monthString);
		NSLog (@"self.currentDocumentsForSpeech.yearString: %@\n", self.currentDocumentsForSpeech.yearString);
		NSLog (@"self.currentDocumentsForSpeech.monthAndYearString: %@\n", self.currentDocumentsForSpeech.monthAndYearString);
		NSLog (@"self.currentDocumentsForSpeech.section: %@\n", self.currentDocumentsForSpeech.section);
		NSLog (@"self.currentDocumentsForSpeech.uniqueIdString: %@\n", self.currentDocumentsForSpeech.uniqueIdString);
		
//		NSLog (@"self.currentDocumentsForSpeech.documentTitle: %@\n", self.currentDocumentsForSpeech.documentTitle);
//		NSLog (@"self.currentDocumentsForSpeech.document: %@\n", self.currentDocumentsForSpeech.document);
	}
}


- (void)addPickedLanguageObserver
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPickedLanguageNotification:) name:@"DidPickedLanguageNotification" object:nil];
}


- (void)didPickedLanguageNotification:(NSNotification *)notification
{
	NSLog(@"DidPickedLanguageNotification Recieved");
	self.utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:self.selectedLanguage];
}


#pragma mark - Add Observer

- (void)addApplicationsStateObserver
{
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
	[center addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
	[center addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
	[center addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}


#pragma mark - Application's State

- (void)applicationWillResignActive
{
	NSLog(@"VC: %@", NSStringFromSelector(_cmd));
}


- (void)applicationDidBecomeActive
{
	NSLog(@"VC: %@", NSStringFromSelector(_cmd));
}


- (void)applicationDidEnterBackground
{
	NSLog(@"VC: %@", NSStringFromSelector(_cmd));
}


- (void)applicationWillEnterForeground
{
	NSLog(@"VC: %@", NSStringFromSelector(_cmd));
	[self pasteText];
}


@end
