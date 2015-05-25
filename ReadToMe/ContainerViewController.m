//
//  ViewController.m
//  ReadToMe
//
//  Created by jun on 3/23/15.
//  Copyright (c) 2015 keicoder. All rights reserved.
//

#define debug                       1


#define kSharedDefaultsSuiteName                @"group.com.keicoder.demo.readtome"
#define kSharedDocument                         @"kSharedDocument"
#define kIsSharedDocument                       @"kIsSharedDocument"
#define kTodayDocument                          @"kTodayDocument"
#define kIsTodayDocument                        @"kIsTodayDocument"
#define kIsSelectedDocumentFromListView         @"kIsSelectedDocumentFromListView"
#define kIsNewDocument                          @"Already Saved Document"
#define kIsSavedDocument                        @"kIsSavedDocument"

#define kSelectedRangeLocation                  @"kSelectedRangeLocation"
#define kSelectedRangeLength                    @"kSelectedRangeLength"

#define kSlideViewHeight                        40.0

#define kPause                                  [UIImage imageNamed:@"pause"]
#define kPlay                                   [UIImage imageNamed:@"play"]

#define kHasLaunchedOnce                        @"kHasLaunchedOnce"
#define kTypeSelecting                          @"kTypeSelecting"
#define kLanguage                               @"kLanguage"
#define kVolumeValue                            @"kVolumeValue"
#define kPitchValue                             @"kPitchValue"
#define kRateValue                              @"kRateValue"

#define kLastViewedDocument                     @"kLastViewedDocument"
#define kSavedDocument                          @"kSavedDocument"

#define kNothingToSaveColor                     [UIColor colorWithRed:0.984 green:0.447 blue:0 alpha:1]

#define kBlankText  @""
#define kSelectedDocumentIndex                  @"kSelectedDocumentIndex"
#define kSelectedDocumentIndexPath              @"kSelectedDocumentIndexPath"


@import AVFoundation;
#import <CoreData/CoreData.h>
#import "ContainerViewController.h"
#import "DocumentsForSpeech.h"
#import "DataManager.h"
#import "KeiTextView.h"
#import "UIImage+ChangeColor.h"
#import "SettingsViewController.h"
#import "LanguagePickerViewController.h"
#import "ListViewController.h"
#import "NSUserDefaults+Extension.h"
#import "ListTableViewCell.h"


@interface ContainerViewController () <AVSpeechSynthesizerDelegate, NSFetchedResultsControllerDelegate, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSMutableArray *fetchedDocuments;
@property (nonatomic, strong) NSDateFormatter *formatter;

@property (nonatomic, strong) NSUserDefaults *sharedDefaults;
@property (nonatomic, strong) NSUserDefaults *defaults;

@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;
@property (nonatomic, strong) AVSpeechUtterance *utterance;
@property (nonatomic, strong) UIPasteboard *pasteBoard;

@property (nonatomic, assign) float volume;
@property (nonatomic, assign) float pitch;
@property (nonatomic, assign) float rate;

@property (strong, nonatomic) NSDictionary *paragraphAttributes;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *menuViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *saveAlertViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardAccessoryViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *progressInfoViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *equalizerViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewHeightConstraint;
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
    NSRange _selectedRange;
    NSString *_lastViewedDocument;
    NSString *_subString;
    float _speechLocationPercentValueInWholeTexts;
    BOOL _floatingViewExpanded;
}


#pragma mark - View life cycle

- (void)viewDidLoad
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
	[super viewDidLoad];
    
	[self configureUI];
    [self setInitialObjectsForSpeech];
    [self stopSpeaking];
    [self checkHasLaunchedOnce];
    [self addObserver];
    [self addTapGesture];
    [self addSwipeGesture];
    
    _floatingViewExpanded = YES;
    self.textView.editable = NO;
    _isTypeSelecting = [self.defaults boolForKey:kTypeSelecting];
}


- (void)viewWillAppear:(BOOL)animated
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
	[super viewWillAppear:animated];
    
    [self retrieveDataForSpeech];
    [self executePerformFetch];
    [self.tableView reloadData];
    NSLog(@"viewWillAppear > [self.tableView reloadData]");
}


