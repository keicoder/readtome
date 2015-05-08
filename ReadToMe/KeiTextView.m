//
//  KeiTextView.m
//  ReadToMe
//
//  Created by jun on 2015. 4. 13..
//  Copyright (c) 2015년 keicoder. All rights reserved.
//

#define debug 1


#import <tgmath.h>
#import "KeiTextView.h"


@implementation KeiTextView
{
    CGRect _keyboardRect;
}


#pragma mark - 캐럿 위치 이동

- (void)scrollToVisibleCaretAnimated
{
    [UIView animateWithDuration:0.2 animations:^{
        [self scrollRectToVisibleConsideringInsets:[self caretRectForPosition:self.selectedTextRange.end] animated:NO];
    }];
}


- (void)scrollRectToVisibleConsideringInsets:(CGRect)rect animated:(BOOL)animated
{
    UIEdgeInsets insets = UIEdgeInsetsMake(self.contentInset.top + self.textContainerInset.top,
                                           self.contentInset.left + self.textContainerInset.left,
                                           self.contentInset.bottom + self.textContainerInset.bottom,
                                           self.contentInset.right + self.textContainerInset.right);
    CGRect visibleRect = UIEdgeInsetsInsetRect(self.bounds, insets);
    if (!CGRectContainsRect(visibleRect, rect)) {
        CGPoint contentOffset = self.contentOffset;
        if (CGRectGetMinY(rect) < CGRectGetMinY(visibleRect)) {
            contentOffset.y = CGRectGetMinY(rect) - insets.top; //up
        } else {
            contentOffset.y = CGRectGetMaxY(rect) + insets.bottom - CGRectGetHeight(self.bounds); //down
        }
        [super setContentOffset:contentOffset animated:animated];
    }
}


#pragma mark - 키보드 handle, 인셋 조정

- (void)keyboardWillShow:(NSNotification *)notification
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    NSDictionary *userInfoDictionary = notification.userInfo;
    CGFloat duration = [[userInfoDictionary objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    int curve = [[userInfoDictionary objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    _keyboardRect = [[userInfoDictionary objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    [UIView animateWithDuration:duration delay:0.0 options:curve animations:^{
        [self updateNoteTextViewInsetWithKeyboard:notification];
    } completion:^(BOOL finished) {
        [self scrollToVisibleCaretAnimated];
    }];
}


- (void)updateNoteTextViewInsetWithKeyboard:(NSNotification*)notification
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    CGFloat contentInsetBottom = 0.f;
    contentInsetBottom = __tg_fmin(CGRectGetHeight(_keyboardRect), CGRectGetWidth(_keyboardRect));
    UIEdgeInsets contentInset = UIEdgeInsetsMake(0, 0, contentInsetBottom - 72.0, 0);
    self.contentInset = contentInset;
}


- (void)keyboardWillHide:(NSNotification*)notification
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    NSDictionary *userInfoDictionary = notification.userInfo;
    CGFloat duration = [[userInfoDictionary objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    int curve = [[userInfoDictionary objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    _keyboardRect = [[userInfoDictionary objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    [UIView animateWithDuration:duration delay:duration options:curve animations:^{
        [self updateNoteTextViewInsetWithoutKeyboard];
    } completion:^(BOOL finished) { }];
}


- (void)updateNoteTextViewInsetWithoutKeyboard
{
    if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    UIEdgeInsets contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.contentInset = contentInset;
}


#pragma mark - Dealloc

- (void)dealloc
{
    NSLog(@"dealloc %@", self);
}


@end
