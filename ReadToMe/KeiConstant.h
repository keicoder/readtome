//
//  KeiConstant.h
//  KeiSliderView
//
//  Created by jun on 5/17/15.
//  Copyright (c) 2015 Keicoder. All rights reserved.
//

#ifndef KeiSliderView_KeiConstant_h
#define KeiSliderView_KeiConstant_h

#define iPad            [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad
#define kLogBOOL(BOOL) NSLog(@"%s: %@",#BOOL, BOOL ? @"YES" : @"NO" )

//Debug
#define debugLog 0

//iCloud Attributes
#define kReadToMeCloudStore                     @"ReadToMeCloudStore"
#define kReadToMeSplite                         @"ReadToMe.sqlite"
#define kReadToMeTransactionData                @"ReadToMe_Transaction_Data"
#define kReadToMeDocumentsSyncronized           @"com.keicoder.documentsSynchronized"

//Global Attributes
#define kSharedDefaultsSuiteName                @"group.com.keicoder.demo.readtome"
#define kIsSharedDocument                       @"kIsSharedDocument"
#define kSharedDocument                         @"kSharedDocument"
#define kIsTodayDocument                        @"kIsTodayDocument"
#define kTodayDocument                          @"kTodayDocument"

//Speech Attributes
#define kLanguage                               @"kLanguage"
#define kVolumeValue                            @"kVolumeValue"
#define kPitchValue                             @"kPitchValue"
#define kRateValue                              @"kRateValue"

//Keyboard Attributes
#define kIntervalForMovingKeyboardCursor        0.1

//ContainerViewController
#define kSlideViewHeight                        40.0
#define kPause                                  [UIImage imageNamed:@"pause"]
#define kPlay                                   [UIImage imageNamed:@"play"]
#define kHasLaunchedOnce                        @"kHasLaunchedOnce"
#define kTypeSelecting                          @"kTypeSelecting"
#define kLastViewedDocument                     @"kLastViewedDocument"
#define kBlankText                              @""
#define kSelectedDocumentIndex                  @"kSelectedDocumentIndex"
#define kSelectedDocumentIndexPath              @"kSelectedDocumentIndexPath"
#define kSelectedRangeLocation                  @"kSelectedRangeLocation"
#define kSelectedRangeLength                    @"kSelectedRangeLength"


#endif
