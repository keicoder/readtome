//
//  DocumentsForSpeech.h
//  ReadToMe
//
//  Created by jun on 3/31/15.
//  Copyright (c) 2015 keicoder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface DocumentsForSpeech : NSManagedObject

@property (nonatomic, retain) NSString * documentBody;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSString * dateString;
@property (nonatomic, retain) NSString * dayString;
@property (nonatomic, retain) NSString * language;
@property (nonatomic, retain) NSString * monthString;
@property (nonatomic, retain) NSNumber * pitch;
@property (nonatomic, retain) NSNumber * rate;
@property (nonatomic, retain) NSString * section;
@property (nonatomic, retain) NSString * documentTitle;
@property (nonatomic, retain) NSString * uniqueIdString;
@property (nonatomic, retain) NSNumber * volume;
@property (nonatomic, retain) NSString * yearString;
@property (nonatomic, retain) NSString * document;

@end
