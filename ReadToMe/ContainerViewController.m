//
//  ViewController.m
//  ReadToMe
//
//  Created by jun on 3/23/15.
//  Copyright (c) 2015 keicoder. All rights reserved.
//


#import "ContainerViewController.h"
#import "LanguagePickerViewController.h"
#import "SettingsViewController.h"


@interface ContainerViewController () <AVSpeechSynthesizerDelegate, NSFetchedResultsControllerDelegate, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, strong) NSDateFormatter *formatter;

@property (nonatomic, strong) NSUserDefaults *sharedDefaults;
@property (nonatomic, strong) NSUserDefaults *defaults;

@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;
@property (nonatomic, strong) AVSpeechUtterance *utterance;
@property (nonatomic, strong) UIPasteboard *pasteBoard;

@property (nonatomic, assign) float volume;
@property (nonatomic, assign) float pitch;
@property (nonatomic, assign) float rate;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *menuViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *saveAlertViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardAccessoryViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *equalizerViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *floatingBackgroundViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *floatingViewWidthConstraint;

@property (weak, nonatomic) IBOutlet UIView *menuView;
@property (weak, nonatomic) IBOutlet UIButton *listButton;
@property (weak, nonatomic) IBOutlet UIButton *archiveButton;
@property (weak, nonatomic) IBOutlet UIButton *logoButton;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;

@property (weak, nonatomic) IBOutlet UIView *progressView;
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;

@property (weak, nonatomic) IBOutlet UIView *saveAlertView;
@property (weak, nonatomic) IBOutlet UILabel *saveAlertLabel;

@property (weak, nonatomic) IBOutlet KeiTextView *textView;

@property (weak, nonatomic) IBOutlet UIView *keyboardAccessoryView;
@property (weak, nonatomic) IBOutlet UIButton *previousButton;
@property (weak, nonatomic) IBOutlet UIButton *keyboardDownButton;
@property (weak, nonatomic) IBOutlet UIButton *selectButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@property (nonatomic, strong) NSTimer *previousButtonTimer;
@property (nonatomic, strong) NSTimer *nextButtonTimer;

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

@property (weak, nonatomic) IBOutlet UIView *floatingBackgroundView;
@property (weak, nonatomic) IBOutlet UIView *floatingView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@end


@implementation ContainerViewController
{
	BOOL _paused;
    BOOL _isTypeSelecting;
    BOOL _equalizerViewExpanded;
    BOOL _floatingViewExpanded;
    NSString *_lastViewedDocument;
    NSRange _selectedRange;
    float _speechLocationPercentValueInWholeTexts;
}


#pragma mark - View life cycle

