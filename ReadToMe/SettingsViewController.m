//
//  SettingsViewController.m
//  ReadToMe
//
//  Created by jun on 3/25/15.
//  Copyright (c) 2015 keicoder. All rights reserved.
//

#define kBackgroundPlayValue	@"kBackgroundPlayValue"
#define kBackgroundOn			@"Background On"
#define kBackgroundOff			@"Background Off"
#define kIsOnColor		[UIColor colorWithRed:1 green:0.73 blue:0.2 alpha:1]
#define kIsOffColor		[UIColor colorWithRed:0.227 green:0.414 blue:0.610 alpha:1.000]
#define iPad			[[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad


#import "SettingsViewController.h"
#import "UIImage+ChangeColor.h"
#import "PopView.h"
#import "LanguagePickerViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "AboutViewController.h"
#import <MessageUI/MessageUI.h>
#import "OpenSourceLicencesViewController.h"


@interface SettingsViewController () <UIGestureRecognizerDelegate, MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *gearImageView;
@property (weak, nonatomic) IBOutlet UILabel *backgroundPlayValueLabel;
@property (weak, nonatomic) IBOutlet PopView *backgroundPlayView;
@property (weak, nonatomic) IBOutlet PopView *aboutView;
@property (weak, nonatomic) IBOutlet PopView *openSourceView;
@property (weak, nonatomic) IBOutlet PopView *sendMailView;
@property (weak, nonatomic) IBOutlet PopView *returnView;

@property (nonatomic, strong) NSUserDefaults *defaults;
@property (nonatomic, strong) AVAudioSession *audioSession;

@end


@implementation SettingsViewController
{
	NSString *_backgroundPlayValue;
}


#pragma mark - View life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.defaults == nil) {
        self.defaults = [NSUserDefaults standardUserDefaults];
    }
	
    if (self.audioSession == nil) {
        self.audioSession = [AVAudioSession sharedInstance];
    }
    
	[self configureUI];
    [self getTheBackgroundPlayValue];
	[self addTapGestureOnTheView:self.backgroundPlayView];
	[self addTapGestureOnTheView:self.aboutView];
	[self addTapGestureOnTheView:self.openSourceView];
	[self addTapGestureOnTheView:self.sendMailView];
	[self addTapGestureOnTheView:self.returnView];
}


#pragma mark - Get the stored NSUserDefaults data

- (void)getTheBackgroundPlayValue
{
	_backgroundPlayValue = [self.defaults objectForKey:kBackgroundPlayValue];
	NSLog (@"_backgroundPlayValue: %@\n", _backgroundPlayValue);
    
	if ([_backgroundPlayValue isEqualToString:kBackgroundOn]) {
		
		self.backgroundPlayView.backgroundColor = kIsOnColor;
		self.backgroundPlayView.backgroundColorNormal = kIsOnColor;
		
	} else {
		
		self.backgroundPlayView.backgroundColor = kIsOffColor;
		self.backgroundPlayView.backgroundColorNormal = kIsOffColor;
	}
	
	self.backgroundPlayValueLabel.text = _backgroundPlayValue;
}


#pragma mark - Tap gesture on the View

- (void)addTapGestureOnTheView:(UIView *)aView
{
	UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gestureViewTapped:)];
	gestureRecognizer.cancelsTouchesInView = NO;
	gestureRecognizer.delegate = self;
	
	[aView addGestureRecognizer:gestureRecognizer];
}


- (void)gestureViewTapped:(UITouch *)touch
{
	if ([touch.view isEqual:(UIView *)self.backgroundPlayView]) {
		
        NSError *error = NULL;
        
		if ([_backgroundPlayValue isEqualToString:kBackgroundOn]) {
			
			_backgroundPlayValue = kBackgroundOff;
            
			self.backgroundPlayView.backgroundColor = kIsOffColor;
			self.backgroundPlayView.backgroundColorNormal = kIsOffColor;
            
            [self.audioSession setCategory:AVAudioSessionCategoryPlayback error:&error];
            if(error) {
                NSLog(@"Speech in background mode error occurred.");
            }
            [self.audioSession setActive:NO error:&error];
            NSLog(@"self.audioSession setActive No");
            if (error) {
                NSLog(@"Speech in background mode error occurred.");
            }
			
		} else {
			
			_backgroundPlayValue = kBackgroundOn;
            
			self.backgroundPlayView.backgroundColor = kIsOnColor;
			self.backgroundPlayView.backgroundColorNormal = kIsOnColor;
			[self playSound];
            
            [self.audioSession setCategory:AVAudioSessionCategoryPlayback error:&error];
            if(error) { NSLog(@"Speech in background mode error occurred."); }
            [self.audioSession setActive:YES error:&error];
            NSLog(@"self.audioSession setActive YES");
            if (error) { NSLog(@"Speech in background mode setActive error occurred."); }
		}
		
		self.backgroundPlayValueLabel.text = _backgroundPlayValue;
		[self.defaults setObject:_backgroundPlayValue forKey:kBackgroundPlayValue];
		[self.defaults synchronize];
		
	} else if ([touch.view isEqual:(UIView *)self.aboutView]) {
		
		AboutViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"AboutViewController"];
		controller.view.frame = self.view.bounds;
		[controller presentInParentViewController:self];
	}
	
	else if ([touch.view isEqual:(UIView *)self.openSourceView]) {
	
		OpenSourceLicencesViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"OpenSourceLicencesViewController"];
		controller.view.frame = self.view.bounds;
		[self presentViewController:controller animated:YES completion:^{ }];
	}
	
	else if ([touch.view isEqual:(UIView *)self.sendMailView]) {
		
		[self sendFeedbackEmail];
	}
	
	else if ([touch.view isEqual:(UIView *)self.returnView]) {
		
		[self dismissViewControllerAnimated:YES completion:nil];
	}
}


