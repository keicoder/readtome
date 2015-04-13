//
//  AttributedTextView.m
//  ReadToMe
//
//  Created by jun on 2015. 4. 13..
//  Copyright (c) 2015년 keicoder. All rights reserved.
//

#import "AttributedTextView.h"

@implementation AttributedTextView


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
