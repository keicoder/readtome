//
//  SettingsViewController.m
//  ReadToMe
//
//  Created by jun on 3/25/15.
//  Copyright (c) 2015 keicoder. All rights reserved.
//

#define kBackgroundPlayValue @"_backgroundPlayValue"


#import "SettingsViewController.h"
#import "UIImage+ChangeColor.h"
#import "PopView.h"


@interface SettingsViewController () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *gearImageView;
@property (weak, nonatomic) IBOutlet PopView *selectVoiceView;
@property (weak, nonatomic) IBOutlet UIView *pitchView;
@property (weak, nonatomic) IBOutlet UIView *rateView;
@property (weak, nonatomic) IBOutlet UIView *backgroundPlayView;
@property (weak, nonatomic) IBOutlet PopView *returnView;
@property (weak, nonatomic) IBOutlet UISlider *pitchSlider;
@property (weak, nonatomic) IBOutlet UISlider *rateSlider;
@property (weak, nonatomic) IBOutlet UISwitch *backgroundPlaySwitch;

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
	[self addTapGestureOnTheView:self.selectVoiceView];
	[self addTapGestureOnTheView:self.returnView];
	[self getTheBackgroundPlaySwitchValue];
}


#pragma mark - Slider and Switch Value

- (IBAction)pitchSliderValueChanged:(id)sender
{
	NSString *pitchValue = [NSString stringWithFormat:@"%f", self.pitchSlider.value];
	NSLog (@"pitchValue: %@\n", pitchValue);
}


- (IBAction)rateSliderValueChanged:(id)sender
{
	NSString *rateValue = [NSString stringWithFormat:@"%f", self.rateSlider.value];
	NSLog (@"rateValue: %@\n", rateValue);
}


- (IBAction)backgroundPlaySwitchValueChanged:(UISwitch *)sender
{
	if([sender isOn]){
		
		_backgroundPlayValue = @"isOn";
		[_defaults setObject:_backgroundPlayValue forKey:kBackgroundPlayValue];
		[_defaults synchronize];
		
	} else{
		_backgroundPlayValue = @"isOff";
		[_defaults setObject:_backgroundPlayValue forKey:kBackgroundPlayValue];
		[_defaults synchronize];
		
	}
}


#pragma mark - Get the stored NSUserDefaults data

- (void)getTheBackgroundPlaySwitchValue
{
	_backgroundPlayValue = [_defaults objectForKey:kBackgroundPlayValue];
	
	if ([_backgroundPlayValue isKindOfClass:[NSNull class]]) {
		
		_backgroundPlayValue = @"isOn";
		[_defaults setObject:_backgroundPlayValue forKey:kBackgroundPlayValue];
		[_defaults synchronize];
		[self.backgroundPlaySwitch setOn:YES animated:YES];
		
	} else if ([_backgroundPlayValue isEqualToString: @"isOn"]) {
		
		[self.backgroundPlaySwitch setOn:YES animated:YES];
		
	} else if ([_backgroundPlayValue isEqualToString: @"isOff"]) {
		
		[self.backgroundPlaySwitch setOn:NO animated:YES];
	}
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
	if ([touch.view isEqual:(UIView *)self.selectVoiceView]) {
		
		NSLog(@"self.selectVoiceView Tapped");
		
	} else if ([touch.view isEqual:(UIView *)self.returnView]) {
		
		NSLog(@"self.returnView Tapped");
		[self dismissViewControllerAnimated:YES completion:nil];
	}
}


#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	if (touch.view == self.selectVoiceView || touch.view == self.returnView) {
		return YES;
	}
	return NO;
}


#pragma mark - Configure UI

- (void)configureUI
{
	//Corner Radius
	float cornerRadius = self.rateView.bounds.size.height/2;
	
	self.selectVoiceView.layer.cornerRadius = cornerRadius;
	self.pitchView.layer.cornerRadius = cornerRadius;
	self.rateView.layer.cornerRadius = cornerRadius;
	self.backgroundPlayView.layer.cornerRadius = cornerRadius;
	self.returnView.layer.cornerRadius = cornerRadius;
	
	//Color
	UIColor *colorNormal1 = [UIColor colorWithRed:0.137 green:0.271 blue:0.424 alpha:1];
	UIColor *colorNormal2 = [UIColor colorWithRed:0.192 green:0.667 blue:0.224 alpha:1];
	
	self.selectVoiceView.backgroundColor = colorNormal1;
	self.pitchView.backgroundColor = colorNormal1;
	self.rateView.backgroundColor = colorNormal1;
	self.backgroundPlayView.backgroundColor = colorNormal1;
	self.returnView.backgroundColor = colorNormal2;
	
	//Image View
	UIColor *color = [UIColor colorWithRed:0.286 green:0.58 blue:0.753 alpha:1];
	UIImage *image = [UIImage imageForChangingColor:@"gear" color:color];
	self.gearImageView.backgroundColor = [UIColor clearColor];
	self.gearImageView.image = image;
}


@end