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

#define kLastViewedDocument         @"kLastViewedDocument"
#define kSavedDocument              @"kSavedDocument"
#define kNotSavedDocument           @"kNotSavedDocument"

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
#import "KeiTextView.h"
#import "UIViewController+BHTKeyboardNotifications.h"


@interface ContainerViewController () <AVSpeechSynthesizerDelegate, NSFetchedResultsControllerDelegate, UITextViewDelegate>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSMutableArray *fetchedDocuments;

@property (nonatomic, strong) NSDateFormatter *formatter;

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
@property (weak, nonatomic) IBOutlet UIButton *logoButton;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;

@property (weak, nonatomic) IBOutlet UIButton *keyboardDownButton;

@property (weak, nonatomic) IBOutlet UIView *progressView;
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;

@property (weak, nonatomic) IBOutlet UIView *saveAlertView;
@property (weak, nonatomic) IBOutlet UILabel *saveAlertLabel;

@property (weak, nonatomic) IBOutlet KeiTextView *textView;

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

@end


@implementation ContainerViewController
{
	BOOL _paused;
    BOOL _isTypeSelecting;
	BOOL _saveAlertViewExpanded;
	BOOL _equalizerViewExpanded;
    NSRange _selectedRange;
    NSString *_lastViewedDocument;
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
    self.isReceivedDocument = NO;
    _subString = self.textView.text;
    
    self.textView.delegate = self;
    
    [self hideSaveAlertViewEqualizerViewAndProgressViewWithNoAnimation]; //화면에 보여주지 않기
}


- (void)viewDidLoad
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
	[super viewDidLoad];
	
	[self configureUI];
    [self configureSliderUI];
	[self setInitialData]; //순서 바꾸지 말 것
    [self stopSpeech];
//    [self setupKeyboardAnimations];
    [self registerKeyboardNotifications];
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
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
	[super viewWillAppear:animated];
    [self lastViewedDocument];
    [self checkToPasteText];
    [self speechLanguage];
    [self typeSelecting];
    [self volumeValue];
    [self pitchValue];
    [self rateValue];
    [self executePerformFetch];
}


-(void)viewDidAppear:(BOOL)animated
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    [super viewDidAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
	[super viewWillDisappear:YES];
	_fetchedResultsController = nil;
}


#pragma mark - Paste Text

