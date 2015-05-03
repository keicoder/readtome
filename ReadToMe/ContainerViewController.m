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


@interface ContainerViewController () <AVSpeechSynthesizerDelegate, NSFetchedResultsControllerDelegate, UITextViewDelegate>

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
	BOOL _equalizerViewExpanded;
    NSRange _selectedRange;
    NSString *_lastViewedDocument;
    NSString *_subString;
    float _speechLocationPercentValueInWholeTexts;
}


#pragma mark - View life cycle

- (void)viewDidLoad
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
	[super viewDidLoad];
	
    [self setInitialData];
	[self configureUI];
    [self configureSliderUI];
    [self stopSpeaking];
    [self checkHasLaunchedOnce];
    [self typeSelecting];
    [self addObserver];
}


- (void)viewWillAppear:(BOOL)animated
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
	[super viewWillAppear:animated];
    
    [self setPasteBoardString];
    [self retrieveSpeechAttributes];
    [self lastViewedDocument];
    [self checkToPasteText];
}


- (void)viewWillDisappear:(BOOL)animated
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
	[super viewWillDisappear:YES];
	//_fetchedResultsController = nil;
}


#pragma mark - Set Initial Data

- (void)setInitialData
{
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


- (NSString *)setPasteBoardString
{
    if (!self.pasteBoard.string) {
        
        self.pasteBoard.string = @"Copy whatever you want to read, ReadToMe will read aloud for you.\n\nYou can play, pause or replay whenever you want.\n\nEnjoy reading!";
    }
    
    return self.pasteBoard.string;
}


#pragma mark - Paste Text

- (void)checkToPasteText
{
    if (!self.sharedDefaults) {
        self.sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:kSharedDefaultsSuiteName];
    }
    
    self.isSharedDocument = [self.sharedDefaults boolForKey:kIsSharedDocument];
    self.isTodayDocument = [self.sharedDefaults boolForKey:kIsTodayDocument];
    self.isSelectedDocumentFromListView = [self.sharedDefaults boolForKey:kIsSelectedDocumentFromListView];
    self.isNewDocument = [self.sharedDefaults boolForKey:kIsNewDocument];
    self.isSavedDocument = [self.sharedDefaults boolForKey:kIsSavedDocument];
    
    [self showLog];
    
    
    if (self.isSharedDocument) {
        
        NSLog(@"viewWillAppear > checkToPasteText > isSharedDocument > self.textView.text = kSharedDocument");
        
        self.textView.text = [self.sharedDefaults objectForKey:kSharedDocument];
        [self saveToSharedDefaultsDocumentIsNew];
        
    } else if (self.isTodayDocument) {
        
        NSLog(@"viewWillAppear > checkToPasteText > isTodayDocument > self.textView.text = kTodayDocument");
        
        self.textView.text = [self.sharedDefaults objectForKey:kTodayDocument];
        [self saveToSharedDefaultsDocumentIsNew];
        
    } else if (self.isSelectedDocumentFromListView) {
        
        NSLog(@"viewWillAppear > checkToPasteText > isSelectedDocumentFromListView > handle rest of logic by didReceivedSelectDocumentsForSpeechNotification");
        
        [self saveToSharedDefaultsDocumentDidAlreadySave];
        
    } else {
        
        NSLog(@"viewWillAppear > checkToPasteText > !isSharedDocument, !isTodayDocument, !isSelectedDocumentFromListView > self.textView.text = self.pasteBoard.string");
        
        self.textView.text = self.pasteBoard.string;
        [self saveToSharedDefaultsDocumentIsNew];
    }
    
    [self showLog];
}


#pragma mark - Utterance

- (void)setupUtterance
{
    if (self.isNewDocument) {
        
        self.utterance = [AVSpeechUtterance speechUtteranceWithString:self.textView.text];
        self.utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:self.language];
        self.utterance.volume = self.volume;
        self.utterance.pitchMultiplier = self.pitch;
        self.utterance.rate = self.rate;
        
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


#pragma mark Speech State

- (void)startSpeaking
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
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


#pragma mark - Other Buttons Action Methods

- (IBAction)listButtonTapped:(id)sender
{
    [self pauseSpeaking];
    
	if (_equalizerViewExpanded == YES) {
        
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
        
        [self changeSelectionButtonColorForTurnOnAndOff:NO];
        
        
    } else {
        
        [self changeSelectionButtonColorForTurnOnAndOff:YES];
        [self performSelector:@selector(selectWord) withObject:nil afterDelay:0.4];
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
        self.language = controller.currentLanguage;
    }];
}


