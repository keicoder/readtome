//
//  DataManager.h


#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface DataManager : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;


+ (instancetype)sharedNoteDataManager;


@end
