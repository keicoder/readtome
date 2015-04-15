//
//  ViewController.m
//  ReadToMe
//
//  Created by jun on 3/23/15.
//  Copyright (c) 2015 keicoder. All rights reserved.
//

#define debug                       1
#define kBackgroundColor            [UIColor colorWithRed:0.286 green:0.58 blue:0.753 alpha:1]
#define kWhiteColor                 [UIColor whiteColor]
#define kPause                      [UIImage imageNamed:@"pause"]
#define kPlay                       [UIImage imageNamed:@"play"]
#define kSettings                   [UIImage imageNamed:@"settings"]

#define kHasLaunchedOnce            @"kHasLaunchedOnce"
#define kSelectionTypeHighlighted   @"kSelectionTypeHighlighted"
#define kLanguage                   @"kLanguage"
#define kVolumeValue                @"kVolumeValue"
#define kPitchValue                 @"kPitchValue"
#define kRateValue                  @"kRateValue"

#define kFontName                   @"HelveticaNeue-Light"
#define kFontSizeiPhone             20.0
#define kFontSizeiPad               22.0

#define kBackgroundPlayValue        @"kBackgroundPlayValue"
#define kBackgroundOn               @"Background On"

#define kSharedDocument             @"kSharedDocument" //Shared Extension item


#import "ContainerViewController.h"
#import <AVFoundation/AVFoundation.h>
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

@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;
@property (nonatomic, strong) AVSpeechUtterance *utterance;
@property (nonatomic, strong) UIPasteboard *pasteBoard;
@property (nonatomic, strong) NSUserDefaults *defaults;

@property (nonatomic, assign) float volume;
@property (nonatomic, assign) float pitch;
@property (nonatomic, assign) float rate;

@property (nonatomic, strong) NSString *backgroundPlayValue;

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
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
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
    BOOL _selectionTypeHighlighted;
	BOOL _saveAlertViewExpanded;
	BOOL _equalizerViewExpanded;
    NSRange _previousSelectedRange;
    int _totalTextLength;
    int _spokenTextLengths;
    float _speechLocationPercentValueInWholeTexts;
}


#pragma mark - View life cycle

- (void)setInitialData
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
	self.managedObjectContext = [DataManager sharedDataManager].managedObjectContext;
    
	self.synthesizer = [[AVSpeechSynthesizer alloc]init];
	self.synthesizer.delegate = self;
	self.pasteBoard = [UIPasteboard generalPasteboard];
	self.pasteBoard.persistent = YES;
	self.defaults = [NSUserDefaults standardUserDefaults];
    
	self.backgroundPlayValue = [self.defaults objectForKey:kBackgroundPlayValue];
	
    _paused = YES;
    _totalTextLength = 0;
    _spokenTextLengths = 0;
    
    [self hideSaveAlertViewAndEqualizerViewWithNoAnimation]; //화면에 보여주지 않기
}


- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[self configureUI];
	[self setInitialData]; //순서 바꾸지 말 것
    [self setInitialTextAttributes];
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
	[self speechLanguage];
    [self selectionTypeHighlighted];
	[self volumeValue];
	[self pitchValue];
	[self rateValue];
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
    NSLog (@"self.language: %@\n", self.language);
    return self.language;
}


- (BOOL)selectionTypeHighlighted
{
    _selectionTypeHighlighted = [self.defaults boolForKey:kSelectionTypeHighlighted];
    NSLog (@"_selectionTypeHighlighted: %@\n", _selectionTypeHighlighted ? @"YES" : @"NO");
    return _selectionTypeHighlighted;
}


- (CGFloat)volumeValue
{
    self.volume = [self.defaults floatForKey:kVolumeValue];
    self.volumeSlider.value = self.volume;
    NSLog (@"self.volume: %f\n", self.volume);
    return self.volume;
}


- (CGFloat)pitchValue
{
    self.pitch = [self.defaults floatForKey:kPitchValue];
    self.pitchSlider.value = self.pitch;
    NSLog (@"self.pitch: %f\n", self.pitch);
    return self.pitch;
}


- (CGFloat)rateValue
{
    self.rate = [self.defaults floatForKey:kRateValue];
    self.rateSlider.value = self.rate;
    NSLog (@"self.rate: %f\n", self.rate);
    return self.rate;
}


#pragma mark - Slider value changed

