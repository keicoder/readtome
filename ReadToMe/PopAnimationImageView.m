//
//  PopAnimationImageView.m
//  QuizKorean
//
//  Created by jun on 2015. 2. 21..
//  Copyright (c) 2015년 jun. All rights reserved.
//


#import "PopAnimationImageView.h"
#import "pop/POP.h"


@implementation PopAnimationImageView


#pragma mark - Init

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if (self) {
        
        self.userInteractionEnabled = YES;
    }
    
    return self;
}


#pragma mark - Handle touches with a nice pop animations

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    POPSpringAnimation *scale = [self pop_animationForKey:@"scale"];
    POPSpringAnimation *rotate = [self.layer pop_animationForKey:@"rotate"];
    
    CGFloat size = 0.88f;
    
    if (scale) {
        scale.toValue = [NSValue valueWithCGPoint:CGPointMake(size, size)];
    } else {
        scale = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
        scale.toValue = [NSValue valueWithCGPoint:CGPointMake(size, size)];
        scale.springBounciness = 20;
        scale.springSpeed = 18.0f;
        [self pop_addAnimation:scale forKey:@"scale"];
    }
    
    CGFloat value = 1;
    if (rotate) {
        rotate.toValue = @(M_PI/value);
    } else {
        rotate = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerRotation];
        rotate.toValue = @(M_PI/value);
        rotate.springBounciness = 20;
        rotate.springSpeed = 18.0f;
        [self.layer pop_addAnimation:rotate forKey:@"rotate"];
    }
    
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    POPSpringAnimation *scale = [self pop_animationForKey:@"scale"];
    POPSpringAnimation *rotate = [self pop_animationForKey:@"rotate"];
    
    CGFloat size = 1.0;
    
    if (scale) {
        scale.toValue = [NSValue valueWithCGPoint:CGPointMake(size, size)];
    } else {
        scale = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
        scale.toValue = [NSValue valueWithCGPoint:CGPointMake(size, size)];
        scale.springBounciness = 20;
        scale.springSpeed = 18.0f;
        [self pop_addAnimation:scale forKey:@"scale"];
    }
    
    if (rotate) {
        rotate.toValue = @(0);
    } else {
        rotate = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerRotation];
        rotate.toValue = @(0);
        rotate.springBounciness = 20;
        rotate.springSpeed = 18.0f;
        [self.layer pop_addAnimation:rotate forKey:@"rotate"];
    }
    
    [super touchesEnded:touches withEvent:event];
}


@end