//
//  DocumentsForSpeech.m
//  ReadToMe
//
//  Created by jun on 3/31/15.
//  Copyright (c) 2015 keicoder. All rights reserved.
//

#define debug 1

#import "DocumentsForSpeech.h"

@interface DocumentsForSpeech ()

@property (nonatomic, strong) NSDateFormatter *formatter;

@end

@implementation DocumentsForSpeech

@dynamic documentBody;
@dynamic createdDate;
@dynamic dateString;
@dynamic dayString;
@dynamic language;
@dynamic monthString;
@dynamic monthAndYearString;
@dynamic pitch;
@dynamic rate;
@dynamic section;
@dynamic isNewDocument;
@dynamic savedDocument;
@dynamic documentTitle;
@dynamic uniqueIdString;
@dynamic volume;
@dynamic yearString;
@dynamic document;

@synthesize formatter = _formatter;


#pragma mark - 데이트 Formatter

- (NSDateFormatter *)formatter
{
	if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
	
	if (!_formatter) {
		_formatter = [[NSDateFormatter alloc] init];
	}
	return _formatter;
}


#pragma mark - awakeFromInsert

- (void)awakeFromInsert
{
	if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
	
	[super awakeFromInsert];
	[self updateDateValue];
}


#pragma mark - Update Date Value

- (void)updateDateValue
{
	if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
	
	NSDate *now = [NSDate date];
	
	[self.formatter setDateFormat:@"yyyy"];
	NSString *stringYear = [self.formatter stringFromDate:now];
	
	[self.formatter setDateFormat:@"MMM"];
	NSString *stringMonth = [self.formatter stringFromDate:now];
	
	[self.formatter setDateFormat:@"dd"];
	NSString *stringDay = [self.formatter stringFromDate:now];
	
	[self.formatter setDateFormat:@"EEEE"];
	NSString *stringDate = [self.formatter stringFromDate:now];
	NSString *stringdaysOfTheWeek = [[stringDate substringToIndex:3] uppercaseString];
	
	self.yearString = stringYear;
	self.monthString = stringMonth;
	self.dayString = stringDay;
	self.dateString = stringdaysOfTheWeek;
	
	[self.formatter setDateFormat:@"MMM yyyy"];
	NSString *monthAndYearString = [self.formatter stringFromDate:now];
	self.monthAndYearString = monthAndYearString;
	
	self.section = stringYear;
	
//	NSLog (@"self.yearString: %@\n", self.yearString);
//	NSLog (@"self.monthString: %@\n", self.monthString);
//	NSLog (@"self.dayString: %@\n", self.dayString);
//	NSLog (@"self.dateString: %@\n", self.dateString);
//	NSLog (@"self.monthAndYearString: %@\n", self.monthAndYearString);
//	NSLog (@"self.section: %@\n", self.section);
}


@end