- (IBAction)equalizerButtonTappped:(id)sender
{
    [self pauseSpeaking];
    
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


- (IBAction)keyboardDownButtonTapped:(id)sender
{
    [self.textView resignFirstResponder];
}


#pragma mark - Save Current Documents For Speech

#pragma mark Save Document

- (IBAction)saveCurrentDocument:(id)sender
{
    [self.textView resignFirstResponder];
    [self pauseSpeaking];
    
    NSLog (@"self.currentDocument.savedDocument: %@\n", self.currentDocument.savedDocument);
    
    if (self.isNewDocument == YES) {
        
        if ([self.textView.text isEqualToString:_lastViewedDocument]) {
            
            NSLog(@"Nothing to Save");
            [self adjustSlideViewHeightWithTitle:@"Nothing to Save" height:kSlideViewHeight color:[UIColor colorWithRed:0.984 green:0.447 blue:0 alpha:1] withSender:self.archiveButton];
            
        } else {
            
            if (self.managedObjectContext == nil) {
                self.managedObjectContext = [DataManager sharedDataManager].managedObjectContext;
            }
            
            self.currentDocument = [NSEntityDescription insertNewObjectForEntityForName:@"DocumentsForSpeech" inManagedObjectContext:self.managedObjectContext];
            
            [self updateDocument];
            
            [self.managedObjectContext performBlock:^{
                NSError *error = nil;
                if ([self.managedObjectContext save:&error]) {
                    
                    NSLog (@"Save to coredata succeed");
                    
                    [self adjustSlideViewHeightWithTitle:@"Saved" height:kSlideViewHeight color:[UIColor colorWithRed:0.988 green:0.71 blue:0 alpha:1] withSender:self.archiveButton];
                    
                    [self saveToSharedDefaultsDocumentDidAlreadySave];
                    [self saveToDefaultsLastViewedDocument];
                    [self executePerformFetch];
                    [self showLog];
                    
                    NSLog (@"[self.isNewDocument > Saved > self.fetchedResultsController fetchedObjects].count: %lu\n", (unsigned long)[self.fetchedResultsController fetchedObjects].count);
                    
                    if ([self.fetchedResultsController fetchedObjects].count > 0) {
                        
                        DocumentsForSpeech *savedDocument = [self.fetchedResultsController fetchedObjects][0];
                        self.currentDocument = savedDocument;
                    }
                    
                } else {
                    
                    NSLog(@"Error saving to coredata: %@", error);
                }
            }];
        }
        
    } else { //isSavedDocument
        
        if ([self.textView.text isEqualToString:_lastViewedDocument]) {
            
            NSLog(@"Nothing to Save");
            
            [self adjustSlideViewHeightWithTitle:@"Nothing to Save" height:kSlideViewHeight color:[UIColor colorWithRed:0.984 green:0.447 blue:0 alpha:1] withSender:self.archiveButton];
            
        } else {
            
            [self updateDocument];
            
            [self.managedObjectContext performBlock:^{
                NSError *error = nil;
                if ([self.managedObjectContext save:&error]) {
                    
                    NSLog (@"Save updated document to coredata succeed");
                    
                    [self adjustSlideViewHeightWithTitle:@"Saved" height:kSlideViewHeight color:[UIColor colorWithRed:0.988 green:0.71 blue:0 alpha:1] withSender:self.archiveButton];
                    
                    _lastViewedDocument = self.textView.text;
                    [self.defaults setObject:_lastViewedDocument forKey:kLastViewedDocument];
                    [self.defaults synchronize];
                    NSLog(@"_lastViewedDocument texts updated");
                    
                    [self executePerformFetch];
                    [self showLog];
                    
                } else {
                    
                    NSLog(@"Error updating to coredata: %@", error);
                }
            }];
        }
    }
}


- (void)updateDocument
{
    self.currentDocument.language = self.language;
    self.currentDocument.volume = [NSNumber numberWithFloat:self.volume];;
    self.currentDocument.pitch = [NSNumber numberWithFloat:self.pitch];
    self.currentDocument.rate = [NSNumber numberWithFloat:self.rate];
    
    if (self.currentDocument.uniqueIdString == nil) {
        NSString *uniqueIDString = [NSString stringWithFormat:@"%li", (long)(arc4random() % 999999999999999999)];
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
        
		NSLog (@"[executePerformFetch > self.fetchedResultsController fetchedObjects].count: %lu\n", (unsigned long)[self.fetchedResultsController fetchedObjects].count);
	}
}


#pragma mark - Select Word

- (void)selectWord
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    if (_isTypeSelecting == YES) {
        
        if (self.synthesizer.continueSpeaking == YES) {
            [self retrieveSelectedRangeValue];
        }
        
        [self.textView select:self];
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


#pragma mark - State Restoration

- (void)retrieveSpeechAttributes
{
    if (self.isNewDocument == YES) {
        
        self.language = [self.defaults objectForKey:kLanguage];
        
        self.volume = [self.defaults floatForKey:kVolumeValue];
        self.pitch = [self.defaults floatForKey:kPitchValue];
        self.rate = [self.defaults floatForKey:kRateValue];
        
        self.volumeSlider.value = self.volume;
        self.pitchSlider.value = self.pitch;
        self.rateSlider.value = self.rate;
        
    } else {
        
        NSLog(@"Saved Document > use Speech Attributes in the self.currentDocument");
        
    }
    
}


- (BOOL)typeSelecting
{
    if (!_isTypeSelecting) {
        
        _isTypeSelecting = YES;
        
    } else {
        
        _isTypeSelecting = [self.defaults boolForKey:kTypeSelecting];
    }
    
    
    if (_isTypeSelecting == YES) {
        
        [self changeSelectionButtonColorForTurnOnAndOff:YES];
        
    } else {
        
        [self changeSelectionButtonColorForTurnOnAndOff:NO];
    }
    
    return _isTypeSelecting;
}


- (NSString *)lastViewedDocument
{
    if (self.isNewDocument == YES) {
        _lastViewedDocument = [self.defaults objectForKey:kLastViewedDocument];
        NSLog (@"viewWillAppear > lastViewedDocument > self.isSavedDocument == NO > _lastViewedDocument = [self.defaults objectForKey:kLastViewedDocument]");
        return _lastViewedDocument;
    } else {
        NSLog (@"viewWillAppear > lastViewedDocument > self.isSavedDocument == YES > _lastViewedDocument = _lastViewedDocument");
        return _lastViewedDocument;
    }
}


#pragma mark - Slider value changed

- (IBAction)sliderValueChanged:(UISlider *)sender
{
    if (sender == self.progressSlider) {
        
        self.progressSlider.value = _speechLocationPercentValueInWholeTexts;
        
    } else if (sender == self.volumeSlider) {
        
        [self stopSpeaking];
        
        self.volume = sender.value;
        [self.defaults setFloat:sender.value forKey:kVolumeValue];
        [self.defaults synchronize];
        
    } else if (sender == self.pitchSlider) {
        
        [self stopSpeaking];
        
        self.pitch = sender.value;
        [self.defaults setFloat:sender.value forKey:kPitchValue];
        [self.defaults synchronize];
        
    } else if (sender == self.rateSlider) {
        
        [self stopSpeaking];
        
        self.rate = sender.value;
        [self.defaults setFloat:self.rateSlider.value forKey:kRateValue];
        [self.defaults synchronize];
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
    
    [self adjustEqualizerViewHeight:keyboardHeight - bottomViewHeight];
    
    CGFloat duration = 0.35f;
    [UIView animateWithDuration:duration animations:^{
        self.keyboardDownButton.alpha = 1.0;
    }completion:^(BOOL finished) { }];
}


- (void)keyboardWillHide:(NSNotification*)notification
{
    [self adjustEqualizerViewHeight:0.0];
    
    CGFloat duration = 0.35f;
    [UIView animateWithDuration:duration animations:^{
        self.keyboardDownButton.alpha = 0.0;
    }completion:^(BOOL finished) { }];
    
    [self pauseSpeaking];
}


#pragma mark Application's State

- (void)applicationWillResignActive
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
}


- (void)applicationDidBecomeActive
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
}


- (void)applicationDidEnterBackground
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
}


