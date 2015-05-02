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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Get the item[s] we're handling from the extension context.
    
    // For example, look for an image and place it into an image view.
    // Replace this with something appropriate for the type[s] your extension supports.
    BOOL documentFound = NO;
    for (NSExtensionItem *item in self.extensionContext.inputItems) {
        for (NSItemProvider *itemProvider in item.attachments) {
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeText]) {
                // This is an image. We'll load it, then place it in our image view.
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
            // We only handle one document, so stop looking for more.
            break;
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)done {
    // Return any edited content to the host app.
    // This template doesn't do anything, so we just echo the passed in items.
    [self.extensionContext completeRequestReturningItems:self.extensionContext.inputItems completionHandler:nil];
}

@end