-(void)viewDidAppear:(BOOL)animated
{
    if (debug==1) {NSLog(@"%@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    [super viewDidAppear:animated];
    [self addShadowEffectToTheView:self.floatingView withOpacity:0.5 andRadius:5.0 afterDelay:0.0 andDuration:0.25];
}


- (void)viewWillDisappear:(BOOL)animated
{
    if (debug==1) {NSLog(@"%@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    [super viewWillDisappear:animated];
    [self checkWhetherSavingDocumentOrNot];
}


#pragma mark - Set Initial Data

- (void)setInitialObjectsForSpeech
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
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
    
    self.textView.delegate = self;
    
    [self hideSlideViewAndEqualizerViewWithNoAnimation];
}


#pragma mark - Speech Synthesizer

#pragma mark Utterance

- (void)setupUtterance
{
    if (self.isNewDocument) {
        
        self.utterance = [AVSpeechUtterance speechUtteranceWithString:self.textView.text];
        self.utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:self.language];
        self.utterance.volume = self.volumeSlider.value;
        self.utterance.pitchMultiplier = self.pitchSlider.value;
        self.utterance.rate = self.rateSlider.value;
        
    } else {
        
        self.utterance = [AVSpeechUtterance speechUtteranceWithString:self.textView.text];
        self.utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:self.currentDocument.language];
        self.utterance.volume = [self.currentDocument.volume floatValue];
        self.utterance.pitchMultiplier = [self.currentDocument.pitch floatValue];
        self.utterance.rate = [self.currentDocument.rate floatValue];
    }
    
    self.utterance.preUtteranceDelay = 0.3f;
    self.utterance.postUtteranceDelay = 0.3f;
}


#pragma mark Speech State

- (void)startSpeaking
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    [self stopSpeaking];
    [self setupUtterance];
    
    if (!self.synthesizer) {
        self.synthesizer = [[AVSpeechSynthesizer alloc]init];
        self.synthesizer.delegate = self;
    }
    
    self.textView.editable = NO;
    [self.textView resignFirstResponder];
    
    [self.synthesizer speakUtterance:self.utterance];
    [self.playPauseButton setImage:kPause forState:UIControlStateNormal];
    _paused = NO;
    
    CGFloat duration = 0.25f;
    [UIView animateWithDuration:duration animations:^{
        self.resetButton.alpha = 1.0;
    }completion:^(BOOL finished) { }];
}


- (void)pauseSpeaking
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    [self saveSelectedRangeValue];
    
    [self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    [self.playPauseButton setImage:kPlay forState:UIControlStateNormal];
    _paused = YES;
    
    CGFloat duration = 0.25f;
    [UIView animateWithDuration:duration animations:^{
        self.resetButton.alpha = 0.0;
    }completion:^(BOOL finished) { }];
}


- (void)continueSpeaking
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    self.textView.editable = NO;
    [self.textView resignFirstResponder];
    
    [self.synthesizer continueSpeaking];
    [self.playPauseButton setImage:kPause forState:UIControlStateNormal];
    _paused = NO;
    
    CGFloat duration = 0.25f;
    [UIView animateWithDuration:duration animations:^{
        self.resetButton.alpha = 1.0;
    }completion:^(BOOL finished) { }];
}


- (void)stopSpeaking
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    self.textView.editable = YES;
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
    [self setupUtterance];
    
    if (!self.synthesizer) {
        self.synthesizer = [[AVSpeechSynthesizer alloc]init];
        self.synthesizer.delegate = self;
    }
    
    if (_paused == YES) {
        
        [self continueSpeaking];
        
    } else {
        
        [self pauseSpeaking];
    }
    
    if (self.synthesizer.isSpeaking == NO) {
        
        [self startSpeaking];
    }
    
    if (_isTypeSelecting == YES) {
        
        [self selectWord];
    }
    
    if (_paused == YES) {
        
        self.textView.editable = YES;
        [self.textView resignFirstResponder];
    }
}


#pragma mark Other Buttons Action Methods

