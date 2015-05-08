//
//  KeiTextView.h
//  ReadToMe
//
//  Created by jun on 2015. 4. 13..
//  Copyright (c) 2015년 keicoder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KeiTextView : UITextView

- (void)scrollToVisibleCaretAnimated;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification*)notification;

@end
