//
//  ActionViewController.m
//  ReadToMeAction
//
//  Created by jun on 3/23/15.
//  Copyright (c) 2015 keicoder. All rights reserved.
//

#import "ActionViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>


@interface ActionViewController () <AVSpeechSynthesizerDelegate>

@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, strong) NSString *utteranceString;
@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;

@end


@implementation ActionViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	NSExtensionItem *item = self.extensionContext.inputItems[0];
	NSItemProvider *itemProvider = item.attachments[0];
	
	if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePlainText]) {
		
		__weak UITextView *textView = self.textView;
		
		[itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypePlainText options:nil completionHandler:^(NSString *item, NSError *error) {
			
			if (item) {
				
				[[NSOperationQueue mainQueue] addOperationWithBlock:^{
					
					[textView setText:item];
					self.utteranceString = textView.text;
					
					AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:self.utteranceString];
					utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"];
					[utterance setRate:0.09]; //AVSpeechUtteranceMinimumSpeechRate
					utterance.preUtteranceDelay = 0.2f;
					utterance.postUtteranceDelay = 0.2f;
					
					self.synthesizer = [[AVSpeechSynthesizer alloc]init];
					self.synthesizer.delegate = self;
					[self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryWord];
					[self.synthesizer speakUtterance:utterance];
				}];
			}
		}];
	}
}


#pragma mark - AVSpeechSynthesizerDelegate

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer willSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance
{
	NSLog(@"%@ %@", [self class], NSStringFromSelector(_cmd));
	
	NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:utterance.speechString];
	[mutableAttributedString addAttribute:NSForegroundColorAttributeName value:[UIColor orangeColor] range:characterRange];
	self.textView.attributedText = mutableAttributedString;
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance
{
	NSLog(@"%@ %@", [self class], NSStringFromSelector(_cmd));
	
	self.textView.attributedText = [[NSAttributedString alloc] initWithString:self.utteranceString];
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
	NSLog(@"%@ %@", [self class], NSStringFromSelector(_cmd));
	
	self.textView.attributedText = [[NSAttributedString alloc] initWithString:self.utteranceString];
}


// Return any edited content to the host app. This template doesn't do anything, so we just echo the passed in items.
- (IBAction)done
{
	[self.extensionContext completeRequestReturningItems:self.extensionContext.inputItems completionHandler:nil];
	[self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
}


@end