- (void)viewDidLoad
{
    if (debugLog==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
	[super viewDidLoad];
    
	[self configureUI];
    [self hideSlideViewAndEqualizerViewWithNoAnimation];
    [self checkHasLaunchedOnce];
    [self addObserver];
    [self addTapGesture];
    [self addSwipeGesture];
    
    self.textView.editable = NO;
    _floatingViewExpanded = NO;
    [self listButtonTapped:self];
}


- (void)viewWillAppear:(BOOL)animated
{
    if (debugLog==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
	[super viewWillAppear:animated];
    
    [self setInitialDataForSpeech];
    [self executePerformFetch];
    [self.tableView reloadData];
    
    _paused = YES;
    
    [self addShadowEffectToTheView:self.floatingView withOpacity:0.5 andRadius:5.0 afterDelay:0.0 andDuration:0.25];
}


- (void)viewWillDisappear:(BOOL)animated
{
    if (debugLog==1) {NSLog(@"%@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    [super viewWillDisappear:animated];
    [self checkWhetherSavingDocumentOrNot];
}


#pragma mark - State Restoration

- (void)setInitialDataForSpeech
{
    if (debugLog==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    if (!self.synthesizer) {
        self.synthesizer = [[AVSpeechSynthesizer alloc]init];
        self.synthesizer.delegate = self;
    }
    
    if (!self.pasteBoard) {
        self.pasteBoard = [UIPasteboard generalPasteboard];
        self.pasteBoard.persistent = YES;
    }
    
    if (!self.defaults) {
        self.defaults = [NSUserDefaults standardUserDefaults];
    }
    
    if (!self.sharedDefaults) {
        self.sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:kSharedDefaultsSuiteName];
    }
    
    self.volumeSlider.value = [self.defaults floatForKey:kVolumeValue];
    self.pitchSlider.value = [self.defaults floatForKey:kPitchValue];
    self.rateSlider.value = [self.defaults floatForKey:kRateValue];
    _lastViewedDocument = [self.defaults objectForKey:kLastViewedDocument];
    
    _isTypeSelecting = [self.defaults boolForKey:kTypeSelecting];
    if (_isTypeSelecting) { //Change icon color
        [self changeSelectionButtonToColored:YES withSlideAnimation:NO];
    } else {
        [self changeSelectionButtonToColored:NO withSlideAnimation:NO];
    }
    
    [self showLog];
}


#pragma mark - Speech Synthesizer

#pragma mark Utterance

- (void)setupUtterance
{
    //Put attributes into objects
    self.utterance = [AVSpeechUtterance speechUtteranceWithString:self.textView.text];
    self.utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:self.currentDocument.language];
    self.utterance.volume = [self.currentDocument.volume floatValue];
    self.utterance.pitchMultiplier = [self.currentDocument.pitch floatValue];
    self.utterance.rate = [self.currentDocument.rate floatValue];
    self.utterance.preUtteranceDelay = 0.3f;
    self.utterance.postUtteranceDelay = 0.3f;
    
    if (!self.synthesizer) {
        self.synthesizer = [[AVSpeechSynthesizer alloc]init];
        self.synthesizer.delegate = self;
    }
    
    [self.synthesizer speakUtterance:self.utterance];
}


#pragma mark Speech State

- (void)startSpeaking
{
    if (debugLog==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    [self setupUtterance];
    
    if ([self.currentDocument.volume floatValue] <= 0) {
        [self setSpeechAttributesValue];
    }
    
    if (self.textView.text.length > 0) {
        _selectedRange = NSMakeRange(0 , 1);
    } else {
        _selectedRange = NSMakeRange(0 , 0);
    }
    self.textView.selectedRange = _selectedRange;
    
    self.textView.editable = NO;
    [self.textView resignFirstResponder];
    
    if (_isTypeSelecting) {
        [self selectWord];
    }
    
    _paused = NO;
    CGFloat duration = 0.25f;
    [UIView animateWithDuration:duration animations:^{
        [self.playPauseButton setImage:kPause forState:UIControlStateNormal];
        self.resetButton.alpha = 1.0;
    }completion:^(BOOL finished) { }];
}


- (void)pauseSpeaking
{
    if (debugLog==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    [self saveSelectedRangeValue];
    
    [self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    
    _paused = YES;
    CGFloat duration = 0.25f;
    [UIView animateWithDuration:duration animations:^{
        [self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
        self.resetButton.alpha = 0.0;
        
    }completion:^(BOOL finished) { }];
    
    self.textView.editable = YES;
    [self.textView resignFirstResponder];
}


- (void)continueSpeaking
{
    if (debugLog==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    self.textView.editable = NO;
    [self.textView resignFirstResponder];
    
    if (_isTypeSelecting == YES) {
        [self selectWord];
    }
    
    [self.synthesizer continueSpeaking];
    
    _paused = NO;
    CGFloat duration = 0.25f;
    [UIView animateWithDuration:duration animations:^{
        [self.playPauseButton setImage:kPause forState:UIControlStateNormal];
        self.resetButton.alpha = 1.0;
    }completion:^(BOOL finished) { }];
}


- (void)stopSpeaking
{
    if (debugLog==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    self.textView.editable = YES;
    [self.textView resignFirstResponder];
    
    [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    [self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
    
    _paused = YES;
    
    if (self.textView.text.length > 0) {
        _selectedRange = NSMakeRange(0 , 1);
    } else {
        _selectedRange = NSMakeRange(0 , 0);
    }
    self.textView.selectedRange = _selectedRange;
    
    CGFloat duration = 0.25f;
    _speechLocationPercentValueInWholeTexts = 0.0;
    [UIView animateWithDuration:duration animations:^{
        self.progressSlider.value = _speechLocationPercentValueInWholeTexts;
        self.resetButton.alpha = 0.0;
    }completion:^(BOOL finished) { }];
}


#pragma mark - Button Action Methods

- (IBAction)playPauseButtonTapped:(id)sender
{
    if (_equalizerViewExpanded == YES) {
        [self adjustEqualizerViewHeight:0.0];
        [self performSelector:@selector(startPauseContinueStopSpeaking:) withObject:nil afterDelay:0.35];
        
    } else {
        [self performSelector:@selector(startPauseContinueStopSpeaking:) withObject:nil afterDelay:0.0];
    }
}


- (void)startPauseContinueStopSpeaking:(id)sender
{
    if (self.synthesizer.isSpeaking == NO) {
        [self startSpeaking];
        
    } else if (_paused == YES) {
        [self continueSpeaking];
        
    } else {
        [self pauseSpeaking];
    }
}


#pragma mark Other Buttons Action Methods

- (IBAction)listButtonTapped:(id)sender
{
    if (debugLog==1) {NSLog(@"%@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    [self pauseSpeaking];
    _floatingViewExpanded = !_floatingViewExpanded;
    
    CGFloat duration = 0.25f;
    
    if (_floatingViewExpanded) {
        [self.textView resignFirstResponder];
        
        if (_equalizerViewExpanded == YES) {
            [self adjustEqualizerViewHeight:0.0];
        }
        
        CGFloat floatingViewWidth = CGRectGetWidth(self.view.bounds) * 0.7;
        self.floatingViewWidthConstraint.constant = floatingViewWidth;
        
        //Spring Animation
        [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:0.1 options:UIViewAnimationOptionCurveEaseInOut animations:^ {
            
            self.addButton.alpha = 1.0;
            self.closeButton.alpha = 1.0;
            [self.view layoutIfNeeded];
            
        } completion:^(BOOL finished) {
            
            CGFloat floatingBackgroundViewWidth = CGRectGetWidth(self.view.bounds);
            self.floatingBackgroundViewWidthConstraint.constant = floatingBackgroundViewWidth;
            
            [self addShadowEffectToTheView:self.floatingView withOpacity:0.5 andRadius:5.0 afterDelay:0.0 andDuration:0.25];
        }];
        
        //Whether to save
        [self checkWhetherSavingDocumentOrNot];
        
    } else {
        
        [self addShadowEffectToTheView:self.floatingView withOpacity:0.0 andRadius:0.0 afterDelay:0.0 andDuration:0.25];
        
        self.floatingViewWidthConstraint.constant = 0.0;
        
        [UIView animateWithDuration:duration animations:^{
            self.addButton.alpha = 0.0;
            self.closeButton.alpha = 0.0;
            [self.view layoutIfNeeded];
            
        }completion:^(BOOL finished) {
            self.floatingBackgroundViewWidthConstraint.constant = 0.0;
        }];
    }
}


- (void)addShadowEffectToTheView:(UIView *)view withOpacity:(float)opacity andRadius:(float)radius afterDelay:(CGFloat)delay andDuration:(CGFloat)duration
{
    [UIView animateWithDuration:duration delay:delay options: UIViewAnimationOptionCurveEaseInOut animations:^{
        view.layer.shadowColor = [UIColor blackColor].CGColor;
        view.layer.shadowOpacity = opacity;
        view.layer.shadowOffset = CGSizeMake(0, 0);
        view.layer.shadowRadius = radius;
        view.layer.masksToBounds = NO;
        view.layer.shadowPath =[UIBezierPath bezierPathWithRect:view.layer.bounds].CGPath;
    } completion:^(BOOL finished) { }];
}


#pragma mark 생성 버튼

- (IBAction)addButtonTapped:(id)sender
{
    if (debugLog==1) {NSLog(@"%@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    if (self.pasteBoard.string.length > 0 && ![self.pasteBoard.string isEqualToString:_lastViewedDocument]) {
        
        //Arert view showing
        NSLog(@"addButtonTapped > checkIfThereAreNewClipboardTexts > Found new pasteboard string > Arert view displaying");
        
        //Alert cotroller and Alert action
        NSString *title = @"Found clipboard texts.";
        NSString *message = @"Paste it?";
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *clipboardAction  = [UIAlertAction actionWithTitle:@"Paste Clipboard Texts" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            NSLog(@"New document with clipboard texts");
            [self createNewDocumentWithTexts:self.pasteBoard.string];
            [self.textView becomeFirstResponder];
        }];
        
        UIAlertAction *addAction  = [UIAlertAction actionWithTitle:@"New Document" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            NSLog(@"New document with blank text");
            [self createNewDocumentWithTexts:kBlankText];
            [self.textView becomeFirstResponder];
        }];
        
        UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            NSLog(@"Cancel");
        }];
        
        [alert addAction:clipboardAction];
        [alert addAction:addAction];
        [alert addAction:cancel];
        
        alert.popoverPresentationController.sourceView = self.view;
        alert.popoverPresentationController.sourceRect = self.view.frame;
        
        [self presentViewController:alert animated:YES completion:nil];
        
    } else {
        
        [self createNewDocumentWithTexts:kBlankText];
        [self.textView becomeFirstResponder];
    }
}


- (void)createNewDocumentWithTexts:(NSString *)texts
{
    if (_floatingViewExpanded) {
        [self listButtonTapped:self];
    }
    
    self.currentDocument = [NSEntityDescription insertNewObjectForEntityForName:@"DocumentsForSpeech" inManagedObjectContext:[DataManager sharedDataManager].managedObjectContext];
    
    //Document Attributes
    self.currentDocument.documentTitle = texts;
    self.currentDocument.document = texts;
    self.textView.text = self.currentDocument.document;
    _lastViewedDocument = kBlankText;
    
    //Other Attributes
    self.currentDocument.isNewDocument = [NSNumber numberWithBool:YES];
    [self setDateAttributes];
    [self setSpeechAttributesValue];
    [self showLog];
    
    _selectedRange = NSMakeRange(0 , 0);
    self.textView.selectedRange = _selectedRange;
    
    self.textView.editable = YES;
}


- (void)setSpeechAttributesValue
{
    //Speech Attributes
    if (!self.defaults) {
        self.defaults = [NSUserDefaults standardUserDefaults];
    }
    
    NSString *language = [self.defaults objectForKey:kLanguage];
    if (!language) {
        NSString *currentLanguageCode = [AVSpeechSynthesisVoice currentLanguageCode];
        NSDictionary *defaultLanguage = @{ kLanguage:currentLanguageCode };
        NSString *defaultLanguageName = [defaultLanguage objectForKey:kLanguage];
        language = defaultLanguageName;
        //UserDefaults
        [self.defaults setObject:language forKey:kLanguage];
        [self.defaults synchronize];
    }
    self.currentDocument.language = language;
    
    float volume = [self.defaults floatForKey:kVolumeValue];
    if (volume <= 0.0) {
        volume = 1.0;
        //UserDefaults
        [self.defaults setFloat:volume forKey:kVolumeValue];
        [self.defaults synchronize];
    }
    self.currentDocument.volume = [NSNumber numberWithFloat:volume];
    
    float pitch = [self.defaults floatForKey:kPitchValue];
    if (pitch <= 0.5) {
        pitch = 1.0;
        //UserDefaults
        [self.defaults setFloat:pitch forKey:kPitchValue];
        [self.defaults synchronize];
    }
    self.currentDocument.pitch = [NSNumber numberWithFloat:pitch];
    
    float rate = [self.defaults floatForKey:kRateValue];
    if (rate <= 0.0) {
        rate = 0.07;
        //UserDefaults
        [self.defaults setFloat:rate forKey:kRateValue];
        [self.defaults synchronize];
    }
    self.currentDocument.rate = [NSNumber numberWithFloat:rate];
    
    //Slider value
    self.volumeSlider.value = volume;
    self.pitchSlider.value = pitch;
    self.rateSlider.value = rate;
}


#pragma mark 리셋 버튼

- (IBAction)resetButtonTapped:(id)sender
{
    [self stopSpeaking];
}


- (IBAction)actionButtonTapped:(id)sender
{
    [self pauseSpeaking];
	
	if (_equalizerViewExpanded == YES) {
		[self adjustEqualizerViewHeight:0.0];
		[self performSelector:@selector(action:) withObject:nil afterDelay:0.35];
        
	} else {
		[self performSelector:@selector(action:) withObject:nil afterDelay:0.0];
	}
}


- (void)action:(id)sender
{
	NSLog(@"Action > Show UIActivityViewController");
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[self.textView.text] applicationActivities:nil];
    [self presentViewController:activityVC animated:YES completion:nil];
}


- (IBAction)selectionButtonTapped:(id)sender
{
    if (_equalizerViewExpanded == YES) {
        [self adjustEqualizerViewHeight:0.0];
    }
    
    if (_isTypeSelecting == YES) {
        [self changeSelectionButtonToColored:NO withSlideAnimation:YES];
        
    } else {
        [self changeSelectionButtonToColored:YES withSlideAnimation:YES];
        self.textView.editable = NO; //Prevent keyboard pop-up
        [self performSelector:@selector(selectWord) withObject:nil afterDelay:0.2];
    }
}


- (IBAction)languageButtonTapped:(id)sender
{
    [self pauseSpeaking];
	
	if (_equalizerViewExpanded == YES) {
		[self adjustEqualizerViewHeight:0.0];
		[self performSelector:@selector(showLanguagePickerView:) withObject:nil afterDelay:0.35];
        
	} else {
		[self performSelector:@selector(showLanguagePickerView:) withObject:nil afterDelay:0.0];
	}
}


- (void)showLanguagePickerView:(id)sender
{
	LanguagePickerViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"LanguagePickerViewController"];
    
    controller.currentDocument = self.currentDocument;
    NSLog (@"showLanguagePickerView > self.currentDocument: %@\n", self.currentDocument);
	[self presentViewController:controller animated:YES completion:^{ }];
}


- (IBAction)equalizerButtonTappped:(id)sender
{
    if (_equalizerViewExpanded == YES) {
        [self adjustEqualizerViewHeight:0.0];
        
    } else {
        [self adjustEqualizerViewHeight:150.0];
    }
}


- (IBAction)settingsButtonTapped:(id)sender
{
    [self pauseSpeaking];
	
	if (_equalizerViewExpanded == YES) {
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


- (IBAction)logoButtonTapped:(id)sender
{
    //Open URL
    UIResponder* responder = self;
    
    while ((responder = [responder nextResponder]) != nil) {
        NSLog(@"responder = %@", responder);
        
        if([responder respondsToSelector:@selector(openURL:)] == YES) {
            [responder performSelector:@selector(openURL:) withObject:[NSURL URLWithString:@"https://itunes.apple.com/us/app/talk-to-me-world/id985869735?l=ko&ls=1&mt=8"]];
        }
    }
}


#pragma mark - Save Data
#pragma mark Saving

- (void)checkWhetherSavingDocumentOrNot
{
    if (debugLog==1) {NSLog(@"%@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    if ([self.currentDocument.isNewDocument boolValue] == YES) {
        
        if ([_lastViewedDocument isEqualToString:self.textView.text]) {
            NSLog(@"It's new document but no texts, so nothing to save");
            
        } else {
            NSLog(@"It's new document and have texts, so save document");
            [self saveSpeechDocumentAndAttributes];
        }
        
    } else {
        
        if ([_lastViewedDocument isEqualToString:self.textView.text]) {
            NSLog(@"Can't find any changing in document, so nothing updated");
            
        } else {
            NSLog(@"Document updated, so save document");
            [self saveSpeechDocumentAndAttributes];
        }
    }
}


- (void)saveSpeechDocumentAndAttributes
{
    if (debugLog==1) {NSLog(@"%@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    if ([self.textView isFirstResponder]) {
        [self.textView resignFirstResponder];
    }
    
    [self updateSpeechDocumentAndAttributes]; //다큐먼트 업데이트
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self saveIndexPath:indexPath];
    
    //Save
    [[DataManager sharedDataManager].managedObjectContext performBlock:^{
        NSError *error = nil;
        if ([[DataManager sharedDataManager].managedObjectContext save:&error]) {
            
            NSLog(@"Document saved > executePerformFetch, tableView reloadData");
            [self executePerformFetch];
            [self.tableView reloadData];
            [self showLog];
        } else {
            NSLog(@"Error saving context: %@", error);
        }
    }];
}


- (void)updateSpeechDocumentAndAttributes
{
    //User defaults
    if (!self.defaults) {
        self.defaults = [NSUserDefaults standardUserDefaults];
    }
    
    //Speech Attributes
    self.currentDocument.language = [self.defaults objectForKey:kLanguage];
    self.currentDocument.volume = [NSNumber numberWithFloat:[self.defaults floatForKey:kVolumeValue]];
    self.currentDocument.pitch = [NSNumber numberWithFloat:[self.defaults floatForKey:kPitchValue]];
    self.currentDocument.rate = [NSNumber numberWithFloat:[self.defaults floatForKey:kRateValue]];
    
    //Document Attributes
    NSString *firstLineForTitle = [self retrieveFirstLineOfStringForTitle:self.textView.text];
    self.currentDocument.documentTitle = firstLineForTitle;
    self.currentDocument.document = self.textView.text;
    _lastViewedDocument = self.textView.text;
    
    //Date Attributes
    [self setDateAttributes];
    
    //Set to saved document
    if (self.currentDocument.isNewDocument) {
        self.currentDocument.isNewDocument = [NSNumber numberWithBool:NO];
    }
    
    //User defaults sync
    [self.defaults setObject:_lastViewedDocument forKey:kLastViewedDocument];
    [self.defaults setObject:self.currentDocument.language forKey:kLanguage];
    [self.defaults setFloat:[self.currentDocument.volume floatValue] forKey:kVolumeValue];
    [self.defaults setFloat:[self.currentDocument.pitch floatValue] forKey:kPitchValue];
    [self.defaults setFloat:[self.currentDocument.rate floatValue] forKey:kRateValue];
    [self.defaults synchronize];
}


- (void)setDateAttributes
{
    //Date Attributes
    NSDate *now = [NSDate date];
    
    if ([self.currentDocument.isNewDocument boolValue] == YES) {
        self.currentDocument.createdDate = now;
    }
    self.currentDocument.modifiedDate = now;
    
    [self.formatter setDateFormat:@"yyyy"];
    NSString *stringYear = [self.formatter stringFromDate:now];
    self.currentDocument.yearString = stringYear;
    
    [self.formatter setDateFormat:@"MMM"];
    NSString *stringMonth = [self.formatter stringFromDate:now];
    self.currentDocument.monthString = stringMonth;
    
    [self.formatter setDateFormat:@"dd"];
    NSString *stringDay = [self.formatter stringFromDate:now];
    self.currentDocument.dayString = stringDay;
    
    [self.formatter setDateFormat:@"EEEE"];
    NSString *stringDate = [self.formatter stringFromDate:now];
    NSString *stringdaysOfTheWeek = [[stringDate substringToIndex:3] uppercaseString];
    self.currentDocument.dateString = stringdaysOfTheWeek;
    
    [self.formatter setDateFormat:@"MMM yyyy"];
    NSString *monthAndYearString = [self.formatter stringFromDate:now];
    self.currentDocument.monthAndYearString = monthAndYearString;
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


#pragma mark Formatter

- (NSDateFormatter *)formatter
{
    if (!_formatter) {
        _formatter = [[NSDateFormatter alloc] init];
    }
    return _formatter;
}


#pragma mark 유저 디폴트 > 현재 인덱스패스 저장

- (void)saveIndexPath:(NSIndexPath *)indexPath
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setIndexPath:indexPath forKey:kSelectedDocumentIndexPath];
    [defaults setInteger:indexPath.row forKey:kSelectedDocumentIndex];
    [defaults synchronize];
}


#pragma mark - Fetched Results Controller

- (void)executePerformFetch
{
    if (debugLog==1) {NSLog(@"%@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    NSError *error = nil;
    if (![[self fetchedResultsController] performFetch:&error]) {
        NSLog (@"executePerformFetch > error occurred");
        NSLog(@"%@, %@", error, error.localizedDescription);
        //abort();
    }
}


- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
        
    } else if (_fetchedResultsController == nil) {
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DocumentsForSpeech"];
        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"modifiedDate" ascending:NO];
        [fetchRequest setSortDescriptors: @[sort]];
        
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[DataManager sharedDataManager].managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        
        [fetchRequest setFetchBatchSize:20];
        _fetchedResultsController.delegate = self;
    }
    
    return _fetchedResultsController;
}


#pragma mark NSFetched Results Controller Delegate (수정사항 반영)

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeUpdate:
            break;
            
        case NSFetchedResultsChangeMove:
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [tableView reloadData];
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}


#pragma mark - Select Word

- (void)selectWord
{
    if (debugLog==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    if (_isTypeSelecting == YES) {
        
        if (self.synthesizer.continueSpeaking == YES) {
            
            [self retrieveSelectedRangeValue];
            [self.textView select:self];
        }
    }
}


#pragma mark Save, Retrieve Selected Range Value

- (void)saveSelectedRangeValue
{
    if (!self.defaults) {
        self.defaults = [NSUserDefaults standardUserDefaults];
    }
    
    UITextPosition* beginning = self.textView.beginningOfDocument;
    UITextRange* selectedRange = self.textView.selectedTextRange;
    UITextPosition* selectionStart = selectedRange.start;
    UITextPosition* selectionEnd = selectedRange.end;
    
    const NSInteger location = [self.textView offsetFromPosition:beginning toPosition:selectionStart];
    const NSInteger length = [self.textView offsetFromPosition:selectionStart toPosition:selectionEnd];
    
    _selectedRange = NSMakeRange(location, length);
    [self.defaults setInteger:_selectedRange.location forKey:kSelectedRangeLocation];
    [self.defaults setInteger:_selectedRange.length forKey:kSelectedRangeLength];
    [self.defaults synchronize];
}


- (void)retrieveSelectedRangeValue
{
    if (!self.defaults) {
        self.defaults = [NSUserDefaults standardUserDefaults];
    }
    NSInteger selectedRangeLocation = [self.defaults integerForKey:kSelectedRangeLocation];
    NSInteger selectedRangeLength =[self.defaults integerForKey:kSelectedRangeLength];
    self.textView.selectedRange = NSMakeRange(selectedRangeLocation, selectedRangeLength);
}


#pragma mark - Slider value changed

- (IBAction)progressSliderValueChanged:(UISlider *)sender
{
    self.progressSlider.value = _speechLocationPercentValueInWholeTexts;
}


- (IBAction)volumeSliderValueChanged:(UISlider *)sender
{
    if (!self.defaults) {
        self.defaults = [NSUserDefaults standardUserDefaults];
    }
    
    [self stopSpeaking];
    [self.defaults setFloat:self.volumeSlider.value forKey:kVolumeValue];
    [self.defaults synchronize];
    [self saveSpeechDocumentAndAttributes];
}


- (IBAction)pitchSliderValueChanged:(UISlider *)sender
{
    if (!self.defaults) {
        self.defaults = [NSUserDefaults standardUserDefaults];
    }
    
    [self stopSpeaking];
    [self.defaults setFloat:self.pitchSlider.value forKey:kPitchValue];
    [self.defaults synchronize];
    [self saveSpeechDocumentAndAttributes];
}


- (IBAction)rateSliderValueChanged:(UISlider *)sender
{
    if (!self.defaults) {
        self.defaults = [NSUserDefaults standardUserDefaults];
    }
    
    [self stopSpeaking];
    [self.defaults setFloat:self.rateSlider.value forKey:kRateValue];
    [self.defaults synchronize];
    [self saveSpeechDocumentAndAttributes];
}


#pragma mark - Add Observer

- (void)addObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    //Picked Language
    [center addObserver:self selector:@selector(didPickedLanguageNotification:) name:@"DidPickedLanguageNotification" object:nil];
    
    //Keyboard
    [center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:self.view.window];
    [center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:self.view.window];
    
    //Device Orientation
    [center addObserver:self selector:@selector(deviceOrientationChanged:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    
    //Application Status
    [center addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [center addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [center addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [center addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [center addObserver:self selector:@selector(applicationDidReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [center addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
}


#pragma mark Picked Language

- (void)didPickedLanguageNotification:(NSNotification *)notification
{
    NSLog(@"DidPickedLanguageNotification Recieved");
    
    [self stopSpeaking];
    
    if (self.defaults) { self.defaults = [NSUserDefaults standardUserDefaults]; }
    
    self.currentDocument.language = [self.defaults objectForKey:kLanguage];
    [self.defaults setObject:self.currentDocument.language forKey:kLanguage];
    [self.defaults synchronize];
    
    [self saveSpeechDocumentAndAttributes];
    
    NSLog (@"didPickedLanguageNotification > self.currentDocument: %@\n", self.currentDocument);
}


#pragma mark Keyboard Handling

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGRect keyboardFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardHeight = CGRectGetHeight(keyboardFrame);
    CGFloat bottomViewHeight = CGRectGetHeight(self.bottomView.frame);
    CGFloat progressViewHeight = CGRectGetHeight(self.progressView.frame);
    
    self.menuViewHeightConstraint.constant = 0.0;
    [self adjustEqualizerViewHeight:keyboardHeight - bottomViewHeight - progressViewHeight];
    self.keyboardAccessoryViewHeightConstraint.constant = 44.0;
    
    [UIView animateWithDuration:0.35 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.view layoutIfNeeded];
        self.keyboardDownButton.alpha = 1.0;
        self.listButton.alpha = 0.0;
    } completion:^(BOOL finished) { }];
}


- (void)keyboardWillHide:(NSNotification*)notification
{
    [self adjustEqualizerViewHeight:0.0];
    if (iPad) {
        self.menuViewHeightConstraint.constant = 60.0;
    } else {
        self.menuViewHeightConstraint.constant = 44.0;
    }
    
    self.keyboardAccessoryViewHeightConstraint.constant = 0.0;
    
    [UIView animateWithDuration:0.35 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.view layoutIfNeeded];
        self.keyboardDownButton.alpha = 0.0;
        self.listButton.alpha = 1.0;
    } completion:nil];
}


#pragma mark Device Orientation Changed

- (void)deviceOrientationChanged:(NSNotification *)notification
{
    if (debugLog==1) {NSLog(@"%@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    if (_floatingViewExpanded) {
        [self addShadowEffectToTheView:self.floatingView withOpacity:0.0 andRadius:0.0 afterDelay:0.0 andDuration:0.0];
        
        CGFloat floatingViewWidth = CGRectGetWidth(self.view.bounds) * 0.7;
        self.floatingViewWidthConstraint.constant = floatingViewWidth;
        
        CGFloat duration = 0.25;
        [UIView animateWithDuration:duration animations:^{
            [self.view layoutIfNeeded];
            
        }completion:^(BOOL finished) {
            CGFloat floatingBackgroundViewWidth = CGRectGetWidth(self.view.bounds);
            self.floatingBackgroundViewWidthConstraint.constant = floatingBackgroundViewWidth;
            [self addShadowEffectToTheView:self.floatingView withOpacity:0.5 andRadius:5.0 afterDelay:0.0 andDuration:0.25];
        }];
    }
}


#pragma mark UITextView delegate method

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if (debugLog==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    CGFloat duration = 0.25f;
    [UIView animateWithDuration:duration animations:^{
        self.playPauseButton.alpha = 0.0;
    }completion:^(BOOL finished) { }];
}


- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (debugLog==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    if ([textView isFirstResponder]) {
        [textView resignFirstResponder];
    }
    
    CGFloat duration = 0.25f;
    [UIView animateWithDuration:duration animations:^{
        self.playPauseButton.alpha = 1.0;
    }completion:^(BOOL finished) { }];
    
    if (![_lastViewedDocument isEqualToString:self.textView.text]) {
        NSLog(@"textViewDidEndEditing > TextView texts are changed, so stop speaking");
        [self stopSpeaking];
        self.currentDocument.document = self.textView.text;
        self.pasteBoard.string = self.textView.text;
        [self saveSpeechDocumentAndAttributes];
        
    } else {
        NSLog(@"textViewDidEndEditing > Nothing Changed");
    }
}


#pragma mark Application's State

- (void)applicationWillResignActive
{
    if (debugLog==1) {NSLog(@"%@ '%@'", self.class, NSStringFromSelector(_cmd));}
}


- (void)applicationDidEnterBackground
{
    if (debugLog==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    NSLog(@"applicationDidEnterBackground > checkWhetherSavingDocumentOrNot");
    [self checkWhetherSavingDocumentOrNot];
}


- (void)applicationWillEnterForeground
{
    if (debugLog==1) {NSLog(@"%@ '%@'", self.class, NSStringFromSelector(_cmd));}
    [self checkIfExtensionDocument];
}


- (void)applicationDidBecomeActive
{
    if (debugLog==1) {NSLog(@"%@ '%@'", self.class, NSStringFromSelector(_cmd));}
}


- (void)applicationDidReceiveMemoryWarning
{
    if (debugLog==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    NSLog(@"applicationDidReceiveMemoryWarning > checkWhetherSavingDocumentOrNot");
    [self checkWhetherSavingDocumentOrNot];
    [self stopSpeaking];
}


- (void)applicationWillTerminate
{
    if (debugLog==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    NSLog(@"applicationWillTerminate > checkWhetherSavingDocumentOrNot");
    [self checkWhetherSavingDocumentOrNot];
    [self stopSpeaking];
}


#pragma mark - Check if extension document

- (void)checkIfExtensionDocument
{
    if (debugLog==1) {NSLog(@"%@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    if (!self.sharedDefaults) {
        self.sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:kSharedDefaultsSuiteName];
    }
    
    //Today Extension
    self.isTodayDocument = [self.sharedDefaults boolForKey:kIsTodayDocument];
    kLogBOOL(self.isTodayDocument);
    
    //Share Extension
    self.isSharedDocument = [self.sharedDefaults boolForKey:kIsSharedDocument];
    kLogBOOL(self.isSharedDocument);
    
    if (self.isTodayDocument) {
        NSLog(@"Found Today Document");
        
        //add new document
        NSString *document = [self.sharedDefaults objectForKey:kTodayDocument];
        [self createNewDocumentWithTexts:document];
        
        //SharedDefaults sync
        [self.sharedDefaults setBool:NO forKey:kIsTodayDocument];
        [self.sharedDefaults synchronize];
        self.isTodayDocument = NO;
        kLogBOOL(self.isTodayDocument);
        
    } else if (self.isSharedDocument) {
        NSLog(@"Found Shared Document");
        
        //add new document
        NSString *document = [self.sharedDefaults objectForKey:kSharedDocument];
        [self createNewDocumentWithTexts:document];
        
        //SharedDefaults sync
        [self.sharedDefaults setBool:NO forKey:kIsSharedDocument];
        [self.sharedDefaults synchronize];
        self.isSharedDocument = NO;
        kLogBOOL(self.isSharedDocument);
    }
    
    if ([self.textView isFirstResponder]) {
        [self.textView resignFirstResponder];
    }
}


#pragma mark - Change Selection Button to Colored or Not

- (void)changeSelectionButtonToColored:(BOOL)didSetColored withSlideAnimation:(BOOL)willAnimate
{
    if (didSetColored == YES) {
        _isTypeSelecting = YES;
        [self.defaults setBool:YES forKey:kTypeSelecting];
        [self.defaults synchronize];
        
        //Spring animation
        CGFloat duration = 0.25f;
        [UIView animateWithDuration:duration animations:^{
            
            UIImage *image = [UIImage imageForChangingColor:@"selection" color:[UIColor colorWithRed:0.988 green:0.71 blue:0 alpha:1]];
            [self.selectionButton setImage:image forState:UIControlStateNormal];
            
        }completion:^(BOOL finished) { }];
        
        if (willAnimate) {
            [self adjustSlideViewHeightWithTitle:@"WORD SELECTING" height:kSlideViewHeight color:[UIColor colorWithRed:0 green:0.635 blue:0.259 alpha:1] withSender:self.selectionButton];
        }
        
    } else {
        
        _isTypeSelecting = NO;
        [self.defaults setBool:NO forKey:kTypeSelecting];
        [self.defaults synchronize];
        
        CGFloat duration = 0.25f;
        [UIView animateWithDuration:duration animations:^{
            
            UIImage *image = [UIImage imageForChangingColor:@"selection" color:[UIColor whiteColor]];
            [self.selectionButton setImage:image forState:UIControlStateNormal];
            
        }completion:^(BOOL finished) { }];
        
        if (willAnimate) {
            [self adjustSlideViewHeightWithTitle:@"NO WORD SELECTING" height:kSlideViewHeight color:[UIColor colorWithRed:0.984 green:0.4 blue:0.302 alpha:1] withSender:self.selectionButton];
        }
    }
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
    [self.textView scrollToVisibleCaretAnimated];
    
    
    float entireTextLength = (float)[self.textView.text length];
    float location = (float)rangeInTotalText.location;
    _speechLocationPercentValueInWholeTexts = (location / entireTextLength) * 100;
    self.progressSlider.value = _speechLocationPercentValueInWholeTexts;
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
    NSLog(@"speechSynthesizer didFinishSpeechUtterance, so stopSpeaking");
    [self stopSpeaking];
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance *)utterance
{
    NSLog(@"speechSynthesizer didPauseSpeechUtterance, so pauseSpeaking");
    [self pauseSpeaking];
}


#pragma mark - Adjust SlideView height when user touches equivalent button

- (void)adjustSlideViewHeightWithTitle:(NSString *)string height:(float)height color:(UIColor *)color withSender:(UIButton *)button
{
    CGFloat duration = 0.25f;
    CGFloat delay = 0.0f;
    
    self.saveAlertViewHeightConstraint.constant = height;
    button.enabled = NO;
    self.saveAlertView.backgroundColor = color;
    
    //Spring animation
    [UIView animateWithDuration:duration delay:delay usingSpringWithDamping:0.6 initialSpringVelocity:0.1 options:UIViewAnimationOptionCurveEaseInOut animations:^ {
        
        [self.view layoutIfNeeded];
        self.saveAlertLabel.alpha = 1.0;
        self.saveAlertLabel.text = string;
        
    } completion:^(BOOL finished) {
        
        //Dispatch After
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.6 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
            
            self.saveAlertViewHeightConstraint.constant = 0.0;
            
            [UIView animateWithDuration:duration delay:delay options: UIViewAnimationOptionCurveEaseInOut animations:^{
                
                [self.view layoutIfNeeded];
                self.saveAlertLabel.alpha = 0.0;
                
            } completion:^(BOOL finished) {
                
                button.enabled = YES;
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
    
    //Spring animation
    [UIView animateWithDuration:duration delay:delay usingSpringWithDamping:0.6 initialSpringVelocity:0.1 options:UIViewAnimationOptionCurveEaseInOut animations:^ {
        
        if (height == 0) {
            self.volumeLabel.alpha = 0.0;
            self.pitchLabel.alpha = 0.0;
            self.rateLabel.alpha = 0.0;
            self.volumeSlider.alpha = 0.0;
            self.pitchSlider.alpha = 0.0;
            self.rateSlider.alpha = 0.0;
            
            _equalizerViewExpanded = NO;
            
        } else {
            self.volumeLabel.alpha = 1.0;
            self.pitchLabel.alpha = 1.0;
            self.rateLabel.alpha = 1.0;
            self.volumeSlider.alpha = 1.0;
            self.pitchSlider.alpha = 1.0;
            self.rateSlider.alpha = 1.0;
            
            _equalizerViewExpanded = YES;
        }
        
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) { }];
}


#pragma mark - hideSlideViewAndEqualizerViewWithNoAnimation

- (void)hideSlideViewAndEqualizerViewWithNoAnimation
{
    [UIView animateWithDuration:0.0 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations:^{
        self.keyboardAccessoryViewHeightConstraint.constant = 0.0;
        [self.view layoutIfNeeded];
        self.keyboardDownButton.alpha = 0.0;
    } completion:nil];
    
    [UIView animateWithDuration:0.0 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations:^{
        self.saveAlertViewHeightConstraint.constant = 0.0;
        [self.view layoutIfNeeded];
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


#pragma mark - 앱 처음 실행인지 체크 > Volume, Pitch, Rate 기본값 적용

- (void)checkHasLaunchedOnce
{
    if (debugLog==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    if (!self.defaults) {
        self.defaults = [NSUserDefaults standardUserDefaults];
    }
    
    if ([self.defaults boolForKey:kHasLaunchedOnce] == NO) {
        NSLog(@"First time launching!");
        
        NSString *currentLanguageCode = [AVSpeechSynthesisVoice currentLanguageCode];
        NSDictionary *defaultLanguage = @{ kLanguage:currentLanguageCode };
        NSString *defaultLanguageName = [defaultLanguage objectForKey:kLanguage];
        [self.defaults setObject:defaultLanguageName forKey:kLanguage];
        
        float volume = 1.0;
        float pitch = 1.0;
        float rate = 0.07;
        [self.defaults setBool:YES forKey:kTypeSelecting];
        [self.defaults setFloat:volume forKey:kVolumeValue];
        [self.defaults setFloat:pitch forKey:kPitchValue];
        [self.defaults setFloat:rate forKey:kRateValue];
        
        _lastViewedDocument = @"";
        _isTypeSelecting = YES;
        
        self.volumeSlider.value = volume;
        self.pitchSlider.value = pitch;
        self.rateSlider.value = rate;
        
        [self.defaults setBool:YES forKey:kHasLaunchedOnce];
        [self.defaults synchronize];
    }
}


#pragma mark - Table View
#pragma mark Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog (@"numberOfRowsInSection: %lu\n", (unsigned long)[[self.fetchedResultsController sections][section] numberOfObjects]);
    return [[self.fetchedResultsController sections][section] numberOfObjects];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    
    ListTableViewCell *cell = (ListTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = (ListTableViewCell *)[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    DocumentsForSpeech *documentsForSpeech = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.titleLabel.text = documentsForSpeech.documentTitle;
    cell.dayLabel.text = documentsForSpeech.dayString;
    cell.dateLabel.text = documentsForSpeech.dateString;
    cell.monthAndYearLabel.text = documentsForSpeech.monthAndYearString;
    
    return cell;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 88.0;
}


#pragma mark Select

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (debugLog==1) {NSLog(@"%@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    [self stopSpeaking];
    
    self.textView.editable = YES;
    
    self.currentDocument = (DocumentsForSpeech *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    NSLog (@"didSelectRowAtIndexPath > self.currentDocument: %@\n", self.currentDocument);
    
    self.textView.text = self.currentDocument.document;
    _lastViewedDocument = self.currentDocument.document;
    
    self.volumeSlider.value = [self.currentDocument.volume floatValue];
    self.pitchSlider.value = [self.currentDocument.pitch floatValue];
    self.rateSlider.value = [self.currentDocument.rate floatValue];
    
    [self saveIndexPath:indexPath];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self listButtonTapped:self];
    
    //User defaults
    if (!self.defaults) {
        self.defaults = [NSUserDefaults standardUserDefaults];
    }
    //User defaults sync
    [self.defaults setObject:_lastViewedDocument forKey:kLastViewedDocument];
    [self.defaults setObject:self.currentDocument.language forKey:kLanguage];
    [self.defaults setFloat:[self.currentDocument.volume floatValue] forKey:kVolumeValue];
    [self.defaults setFloat:[self.currentDocument.pitch floatValue] forKey:kPitchValue];
    [self.defaults setFloat:[self.currentDocument.rate floatValue] forKey:kRateValue];
    [self.defaults synchronize];
    
}


#pragma mark Editing

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        if (debugLog==1) {NSLog(@"%@ '%@'", self.class, NSStringFromSelector(_cmd));}
        
        [self deleteCoreDataNoteObject:indexPath];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSInteger index = [defaults integerForKey:kSelectedDocumentIndex];
        
        NSLog (@"kSelectedDocumentIndex: %ld\n", (long)index);
        NSLog (@"indexPath.row: %ld\n", (long)indexPath.row);
        
        if (index == indexPath.row) {
            
            NSLog(@"self.currentDocument was deleted");
            self.currentDocument = nil;
            self.textView.text = kBlankText;
            self.textView.editable = NO;
            [self stopSpeaking]; //If there's paused speech, stop it.
        }
    }
}


- (void)deleteCoreDataNoteObject:(NSIndexPath *)indexPath
{
    [[DataManager sharedDataManager].managedObjectContext deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
    NSError *error = nil;
    [[DataManager sharedDataManager].managedObjectContext save:&error];
}


#pragma mark Moving

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}


#pragma mark - Gesture
#pragma mark Tap Gesture

- (void)addTapGesture
{
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(listButtonTapped:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.delegate = self;
    
    [self.floatingBackgroundView addGestureRecognizer:gestureRecognizer];
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return (touch.view == self.floatingBackgroundView);
}

#pragma mark Swipe Gesture

- (void)addSwipeGesture
{
    UISwipeGestureRecognizer *right = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipes:)];
    right.direction = UISwipeGestureRecognizerDirectionRight;
    right.numberOfTouchesRequired = 1;
    [self.textView addGestureRecognizer:right];
    
    UISwipeGestureRecognizer *left = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipes:)];
    left.direction = UISwipeGestureRecognizerDirectionLeft;
    left.numberOfTouchesRequired = 1;
    [self.floatingBackgroundView addGestureRecognizer:left];
}


- (void)handleSwipes:(UISwipeGestureRecognizer *)swipeGesture
{
    if (swipeGesture.direction & UISwipeGestureRecognizerDirectionLeft){
        _floatingViewExpanded = YES;
        [self listButtonTapped:swipeGesture];
    }
    
    if (swipeGesture.direction & UISwipeGestureRecognizerDirectionRight){
        _floatingViewExpanded = NO;
        [self listButtonTapped:swipeGesture];
    }
}


#pragma mark Keyboard Accessory Buttons Action Methods

- (IBAction)previousButtonTapped:(id)sender
{
    self.previousButtonTimer = [NSTimer scheduledTimerWithTimeInterval:0.15 target:self selector:@selector(previousCharacter:) userInfo:nil repeats:YES];
    [self.previousButtonTimer fire];
}


-(void)previousCharacter:(id)sender
{
    if (self.previousButton.state == UIControlStateNormal){
        [self.previousButtonTimer invalidate];
        self.previousButtonTimer = nil;
    }
    else {
        UITextRange *selectedRange = [self.textView selectedTextRange];
        
        if (self.textView.selectedRange.location > 0)
        {
            UITextPosition *newPosition = [self.textView positionFromPosition:selectedRange.start offset:-1];
            UITextRange *newRange = [self.textView textRangeFromPosition:newPosition toPosition:newPosition];
            [self.textView setSelectedTextRange:newRange];
        }
        [self.textView scrollToVisibleCaretAnimated];
    }
}


- (IBAction)keyboardDownButtonTapped:(id)sender
{
    [self.textView resignFirstResponder];
}


- (IBAction)selectButtonTapped:(id)sender
{
    _selectedRange = self.textView.selectedRange;
    
    if (![self.textView hasText])
    {
        [self.textView select:self];
    }
    else if ([self.textView hasText] && _selectedRange.length == 0)
    {
        [self.textView select:self];
    }
    else if ([self.textView hasText] && _selectedRange.length > 0)
    {
        _selectedRange.location = _selectedRange.location + _selectedRange.length;
        _selectedRange.length = 0;
        self.textView.selectedRange = _selectedRange;
    }
}


- (IBAction)nextButtonTapped:(id)sender
{
    self.nextButtonTimer = [NSTimer scheduledTimerWithTimeInterval:0.15 target:self selector:@selector(nextCharacter:) userInfo:nil repeats:YES];
    [self.nextButtonTimer fire];
}


-(void)nextCharacter:(id)sender
{
    if (self.nextButton.state == UIControlStateNormal){
        [self.nextButtonTimer invalidate];
        self.nextButtonTimer = nil;
    
    } else {
        UITextRange *selectedRange = [self.textView selectedTextRange];
        
        if (self.textView.selectedRange.location < self.textView.text.length)
        {
            UITextPosition *newPosition = [self.textView positionFromPosition:selectedRange.start offset:1];
            UITextRange *newRange = [self.textView textRangeFromPosition:newPosition toPosition:newPosition];
            [self.textView setSelectedTextRange:newRange];
        }
        [self.textView scrollToVisibleCaretAnimated];
    }
}


#pragma mark - Configure UI

- (void)configureUI
{
    if (debugLog==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    self.menuView.backgroundColor = [UIColor colorWithRed:0.294 green:0.463 blue:0.608 alpha:1];
    self.saveAlertView.backgroundColor = [UIColor colorWithRed:0.945 green:0.671 blue:0.686 alpha:1];
    self.bottomView.backgroundColor = [UIColor colorWithRed:0.157 green:0.29 blue:0.42 alpha:1];
    self.progressView.backgroundColor = [UIColor colorWithRed:0.294 green:0.463 blue:0.608 alpha:1];
    self.equalizerView.backgroundColor = [UIColor colorWithRed:0.294 green:0.463 blue:0.608 alpha:1];
    self.floatingView.backgroundColor = self.menuView.backgroundColor;
    self.tableView.backgroundColor = [UIColor whiteColor];
    
    //키보드 액세서리 뷰
    self.keyboardAccessoryView.backgroundColor = [UIColor colorWithRed:0.255 green:0.427 blue:0.475 alpha:1]; //[UIColor colorWithRed:0.008 green:0.141 blue:0.227 alpha:1];
    
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
    self.listButton.enabled = YES;
    self.listButton.alpha = 1.0;
    self.archiveButton.enabled = NO;
    self.archiveButton.alpha = 0.0;
    self.logoButton.enabled = NO;
    self.logoButton.alpha = 0.0;
    self.actionButton.enabled = NO;
    self.actionButton.alpha = 0.0;
    self.resetButton.alpha = 0.0;
    
    //Slider UI
    UIImage *thumbImageNormal = [UIImage imageNamed:@"recordNormal"];
    [self.progressSlider setThumbImage:thumbImageNormal forState:UIControlStateNormal];
    UIImage *thumbImageHighlighted = [UIImage imageNamed:@"record"];
    [self.progressSlider setThumbImage:thumbImageHighlighted forState:UIControlStateHighlighted];
    UIImage *trackLeftImage = [[UIImage imageNamed:@"SliderTrackLeft"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 14, 0, 14)];
    [self.progressSlider setMinimumTrackImage:trackLeftImage forState:UIControlStateNormal];
    UIImage *trackRightImage = [[UIImage imageNamed:@"SliderTrackRight"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 14, 0, 14)];
    [self.progressSlider setMaximumTrackImage:trackRightImage forState:UIControlStateNormal];
}


#pragma mark - Dealloc

- (void)dealloc
{
    NSLog(@"dealloc %@", self);
}


#pragma mark - Show Log

- (void)showLog
{
    NSLog(@"\n");
    NSLog (@"*****Speech Attributes*****");
    NSLog (@"self.currentDocument.language: %@\n", self.currentDocument.language);
    NSLog (@"[self.currentDocument.volume floatValue]: %f\n", [self.currentDocument.volume floatValue]);
    NSLog (@"[self.currentDocument.pitch floatValue]: %f\n", [self.currentDocument.pitch floatValue]);
    NSLog (@"[self.currentDocument.rate floatValue]: %f\n", [self.currentDocument.rate floatValue]);
    
    NSLog(@"\n");
    NSLog(@"Slider Attributes");
    NSLog (@"self.volumeSlider.value: %f\n", self.volumeSlider.value);
    NSLog (@"self.pitchSlider.value: %f\n", self.pitchSlider.value);
    NSLog (@"self.rateSlider.value: %f\n", self.rateSlider.value);
    
    NSLog(@"\n");
    NSLog(@"Document Attributes");
    NSLog (@"_isTypeSelecting: %@\n", _isTypeSelecting ? @"YES" : @"NO");
    NSLog (@"self.currentDocument.isNewDocument: %@\n", self.currentDocument.isNewDocument ? @"YES" : @"NO");
    NSLog (@"self.currentDocument.createdDate: %@\n", self.currentDocument.createdDate);
    NSLog (@"self.currentDocument.modifiedDate: %@\n", self.currentDocument.modifiedDate);
    NSLog (@"self.currentDocument.yearString: %@\n", self.currentDocument.yearString);
    NSLog (@"self.currentDocument.monthString: %@\n", self.currentDocument.monthString);
    NSLog (@"self.currentDocument.dateString: %@\n", self.currentDocument.dateString);
    NSLog (@"self.currentDocument.dayString: %@\n", self.currentDocument.dayString);
    NSLog (@"self.currentDocument.monthAndYearString: %@\n", self.currentDocument.monthAndYearString);
    NSLog (@"self.currentDocument.documentTitle: %@\n", self.currentDocument.documentTitle);
    NSLog (@"self.currentDocument.document: %@\n", self.currentDocument.document);
    
    /*
     @property (nonatomic, retain) NSDate * createdDate;
     @property (nonatomic, retain) NSDate * modifiedDate;
     @property (nonatomic, retain) NSString * dateString;
     @property (nonatomic, retain) NSString * dayString;
     @property (nonatomic, retain) NSString * language;
     @property (nonatomic, retain) NSString * monthString;
     @property (nonatomic, retain) NSString * monthAndYearString;
     @property (nonatomic, retain) NSNumber * pitch;
     @property (nonatomic, retain) NSNumber * rate;
     @property (nonatomic, retain) NSNumber * isNewDocument;
     @property (nonatomic, retain) NSString * documentTitle;
     @property (nonatomic, retain) NSNumber * volume;
     @property (nonatomic, retain) NSString * yearString;
     @property (nonatomic, retain) NSString * document;
     */
}


@end
