//
//  ActionViewController.m
//  ReadToMeActionExtension
//
//  Created by jun on 2015. 5. 2..
//  Copyright (c) 2015년 keicoder. All rights reserved.
//

#import "ActionViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface ActionViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end


@implementation ActionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    BOOL documentFound = NO;
    for (NSExtensionItem *item in self.extensionContext.inputItems) {
        
        for (NSItemProvider *itemProvider in item.attachments) {
            
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeText]) {
                
                __weak UITextView *textView = self.textView;
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeText options:nil completionHandler:^(NSString *document, NSError *error) {
                    
                    if(document) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [textView setText:document];
                        }];
                    }
                }];
                
                documentFound = YES;
                break;
            }
        }
        
        if (documentFound) {
            
            break; // We only handle one document, so stop looking for more.
        }
    }
}


- (IBAction)done
{
    // Return any edited content to the host app.
    // This template doesn't do anything, so we just echo the passed in items.
    [self.extensionContext completeRequestReturningItems:self.extensionContext.inputItems completionHandler:nil];
}

@end
