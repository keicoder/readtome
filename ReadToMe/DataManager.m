//
//  DataManager.m


#import "DataManager.h"


@implementation DataManager

@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectContext = _managedObjectContext;


#pragma mark -
#pragma mark 싱글턴 모델

//참조: [NoteDataManager sharedNoteDataManager]

+ (instancetype)sharedNoteDataManager
{
    static dispatch_once_t pred;
    static DataManager *shared = nil;
    
    dispatch_once(&pred, ^{
        shared = [[DataManager alloc] init];
    });
    return shared;
}


#pragma mark -
#pragma mark 코어데이터 스택

#pragma mark 모델

- (NSManagedObjectModel *)managedObjectModel
{
    //if (debug==1) {NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));}
    
    if (_managedObjectModel != nil)
    {
        return _managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Clarity" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    //NSLog (@"ManagedObjectModel URL: %@\n", modelURL);
    //NSLog (@"NSManaged Object Model > _managedObjectModel: %@\n", _managedObjectModel);
    return _managedObjectModel;
}


#pragma mark 영구 저장소 조율기: 노트 영구저장소 이원화 > 로컬 노트, 드랍박스 노트

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil)
    {
        return _persistentStoreCoordinator;
    }
    
    NSURL *applicationDocumentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    //NSLog (@"NSFile Manager > Application Documents Directory:\n %@\n", applicationDocumentsDirectory);
    
    //노트 영구 저장소
    {
        NSURL *storeURL = [applicationDocumentsDirectory URLByAppendingPathComponent:@"DocumentsForSpeech.sqlite"];
        //NSLog (@"NoteDataManager > Persistent Store URL: %@\n", storeURL);
        
        NSError *error = nil;
        
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        
        //lightweight migrations
        NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption : @(YES),
                                   NSInferMappingModelAutomaticallyOption : @(YES)};
        
        if ([_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                       configuration:nil
                                                                 URL:storeURL
                                                             options:options
                                                               error:&error] == NO)
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    
    return _persistentStoreCoordinator;
}


#pragma mark 컨텍스트

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil)
    {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    
    if (coordinator != nil)
    {
        _managedObjectContext = [[NSManagedObjectContext alloc]
                                 initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    //NSLog (@"DataManager > NSManaged Object Context > _managedObjectContext: %@\n", _managedObjectContext);
    return _managedObjectContext;
}


@end