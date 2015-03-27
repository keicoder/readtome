//
//  LanguagePickerViewController.h
//  ReadToMe
//
//  Created by jun on 3/27/15.
//  Copyright (c) 2015 keicoder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface LanguagePickerViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIPickerView *languagePickerView;
@property (strong, nonatomic) AVSpeechSynthesizer *synthesizer;
@property (nonatomic, strong) NSArray *languageCodes;
@property (nonatomic, strong) NSDictionary *languageDictionary;
@property (strong, nonatomic) NSString *selectedLanguage;

@end
