//
//  CdManagedObjectContext.m
//  CadmiumObjC
//
//  Created by Jason Fieldman on 2/26/17.
//  Copyright © 2017 Jason Fieldman. All rights reserved.
//

#import "CdInternal.h"
#import "CdManagedObjectContext.h"
#import "CdManagedObject.h"
#import "CdException.h"
#import "NSThread+Cadmium.h"

static CdManagedObjectContext * _mainThreadContext = nil;
static CdManagedObjectContext * _masterSaveContext = nil;
static dispatch_queue_t serialTransactionQueue;

@implementation CdManagedObjectContext

+ (void)initializeMasterContexts:(NSPersistentStoreCoordinator * _Nonnull)coordinator {
    serialTransactionQueue = dispatch_queue_create("Cd.ManagedObjectContext.serialTransactionQueue", DISPATCH_QUEUE_SERIAL);
    
    _masterSaveContext = [[CdManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    _masterSaveContext.undoManager = nil;
    _masterSaveContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    _masterSaveContext.persistentStoreCoordinator = coordinator;
    
    _mainThreadContext = [[CdManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _mainThreadContext.undoManager = nil;
    _mainThreadContext.parentContext = _masterSaveContext;
    
    [NSNotificationCenter.defaultCenter addObserverForName:NSManagedObjectContextDidSaveNotification
                                                    object:_masterSaveContext
                                                     queue:[[NSOperationQueue alloc] init]
                                                usingBlock:^(NSNotification * _Nonnull note)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSThread.currentThread.insideMainThreadChangeNotification = YES;
            
            NSSet<NSManagedObject *> *updates = note.userInfo[@"updated"];
            for (NSManagedObject *update in updates) {
                [[_mainThreadContext objectWithID:update.objectID] willAccessValueForKey:nil];
            }
            
            [_mainThreadContext mergeChangesFromContextDidSaveNotification:note];
            
            NSThread.currentThread.insideMainThreadChangeNotification = NO;
        });
    }];
    
    [NSNotificationCenter.defaultCenter addObserverForName:NSManagedObjectContextObjectsDidChangeNotification
                                                    object:_mainThreadContext
                                                     queue:nil
                                                usingBlock:^(NSNotification * _Nonnull note)
    {
        NSSet<CdManagedObject *> *objects = note.userInfo[NSRefreshedObjectsKey];
        for (CdManagedObject *object in objects) {
            [object notifyUpdateHandlers:CdManagedObjectUpdateEventRefreshed];
        }
        
        objects = note.userInfo[NSUpdatedObjectsKey];
        for (CdManagedObject *object in objects) {
            [object notifyUpdateHandlers:CdManagedObjectUpdateEventUpdated];
        }
        
        objects = note.userInfo[NSDeletedObjectsKey];
        for (CdManagedObject *object in objects) {
            [object notifyUpdateHandlers:CdManagedObjectUpdateEventDeleted];
        }
    }];
}


@end


@implementation CdManagedObjectContext (Internal)

+ (nonnull CdManagedObjectContext *)mainThreadContext {
    if (!_mainThreadContext) {
        [CdException raiseWithFormat:@"Cadmium must be initialized before the main thread context is available."];
    }
    
    return _mainThreadContext;
}

+ (nonnull CdManagedObjectContext *)masterSaveContext {
    if (!_masterSaveContext) {
        [CdException raiseWithFormat:@"Cadmium must be initialized before the master save context is available."];
    }
    
    return _masterSaveContext;
}

+ (nonnull CdManagedObjectContext *)newBackgroundContext {
    CdManagedObjectContext *newContext = [[CdManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    newContext.parentContext = _masterSaveContext;
    newContext.undoManager = nil;
    return newContext;
}


+ (void)saveMasterWriteContext:(NSError * _Nullable * _Nullable)error {
    if (!_masterSaveContext) {
        return;
    }
    
    __block NSError *internalError = nil;
    
    [_masterSaveContext performBlockAndWait:^{
        if (!_masterSaveContext.hasChanges) {
            return;
        }
        
        [_masterSaveContext obtainPermanentIDsForObjects:_masterSaveContext.insertedObjects.allObjects error:&internalError];
        
        if (internalError) {
            return;
        }
        
        [_masterSaveContext save:&internalError];
    }];
    
    if (error) {
        *error = internalError;
    }
}


@end