- (void)checkToPasteText
{
    if (self.isSavedDocument == NO) {
        
        NSLog(@"checkToPasteText > self.isSavedDocument == NO");
        
        if (!self.pasteBoard.string) {
            
            self.pasteBoard.string = @"There are no text to speech.\n\nCopy whatever you want to read, ReadToMe will read aloud for you.\n\nYou can play, pause or replay whenever you want.\n\nEnjoy reading!";
            self.textView.text = self.pasteBoard.string;
            
        } else if (self.isReceivedDocument == YES) {
            
            NSLog(@"Received Document");
            self.textView.text = self.pasteBoard.string;
            
        } else {
            
            self.textView.text = self.pasteBoard.string;
            
            self.currentDocument.isNewDocument = [NSNumber numberWithBool:YES];
            self.currentDocument.savedDocument = kNotSavedDocument;
            self.currentDocument.document = self.textView.text;
            
            self.isReceivedDocument = NO;
        }
        
        _selectedRange = NSMakeRange(0, 0);
        self.textView.selectedRange = _selectedRange;
        
        [self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
        _paused = YES;
        
    } else {
        
        NSLog(@"checkToPasteText > self.isSavedDocument == YES");
        
    }
}


#pragma mark - Speech

- (IBAction)speechText:(id)sender
{
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
    [self stopSpeech];
    
	if (_equalizerViewExpanded == YES) {
        _equalizerViewExpanded = NO;
        [self adjustEqualizerViewHeight:0.0];
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
    [self stopSpeech];
    
    CGFloat duration = 0.25f;
    [UIView animateWithDuration:duration animations:^{
        self.resetButton.alpha = 0.0;
    }completion:^(BOOL finished) { }];
    
//    if (self.textView.editable == NO) {
//        self.textView.editable = YES;
//        [self.textView resignFirstResponder];
//    }
}


- (IBAction)actionButtonTapped:(id)sender
{
	[self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
	[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
	_paused = YES;
	
	if (_equalizerViewExpanded == YES) {
        _equalizerViewExpanded = NO;
		[self adjustEqualizerViewHeight:0.0];
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
    [self pauseSpeech];
    
    if (_equalizerViewExpanded == YES) {
        _equalizerViewExpanded = NO;
        [self adjustEqualizerViewHeight:0.0];
    }
    
    if (_isTypeSelecting == YES) {
        
        _isTypeSelecting = NO;
        [self.defaults setBool:NO forKey:kTypeSelecting];
        [self.defaults synchronize];
        
        [self adjustSlideViewHeightWithTitle:@"NO WORD SELECTING" andColor:[UIColor colorWithRed:0.984 green:0.4 blue:0.302 alpha:1] withSender:self.selectionButton];
        
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
        
        [self adjustSlideViewHeightWithTitle:@"WORD SELECTING" andColor:[UIColor colorWithRed:0 green:0.635 blue:0.259 alpha:1] withSender:self.selectionButton];
        
        [self typeSelecting];
        
        NSRange selectedRange = self.textView.selectedRange;
        if (selectedRange.length > 0) {
            selectedRange.length = 0;
            self.textView.selectedRange = NSMakeRange(selectedRange.location, selectedRange.length);
        }
    }
}


- (IBAction)languageButtonTapped:(id)sender
{
    [self stopSpeech];
	
	if (_equalizerViewExpanded == YES) {
        _equalizerViewExpanded = NO;
		[self adjustEqualizerViewHeight:0.0];
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
    [self stopSpeech];
    if (_equalizerViewExpanded == YES) {
        _equalizerViewExpanded = NO;
        [self adjustEqualizerViewHeight:0.0];
    } else {
        _equalizerViewExpanded = YES;
        [self adjustEqualizerViewHeight:150.0];
    }
}


- (IBAction)settingsButtonTapped:(id)sender
{
	[self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
	_paused = YES;
	[self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
	
	if (_equalizerViewExpanded == YES) {
        _equalizerViewExpanded = NO;
		[self adjustEqualizerViewHeight:0.0];
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


- (IBAction)keyboardDownButtonTapped:(id)sender
{
    [self.textView resignFirstResponder];
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
    [self stopSpeech];
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
        
        _lastViewedDocument = @"";
    }
}


#pragma mark - Adjust SlideView height when user touches equivalent button

- (void)adjustSlideViewHeightWithTitle:(NSString *)string andColor:(UIColor *)color withSender:(UIButton *)button
{
	CGFloat duration = 0.2f;
	CGFloat delay = 0.0f;
	
    _saveAlertViewExpanded = YES;
    self.saveAlertViewHeightConstraint.constant = 60.0;
    button.enabled = NO;
    self.saveAlertView.backgroundColor = color;
    
	[UIView animateWithDuration:duration delay:delay options: UIViewAnimationOptionCurveEaseInOut animations:^{
		
        [self.view layoutIfNeeded];
		self.saveAlertLabel.alpha = 1.0;
        self.saveAlertLabel.text = string;
		
	} completion:^(BOOL finished) {
		
        //Dispatch After
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
            
            _saveAlertViewExpanded = NO;
            self.saveAlertViewHeightConstraint.constant = 0.0;
            
            [UIView animateWithDuration:duration delay:delay options: UIViewAnimationOptionCurveEaseInOut animations:^{
                
                [self.view layoutIfNeeded];
                self.saveAlertLabel.alpha = 0.0;
                
            } completion:^(BOOL finished) {
                button.enabled = YES;
//                self.saveAlertView.backgroundColor = [UIColor colorWithRed:0.945 green:0.671 blue:0.686 alpha:1];
            }];
        });
	}];
}


#pragma mark - Show equalizer view when user touches equalizer button

- (void)adjustEqualizerViewHeight:(float)height
{
    self.equalizerViewHeightConstraint.constant = height;
    
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
    
    NSLog (@"didReceivedSelectDocumentsForSpeechNotification > self.isSavedDocument: %@\n", self.isSavedDocument ? @"YES" : @"NO");
    
    NSDictionary *userInfo = notification.userInfo;
    
    DocumentsForSpeech *receivedDocument = [userInfo objectForKey:@"DidSelectDocumentsForSpeechNotificationKey"];
    
    self.currentDocument = receivedDocument;
    //self.isSavedDocument = YES;
    
    
    self.pasteBoard.string = self.currentDocument.document;
    _lastViewedDocument = self.currentDocument.document;
    self.textView.text = self.currentDocument.document;
    
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
    
    [self showLog];
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

- (NSDateFormatter *)formatter
{
    if (!_formatter) {
        _formatter = [[NSDateFormatter alloc] init];
    }
    return _formatter;
}

- (void)updateDocument
{
    self.currentDocument.language = self.language;
    self.currentDocument.volume = [NSNumber numberWithFloat:self.volume];;
    self.currentDocument.pitch = [NSNumber numberWithFloat:self.pitch];
    self.currentDocument.rate = [NSNumber numberWithFloat:self.rate];
    
    if (self.currentDocument.uniqueIdString == nil) {
        NSString *uniqueIDString = [NSString stringWithFormat:@"%li", (long)arc4random() % 999999999999999999];
        self.currentDocument.uniqueIdString = uniqueIDString;
    }
    
    self.currentDocument.isNewDocument = [NSNumber numberWithBool:NO];
    self.currentDocument.savedDocument = kSavedDocument;
    
    self.currentDocument.document = self.textView.text;
    
    NSString *firstLineForTitle = [self retrieveFirstLineOfStringForTitle:self.textView.text];
    self.currentDocument.documentTitle = firstLineForTitle;
    
    NSDate *now = [NSDate date];
    
    [self.formatter setDateFormat:@"yyyy"];
    NSString *stringYear = [self.formatter stringFromDate:now];
    
    [self.formatter setDateFormat:@"MMM"];
    NSString *stringMonth = [self.formatter stringFromDate:now];
    
    [self.formatter setDateFormat:@"dd"];
    NSString *stringDay = [self.formatter stringFromDate:now];
    
    [self.formatter setDateFormat:@"EEEE"];
    NSString *stringDate = [self.formatter stringFromDate:now];
    NSString *stringdaysOfTheWeek = [[stringDate substringToIndex:3] uppercaseString];
    
    if (self.currentDocument.createdDate == nil) {
        self.currentDocument.createdDate = now;
    }
    
    if (self.currentDocument.modifiedDate == nil) {
        self.currentDocument.modifiedDate = now;
    }
    
    self.currentDocument.yearString = stringYear;
    self.currentDocument.monthString = stringMonth;
    self.currentDocument.dayString = stringDay;
    self.currentDocument.dateString = stringdaysOfTheWeek;
    
    [self.formatter setDateFormat:@"MMM yyyy"];
    NSString *monthAndYearString = [self.formatter stringFromDate:now];
    self.currentDocument.monthAndYearString = monthAndYearString;
    
    self.currentDocument.section = monthAndYearString;
}


- (IBAction)saveCurrentDocument:(id)sender
{
    [self.textView resignFirstResponder];
    [self pauseSpeech];
    [self showLog];
    
    if (self.isSavedDocument == NO) {
        
        if ([self.textView.text isEqualToString:_lastViewedDocument]) {
            
            NSLog(@"Nothing to Save");
            [self adjustSlideViewHeightWithTitle:@"Nothing to Save" andColor:[UIColor colorWithRed:0.984 green:0.447 blue:0 alpha:1] withSender:self.archiveButton];
            
        } else {
            
            self.managedObjectContext = [DataManager sharedDataManager].managedObjectContext;
            
            self.currentDocument = [NSEntityDescription insertNewObjectForEntityForName:@"DocumentsForSpeech" inManagedObjectContext:self.managedObjectContext];
            
            [self updateDocument];
            
            [self.managedObjectContext performBlock:^{
                NSError *error = nil;
                if ([self.managedObjectContext save:&error]) {
                    
                    NSLog (@"Save to coredata succeed");
                    
                    [self adjustSlideViewHeightWithTitle:@"Saved" andColor:[UIColor colorWithRed:0.988 green:0.71 blue:0 alpha:1] withSender:self.archiveButton];
                    
                    _lastViewedDocument = self.textView.text;
                    [self.defaults setObject:_lastViewedDocument forKey:kLastViewedDocument];
                    [self.defaults synchronize];
                    NSLog(@"_lastViewedDocument texts updated");
                    
                    [self executePerformFetch];
                    
                } else {
                    
                    NSLog(@"Error saving to coredata: %@", error);
                }
            }];
        }
        
    } else {
        
        if ([self.textView.text isEqualToString:_lastViewedDocument]) {
            
            NSLog(@"Nothing to Save");
            [self adjustSlideViewHeightWithTitle:@"Nothing to Save" andColor:[UIColor colorWithRed:0.984 green:0.447 blue:0 alpha:1] withSender:self.archiveButton];
            
        } else {
            
            self.managedObjectContext = [DataManager sharedDataManager].managedObjectContext;
            
            self.currentDocument = [NSEntityDescription insertNewObjectForEntityForName:@"DocumentsForSpeech" inManagedObjectContext:self.managedObjectContext];
            
            [self updateDocument];
            
            [self.managedObjectContext performBlock:^{
                NSError *error = nil;
                if ([self.managedObjectContext save:&error]) {
                    
                    NSLog (@"Save to coredata succeed");
                    
                    [self adjustSlideViewHeightWithTitle:@"Saved" andColor:[UIColor colorWithRed:0.988 green:0.71 blue:0 alpha:1] withSender:self.archiveButton];
                    
                    _lastViewedDocument = self.textView.text;
                    [self.defaults setObject:_lastViewedDocument forKey:kLastViewedDocument];
                    [self.defaults synchronize];
                    NSLog(@"_lastViewedDocument texts updated");
                    
                    [self executePerformFetch];
                    
                } else {
                    
                    NSLog(@"Error saving to coredata: %@", error);
                }
            }];
        }
    }
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
		
		NSSortDescriptor *createdDateSort = [[NSSortDescriptor alloc] initWithKey:@"modifiedDate" ascending:NO];
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
		
	} else {
        
		NSLog (@"[self.fetchedResultsController fetchedObjects].count: %lu\n", (unsigned long)[self.fetchedResultsController fetchedObjects].count);
        
        if ([self.fetchedResultsController fetchedObjects].count > 0) {
            
            DocumentsForSpeech *savedDocument = [self.fetchedResultsController fetchedObjects][0];
            NSLog (@"savedDocument.document: %@\n", savedDocument.document);
            NSLog (@"savedDocument.uniqueIdString: %@\n", savedDocument.uniqueIdString);
            self.currentDocument = savedDocument;
            self.isSavedDocument = YES;
        }
	}
}


#pragma mark - Configure UI

- (void)configureUI
{
    self.menuView.backgroundColor = [UIColor colorWithRed:0.294 green:0.463 blue:0.608 alpha:1];
    self.saveAlertView.backgroundColor = [UIColor colorWithRed:0.945 green:0.671 blue:0.686 alpha:1];
    self.bottomView.backgroundColor = [UIColor colorWithRed:0.157 green:0.29 blue:0.42 alpha:1];
    self.progressView.backgroundColor = [UIColor colorWithRed:0.294 green:0.463 blue:0.608 alpha:1];
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
    self.logoButton.enabled = NO;
    self.logoButton.alpha = 0.0;
    self.actionButton.enabled = NO;
    self.actionButton.alpha = 0.0;
    self.resetButton.alpha = 0.0;
    
    //Keyboard Down Button
    float cornerRadius = self.keyboardDownButton.bounds.size.height/2;
    self.keyboardDownButton.layer.cornerRadius = cornerRadius;
    self.keyboardDownButton.backgroundColor = [UIColor colorWithRed:0.294 green:0.463 blue:0.608 alpha:0.5];
    self.keyboardDownButton.alpha = 0.0;
}


#pragma mark - Configure Slider UI

- (void)configureSliderUI
{
    UIImage *thumbImageNormal = [UIImage imageNamed:@"recordNormal"];
    [self.progressSlider setThumbImage:thumbImageNormal forState:UIControlStateNormal];
    UIImage *thumbImageHighlighted = [UIImage imageNamed:@"record"];
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

    if ([self.textView hasText] && _selectedRange.length == 0) {
        
        [self.textView select:self];
        
    } else if ([self.textView hasText] && _selectedRange.length > 0) {
        
        self.textView.selectedRange = _selectedRange;
    }
}


#pragma mark - State Restoration

- (NSString *)lastViewedDocument
{
    if (self.isSavedDocument == NO) {
        _lastViewedDocument = [self.defaults objectForKey:kLastViewedDocument];
        NSLog (@"viewWillAppear: self.isSavedDocument == NO > _lastViewedDocument: %@\n", _lastViewedDocument);
        return _lastViewedDocument;
    } else {
        NSLog (@"viewWillAppear: self.isReceivedDocument == YES > _lastViewedDocument: %@\n", _lastViewedDocument);
        return _lastViewedDocument;
    }
}


- (NSString *)speechLanguage
{
    self.language = [self.defaults objectForKey:kLanguage];
    NSLog (@"self.language: %@\n", self.language);
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
    self.volume = sender.value;
    [self.defaults setFloat:sender.value forKey:kVolumeValue];
    [self.defaults synchronize];
}


- (IBAction)pitchSliderValueChanged:(UISlider *)sender
{
    self.pitch = sender.value;
    [self.defaults setFloat:sender.value forKey:kPitchValue];
    [self.defaults synchronize];
}


- (IBAction)rateSliderValueChanged:(UISlider *)sender
{
    self.rate = sender.value;
    [self.defaults setFloat:self.rateSlider.value forKey:kRateValue];
    [self.defaults synchronize];
}


#pragma mark - Speech State

- (void)stopSpeech
{
    [self.textView resignFirstResponder];
    
    [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    [self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
    _paused = YES;
    
    _selectedRange = NSMakeRange(0, 0);
    self.textView.selectedRange = _selectedRange;
    
    CGFloat duration = 0.25f;
    _speechLocationPercentValueInWholeTexts = 0.0;
    [UIView animateWithDuration:duration animations:^{
        self.progressSlider.value = _speechLocationPercentValueInWholeTexts;
        self.resetButton.alpha = 0.0;
    }completion:^(BOOL finished) { }];
}


- (void)pauseSpeech
{
    [self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    [self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
    _paused = YES;
    
    CGFloat duration = 0.25f;
    [UIView animateWithDuration:duration animations:^{
        self.resetButton.alpha = 0.0;
    }completion:^(BOOL finished) { }];
}


//#pragma mark - Keyboard handle
//
//- (void)setupKeyboardAnimations
//{
//    __weak typeof(self) wself = self;
//    
//    [self setKeyboardWillShowAnimationBlock:^(CGRect keyboardFrame) {
//    
//        _equalizerViewExpanded = YES;
//        [wself adjustEqualizerViewHeight:keyboardFrame.size.height];
//    }];
//    
//    [self setKeyboardWillHideAnimationBlock:^(CGRect keyboardFrame) {
//        
//        _equalizerViewExpanded = NO;
//        [wself adjustEqualizerViewHeight:0.0];
//    }];
//}


#pragma mark - Keyboard Handling


- (void)registerKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:self.view.window];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:self.view.window];
}


- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGRect keyboardFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardHeight = CGRectGetHeight(keyboardFrame);
    CGFloat bottomViewHeight = CGRectGetHeight(self.bottomView.frame);
    
    _equalizerViewExpanded = YES;
    [self adjustEqualizerViewHeight:keyboardHeight - bottomViewHeight];
    
    CGFloat duration = 0.35f;
    [UIView animateWithDuration:duration animations:^{
        self.keyboardDownButton.alpha = 1.0;
    }completion:^(BOOL finished) { }];
}


- (void)keyboardWillHide:(NSNotification*)notification
{
    _equalizerViewExpanded = NO;
    [self adjustEqualizerViewHeight:0.0];
    
    CGFloat duration = 0.35f;
    [UIView animateWithDuration:duration animations:^{
        self.keyboardDownButton.alpha = 0.0;
    }completion:^(BOOL finished) { }];
    
    [self pauseSpeech];
    
    NSRange selectedRange = self.textView.selectedRange;
    if (selectedRange.length > 0) {
        selectedRange.length = 0;
        self.textView.selectedRange = NSMakeRange(selectedRange.location, selectedRange.length);
    }
}


#pragma mark - UITextView delegate method (optional)

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    NSLog(@"textViewShouldBeginEditing");
    
    return YES;
}


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSLog(@"textView shouldChangeTextInRange");
    
    _lastViewedDocument = self.textView.text;
    
    return YES;
}


- (void)textViewDidChange:(UITextView *)textView
{
    NSLog(@"textView textViewDidChange");
    
    if ([_lastViewedDocument isEqualToString:self.textView.text]) {
        
        NSLog(@"Nothing Changed");
        
    } else {
        
        NSLog(@"TextView texts are changed");
        
        [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
        [self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
        _paused = YES;
    }
}


- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    NSLog(@"textViewShouldEndEditing");
    
    return YES;
}


#pragma mark - Show Log

- (void)showLog
{
    NSLog (@"self.isSavedDocument: %@\n", self.isSavedDocument ? @"YES" : @"NO");
    
    NSLog (@"[self.currentDocument.volume floatValue]: %f\n", [self.currentDocument.volume floatValue]);
    NSLog (@"[self.currentDocument.pitch floatValue]: %f\n", [self.currentDocument.pitch floatValue]);
    NSLog (@"[self.currentDocument.rate floatValue]: %f\n", [self.currentDocument.rate floatValue]);
    
    NSLog (@"self.volumeSlider.value: %f\n", self.volumeSlider.value);
    NSLog (@"self.pitchSlider.value: %f\n", self.pitchSlider.value);
    NSLog (@"self.rateSlider.value: %f\n", self.rateSlider.value);
    
    NSLog (@"self.volume: %f\n", self.volume);
    NSLog (@"self.pitch: %f\n", self.pitch);
    NSLog (@"self.rate: %f\n", self.rate);
    
//    NSLog (@"self.textView.text: %@\n", self.textView.text);
//    NSLog (@"_lastViewedDocument: %@\n", _lastViewedDocument);
}


#pragma mark - Dealloc

- (void)dealloc
{
    NSLog(@"dealloc %@", self);
}


@end
