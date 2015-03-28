//
//  ListViewController.m
//  ReadToMe
//
//  Created by jun on 3/28/15.
//  Copyright (c) 2015 keicoder. All rights reserved.
//

#import "ListViewController.h"

@interface ListViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *menuView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end


@implementation ListViewController


#pragma mark - View life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self configureUI];
	self.tableView.dataSource = self;
	self.tableView.delegate = self;
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 30;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * cellIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
	}
	
	NSString *titleText = [NSString stringWithFormat:@"Title with Random Number: %u", arc4random_uniform(1000)];
	cell.textLabel.text = titleText;
	
	NSString *detailText = [NSString stringWithFormat:@"Detail Text with Random Number: %u", arc4random_uniform(1000)];
	cell.detailTextLabel.text = detailText;
	
	return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 60;
}


-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if (section == 0) {
		return @"Footer";
	}
	return nil;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSLog(@"Did Select Row!");
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - Button Action Methods

- (IBAction)returnButtonTapped:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Configure UI

- (void)configureUI
{
	self.menuView.backgroundColor = [UIColor colorWithRed:0.204 green:0.596 blue:0.859 alpha:1];
}


@end
