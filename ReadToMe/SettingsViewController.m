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
#import "LanguagePickerViewController.h"


@interface SettingsViewController () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *gearImageView;
@property (weak, nonatomic) IBOutlet PopView *backgroundPlayView;
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


#pragma mark - Slider and Switch Value



- (void)backgroundPlayValueChanged
{
	
}


#pragma mark - Get the stored NSUserDefaults data

- (void)getTheBackgroundPlayValue
{
	_backgroundPlayValue = [_defaults objectForKey:kBackgroundPlayValue];
	
	if ([_backgroundPlayValue isKindOfClass:[NSNull class]]) {
		
		_backgroundPlayValue = @"isOn";
		[_defaults setObject:_backgroundPlayValue forKey:kBackgroundPlayValue];
		[_defaults synchronize];
		
	} else if ([_backgroundPlayValue isEqualToString: @"isOn"]) {
		
		
		
	} else if ([_backgroundPlayValue isEqualToString: @"isOff"]) {
		
		
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
	if ([touch.view isEqual:(UIView *)self.backgroundPlayView]) {
		
		
	} else if ([touch.view isEqual:(UIView *)self.aboutView]) {
		
		
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
	
	self.backgroundPlayView.backgroundColor = colorNormal1;
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