//
//  ListViewController.m
//  ReadToMe
//
//  Created by jun on 3/28/15.
//  Copyright (c) 2015 keicoder. All rights reserved.
//

#import "ListViewController.h"
#import "DataManager.h"
#import "DocumentsForSpeech.h"
#import "ContainerViewController.h"
#import "ListTableViewCell.h"


@interface ListViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *menuView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) DocumentsForSpeech *selectedDocumentsForSpeech;

@end


@implementation ListViewController

#pragma mark - View life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self configureUI];
	self.tableView.dataSource = self;
	self.tableView.delegate = self;
	[self addApplicationsStateObserver];
}


- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self executePerformFetch];
}


- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:YES];
	_fetchedResultsController = nil;
}


#pragma mark - Fetched Results Controller

- (NSFetchedResultsController *)fetchedResultsController
{
	if (_fetchedResultsController != nil) {
		return _fetchedResultsController;
	}
	else if (_fetchedResultsController == nil)
	{
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DocumentsForSpeech"];
		
		NSSortDescriptor *noteModifiedDateSort = [[NSSortDescriptor alloc] initWithKey:@"createdDate" ascending:NO];
		[fetchRequest setSortDescriptors: @[noteModifiedDateSort]];
		
		_fetchedResultsController = [[NSFetchedResultsController alloc]
									 initWithFetchRequest:fetchRequest
									 managedObjectContext:[DataManager sharedDataManager].managedObjectContext
									 sectionNameKeyPath:nil cacheName:nil];
		[fetchRequest setFetchBatchSize:20];
		_fetchedResultsController.delegate = self;
	}
	return _fetchedResultsController;
}


#pragma mark Perform Fetch

- (void)executePerformFetch
{
	NSError *error = nil;
	
	if (![[self fetchedResultsController] performFetch:&error])
	{
		NSLog (@"executePerformFetch > error occurred");
		//abort();
	} else {
		NSLog (@"self.fetchedResultsController: %@\n", self.fetchedResultsController);
		NSLog (@"self.fetchedResultsController count: %lu\n", (unsigned long)[[self.fetchedResultsController sections] count]);
	}
}


#pragma mark - NSFetched Results Controller Delegate (수정사항 반영)

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
	[self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
	switch(type) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
						  withRowAnimation:UITableViewRowAnimationAutomatic];
			break;
			
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
						  withRowAnimation:UITableViewRowAnimationAutomatic];
			break;
			
		case NSFetchedResultsChangeUpdate:
			break;
			
		case NSFetchedResultsChangeMove:
			break;
	}
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
	UITableView *tableView = self.tableView;
	switch(type)
	{
		case NSFetchedResultsChangeInsert:
			[tableView insertRowsAtIndexPaths:@[newIndexPath]
							 withRowAnimation:UITableViewRowAnimationAutomatic];
			break;
			
		case NSFetchedResultsChangeDelete:
			[tableView deleteRowsAtIndexPaths:@[indexPath]
							 withRowAnimation:UITableViewRowAnimationAutomatic];
			break;
			
		case NSFetchedResultsChangeUpdate:
			[tableView reloadData];
			[tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
			break;
			
		case NSFetchedResultsChangeMove:
			[tableView deleteRowsAtIndexPaths:@[indexPath]
							 withRowAnimation:UITableViewRowAnimationAutomatic];
			[tableView insertRowsAtIndexPaths:@[newIndexPath]
							 withRowAnimation:UITableViewRowAnimationAutomatic];
			break;
	}
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	[self.tableView endUpdates];
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [[self.fetchedResultsController sections] count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[self.fetchedResultsController sections][section] numberOfObjects];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * cellIdentifier = @"Cell";
	ListTableViewCell *cell = (ListTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	if (cell == nil) {
		cell = (ListTableViewCell *)[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
	}
	
	[self configureCell:cell atIndexPath:indexPath];
	
	DocumentsForSpeech *documentsForSpeech = [self.fetchedResultsController objectAtIndexPath:indexPath];
	cell.titleLabel.text = documentsForSpeech.documentTitle;
	cell.dayLabel.text = documentsForSpeech.dayString;
	cell.dateLabel.text = documentsForSpeech.dateString;
	cell.monthAndYearLabel.text = documentsForSpeech.monthAndYearString;
	
	return cell;
}


- (void)configureCell:(ListTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	if ([cell respondsToSelector:@selector(setSeparatorInset:)]) { cell.separatorInset = UIEdgeInsetsZero; }
	cell.backgroundColor = [UIColor whiteColor];
	cell.accessoryType = UITableViewCellAccessoryNone;
	
	cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
	cell.textLabel.textColor = [UIColor darkTextColor];
	cell.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];;
	cell.detailTextLabel.textColor = [UIColor lightGrayColor];
}


#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 88;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		[self deleteCoreDataDocumentObject:indexPath];
	}
}


- (void)deleteCoreDataDocumentObject:(NSIndexPath *)indexPath
{
	NSManagedObjectContext *managedObjectContext = [DataManager sharedDataManager].managedObjectContext;
	NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
	[managedObjectContext deleteObject:managedObject];
	NSError *error = nil;
	[managedObjectContext save:&error];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	DocumentsForSpeech *documentsForSpeech = [self.fetchedResultsController objectAtIndexPath:indexPath];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:documentsForSpeech forKey:@"DidSelectDocumentsForSpeechNotificationKey"];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"DidSelectDocumentsForSpeechNotification" object:nil userInfo:userInfo];
	
	UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
	pasteBoard.persistent = YES;
	pasteBoard.string = documentsForSpeech.document;
	
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	[self dismissViewControllerAnimated:YES completion:nil];
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
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


#pragma mark - Add Observer

- (void)addApplicationsStateObserver
{
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
	[center addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
	[center addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
	[center addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}


#pragma mark - Application's State

- (void)applicationWillResignActive
{
	NSLog(@"VC: %@", NSStringFromSelector(_cmd));
}


- (void)applicationDidBecomeActive
{
	NSLog(@"VC: %@", NSStringFromSelector(_cmd));
}


- (void)applicationDidEnterBackground
{
	NSLog(@"VC: %@", NSStringFromSelector(_cmd));
}


- (void)applicationWillEnterForeground
{
	NSLog(@"VC: %@", NSStringFromSelector(_cmd));
}


@end
