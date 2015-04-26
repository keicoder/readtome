//
//  ViewController.m
//  ReadToMe
//
//  Created by jun on 3/23/15.
//  Copyright (c) 2015 keicoder. All rights reserved.
//

#define debug                       1

#define kPause                      [UIImage imageNamed:@"pause"]
#define kPlay                       [UIImage imageNamed:@"play"]

#define kHasLaunchedOnce            @"kHasLaunchedOnce"
#define kTypeSelecting              @"kTypeSelecting"
#define kLanguage                   @"kLanguage"
#define kVolumeValue                @"kVolumeValue"
#define kPitchValue                 @"kPitchValue"
#define kRateValue                  @"kRateValue"

#define kFontName                   @"HelveticaNeue-Light"
#define kFontSizeiPhone             20.0
#define kFontSizeiPad               22.0


#import "ContainerViewController.h"
@import AVFoundation;
#import "UIImage+ChangeColor.h"
#import "SettingsViewController.h"
#import "LanguagePickerViewController.h"
#import "ListViewController.h"
#import <CoreData/CoreData.h>
#import "DocumentsForSpeech.h"
#import "DataManager.h"
#import "AttributedTextView.h"


@interface ContainerViewController () <AVSpeechSynthesizerDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSMutableArray *fetchedDocuments;

@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;
@property (nonatomic, strong) AVSpeechUtterance *utterance;
@property (nonatomic, strong) UIPasteboard *pasteBoard;
@property (nonatomic, strong) NSUserDefaults *defaults;

@property (nonatomic, assign) float volume;
@property (nonatomic, assign) float pitch;
@property (nonatomic, assign) float rate;

@property (strong, nonatomic) NSDictionary *paragraphAttributes;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *equalizerViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *saveAlertViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *progressInfoViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *menuView;
@property (weak, nonatomic) IBOutlet UIButton *listButton;
@property (weak, nonatomic) IBOutlet UIButton *archiveButton;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;

@property (weak, nonatomic) IBOutlet UIView *progressView;
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;

@property (weak, nonatomic) IBOutlet UIView *saveAlertView;
@property (weak, nonatomic) IBOutlet UILabel *saveAlertLabel;

@property (weak, nonatomic) IBOutlet AttributedTextView *textView;

@property (weak, nonatomic) IBOutlet UIView *equalizerView;
@property (weak, nonatomic) IBOutlet UILabel *volumeLabel;
@property (weak, nonatomic) IBOutlet UILabel *pitchLabel;
@property (weak, nonatomic) IBOutlet UILabel *rateLabel;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;
@property (weak, nonatomic) IBOutlet UISlider *pitchSlider;
@property (weak, nonatomic) IBOutlet UISlider *rateSlider;

@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property (weak, nonatomic) IBOutlet UIButton *selectionButton;
@property (weak, nonatomic) IBOutlet UIButton *languageButton;
@property (weak, nonatomic) IBOutlet UIButton *equalizerButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;

@property (nonatomic, assign) BOOL isReceivedDocument;

@end


@implementation ContainerViewController
{
	BOOL _paused;
    BOOL _isTypeSelecting;
    BOOL _progressViewExpanded;
	BOOL _saveAlertViewExpanded;
	BOOL _equalizerViewExpanded;
    NSRange _selectedRange;
    int _spokenTextRangeLocation;
    int _spokenTextRangeLength;
    NSString *_subString;
    float _speechLocationPercentValueInWholeTexts;
}


#pragma mark - View life cycle

- (void)setInitialData
{
	self.managedObjectContext = [DataManager sharedDataManager].managedObjectContext;
    
	self.synthesizer = [[AVSpeechSynthesizer alloc]init];
	self.synthesizer.delegate = self;
	self.pasteBoard = [UIPasteboard generalPasteboard];
	self.pasteBoard.persistent = YES;
	self.defaults = [NSUserDefaults standardUserDefaults];
    
    _paused = YES;
    _subString = self.textView.text;
    
    [self hideSaveAlertViewEqualizerViewAndProgressViewWithNoAnimation]; //화면에 보여주지 않기
}


- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[self configureUI];
    [self configureSliderUI];
	[self setInitialData]; //순서 바꾸지 말 것
    [self setInitialTextAttributesSpeechLocationAndProgressSliderViewHeight];
    [self checkHasLaunchedOnce];
	[self addPickedLanguageObserver];
	[self addApplicationsStateObserver];
	[self addDidSelectDocumentForSpeechFromListViewObserver];
    [self addObserverForChangingSliderValue];
    
    //Speech Voices
    //NSLog (@"[AVSpeechSynthesisVoice speechVoices]: %@\n", [AVSpeechSynthesisVoice speechVoices]);
}


- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    [self checkToPasteText];
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self executePerformFetch];
}


- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:YES];
	_fetchedResultsController = nil;
}


#pragma mark - State Restoration

- (NSString *)speechLanguage
{
    self.language = [self.defaults objectForKey:kLanguage];
    //NSLog (@"self.language: %@\n", self.language);
    return self.language;
}


- (BOOL)typeSelecting
{
    _isTypeSelecting = [self.defaults boolForKey:kTypeSelecting];
    //NSLog (@"_isTypeSelecting: %@\n", _isTypeSelecting ? @"YES" : @"NO");
    return _isTypeSelecting;
}


- (CGFloat)volumeValue
{
    self.volume = [self.defaults floatForKey:kVolumeValue];
    self.volumeSlider.value = self.volume;
    //NSLog (@"self.volume: %f\n", self.volume);
    return self.volume;
}


- (CGFloat)pitchValue
{
    self.pitch = [self.defaults floatForKey:kPitchValue];
    self.pitchSlider.value = self.pitch;
    //NSLog (@"self.pitch: %f\n", self.pitch);
    return self.pitch;
}


- (CGFloat)rateValue
{
    self.rate = [self.defaults floatForKey:kRateValue];
    self.rateSlider.value = self.rate;
    //NSLog (@"self.rate: %f\n", self.rate);
    return self.rate;
}


#pragma mark - Slider value changed

- (IBAction)progressSliderValueChanged:(UISlider *)sender
{
    self.progressSlider.value = _speechLocationPercentValueInWholeTexts;
}