- (IBAction)listButtonTapped:(id)sender
{
    if (debug==1) {NSLog(@"%@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    _floatingViewExpanded = !_floatingViewExpanded;
    
    CGFloat duration = 0.25f;
    
    if (_floatingViewExpanded) {
        
        [self.textView resignFirstResponder];
        
        CGFloat floatingViewWidth = CGRectGetWidth(self.view.bounds) * 0.7;
        self.floatingViewWidthConstraint.constant = floatingViewWidth;
        
        [UIView animateWithDuration:duration animations:^{
            self.addButton.alpha = 1.0;
            self.closeButton.alpha = 1.0;
            [self.view layoutIfNeeded];
            
        }completion:^(BOOL finished) {
            CGFloat floatingBackgroundViewWidth = CGRectGetWidth(self.view.bounds);
            self.floatingBackgroundViewWidthConstraint.constant = floatingBackgroundViewWidth;
            
            [self addShadowEffectToTheView:self.floatingView withOpacity:0.5 andRadius:5.0 afterDelay:0.0 andDuration:0.25];
        }];
        
        [self checkWhetherSavingDocumentOrNot];
        [self executePerformFetch];
        [self.tableView reloadData];
        NSLog(@"_floatingViewExpanded > [self.tableView reloadData]");
        
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


//- (IBAction)listButtonTapped:(id)sender
//{
//    [self pauseSpeaking];
//    
//	if (_equalizerViewExpanded == YES) {
//        
//        [self adjustEqualizerViewHeight:0.0];
//		[self performSelector:@selector(showListView:) withObject:nil afterDelay:0.35];
//	} else {
//		[self performSelector:@selector(showListView:) withObject:nil afterDelay:0.0];
//	}
//}


//- (void)showListView:(id)sender
//{
//	ListViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"ListViewController"];
//	[self presentViewController:controller animated:YES completion:^{ }];
//}


#pragma mark 생성 버튼

- (IBAction)addButtonTapped:(id)sender
{
    if (debug==1) {NSLog(@"%@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    self.textView.editable = YES;
    
    if (_floatingViewExpanded) {
        [self listButtonTapped:self];
    }
    
    self.currentDocument = [NSEntityDescription insertNewObjectForEntityForName:@"DocumentsForSpeech" inManagedObjectContext:[DataManager sharedDataManager].managedObjectContext];
    
    self.currentDocument.isNewDocument = [NSNumber numberWithBool:YES];
    self.currentDocument.document = kBlankText;
    self.textView.text = self.currentDocument.document;
    _lastViewedDocument = self.currentDocument.document;
    
    [self.textView becomeFirstResponder];
}


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
        [self changeSelectionButtonColor:NO];
        
    } else {
        [self changeSelectionButtonColor:YES];
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
	[self presentViewController:controller animated:YES completion:^{
        if (self.isNewDocument == YES) {
            NSLog(@"showLanguagePickerView > isNewDocument > controller.currentLanguage = self.language");
            controller.currentLanguage = self.language;
        } else {
            NSLog(@"showLanguagePickerView > isSavedDocument > controller.currentLanguage = self.currentDocument.language");
            controller.currentLanguage = self.currentDocument.language;
        }
    }];
}


- (IBAction)equalizerButtonTappped:(id)sender
{
    //[self pauseSpeaking];
    
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
    while ((responder = [responder nextResponder]) != nil)
    {
        NSLog(@"responder = %@", responder);
        if([responder respondsToSelector:@selector(openURL:)] == YES)
        {
            [responder performSelector:@selector(openURL:) withObject:[NSURL URLWithString:@"https://itunes.apple.com/us/app/talk-to-me-world/id985869735?l=ko&ls=1&mt=8"]];
        }
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
    NSRange selectedRange = self.textView.selectedRange;
    
    if (![self.textView hasText])
    {
        [self.textView select:self];
    }
    else if ([self.textView hasText] && selectedRange.length == 0)
    {
        [self.textView select:self];
    }
    else if ([self.textView hasText] && selectedRange.length > 0)
    {
        selectedRange.location = selectedRange.location + selectedRange.length;
        selectedRange.length = 0;
        self.textView.selectedRange = selectedRange;
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
    }
    else {
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


#pragma mark - Check if there are new clipboard texts

- (void)checkIfThereAreNewClipboardTexts
{
    if (debug==1) {NSLog(@"%@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    if (![self.pasteBoard.string isEqualToString:_lastViewedDocument]) {
        //Arert View
        NSLog(@"checkIfThereAreNewClipboardTexts > Found new pasteboard string > Arert view displaying");
    }
}


#pragma mark - State Restoration

- (void)retrieveDataForSpeech
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    self.language = [self.defaults objectForKey:kLanguage];
    self.volume = [self.defaults floatForKey:kVolumeValue];
    self.pitch = [self.defaults floatForKey:kPitchValue];
    self.rate = [self.defaults floatForKey:kRateValue];
    
    self.volumeSlider.value = self.volume;
    self.pitchSlider.value = self.pitch;
    self.rateSlider.value = self.rate;
    
    _isTypeSelecting = [self.defaults boolForKey:kTypeSelecting];
    
    _lastViewedDocument = [self.defaults objectForKey:kLastViewedDocument];
}


#pragma mark - Save Data
#pragma mark Saving

- (void)checkWhetherSavingDocumentOrNot
{
    if (debug==1) {NSLog(@"%@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    if ([self.currentDocument.isNewDocument boolValue] == YES) {
        
        if ([_lastViewedDocument isEqualToString:self.textView.text]) {
            NSLog(@"It's new document but no texts, so nothing to save");
            [self adjustSlideViewHeightWithTitle:@"Nothing to Save" height:kSlideViewHeight color:kNothingToSaveColor withSender:self.archiveButton];
            
        } else {
            NSLog(@"It's new document and have texts, so save document");
            [self saveSpeechDocumentAndAttributes];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [self saveIndexPath:indexPath];
        }
        
    } else {
        
        if ([_lastViewedDocument isEqualToString:self.textView.text]) {
            NSLog(@"Can't find any changing in document, so nothing updated");
            [self adjustSlideViewHeightWithTitle:@"Nothing to Save" height:kSlideViewHeight color:kNothingToSaveColor withSender:self.archiveButton];
            
        } else {
            NSLog(@"Document updated, so save document");
            [self saveSpeechDocumentAndAttributes];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [self saveIndexPath:indexPath];
        }
    }
}


- (void)saveSpeechDocumentAndAttributes
{
    if (debug==1) {NSLog(@"%@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    if ([self.textView isFirstResponder]) {
        [self.textView resignFirstResponder];
    }
    [self pauseSpeaking];
    [self updateSpeechDocumentAndAttributes]; //다큐먼트 업데이트
    
    //Save
    [[DataManager sharedDataManager].managedObjectContext performBlock:^{
        NSError *error = nil;
        if ([[DataManager sharedDataManager].managedObjectContext save:&error]) {
            NSLog(@"Saved");
        } else {
            NSLog(@"Error saving context: %@", error);
        }
    }];
}


- (void)updateSpeechDocumentAndAttributes
{
    //Speech Attributes
    self.currentDocument.language = self.language;
    self.currentDocument.volume = [NSNumber numberWithFloat:self.volume];;
    self.currentDocument.pitch = [NSNumber numberWithFloat:self.pitch];
    self.currentDocument.rate = [NSNumber numberWithFloat:self.rate];
    
    //Document Attributes
    if (self.currentDocument.isNewDocument) {
        self.currentDocument.isNewDocument = [NSNumber numberWithBool:NO];
    }
    self.currentDocument.document = self.textView.text;
    
    _lastViewedDocument = self.currentDocument.document;
    [self.defaults setObject:_lastViewedDocument forKey:kLastViewedDocument];
    [self.defaults synchronize];
    NSLog(@"_lastViewedDocument texts updated");
    
    
    NSString *firstLineForTitle = [self retrieveFirstLineOfStringForTitle:self.textView.text];
    self.currentDocument.documentTitle = firstLineForTitle;
    
    //Date Attributes
    NSDate *now = [NSDate date];
    
    if (self.currentDocument.createdDate == nil) {
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
    if (debug==1) {NSLog(@"%@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
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
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
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

- (IBAction)sliderValueChanged:(UISlider *)sender
{
    if (sender == self.progressSlider) {
        
        self.progressSlider.value = _speechLocationPercentValueInWholeTexts;
        
    } else if (sender == self.volumeSlider) {
        
        [self stopSpeaking];
        
        self.volume = self.volumeSlider.value;
        self.utterance.volume = self.volumeSlider.value;
        [self.defaults setFloat:sender.value forKey:kVolumeValue];
        [self.defaults synchronize];
        
    } else if (sender == self.pitchSlider) {
        
        [self stopSpeaking];
        
        self.pitch = sender.value;
        [self.defaults setFloat:self.pitchSlider.value forKey:kPitchValue];
        [self.defaults synchronize];
        
    } else if (sender == self.rateSlider) {
        
        [self stopSpeaking];
        
        self.rate = sender.value;
        [self.defaults setFloat:self.rateSlider.value forKey:kRateValue];
        [self.defaults synchronize];
    }
    
    [self showLog];
}


#pragma mark - Add Observer

- (void)addObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    //Picked Language
    [center addObserver:self selector:@selector(didPickedLanguageNotification:) name:@"DidPickedLanguageNotification" object:nil];
    
    //Select Document
    [center addObserver:self selector:@selector(didReceivedSelectDocumentsForSpeechNotification:) name:@"DidSelectDocumentsForSpeechNotification" object:nil];
    
    //Slider Value
    [center addObserver:self selector:@selector(didChangeSliderValue:) name:@"DidChangeSliderValueNotification" object:nil];
    
    //Keyboard
    [center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:self.view.window];
    [center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:self.view.window];
    
    //Device Orientation
    [center addObserver:self selector:@selector(deviceOrientationChanged:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    
    //Application Status
    [center addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [center addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [center addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [center addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [center addObserver:self selector:@selector(applicationDidReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [center addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
}


#pragma mark Picked Language

- (void)didPickedLanguageNotification:(NSNotification *)notification
{
    NSLog(@"DidPickedLanguageNotification Recieved");
    
    [self stopSpeaking];
    
    if (self.defaults) {
        self.defaults = [NSUserDefaults standardUserDefaults];
    }
    
    self.language = [self.defaults objectForKey:kLanguage];
    [self setupUtterance];
}


#pragma mark Select Document

- (void)didReceivedSelectDocumentsForSpeechNotification:(NSNotification *)notification
{
    NSLog(@"DidSelectDocumentsForSpeechNotification Recieved");
    
    [self stopSpeaking];
    
    NSDictionary *userInfo = notification.userInfo;
    DocumentsForSpeech *receivedDocument = [userInfo objectForKey:@"DidSelectDocumentsForSpeechNotificationKey"];
    
    self.currentDocument = receivedDocument;
    
    self.pasteBoard.string = self.currentDocument.document;
    _lastViewedDocument = self.currentDocument.document;
    self.textView.text = self.currentDocument.document;
    
    self.textView.text = self.currentDocument.document;
    self.language = self.currentDocument.language;
    
    self.volume = [self.currentDocument.volume floatValue];
    self.pitch = [self.currentDocument.pitch floatValue];
    self.rate = [self.currentDocument.rate floatValue];
    
    //Slider Value
    self.volumeSlider.value = self.volume;
    self.pitchSlider.value = self.pitch;
    self.rateSlider.value = self.rate;
    
    [self showLog];
}


#pragma mark Slider Value Changed

- (void)didChangeSliderValue:(NSNotification *)notification
{
    if ([notification.name isEqualToString:@"DidChangeSliderValueNotification"]) {
        NSLog(@"DidChangeSliderValue Notification Received");
    }
}

#pragma mark Keyboard Handling

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGRect keyboardFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardHeight = CGRectGetHeight(keyboardFrame);
    CGFloat bottomViewHeight = CGRectGetHeight(self.bottomView.frame);
    CGFloat progressViewHeight = CGRectGetHeight(self.progressView.frame);
    
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
    if (debug==1) {NSLog(@"%@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
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
            
            [self addShadowEffectToTheView:self.floatingView withOpacity:0.5 andRadius:5.0 afterDelay:0.0 andDuration:0.0];
        }];
    }
}


#pragma mark UITextView delegate method

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    CGFloat duration = 0.25f;
    [UIView animateWithDuration:duration animations:^{
        self.playPauseButton.alpha = 0.0;
    }completion:^(BOOL finished) { }];
    
    _lastViewedDocument = self.textView.text;
}


- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
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
        self.pasteBoard.string = self.textView.text;
        
    } else {
        NSLog(@"Nothing Changed");
    }
}


#pragma mark Application's State

- (void)applicationWillResignActive
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
}


- (void)applicationDidEnterBackground
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    NSLog(@"applicationDidEnterBackground > checkWhetherSavingDocumentOrNot");
    [self checkWhetherSavingDocumentOrNot];
}


- (void)applicationWillEnterForeground
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
}


- (void)applicationDidBecomeActive
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    [self checkIfThereAreNewClipboardTexts];
}


- (void)applicationDidReceiveMemoryWarning
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    NSLog(@"applicationDidReceiveMemoryWarning > checkWhetherSavingDocumentOrNot");
    [self checkWhetherSavingDocumentOrNot];
}


- (void)applicationWillTerminate
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    NSLog(@"applicationWillTerminate > checkWhetherSavingDocumentOrNot");
    [self checkWhetherSavingDocumentOrNot];
}


#pragma mark - Change Selection Button Color For TurnOn or TurnOff

- (void)changeSelectionButtonColor:(BOOL)didTurnOn
{
    if (didTurnOn == YES) {
        
        _isTypeSelecting = YES;
        [self.defaults setBool:YES forKey:kTypeSelecting];
        [self.defaults synchronize];
        
        CGFloat duration = 0.35f;
        [UIView animateWithDuration:duration animations:^{
            
            UIImage *image = [UIImage imageForChangingColor:@"selection" color:[UIColor colorWithRed:0.988 green:0.71 blue:0 alpha:1]];
            [self.selectionButton setImage:image forState:UIControlStateNormal];
            
        }completion:^(BOOL finished) { }];
        
        [self adjustSlideViewHeightWithTitle:@"WORD SELECTING" height:kSlideViewHeight color:[UIColor colorWithRed:0 green:0.635 blue:0.259 alpha:1] withSender:self.selectionButton];
        
    } else {
        
        _isTypeSelecting = NO;
        [self.defaults setBool:NO forKey:kTypeSelecting];
        [self.defaults synchronize];
        
        CGFloat duration = 0.35f;
        [UIView animateWithDuration:duration animations:^{
            
            UIImage *image = [UIImage imageForChangingColor:@"selection" color:[UIColor whiteColor]];
            [self.selectionButton setImage:image forState:UIControlStateNormal];
            
        }completion:^(BOOL finished) { }];
        
        [self adjustSlideViewHeightWithTitle:@"NO WORD SELECTING" height:kSlideViewHeight color:[UIColor colorWithRed:0.984 green:0.4 blue:0.302 alpha:1] withSender:self.selectionButton];
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


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance
{
    NSLog(@"speechSynthesizer didStartSpeechUtterance");
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
    NSLog(@"speechSynthesizer didFinishSpeechUtterance");
    [self stopSpeaking];
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance *)utterance
{
    NSLog(@"speechSynthesizer didPauseSpeechUtterance");
    [self pauseSpeaking];
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didContinueSpeechUtterance:(AVSpeechUtterance *)utterance
{
    NSLog(@"speechSynthesizer didContinueSpeechUtterance");
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance
{
    NSLog(@"speechSynthesizer didCancelSpeechUtterance");
    [self stopSpeaking];
}


#pragma mark - Adjust SlideView height when user touches equivalent button

- (void)adjustSlideViewHeightWithTitle:(NSString *)string height:(float)height color:(UIColor *)color withSender:(UIButton *)button
{
    CGFloat duration = 0.3f;
    CGFloat delay = 0.0f;
    
    self.saveAlertViewHeightConstraint.constant = height;
    button.enabled = NO;
    self.saveAlertView.backgroundColor = color;
    
    [UIView animateWithDuration:duration delay:delay options: UIViewAnimationOptionCurveEaseInOut animations:^{
        
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
    [UIView animateWithDuration:duration delay:delay options: UIViewAnimationOptionCurveEaseInOut animations:^{
        
        [self.view layoutIfNeeded];
        
        if (height == 0) {
            
            _equalizerViewExpanded = NO;
            
            self.volumeLabel.alpha = 0.0;
            self.pitchLabel.alpha = 0.0;
            self.rateLabel.alpha = 0.0;
            self.volumeSlider.alpha = 0.0;
            self.pitchSlider.alpha = 0.0;
            self.rateSlider.alpha = 0.0;
            
        } else {
            
            _equalizerViewExpanded = YES;
            
            self.volumeLabel.alpha = 1.0;
            self.pitchLabel.alpha = 1.0;
            self.rateLabel.alpha = 1.0;
            self.volumeSlider.alpha = 1.0;
            self.pitchSlider.alpha = 1.0;
            self.rateSlider.alpha = 1.0;
        }
        
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
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
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


#pragma mark - Table View
#pragma mark Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSLog (@"numberOfSectionsInTableView: %lu\n", (unsigned long)[[self.fetchedResultsController sections] count]);
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
    if (debug==1) {NSLog(@"%@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    self.textView.editable = YES;
    
    self.currentDocument = (DocumentsForSpeech *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    NSLog (@"self.currentDocument: %@\n", self.currentDocument);
    
    self.textView.text = self.currentDocument.document;
    _lastViewedDocument = self.currentDocument.document;
    
    [self saveIndexPath:indexPath];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self listButtonTapped:self];
}


#pragma mark Editing

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        if (debug==1) {NSLog(@"%@ '%@'", self.class, NSStringFromSelector(_cmd));}
        
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


#pragma mark - Configure UI

- (void)configureUI
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    self.menuView.backgroundColor = [UIColor colorWithRed:0.294 green:0.463 blue:0.608 alpha:1];
    self.saveAlertView.backgroundColor = [UIColor colorWithRed:0.945 green:0.671 blue:0.686 alpha:1];
    self.bottomView.backgroundColor = [UIColor colorWithRed:0.157 green:0.29 blue:0.42 alpha:1];
    self.progressView.backgroundColor = [UIColor colorWithRed:0.294 green:0.463 blue:0.608 alpha:1];
    self.equalizerView.backgroundColor = [UIColor colorWithRed:0.294 green:0.463 blue:0.608 alpha:1];
    self.floatingView.backgroundColor = self.menuView.backgroundColor;
    self.tableView.backgroundColor = [UIColor whiteColor];
    
    //키보드 액세서리 뷰
    self.keyboardAccessoryView.backgroundColor = [UIColor colorWithRed:0.988 green:0.831 blue:0.345 alpha:1]; //[UIColor colorWithRed:0.71 green:0.714 blue:0.722 alpha:1];
    
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
    NSLog (@"\n");
    NSLog (@"self.isSharedDocument: %@\n", self.isSharedDocument ? @"YES" : @"NO");
    NSLog (@"self.isTodayDocument: %@\n", self.isTodayDocument ? @"YES" : @"NO");
    NSLog (@"self.isSelectedDocumentFromListView: %@\n", self.isSelectedDocumentFromListView ? @"YES" : @"NO");
    NSLog (@"self.isNewDocument: %@\n", self.isNewDocument ? @"YES" : @"NO");
    NSLog (@"_isTypeSelecting: %@\n", _isTypeSelecting ? @"YES" : @"NO");
    
    NSLog(@"\n");
    NSLog (@"self.currentDocument.language: %@\n", self.currentDocument.language);
    NSLog (@"[self.currentDocument.volume floatValue]: %f\n", [self.currentDocument.volume floatValue]);
    NSLog (@"[self.currentDocument.pitch floatValue]: %f\n", [self.currentDocument.pitch floatValue]);
    NSLog (@"[self.currentDocument.rate floatValue]: %f\n", [self.currentDocument.rate floatValue]);
    
    NSLog(@"\n");
    
    NSLog (@"self.volumeSlider.value: %f\n", self.volumeSlider.value);
    NSLog (@"self.pitchSlider.value: %f\n", self.pitchSlider.value);
    NSLog (@"self.rateSlider.value: %f\n", self.rateSlider.value);
    
    NSLog(@"\n");
    NSLog (@"self.language: %@\n", self.language);
    NSLog (@"self.volume: %f\n", self.volume);
    NSLog (@"self.pitch: %f\n", self.pitch);
    NSLog (@"self.rate: %f\n", self.rate);
    NSLog(@"\n");
}


@end
