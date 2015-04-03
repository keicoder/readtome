//
//  ListTableViewCell.h
//  ReadToMe
//
//  Created by jun on 4/3/15.
//  Copyright (c) 2015 keicoder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ListTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *dayLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *monthAndYearLabel;

@end