- (void)applicationWillEnterForeground
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    [self checkToPasteText];
}


- (void)applicationDidReceiveMemoryWarning
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
}


- (void)applicationWillTerminate
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
}


#pragma mark - UITextView delegate method (optional)

- (void)textViewDidChange:(UITextView *)textView
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    if (![_lastViewedDocument isEqualToString:self.textView.text]) {
        
        NSLog(@"TextView texts are changed");
        [self stopSpeaking];
        
    } else {
        
        NSLog(@"Nothing Changed");
    }
}


#pragma mark - Change Selection Button Color For TurnOn or TurnOff

- (void)changeSelectionButtonColorForTurnOnAndOff:(BOOL)didTurnOn
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


#pragma mark - Save To SharedDefaults Document Is New or Did Already Save

- (void)saveToSharedDefaultsDocumentIsNew
{
    [self.sharedDefaults setBool:NO forKey:kIsSharedDocument];
    [self.sharedDefaults setBool:NO forKey:kIsTodayDocument];
    [self.sharedDefaults setBool:NO forKey:kIsSelectedDocumentFromListView];
    [self.sharedDefaults setBool:YES forKey:kIsNewDocument];
    [self.sharedDefaults setBool:NO forKey:kIsSavedDocument];
    [self.sharedDefaults synchronize];
    self.isSharedDocument = NO;
    self.isTodayDocument = NO;
    self.isSelectedDocumentFromListView = NO;
    self.isNewDocument = YES;
    self.isSavedDocument = NO;
}