- (IBAction)volumeSliderValueChanged:(UISlider *)sender
{
    [self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    [self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
    _paused = YES;
    
    self.volume = sender.value;
    [self.defaults setFloat:sender.value forKey:kVolumeValue];
    [self.defaults synchronize];
    
    [self volumeValue];
}


- (IBAction)pitchSliderValueChanged:(UISlider *)sender
{
    [self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    [self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
    _paused = YES;
    
    self.pitch = sender.value;
    [self.defaults setFloat:sender.value forKey:kPitchValue];
    [self.defaults synchronize];
    
    [self pitchValue];
}


- (IBAction)rateSliderValueChanged:(UISlider *)sender
{
    [self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    [self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
    _paused = YES;
    
    self.rate = sender.value;
    [self.defaults setFloat:self.rateSlider.value forKey:kRateValue];
    [self.defaults synchronize];
    
    [self rateValue];
}


#pragma mark - Paste Text

- (void)checkToPasteText
{
    if (!self.pasteBoard.string || [self.pasteBoard.string  isEqualToString: @""]) {
        
        self.pasteBoard.string = @"There are no text to speech.\n\nCopy whatever you want to read, ReadToMe will read aloud for you.\n\nYou can play, pause or replay whenever you want.\n\nEnjoy reading!";
        self.textView.text = self.pasteBoard.string;
        
    } else if (![self.pasteBoard.string isEqualToString:self.textView.text]) {
        
        self.textView.text = self.pasteBoard.string;
    }
    
    _selectedRange = NSMakeRange(0, 0);
    self.textView.selectedRange = _selectedRange;
    
    [self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
    _paused = YES;
}


#pragma mark - Speech

- (IBAction)speechText:(id)sender
{
    CGFloat time;
    if (_equalizerViewExpanded == YES) {
        [self adjustEqualizerViewHeight];
        time = 0.35;
    } else if (_progressViewExpanded == NO) {
        time = 0.30;
        [self adjustProgressViewHeight];
    } else {
        time = 0.0;
    }
    
    
    [self speechLanguage];
    [self typeSelecting];
    [self volumeValue];
    [self pitchValue];
    [self rateValue];
    
    
    self.utterance = [AVSpeechUtterance speechUtteranceWithString:self.textView.text];
    self.utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:self.language];
    self.utterance.volume = self.volume;
    self.utterance.pitchMultiplier = self.pitch;
    self.utterance.rate = self.rate;
    self.utterance.preUtteranceDelay = 0.3f;
    self.utterance.postUtteranceDelay = 0.3f;
    
    
    CGFloat duration = 0.25f;
    
    if (_paused == YES) {
        
        [self.playPauseButton setImage:kPause forState:UIControlStateNormal];
        _paused = NO;
        
        [self.synthesizer continueSpeaking];
        
        [UIView animateWithDuration:duration animations:^{
            self.resetButton.alpha = 1.0;
        }completion:^(BOOL finished) { }];
        
    } else {
        
        [self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
        _paused = YES;
        
        [self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
        
        [UIView animateWithDuration:duration animations:^{
            self.resetButton.alpha = 0.0;
        }completion:^(BOOL finished) { }];
    }
    
    if (self.synthesizer.isSpeaking == NO) {
        
        [self.playPauseButton setImage:kPause forState:UIControlStateNormal];
        _paused = NO;
        
        [self.synthesizer speakUtterance:self.utterance];
        
        [UIView animateWithDuration:duration animations:^{
            self.resetButton.alpha = 1.0;
        }completion:^(BOOL finished) { }];
    }
    
    if (_isTypeSelecting == YES) {
        [self selectWord];
    }
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
    [self setInitialTextAttributesSpeechLocationAndProgressSliderViewHeight];
    
    CGFloat duration = 0.25f;
    [UIView animateWithDuration:duration animations:^{
        self.resetButton.alpha = 0.0;
    }completion:^(BOOL finished) { }];
    
	[self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    
    _paused = YES;
    [self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
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


- (IBAction)selectionButtonTapped:(id)sender
{
    [self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    [self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
    _paused = YES;
    
    CGFloat duration = 0.25f;
    [UIView animateWithDuration:duration animations:^{
        self.resetButton.alpha = 0.0;
    }completion:^(BOOL finished) { }];
    
    if (_equalizerViewExpanded == YES) {
        [self adjustEqualizerViewHeight];
    }
    
    if (_isTypeSelecting == YES) {
        
        _isTypeSelecting = NO;
        [self.defaults setBool:NO forKey:kTypeSelecting];
        [self.defaults synchronize];
        
        [self adjustSlideViewHeightWithTitle:@"NO WORD SELECTING" withSender:self.selectionButton];
        
        [self typeSelecting];
        
        NSRange selectedRange = self.textView.selectedRange;
        if (selectedRange.length > 0) {
            selectedRange.length = 0;
            self.textView.selectedRange = NSMakeRange(selectedRange.location, selectedRange.length);
        }
        
    } else {
        
        _isTypeSelecting = YES;
        [self.defaults setBool:YES forKey:kTypeSelecting];
        [self.defaults synchronize];
        
        [self adjustSlideViewHeightWithTitle:@"WORD SELECTING" withSender:self.selectionButton];
        
        [self typeSelecting];
        
        NSRange selectedRange = self.textView.selectedRange;
        if (selectedRange.length > 0) {
            selectedRange.length = 0;
            self.textView.selectedRange = NSMakeRange(selectedRange.location, selectedRange.length);
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        
        [self.synthesizer continueSpeaking];
        [self.playPauseButton setImage:kPause forState:UIControlStateNormal];
        _paused = NO;
    });
}


- (IBAction)languageButtonTapped:(id)sender
{
    [self setInitialTextAttributesSpeechLocationAndProgressSliderViewHeight];
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
	[self presentViewController:controller animated:YES completion:^{
        self.language = controller.currentLanguage;
    }];
}


- (IBAction)equalizerButtonTappped:(id)sender
{
    //[self setInitialTextAttributesSpeechLocationAndProgressSliderViewHeight];
	//[self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    //[self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
	//[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
    //_paused = YES;
    [self adjustEqualizerViewHeight];
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
    NSRange rangeInTotalText;
    
    if (_isTypeSelecting == YES) {
        
        rangeInTotalText = NSMakeRange(characterRange.location, characterRange.length);
        
    } else {
        
        rangeInTotalText = NSMakeRange(characterRange.location, characterRange.length  - characterRange.length);
    }
    
    self.textView.selectedRange = rangeInTotalText;
    [self.textView scrollToVisibleCaretAnimated]; //Auto Scroll. Yahoo!
    
    float entireTextLength = (float)[self.textView.text length];
    float location = (float)self.textView.selectedRange.location;
    _speechLocationPercentValueInWholeTexts = (location / entireTextLength) * 100;
    self.progressSlider.value = _speechLocationPercentValueInWholeTexts;
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance
{
    NSLog(@"speechSynthesizer didStartSpeechUtterance");
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
    NSLog(@"speechSynthesizer didFinishSpeechUtterance");
    
    [self setInitialTextAttributesSpeechLocationAndProgressSliderViewHeight];
    
	[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
	_paused = YES;
    
    CGFloat duration = 0.25f;
    [UIView animateWithDuration:duration animations:^{
        self.resetButton.alpha = 0.0;
    }completion:^(BOOL finished) { }];
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance *)utterance
{
    NSLog(@"speechSynthesizer didPauseSpeechUtterance");
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didContinueSpeechUtterance:(AVSpeechUtterance *)utterance
{
    NSLog(@"speechSynthesizer didContinueSpeechUtterance");
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance
{
    NSLog(@"speechSynthesizer didCancelSpeechUtterance");
}


#pragma mark - NSAttributedString

- (void)setInitialTextAttributesSpeechLocationAndProgressSliderViewHeight
{
    self.paragraphAttributes = [self paragraphAttributesWithColor:[UIColor darkTextColor]];
    self.textView.attributedText = [[NSAttributedString alloc] initWithString:self.textView.attributedText.string attributes:self.paragraphAttributes];
    
    _speechLocationPercentValueInWholeTexts = 0.0;
    self.progressSlider.value = _speechLocationPercentValueInWholeTexts;
    
    _selectedRange = NSMakeRange(0, 0);
    self.textView.selectedRange = _selectedRange;
//    NSLog (@"self.textView.selectedRange.location: %lu, and length: %lu\n", self.textView.selectedRange.location, self.textView.selectedRange.length);
    
    if (_progressViewExpanded == YES) {
        [self adjustProgressViewHeight];
        _progressViewExpanded = NO;
    }
}


- (NSDictionary *)paragraphAttributesWithColor:(UIColor *)color
{
	if ( _paragraphAttributes == nil) {
		
        UIFont *font;
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            font = [UIFont fontWithName:kFontName size:kFontSizeiPad];
        } else {
            font = [UIFont fontWithName:kFontName size:kFontSizeiPhone];
        }
		
		NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		paragraphStyle.firstLineHeadIndent = 0.0f;
		paragraphStyle.lineSpacing = 2.0f;
		paragraphStyle.paragraphSpacing = 4.0f;
		paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
		
        _paragraphAttributes = @{ NSFontAttributeName:font, NSParagraphStyleAttributeName:paragraphStyle, NSForegroundColorAttributeName:color };
	}
	
	return _paragraphAttributes;
}


#pragma mark - Observer

- (void)addObserverForChangingSliderValue
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeSliderValue:) name:@"DidChangeSliderValueNotification" object:nil];
}


- (void)didChangeSliderValue:(NSNotification *)notification
{
    if ([notification.name isEqualToString:@"DidChangeSliderValueNotification"]) {
        NSLog(@"DidChangeSliderValue Notification Received");
    }
}


#pragma mark - 앱 처음 실행인지 체크 > Volume, Pitch, Rate 기본값 적용

- (void)checkHasLaunchedOnce
{
    if ([self.defaults boolForKey:kHasLaunchedOnce] == NO) {
        
        [self.defaults setBool:YES forKey:kHasLaunchedOnce];
        
        NSString *currentLanguageCode = [AVSpeechSynthesisVoice currentLanguageCode];
        NSDictionary *defaultLanguage = @{ kLanguage:currentLanguageCode };
        NSString *defaultLanguageName = [defaultLanguage objectForKey:kLanguage];
        
        [self.defaults setObject:defaultLanguageName forKey:kLanguage];
        [self.defaults setBool:YES forKey:kTypeSelecting];
        [self.defaults setFloat:1.0 forKey:kVolumeValue];
        [self.defaults setFloat:1.0 forKey:kPitchValue];
        [self.defaults setFloat:0.07 forKey:kRateValue];
    }
}


#pragma mark - Adjust SlideView height when user touches equivalent button

- (void)adjustSlideViewHeightWithTitle:(NSString *)string withSender:(UIButton *)button
{
	CGFloat duration = 0.2f;
	CGFloat delay = 0.0f;
	
	[UIView animateWithDuration:duration delay:delay options: UIViewAnimationOptionCurveEaseInOut animations:^{
		
        button.enabled = NO;
		_saveAlertViewExpanded = YES;
		self.saveAlertViewHeightConstraint.constant = 60.0;
		[self.view layoutIfNeeded];
		self.archiveButton.enabled = NO;
		self.saveAlertLabel.alpha = 1.0;
		self.saveAlertLabel.text = string;
		
	} completion:^(BOOL finished) {
		
        //Dispatch After
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
            
            [UIView animateWithDuration:duration delay:delay options: UIViewAnimationOptionCurveEaseInOut animations:^{
                
                _saveAlertViewExpanded = NO;
                self.saveAlertViewHeightConstraint.constant = 0.0;
                [self.view layoutIfNeeded];
                self.archiveButton.enabled = YES;
                self.saveAlertLabel.alpha = 0.0;
                
            } completion:^(BOOL finished) {
                button.enabled = YES;
            }];
        });
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



#pragma mark - Show progress view when speech start

- (void)adjustProgressViewHeight
{
	if (_progressViewExpanded == YES) {
		self.progressInfoViewHeightConstraint.constant = 0.0;
		_progressViewExpanded = NO;
	} else {
		self.progressInfoViewHeightConstraint.constant = 33.0;
		_progressViewExpanded = YES;
	}
	
	CGFloat duration = 0.25f;
	CGFloat delay = 0.0f;
	[UIView animateWithDuration:duration delay:delay options: UIViewAnimationOptionCurveEaseInOut animations:^{
		
		[self.view layoutIfNeeded];
		
		if (_progressViewExpanded == YES) {
			self.progressSlider.alpha = 1.0;
			
		} else {
			self.progressSlider.alpha = 0.0;
		}
		
	} completion:^(BOOL finished) { }];
}


#pragma mark - hideSaveAlertViewEqualizerViewAndProgressViewWithNoAnimation

- (void)hideSaveAlertViewEqualizerViewAndProgressViewWithNoAnimation
{
    [UIView animateWithDuration:0.0 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations:^{
        _saveAlertViewExpanded = NO;
        self.saveAlertViewHeightConstraint.constant = 0.0;
        [self.view layoutIfNeeded];
        self.archiveButton.enabled = YES;
        self.saveAlertLabel.alpha = 0.0;
    } completion:nil];
    
    [UIView animateWithDuration:0.0 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations:^{
        _equalizerViewExpanded = NO;
        self.equalizerViewHeightConstraint.constant = 0.0;
        [self.view layoutIfNeeded];
        self.volumeLabel.alpha = 0.0;
        self.pitchLabel.alpha = 0.0;
        self.rateLabel.alpha = 0.0;
        self.volumeSlider.alpha = 0.0;
        self.pitchSlider.alpha = 0.0;
        self.rateSlider.alpha = 0.0;
    } completion:nil];
    
    [UIView animateWithDuration:0.0 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations:^{
        _progressViewExpanded = NO;
        self.progressInfoViewHeightConstraint.constant = 0.0;
        [self.view layoutIfNeeded];
        self.progressSlider.alpha = 0.0;
    } completion:nil];
}


#pragma mark - Listening Notification

- (void)addDidSelectDocumentForSpeechFromListViewObserver
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceivedSelectDocumentsForSpeechNotification:) name:@"DidSelectDocumentsForSpeechNotification" object:nil];
}


/* receivedObject.document - clipboard - textview.text - tempDocument(user default saving) */
- (void)didReceivedSelectDocumentsForSpeechNotification:(NSNotification *)notification
{
    NSLog(@"DidSelectDocumentsForSpeechNotification Recieved");
    
    NSDictionary *userInfo = notification.userInfo;
    self.currentDocument = [userInfo objectForKey:@"DidSelectDocumentsForSpeechNotificationKey"];
    
    self.pasteBoard.string = self.currentDocument.document;
    NSLog (@"[self.pasteBoard.string isEqualToString:self.currentDocument.document] : %@\n", [self.pasteBoard.string isEqualToString:self.currentDocument.document] ? @"YES" : @"NO");
    
    self.isReceivedDocument = YES;
    self.textView.text = self.currentDocument.document;
    self.language = self.currentDocument.language;
    self.volume = [self.currentDocument.volume floatValue];
    self.pitch = [self.currentDocument.pitch floatValue];
    self.rate = [self.currentDocument.rate floatValue];
    
    //Slider Value
    self.volumeSlider.value = [self.currentDocument.volume floatValue];
    self.pitchSlider.value = [self.currentDocument.pitch floatValue];
    self.rateSlider.value = [self.currentDocument.rate floatValue];
}


- (void)addPickedLanguageObserver
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPickedLanguageNotification:) name:@"DidPickedLanguageNotification" object:nil];
}


- (void)didPickedLanguageNotification:(NSNotification *)notification
{
	NSLog(@"DidPickedLanguageNotification Recieved");
	self.utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:self.language];
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
    
}


- (void)applicationDidBecomeActive
{
    
}


- (void)applicationDidEnterBackground
{
    
}


- (void)applicationWillEnterForeground
{
	[self checkToPasteText];
}


#pragma mark - Save Current Documents For Speech

- (void)saveCurrentDocument
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    if (self.managedObjectContext == nil) {
        self.managedObjectContext = [DataManager sharedDataManager].managedObjectContext;
    }
    
    self.currentDocument = [NSEntityDescription insertNewObjectForEntityForName:@"DocumentsForSpeech" inManagedObjectContext:self.managedObjectContext];
    self.currentDocument.language = self.language;
    self.currentDocument.volume = [NSNumber numberWithFloat:self.volume];;
    self.currentDocument.pitch = [NSNumber numberWithFloat:self.pitch];
    self.currentDocument.rate = [NSNumber numberWithFloat:self.rate];
    
    NSString *uniqueIDString = [NSString stringWithFormat:@"%li", arc4random() % 999999999999999999];
    self.currentDocument.uniqueIdString = uniqueIDString;
    
    self.currentDocument.document = self.textView.text;
    
    NSString *firstLineForTitle = [self retrieveFirstLineOfStringForTitle:self.textView.text];
    self.currentDocument.documentTitle = firstLineForTitle;
    
    [self.managedObjectContext performBlock:^{
        NSError *error = nil;
        if ([self.managedObjectContext save:&error]) {
            
            NSLog (@"Save to coredata succeed");
            
            [self executePerformFetch];
            
        } else {
            
            NSLog(@"Error saving to coredata: %@", error);
        }
    }];
}


#pragma mark 첫째 라인만 가져오기

- (NSString *)retrieveFirstLineOfStringForTitle:(NSString *)string
{
    NSString *trimmedString = nil;
    NSCharacterSet *charSet = [NSCharacterSet whitespaceAndNewlineCharacterSet]; //공백, 라인 피드문자 삭제
    trimmedString = [string stringByTrimmingCharactersInSet:charSet];
    
    __block NSString *firstLine = nil;
    NSString *wholeText = trimmedString;
    [wholeText enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        firstLine = [line copy];
        *stop = YES;
    }];
    
    if (firstLine.length == 0)
    {
        firstLine = @"Empty Title";
    }
    
    if (firstLine.length > 0)
    {
        __block NSString *trimmedTitle = nil;
        [firstLine enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {trimmedTitle = line; *stop = YES;}];
    }
    
    return firstLine;
}


#pragma mark - Fetched Results Controller

- (NSFetchedResultsController *)fetchedResultsController
{
	if (_fetchedResultsController != nil) {
		return _fetchedResultsController;
	}
	else if (_fetchedResultsController == nil)
	{
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DocumentsForSpeech"];
		
		NSSortDescriptor *createdDateSort = [[NSSortDescriptor alloc] initWithKey:@"createdDate" ascending:NO];
		[fetchRequest setSortDescriptors: @[createdDateSort]];
		
		_fetchedResultsController = [[NSFetchedResultsController alloc]
									 initWithFetchRequest:fetchRequest
									 managedObjectContext:[DataManager sharedDataManager].managedObjectContext
									 sectionNameKeyPath:nil cacheName:nil];
		[fetchRequest setFetchBatchSize:20];
		_fetchedResultsController.delegate = self;
	}
	return _fetchedResultsController;
}


#pragma mark Perform Fetch

- (void)executePerformFetch
{
	NSError *error = nil;
	
	if (![[self fetchedResultsController] performFetch:&error])
	{
		NSLog(@"Unable to perform fetch.");
		NSLog(@"%@, %@", error, error.localizedDescription);
		//abort();
		
	} else {
		
		NSLog (@"[self.fetchedResultsController fetchedObjects].count: %lu\n", (unsigned long)[self.fetchedResultsController fetchedObjects].count);
        
        self.fetchedDocuments = nil;
        
        for (DocumentsForSpeech *document in [self.fetchedResultsController fetchedObjects]) {
        
            //NSLog (@"document: %@\n", document);
            //NSLog (@"document.uniqueIdString: %@\n", document.uniqueIdString);
            [self.fetchedDocuments addObject:document];
        }
        
        for (DocumentsForSpeech *document in self.fetchedDocuments) {
            if (document.uniqueIdString == self.currentDocument.uniqueIdString) {
                self.currentDocument = document;
                NSLog (@"document.uniqueIdString: %@\n", document.uniqueIdString);
                NSLog (@"self.currentDocument.uniqueIdString: %@\n", self.currentDocument.uniqueIdString);
            }
        }
	}
}


#pragma mark - Configure UI

- (void)configureUI
{
    self.menuView.backgroundColor = [UIColor colorWithRed:0.294 green:0.463 blue:0.608 alpha:1];
    self.saveAlertView.backgroundColor = [UIColor colorWithRed:0.945 green:0.671 blue:0.686 alpha:1];
    self.progressView.backgroundColor = [UIColor colorWithRed:0.294 green:0.463 blue:0.608 alpha:1];
    self.bottomView.backgroundColor = [UIColor colorWithRed:0.157 green:0.29 blue:0.42 alpha:1];
    self.equalizerView.backgroundColor = [UIColor colorWithRed:0.294 green:0.463 blue:0.608 alpha:1];
    
    //Image View
    [self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
    
    //Equalizer View
    self.volumeLabel.alpha = 0.0;
    self.pitchLabel.alpha = 0.0;
    self.rateLabel.alpha = 0.0;
    self.volumeSlider.alpha = 0.0;
    self.pitchSlider.alpha = 0.0;
    self.rateSlider.alpha = 0.0;
    
    //Button
    self.listButton.enabled = NO;
    self.listButton.alpha = 0.0;
    self.archiveButton.enabled = NO;
    self.archiveButton.alpha = 0.0;
    self.actionButton.enabled = NO;
    self.actionButton.alpha = 0.0;
    
    self.resetButton.alpha = 0.0;
}


#pragma mark - Configure Slider UI

- (void)configureSliderUI
{
    UIImage *thumbImageNormal = [UIImage imageNamed:@"SliderThumb-Normal"];
    [self.progressSlider setThumbImage:thumbImageNormal forState:UIControlStateNormal];
    UIImage *thumbImageHighlighted = [UIImage imageNamed:@"SliderThumb-Highlighted"];
    [self.progressSlider setThumbImage:thumbImageHighlighted forState:UIControlStateHighlighted];
    UIImage *trackLeftImage =
    [[UIImage imageNamed:@"SliderTrackLeft"]
     resizableImageWithCapInsets:UIEdgeInsetsMake(0, 14, 0, 14)];
    [self.progressSlider setMinimumTrackImage:trackLeftImage forState:UIControlStateNormal];
    UIImage *trackRightImage = [[UIImage imageNamed:@"SliderTrackRight"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 14, 0, 14)];
    [self.progressSlider setMaximumTrackImage:trackRightImage forState:UIControlStateNormal];
}


#pragma mark - Select Word

- (void)selectWord
{
    _selectedRange = self.textView.selectedRange;
    
    [self.textView select:self];
    
//    if ([self.textView hasText] && _selectedRange.length == 0) {
//        
//        //[self.textView select:self];
//        
//    } else if ([self.textView hasText] && _selectedRange.length > 0) {
//        
//        self.textView.selectedRange = _selectedRange;
//    }
}


#pragma mark - Not Use

- (void)nextWord
{
    _selectedRange = self.textView.selectedRange;
    NSInteger currentLocation = _selectedRange.location + _selectedRange.length;
    NSInteger textLength = [self.textView.text length];
    
    if ( currentLocation == textLength ) {
        return;
    }
    
    NSRange newRange = [self.textView.text rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] options:NSCaseInsensitiveSearch range:NSMakeRange((currentLocation + 1), (textLength - 1 - currentLocation))];
    
    if ( newRange.location != NSNotFound ) {
        
        self.textView.selectedRange = NSMakeRange(newRange.location, 0);
        
    } else {
        
        self.textView.selectedRange = NSMakeRange(textLength, 0);
    }
    
    [self.textView scrollToVisibleCaretAnimated];
}


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


- (void)updateTextAttributeWithSelectedRange:(NSRange)characterRange
{
    UIFont *font = [UIFont fontWithName:kFontName size:kFontSizeiPhone];
    UIColor *color = [UIColor orangeColor];
    
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:self.textView.attributedText];
    [mutableAttributedString addAttribute:NSForegroundColorAttributeName value:color range:characterRange];
    [mutableAttributedString addAttribute:NSFontAttributeName value:font range:characterRange];
    self.textView.attributedText = mutableAttributedString;
}


@end
