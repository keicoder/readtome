//
//  ViewController.h
//  ReadToMe
//
//  Created by jun on 3/23/15.
//  Copyright (c) 2015 keicoder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DocumentsForSpeech.h"

@interface ContainerViewController : UIViewController

@property (strong, nonatomic) DocumentsForSpeech *currentDocument;
@property (nonatomic, strong) NSString *language;

@property (nonatomic, assign) BOOL isSharedDocument;
@property (nonatomic, assign) BOOL isTodayDocument;
@property (nonatomic, assign) BOOL isSelectedDocumentFromListView;

@property (nonatomic, assign) BOOL isNewDocument;
@property (nonatomic, assign) BOOL isSavedDocument;



@end

