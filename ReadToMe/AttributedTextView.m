//
//  AttributedTextView.m
//  ReadToMe
//
//  Created by jun on 2015. 4. 13..
//  Copyright (c) 2015년 keicoder. All rights reserved.
//

#import "AttributedTextView.h"

@implementation AttributedTextView


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
            contentOffset.y = CGRectGetMinY(rect) - insets.top;                                     //up
        } else {
            contentOffset.y = CGRectGetMaxY(rect) + insets.bottom - CGRectGetHeight(self.bounds);   //down
        }
        [super setContentOffset:contentOffset animated:animated];
    }
}


- (void)replaceSelectionWithAttributedText:(NSAttributedString *)text
{
    [self replaceRange:self.selectedRange withAttributedText:text];
}


- (void)replaceRange:(NSRange)range withAttributedText:(NSAttributedString *)text
{
    [self replaceRange:range withAttributedText:text andSelectRange:NSMakeRange(range.location, text.length)];
}


- (void)replaceRange:(NSRange)range withAttributedText:(NSAttributedString *)text andSelectRange:(NSRange)selection
{
    [[self.undoManager prepareWithInvocationTarget:self] replaceRange:NSMakeRange(range.location, text.length) withAttributedText:[self.attributedText attributedSubstringFromRange:range] andSelectRange:self.selectedRange];
    [self.textStorage replaceCharactersInRange:range withAttributedString:text];
    self.selectedRange = selection;
}


@end
