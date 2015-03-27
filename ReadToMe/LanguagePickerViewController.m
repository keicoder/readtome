//
//  LanguagePickerViewController.m
//  ReadToMe
//
//  Created by jun on 3/27/15.
//  Copyright (c) 2015 keicoder. All rights reserved.
//

#import "LanguagePickerViewController.h"


@interface LanguagePickerViewController () <UIPickerViewDelegate, UIPickerViewDataSource>

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

@end
