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

@property (nonatomic, strong) NSString *selectedLanguage;
@property (strong, nonatomic) DocumentsForSpeech *currentDocumentsForSpeech;


@end