#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	if (touch.view == self.backgroundPlayView || touch.view == self.aboutView || touch.view == self.openSourceView || touch.view == self.sendMailView || touch.view == self.returnView) {
		return YES;
	}
	return NO;
}


#pragma mark - Sound

- (void)playSound
{
	NSString *path = [[NSBundle mainBundle] pathForResource:@"correct" ofType:@"caf"];
	NSURL *URL = [NSURL fileURLWithPath:path];
	SystemSoundID correctSoundID;
	AudioServicesCreateSystemSoundID((__bridge CFURLRef)URL, &correctSoundID);
	AudioServicesPlaySystemSound(correctSoundID);
}


#pragma mark - 이메일 공유 (MFMailComposeViewController)

- (void)sendFeedbackEmail
{
	if ([MFMailComposeViewController canSendMail])
	{
		MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
		mailViewController.mailComposeDelegate = self;
		
		NSString *versionString = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
		NSString *buildNumberString = [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"];
		NSString *messageSubject = @"ReadToMe iOS Feedback";
		NSString *messageBody = [NSString stringWithFormat:@"ReadToMe iOS Version %@ (Build %@)\n\n\n", versionString, buildNumberString];
		
		[mailViewController setToRecipients:@[@"lovejun.soft@gmail.com"]];
		[mailViewController setSubject:NSLocalizedString(messageSubject, messageSubject)];
		[mailViewController setMessageBody:NSLocalizedString(messageBody, messageBody) isHTML:NO];
		
		[self setupMailComposeViewModalTransitionStyle:mailViewController];
		mailViewController.modalPresentationCapturesStatusBarAppearance = YES;
		
		[self presentViewController:mailViewController animated:YES completion:^{ }];
	}
	
	else {
		
		NSLog(@"This device cannot send email");
	}
}


#pragma mark 이메일 공유 (Mail ComposeView Modal Transition Style)

- (void)setupMailComposeViewModalTransitionStyle:(MFMailComposeViewController *)mailViewController
{
	if (iPad) {
		mailViewController.modalPresentationStyle = UIModalPresentationFormSheet;
	} else {
		mailViewController.modalPresentationStyle = UIModalPresentationPageSheet;
	}
}


#pragma mark 델리게이트 메소드 (MFMailComposeViewControllerDelegate)

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	switch (result)
	{
		case MFMailComposeResultCancelled:
			NSLog(@"mail composer cancelled");
			break;
		case MFMailComposeResultSaved:
			NSLog(@"mail composer saved");
			break;
		case MFMailComposeResultSent:
			NSLog(@"mail composer sent");
			break;
		case MFMailComposeResultFailed:
			NSLog(@"mail composer failed");
			break;
	}
	[controller dismissViewControllerAnimated:YES completion:^{
		
	}];
}


#pragma mark - Configure UI

- (void)configureUI
{
	//Corner Radius
	float cornerRadius = self.aboutView.bounds.size.height/2;
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		cornerRadius = 35;
	} else {
		cornerRadius = self.openSourceView.bounds.size.height/2;
	}
	
	self.backgroundPlayView.layer.cornerRadius = cornerRadius;
	self.aboutView.layer.cornerRadius = cornerRadius;
	self.openSourceView.layer.cornerRadius = cornerRadius;
	self.sendMailView.layer.cornerRadius = cornerRadius;
	self.returnView.layer.cornerRadius = cornerRadius;
	
	//Color
	UIColor *colorNormal1 = [UIColor colorWithRed:0.396 green:0.675 blue:0.82 alpha:1];
	UIColor *colorNormal2 = [UIColor colorWithRed:0.906 green:0.298 blue:0.235 alpha:1];

	self.aboutView.backgroundColor = colorNormal1;
	self.openSourceView.backgroundColor = colorNormal1;
	self.sendMailView.backgroundColor = colorNormal1;
	self.returnView.backgroundColor = colorNormal2;
	
	//Image View
	UIColor *color = [UIColor colorWithRed:0.286 green:0.58 blue:0.753 alpha:1];
	UIImage *image = [UIImage imageForChangingColor:@"gear" color:color];
	self.gearImageView.backgroundColor = [UIColor clearColor];
	self.gearImageView.image = image;
}


@end