- (void)saveToSharedDefaultsDocumentDidAlreadySave
{
    [self.sharedDefaults setBool:NO forKey:kIsSharedDocument];
    [self.sharedDefaults setBool:NO forKey:kIsTodayDocument];
    [self.sharedDefaults setBool:NO forKey:kIsSelectedDocumentFromListView];
    [self.sharedDefaults setBool:NO forKey:kIsNewDocument];
    [self.sharedDefaults setBool:YES forKey:kIsSavedDocument];
    [self.sharedDefaults synchronize];
    self.isSharedDocument = NO;
    self.isTodayDocument = NO;
    self.isSelectedDocumentFromListView = NO;
    self.isNewDocument = NO;
    self.isSavedDocument = YES;
}


- (void)saveToDefaultsLastViewedDocument
{
    _lastViewedDocument = self.textView.text;
    [self.defaults setObject:_lastViewedDocument forKey:kLastViewedDocument];
    [self.defaults synchronize];
    NSLog(@"_lastViewedDocument texts updated");
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
    NSLog (@"self.isSavedDocument: %@\n", self.isSavedDocument ? @"YES" : @"NO");
    
//    NSLog (@"[self.currentDocument.volume floatValue]: %f\n", [self.currentDocument.volume floatValue]);
//    NSLog (@"[self.currentDocument.pitch floatValue]: %f\n", [self.currentDocument.pitch floatValue]);
//    NSLog (@"[self.currentDocument.rate floatValue]: %f\n", [self.currentDocument.rate floatValue]);
//    
//    NSLog (@"self.volumeSlider.value: %f\n", self.volumeSlider.value);
//    NSLog (@"self.pitchSlider.value: %f\n", self.pitchSlider.value);
//    NSLog (@"self.rateSlider.value: %f\n", self.rateSlider.value);
//    
//    NSLog (@"self.volume: %f\n", self.volume);
//    NSLog (@"self.pitch: %f\n", self.pitch);
//    NSLog (@"self.rate: %f\n", self.rate);
    
//    NSLog (@"self.textView.text: %@\n", self.textView.text);
//    NSLog (@"_lastViewedDocument: %@\n", _lastViewedDocument);
}


@end
