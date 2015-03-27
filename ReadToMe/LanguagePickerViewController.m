//
//  LanguagePickerViewController.m
//  ReadToMe
//
//  Created by jun on 3/27/15.
//  Copyright (c) 2015 keicoder. All rights reserved.
//

#import "LanguagePickerViewController.h"
#import "UIImage+ChangeColor.h"


@interface LanguagePickerViewController () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet UIButton *returnButton;

@end


@implementation LanguagePickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self languageDictionary];
	[self languageCodes];
	NSLog (@"self.languageDictionary: %@\n", self.languageDictionary);
	NSLog (@"self.languageCodes: %@\n", self.languageCodes);
	
	NSUInteger index = [self.languageCodes indexOfObject:self.selectedLanguage];
	if (index != NSNotFound)
	{
		[self.languagePickerView selectRow:index inComponent:0 animated:NO];
	}
	
	[self configureUI];
}


#pragma mark - Language Accessors

// Language codes used to create custom voices. Array is sorted based
// on the display names in the language dictionary
- (NSArray *)languageCodes
{
	if (!_languageCodes)
	{
		_languageCodes = [self.languageDictionary keysSortedByValueUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	}
	return _languageCodes;
}


// Map between language codes and locale specific display name
- (NSDictionary *)languageDictionary
{
	if (!_languageDictionary)
	{
		NSArray *voices = [AVSpeechSynthesisVoice speechVoices];
		NSArray *languages = [voices valueForKey:@"language"];
		
		NSLocale *currentLocale = [NSLocale autoupdatingCurrentLocale];
		NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
		for (NSString *code in languages)
		{
			dictionary[code] = [currentLocale displayNameForKey:NSLocaleIdentifier value:code];
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
	self.selectedLanguage = [self.languageCodes objectAtIndex:row];
	NSUserDefaults *defults = [NSUserDefaults standardUserDefaults];
	[defults setObject:self.selectedLanguage forKey:@"kSelectedLanguage"];
	[defults synchronize];
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
