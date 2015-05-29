//
//  LanguagePickerViewController.m
//  ReadToMe
//
//  Created by jun on 3/27/15.
//  Copyright (c) 2015 keicoder. All rights reserved.
//


#import "LanguagePickerViewController.h"
#import "ContainerViewController.h"


@interface LanguagePickerViewController () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSUserDefaults *defaults;

@property (weak, nonatomic) IBOutlet UIButton *returnButton;

@end


@implementation LanguagePickerViewController
{
	NSString *_languageCode;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self restoreUserPreferences];
	
    NSUInteger index = [self.languageCodes indexOfObject:self.currentDocument.language];
    if (index != NSNotFound)
    {
        [self.languagePickerView selectRow:index inComponent:0 animated:YES];
    }
	
	[self configureUI];
}


#pragma mark - State Restoration

- (void)restoreUserPreferences
{
    if (!self.defaults) {
        self.defaults = [NSUserDefaults standardUserDefaults];
    }
	
    NSLog (@"LanguagePickerViewController > restoreUserPreferences > self.currentDocument: %@\n", self.currentDocument);
    
    if (self.currentDocument.language == nil) {
        NSLog (@"LanguagePickerViewController > restoreUserPreferences > self.currentDocument.language == nil");
        NSLog (@"LanguagePickerViewController > restoreUserPreferences > self.currentDocument.language: %@\n", self.currentDocument.language);
        NSString *currentLanguageCode = [AVSpeechSynthesisVoice currentLanguageCode];
        NSDictionary *currentLanguage = @{ kLanguage:currentLanguageCode };
        [self.defaults registerDefaults:currentLanguage];
        self.currentDocument.language = [self.defaults stringForKey:kLanguage];
        NSLog (@"LanguagePickerViewController > restoreUserPreferences > self.currentDocument.language: %@\n", self.currentDocument.language);
        NSLog (@"LanguagePickerViewController > restoreUserPreferences > self.currentDocument: %@\n", self.currentDocument);
        
    } else {
        NSLog (@"LanguagePickerViewController > restoreUserPreferences > self.currentDocument.language == not nil");
        NSLog (@"LanguagePickerViewController > restoreUserPreferences > self.currentDocument.language: %@\n", self.currentDocument.language);
        NSLog (@"LanguagePickerViewController > restoreUserPreferences > self.currentDocument: %@\n", self.currentDocument);
    }
}


#pragma mark - Language Accessors

- (NSArray *)languageCodes
{
	if (!_languageCodes)
	{
		_languageCodes = [self.languageDictionary keysSortedByValueUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	}
	return _languageCodes;
}


- (NSDictionary *)languageDictionary
{
	if (!_languageDictionary)
	{
		NSArray *voices = [AVSpeechSynthesisVoice speechVoices];
		NSArray *languages = [voices valueForKey:@"language"];
		
		NSLocale *currentLocale = [NSLocale autoupdatingCurrentLocale];
		NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
		
        for (NSString *code in languages) {
			dictionary[code] = [currentLocale displayNameForKey:NSLocaleIdentifier value:code];
            //NSLog (@"dictionary[code]: %@\n", dictionary[code]);
		}
		_languageDictionary = dictionary;
	}
	return _languageDictionary;
}


#pragma mark - UIPickerViewDelegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return [self.languageCodes count];
}


- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.currentDocument.language = [self.languageCodes objectAtIndex:row];
    
    
    if (self.defaults == nil) {
        self.defaults = [NSUserDefaults standardUserDefaults];
    }
    [self.defaults setObject:self.currentDocument.language forKey:kLanguage];
    [self.defaults synchronize];
}


#pragma mark - UIPickerViewDataSource

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	NSString *languageCode = self.languageCodes[row];
	NSString *languageName = self.languageDictionary[languageCode];
	return languageName;
}


- (IBAction)returnButtonTapped:(id)sender
{
	NSLog(@"self.returnButton Tapped");
    //Post a notification when picked
    [[NSNotificationCenter defaultCenter] postNotificationName: @"DidPickedLanguageNotification" object:nil userInfo:nil];
    
    ContainerViewController *controller = (ContainerViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"ContainerViewController"];
    controller.currentDocument.language = self.currentDocument.language;
    controller.currentDocument = self.currentDocument;
	[self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - ConfigureUI

- (void)configureUI
{
	float cornerRadius = self.returnButton.bounds.size.height/2;
	self.returnButton.layer.cornerRadius = cornerRadius;
	self.returnButton.backgroundColor = [UIColor colorWithRed:0.906 green:0.298 blue:0.235 alpha:1];
}


@end