- (IBAction)progressSliderValueChanged:(UISlider *)sender
{
    self.progressSlider.value = _speechLocationPercentValueInWholeTexts;
}



- (IBAction)volumeSliderValueChanged:(UISlider *)sender
{
    [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    _paused = YES;
    [self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
    self.volume = sender.value;
    [self.defaults setFloat:sender.value forKey:kVolumeValue];
    [self.defaults synchronize];
    
}


- (IBAction)pitchSliderValueChanged:(UISlider *)sender
{
    [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    _paused = YES;
    [self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
    self.pitch = sender.value;
    [self.defaults setFloat:sender.value forKey:kPitchValue];
    [self.defaults synchronize];
}


- (IBAction)rateSliderValueChanged:(UISlider *)sender
{
    [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    _paused = YES;
    [self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
    self.rate = sender.value;
    [self.defaults setFloat:self.rateSlider.value forKey:kRateValue];
    [self.defaults synchronize];
}


#pragma mark - Paste Text

- (void)checkToPasteText
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    if (self.pasteBoard.string == NULL || self.pasteBoard.string == nil || [self.pasteBoard.string  isEqualToString: @""]) {
        NSLog(@"self.pasteBoard.string is null");
    }
    else if ([self.pasteBoard.string isEqualToString:self.textView.text]) {
        NSLog(@"self.pasteBoard.string and self.textView.text are equal, so nothing happened");
        
    }
    else {
        NSLog(@"self.pasteBoard.string and self.textView.text are not equal, so paste it to textview");
        self.textView.text = self.pasteBoard.string;
        NSLog(@"paste done");
        
        if (self.synthesizer != nil) {
            [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
            NSLog(@"Because paste new text, avspeech synthsizer stoped speaking. New Start will began.");
            _paused = YES;
            [self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
        }
    }
    
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.keicoder.demo.readtome"];
    NSString *sharedDocument = [sharedDefaults objectForKey:kSharedDocument];
    NSLog (@"sharedDocument: %@\n", sharedDocument);
    
}


#pragma mark - Speech

- (IBAction)speechText:(id)sender
{
    CGFloat time;
    if (_equalizerViewExpanded == YES) {
        [self adjustEqualizerViewHeight];
        time = 0.35;
    } else {
        time = 0.0;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        
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
            [self.synthesizer continueSpeaking];
            _paused = NO;
            [UIView animateWithDuration:duration animations:^{
                self.resetButton.alpha = 1.0;
            }completion:^(BOOL finished) { }];
        } else {
            [self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
            [self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
            _paused = YES;
            [UIView animateWithDuration:duration animations:^{
                self.resetButton.alpha = 0.0;
            }completion:^(BOOL finished) { }];
        }
        
        if (self.synthesizer.isSpeaking == NO) {
            if (_selectionTypeHighlighted == NO) {
                NSLog (@"_selectionTypeHighlighted: %@\n", _selectionTypeHighlighted ? @"YES" : @"NO");
                [self selectWord];
            } else {
                NSLog (@"_selectionTypeHighlighted: %@\n", _selectionTypeHighlighted ? @"YES" : @"NO");
            }
            [self.playPauseButton setImage:kPause forState:UIControlStateNormal];
            [self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
            [self.synthesizer speakUtterance:self.utterance];
            
            [UIView animateWithDuration:duration animations:^{
                self.resetButton.alpha = 1.0;
            }completion:^(BOOL finished) { }];
        }
    });
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
    [self setInitialTextAttributes];
    
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
    [self setInitialTextAttributes];
    [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    [self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
    _paused = YES;
    
    CGFloat duration = 0.25f;
    [UIView animateWithDuration:duration animations:^{
        self.resetButton.alpha = 0.0;
    }completion:^(BOOL finished) { }];
    
    if (_equalizerViewExpanded == YES) {
        [self adjustEqualizerViewHeight];
    }
    
    if (_selectionTypeHighlighted == YES) {
        _selectionTypeHighlighted = NO;
        [self.defaults setBool:NO forKey:kSelectionTypeHighlighted];
        [self.defaults synchronize];
        
        [self adjustSlideViewHeightWithTitle:@"WORD SELECTING" withSender:self.selectionButton];
    } else {
        _selectionTypeHighlighted = YES;
        [self.defaults setBool:YES forKey:kSelectionTypeHighlighted];
        [self.defaults synchronize];
        [self adjustSlideViewHeightWithTitle:@"NO WORD SELECTING" withSender:self.selectionButton];
    }
    
    NSRange selectedRange = self.textView.selectedRange;
    if (selectedRange.length > 0) {
        selectedRange.length = 0;
        self.textView.selectedRange = NSMakeRange(selectedRange.location, selectedRange.length);
    }
    
    NSLog (@"_selectionTypeHighlighted: %@\n", _selectionTypeHighlighted ? @"YES" : @"NO");
}


- (IBAction)languageButtonTapped:(id)sender
{
    [self setInitialTextAttributes];
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
    [self setInitialTextAttributes];
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
    self.utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:self.language];
	self.utterance.volume = self.volume;
	self.utterance.pitchMultiplier = self.pitch;
	self.utterance.rate = self.rate;
    
    if (_selectionTypeHighlighted == YES) {
        
        //NSLog(@"_selectionTypeHighlighted == YES");
        
        NSRange rangeInTotalText = NSMakeRange(_spokenTextLengths + characterRange.location, characterRange.length - characterRange.length);
        self.textView.selectedRange = rangeInTotalText;
        [self.textView scrollToVisibleCaretAnimated]; //Auto Scroll. Yahoo!
        
        
        //보류
//        UIFont *font = [UIFont fontWithName:kFontName size:kFontSizeiPhone];
//        UIColor *color = [UIColor orangeColor];
//        
//        NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:self.textView.attributedText];
//        [mutableAttributedString addAttribute:NSForegroundColorAttributeName value:color range:characterRange];
//        [mutableAttributedString addAttribute:NSFontAttributeName value:font range:characterRange];
//        self.textView.attributedText = mutableAttributedString;
        
    } else {
        
        //NSLog(@"_selectionTypeHighlighted == NO");
        NSRange rangeInTotalText = NSMakeRange(_spokenTextLengths + characterRange.location, characterRange.length);
        self.textView.selectedRange = rangeInTotalText;
        [self.textView scrollToVisibleCaretAnimated]; //Auto Scroll. Yahoo!
        
        //NSLog (@"self.textView.selectedRange.location: %lu, self.textView.selectedRange.length: %lu\n", self.textView.selectedRange.location, self.textView.selectedRange.length);
    }
    float textViewLength = (float)[self.textView.text length];
    float location = (float)self.textView.selectedRange.location;
    _speechLocationPercentValueInWholeTexts = (location / textViewLength) * 100;
    self.progressSlider.value = _speechLocationPercentValueInWholeTexts;
    NSLog (@"_speechLocationPercentValueInWholeTexts: %f\n", _speechLocationPercentValueInWholeTexts);
    
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance
{
    
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
    [self setInitialTextAttributes];
    
    [self selectWord];
    
	[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
	_paused = YES;
    
    CGFloat duration = 0.25f;
    [UIView animateWithDuration:duration animations:^{
        self.resetButton.alpha = 0.0;
    }completion:^(BOOL finished) { }];
}


#pragma mark - NSAttributedString

- (void)setInitialTextAttributes
{
    self.paragraphAttributes = [self paragraphAttributesWithColor:[UIColor darkTextColor]];
    self.textView.attributedText = [[NSAttributedString alloc] initWithString:self.textView.attributedText.string attributes:self.paragraphAttributes];
    
    _speechLocationPercentValueInWholeTexts = 0.0;
    self.progressSlider.value = _speechLocationPercentValueInWholeTexts;
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
		
        NSLog (@"HasLaunchedOnce: %@\n", [self.defaults boolForKey:kHasLaunchedOnce] ? @"YES" : @"NO");
        
        [self.defaults setBool:YES forKey:kHasLaunchedOnce];
        
        NSString *currentLanguageCode = [AVSpeechSynthesisVoice currentLanguageCode];
        NSDictionary *defaultLanguage = @{ kLanguage:currentLanguageCode };
        NSString *defaultLanguageName = [defaultLanguage objectForKey:kLanguage];
        NSLog (@"defaultLanguageName: %@\n", defaultLanguageName);
        
        [self.defaults setObject:defaultLanguageName forKey:kLanguage];
        [self.defaults setBool:YES forKey:kSelectionTypeHighlighted];
        [self.defaults setFloat:1.0 forKey:kVolumeValue];
        [self.defaults setFloat:1.0 forKey:kPitchValue];
        [self.defaults setFloat:0.07 forKey:kRateValue];
        
        [self.defaults setObject:kBackgroundOn forKey:kBackgroundPlayValue];        
        [self.defaults synchronize];
        
        NSString *backgroundPlayValue = [self.defaults objectForKey:kBackgroundPlayValue];
        NSLog (@"backgroundPlayValue: %@\n", backgroundPlayValue);
    
    } else {
        
        NSLog (@"HasLaunchedOnce: %@\n", [self.defaults boolForKey:kHasLaunchedOnce] ? @"YES" : @"NO");
    }
}


#pragma mark - Adjust SlideView height when user touches equivalent button

- (void)adjustSlideViewHeightWithTitle:(NSString *)string withSender:(UIButton *)button
{
	CGFloat duration = 0.3f;
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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.7 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
            
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


- (void)hideSaveAlertViewAndEqualizerViewWithNoAnimation
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
	[self checkToPasteText];
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
	}
}


#pragma mark - Configure UI

- (void)configureUI
{
    self.menuView.backgroundColor = [UIColor colorWithRed:0.149 green:0.604 blue:0.949 alpha:1];
    self.bottomView.backgroundColor = [UIColor colorWithRed:0.329 green:0.384 blue:0.827 alpha:1];
    self.equalizerView.backgroundColor = [UIColor colorWithRed:0.329 green:0.384 blue:0.827 alpha:1];
    
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


#pragma mark - Save Current Documents For Speech

- (IBAction)saveCurrentDocument:(id)sender
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    if (self.managedObjectContext == nil) {
        self.managedObjectContext = [DataManager sharedDataManager].managedObjectContext;
        NSLog (@"self.managedObjectContext: %@\n", self.managedObjectContext);
    }
    
    DocumentsForSpeech *document = [NSEntityDescription insertNewObjectForEntityForName:@"DocumentsForSpeech" inManagedObjectContext:self.managedObjectContext];
    document.language = self.language;
    document.volume = [NSNumber numberWithFloat:self.volume];;
    document.pitch = [NSNumber numberWithFloat:self.pitch];
    document.rate = [NSNumber numberWithFloat:self.rate];
    
    document.document = self.textView.text;
    
    NSString *firstLineForTitle = [self retrieveFirstLineOfStringForTitle:self.textView.text];
    document.documentTitle = firstLineForTitle;
    
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


#pragma mark - Select Word

- (void)selectWord
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    NSRange selectedRange;
    
    if (self.textView.selectedRange.location == 0) { //or NSNotFound?
        dispatch_async(dispatch_get_main_queue(), ^{
            self.textView.selectedRange = NSMakeRange(0, 0);
        });;
    } else {
        selectedRange = self.textView.selectedRange;
    }
    
    if (![self.textView hasText])
    {
        [self.textView select:self];
    }
    else if ([self.textView hasText] && selectedRange.length == 0)
    {
        [self.textView select:self];
        
        NSRange selectedRange = self.textView.selectedRange;
        if (selectedRange.length > 0) {
            selectedRange.length = 0;
            self.textView.selectedRange = NSMakeRange(selectedRange.location, selectedRange.length);
        }
    }
    else if ([self.textView hasText] && selectedRange.length > 0)
    {
        selectedRange.location = selectedRange.location + selectedRange.length;
        selectedRange.length = 0;
        self.textView.selectedRange = selectedRange;
    }
}


- (void)nextWord
{
    NSRange selectedRange = self.textView.selectedRange;
    NSInteger currentLocation = selectedRange.location + selectedRange.length;
    NSInteger textLength = [self.textView.text length];
    
    if ( currentLocation == textLength ) {
        return;
    }
    
    NSRange newRange = [self.textView.text
                        rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]
                        options:NSCaseInsensitiveSearch
                        range:NSMakeRange((currentLocation + 1), (textLength - 1 - currentLocation))];
    
    if ( newRange.location != NSNotFound ) {
        self.textView.selectedRange = NSMakeRange(newRange.location, 0);
    } else {
        self.textView.selectedRange = NSMakeRange(textLength, 0);
    }
    [self.textView scrollToVisibleCaretAnimated];
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


@end
