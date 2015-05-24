//
//  NSUserDefaults+Extension.m
//  SwiftNote
//
//  Created by jun on 2014. 6. 27..
//  Copyright (c) 2014년 Overcommitted, LLC. All rights reserved.
//

#import "NSUserDefaults+Extension.h"

@implementation NSUserDefaults (Extension)


- (void)setIndexPath:(NSIndexPath *)indexPath forKey:(NSString *)keyName
{
    [self setObject:@{@"row": @(indexPath.row), @"section": @(indexPath.section)} forKey:keyName];
}


- (NSIndexPath *)indexPathForKey:(NSString *)keyName
{
    NSDictionary *dict = [self objectForKey:keyName];
    return [NSIndexPath indexPathForRow:[dict[@"row"] integerValue] inSection:[dict[@"section"] integerValue]];
}


@end
