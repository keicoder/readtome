//
//  AboutViewController.m
//  QuizKorean
//
//  Created by jun on 2/10/15.
//  Copyright (c) 2015 jun. All rights reserved.
//

#import "AboutViewController.h"
#import "GradientView.h"
#import "UIImage+ChangeColor.h"


@interface AboutViewController () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UILabel *aboutLabel;
@property (weak, nonatomic) IBOutlet UIImageView *clipImageView;

@end

@implementation AboutViewController
{
	GradientView *_gradientView;
}


- (void)viewDidLoad
{
	[super viewDidLoad];
	[self configureUI];
	[self addTapGuesture];
	[self updateLabel];
}


- (void)updateLabel
{
	self.aboutLabel.text = @"ReadToMe\n\nReadToMe app can make your iPhone or iPad read aloud document. Enjoy it.\n\nTwitter: @hyun2012\nEmail: lovejun.soft@gmail.com\n\nKeiCoder 2015";
}


#pragma mark - Present In ParentView Controller

- (void)presentInParentViewController:(UIViewController *)parentViewController
{
	_gradientView = [[GradientView alloc] initWithFrame:parentViewController.view.bounds];
	[parentViewController.view addSubview:_gradientView];
	
	self.view.frame = parentViewController.view.bounds;
	[parentViewController.view addSubview:self.view];
	[parentViewController addChildViewController:self];
	
	CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
	
	bounceAnimation.duration = 0.4;
	bounceAnimation.delegate = self;
	
	bounceAnimation.values = @[ @0.8, @1.2, @0.9, @1.0 ];
	bounceAnimation.keyTimes = @[ @0.0, @0.334, @0.666, @1.0 ];
	
	bounceAnimation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
	
	[self.view.layer addAnimation:bounceAnimation forKey:@"bounceAnimation"];
	
	CABasicAnimation *fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
	fadeAnimation.fromValue = @0.0f;
	fadeAnimation.toValue = @1.0f;
	fadeAnimation.duration = 0.2;
	[_gradientView.layer addAnimation:fadeAnimation forKey:@"fadeAnimation"];
}


- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
	[self didMoveToParentViewController:self.parentViewController];
}


- (void)dismissFromParentViewController
{
	[self willMoveToParentViewController:nil];
	
	[UIView animateWithDuration:0.3 animations:^
	 {
		 CGRect rect = self.view.bounds;
		 rect.origin.y += rect.size.height;
		 self.view.frame = rect;
		 _gradientView.alpha = 0.0f;
	 }
					 completion:^(BOOL finished)
	 {
		 [self.view removeFromSuperview];
		 [self removeFromParentViewController];
		 
		 [_gradientView removeFromSuperview];
	 }];
}


#pragma mark - Button and Touch Action

- (IBAction)dismissButtonTapped:(id)sender
{
	[self dismissFromParentViewController];
}


- (void)addTapGuesture
{
	UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissButtonTapped:)];
	gestureRecognizer.cancelsTouchesInView = NO;
	gestureRecognizer.delegate = self;
	
	[self.view addGestureRecognizer:gestureRecognizer];
}


#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	return (touch.view == self.view);
}


#pragma mark - Configure UI

- (void)configureUI
{
	self.view.tintColor = [UIColor colorWithRed:20/255.0f green:160/255.0f blue:160/255.0f alpha:1.0f];
	self.view.backgroundColor = [UIColor clearColor];
	self.containerView.backgroundColor = [UIColor colorWithRed:0.05 green:0.32 blue:0.41 alpha:1];
	self.containerView.layer.cornerRadius = 10.0f;
	
	UIImage *image = [UIImage imageForChangingColor:@"clip" color:[UIColor whiteColor]];
	self.clipImageView.image = image;
}


#pragma mark - Dealloc

- (void)dealloc
{
	NSLog(@"dealloc %@", self);
}

@end
