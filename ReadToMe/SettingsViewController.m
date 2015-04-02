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
#define kIsOnColor  [UIColor colorWithRed:1 green:0.73 blue:0.2 alpha:1]
#define kIsOffColor [UIColor colorWithRed:0.227 green:0.414 blue:0.610 alpha:1.000]


#import "SettingsViewController.h"
#import "UIImage+ChangeColor.h"
#import "PopView.h"
#import "LanguagePickerViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "AboutViewController.h"


@interface SettingsViewController () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *gearImageView;
@property (weak, nonatomic) IBOutlet PopView *backgroundPlayView;
@property (weak, nonatomic) IBOutlet UILabel *backgroundPlayValueLabel;
@property (weak, nonatomic) IBOutlet PopView *aboutView;
@property (weak, nonatomic) IBOutlet PopView *openSourceView;
@property (weak, nonatomic) IBOutlet PopView *returnView;

@end


@implementation SettingsViewController
{
	NSUserDefaults *_defaults;
	NSString *_backgroundPlayValue;
}


#pragma mark - View life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	_defaults = [NSUserDefaults standardUserDefaults];
	[self configureUI];
	[self addTapGestureOnTheView:self.backgroundPlayView];
	[self addTapGestureOnTheView:self.aboutView];
	[self addTapGestureOnTheView:self.openSourceView];
	[self addTapGestureOnTheView:self.returnView];
	[self getTheBackgroundPlayValue];
}


#pragma mark - Get the stored NSUserDefaults data

- (void)getTheBackgroundPlayValue
{
	_backgroundPlayValue = [_defaults objectForKey:kBackgroundPlayValue];
	
	if ([_backgroundPlayValue isEqualToString:kBackgroundOn]) {
		
		self.backgroundPlayView.backgroundColor = kIsOnColor;
		self.backgroundPlayView.backgroundColorNormal = kIsOnColor;
		
	} else {
		
		self.backgroundPlayView.backgroundColor = kIsOffColor;
		self.backgroundPlayView.backgroundColorNormal = kIsOffColor;
	}
	
	NSLog (@"_backgroundPlayValue: %@\n", _backgroundPlayValue);
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
		
		if ([_backgroundPlayValue isEqualToString:kBackgroundOn]) {
			
			_backgroundPlayValue = kBackgroundOff;
			self.backgroundPlayView.backgroundColor = kIsOffColor;
			self.backgroundPlayView.backgroundColorNormal = kIsOffColor;
			
		} else {
			
			_backgroundPlayValue = kBackgroundOn;
			self.backgroundPlayView.backgroundColor = kIsOnColor;
			self.backgroundPlayView.backgroundColorNormal = kIsOnColor;
			[self playSound];
		}
		
		NSLog (@"_backgroundPlayValue: %@\n", _backgroundPlayValue);
		self.backgroundPlayValueLabel.text = _backgroundPlayValue;
		[_defaults setObject:_backgroundPlayValue forKey:kBackgroundPlayValue];
		[_defaults synchronize];
		
	} else if ([touch.view isEqual:(UIView *)self.aboutView]) {
		
		AboutViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"AboutViewController"];
		controller.view.frame = self.view.bounds;
		[controller presentInParentViewController:self];
	}
	
	else if ([touch.view isEqual:(UIView *)self.openSourceView]) {
	
		
	}
	
	else if ([touch.view isEqual:(UIView *)self.returnView]) {
		
		[self dismissViewControllerAnimated:YES completion:nil];
	}
}


#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	if (touch.view == self.backgroundPlayView || touch.view == self.aboutView || touch.view == self.openSourceView || touch.view == self.returnView) {
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


#pragma mark - Configure UI

- (void)configureUI
{
	//Corner Radius
	float cornerRadius = self.aboutView.bounds.size.height/2;
	
	self.backgroundPlayView.layer.cornerRadius = cornerRadius;
	self.aboutView.layer.cornerRadius = cornerRadius;
	self.openSourceView.layer.cornerRadius = cornerRadius;
	self.returnView.layer.cornerRadius = cornerRadius;
	
	//Color
	UIColor *colorNormal1 = [UIColor colorWithRed:0.396 green:0.675 blue:0.82 alpha:1];
	UIColor *colorNormal2 = [UIColor colorWithRed:0.906 green:0.298 blue:0.235 alpha:1];

	self.aboutView.backgroundColor = colorNormal1;
	self.openSourceView.backgroundColor = colorNormal1;
	self.returnView.backgroundColor = colorNormal2;
	
	//Image View
	UIColor *color = [UIColor colorWithRed:0.286 green:0.58 blue:0.753 alpha:1];
	UIImage *image = [UIImage imageForChangingColor:@"gear" color:color];
	self.gearImageView.backgroundColor = [UIColor clearColor];
	self.gearImageView.image = image;
}


@end