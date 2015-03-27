//
//  PopView.m
//  QuizKorean
//
//  Created by jun on 2015. 2. 18..
//  Copyright (c) 2015년 jun. All rights reserved.
//


#define kBackgroundColorNormal [UIColor colorWithRed:0.506 green:0.678 blue:0.860 alpha:1.000]
#define kBackgroundColorHighlight [UIColor colorWithRed:0.044 green:0.132 blue:0.247 alpha:1.000]


#import "PopView.h"
#import "pop/POP.h"


@implementation PopView
{
    CGFloat _duration;
}


#pragma mark - Init

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if (self) {
        
        _duration = 0.2f;
        
        if (!self.backgroundColorNormal) {
            [self setBackgroundColor:kBackgroundColorNormal];
        } else {
            [self setBackgroundColor:self.backgroundColorNormal];
        }
    }
    
    return self;
}


#pragma mark - Handle touches with a nice pop animations

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    
    POPSpringAnimation *scale = [self pop_animationForKey:@"scale"];
    
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
    
    [UIView animateWithDuration:_duration animations:^{
		
        if (!self.backgroundColorHighlight) {
            [self setBackgroundColor:kBackgroundColorHighlight];
        } else {
            [self setBackgroundColor:self.backgroundColorHighlight];
        }
    }completion:^(BOOL finished) { }];
    
    [super touchesBegan:touches withEvent:event];
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    POPSpringAnimation *scale = [self pop_animationForKey:@"scale"];
    
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
    
    [UIView animateWithDuration:_duration animations:^{
		
        if (!self.backgroundColorNormal) {
            [self setBackgroundColor:kBackgroundColorNormal];
        } else {
            [self setBackgroundColor:self.backgroundColorNormal];
        }
    }completion:^(BOOL finished) { }];
    
    [super touchesEnded:touches withEvent:event];
}


@end
