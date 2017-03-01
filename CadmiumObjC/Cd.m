//
//  Cd.m
//  CadmiumObjC
//
//  Created by Jason Fieldman on 2/26/17.
//  Copyright © 2017 Jason Fieldman. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "Cd.h"
#import "CdInternal.h"
#import "CdException.h"
#import "CdManagedObjectContext.h"
#import "NSThread+Cadmium.h"

BOOL s_cadmium_defaultSerialTransactions = YES;

@implementation Cd

+ (void)initWithSQLStore:(nonnull NSURL*)momdURL
               sqliteURL:(nonnull NSURL*)sqliteURL
                 options:(nullable NSDictionary*)options {

    NSManagedObjectModel *momd = [[NSManagedObjectModel alloc] initWithContentsOfURL:momdURL];
    if (!momd) {
        [CdInvalidMOMDException raiseWithFormat:@"Invalid MOMD"];
    }
    
    NSError *error = nil;
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:momd];
    
    if (!psc) {
        [CdPersistentStoreError raiseWithFormat:@"Persistent store is nil"];
    }
    
    [psc addPersistentStoreWithType:NSSQLiteStoreType
                      configuration:nil
                                URL:sqliteURL
                            options:options
                              error:&error];
    
    if (error) {
        [CdPersistentStoreError raiseWithFormat:@"Persistent store error: %@", error];
    }
    
    [CdManagedObjectContext initializeMasterContexts:psc];
}

+ (void)initWithSQLStore:(nonnull NSURL*)momdURL
               sqliteURL:(nonnull NSURL*)sqliteURL
                 options:(nullable NSDictionary*)options
                serialTX:(BOOL)serialTX {
    
    s_cadmium_defaultSerialTransactions = serialTX;
    
    [Cd initWithSQLStore:momdURL
               sqliteURL:sqliteURL
                 options:options];
    
    
}

+ (void)initWithMomd:(nonnull NSString*)momdName
            bundleID:(nullable NSString*)bundleID
      sqliteFilename:(nonnull NSString*)sqliteFilename
             options:(nullable NSDictionary *)options
            serialTX:(BOOL)serialTX {
    
    NSBundle *bundle = (bundleID == nil)
                       ? [NSBundle mainBundle]
                       : [NSBundle bundleWithIdentifier:bundleID];
    
    if (!bundle) {
        [CdInvalidBundleException raiseWithFormat:@"Invalid bundle ID: %@", bundleID];
    }
    
    NSString *actualMomd = momdName;
    if ([[actualMomd pathExtension] isEqualToString:@"momd"]) {
        actualMomd = [actualMomd stringByDeletingPathExtension];
    }
    
    NSURL *momdUrl = [bundle URLForResource:actualMomd withExtension:@"momd"];
    if (!momdUrl) {
        [CdInvalidMOMDException raiseWithFormat:@"Could not create momd url: %@", momdName];
    }
    
    NSArray<NSURL *> *urls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *docDir = urls[0];
    NSURL *sqlDir = [docDir URLByAppendingPathComponent:sqliteFilename];
    
    [[NSFileManager defaultManager] createDirectoryAtURL:docDir withIntermediateDirectories:YES attributes:nil error:nil];
    [Cd initWithSQLStore:momdUrl sqliteURL:sqlDir options:options serialTX:serialTX];
}



+ (void)transact:(nonnull CdTransactionBlock)block {
    [Cd transact:block completion:nil];
}

+ (void)transact:(nonnull CdTransactionBlock)block completion:(nullable CdCompletionBlock)completion {
    dispatch_queue_t queue = s_cadmium_defaultSerialTransactions
                             ? CdManagedObjectContext.serialTransactionQueue
                             : CdManagedObjectContext.concurrentTransactionQueue;
    [Cd transactOnQueue:queue block:block completion:completion];
}

+ (void)transactOnQueue:(nonnull dispatch_queue_t)queue block:(nonnull CdTransactionBlock)block completion:(nullable CdCompletionBlock)completion {
    dispatch_async(queue, ^{
        CdManagedObjectContext *newContext = [CdManagedObjectContext newBackgroundContext];
        __block NSError *error = nil;
        [newContext performBlockAndWait:^{
            NSThread *currentThread = NSThread.currentThread;
            BOOL prevInside = currentThread.insideTransaction;
            currentThread.insideTransaction = YES;
            error = [Cd _transactOperationFromContext:newContext operation:block];
            currentThread.insideTransaction = prevInside;
        }];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(error);
            });
        }
    });
}

+ (nullable NSError *)transactAndWait:(nonnull CdTransactionBlock)block {
    return [Cd transactAndWaitOnQueue:nil block:block];
}

+ (nullable NSError *)transactAndWaitOnQueue:(nullable dispatch_queue_t)queue block:(nonnull CdTransactionBlock)block {
    NSThread *currentThread = NSThread.currentThread;
    if (currentThread.isMainThread) {
        [CdMainThreadAssertion raiseWithFormat:@"You cannot perform transactAndWait on the main thread.  Use transact, or spin off a new background thread to call transactAndWait"];
    }
    
    // Ensure queue
    if (queue == nil) {
        queue = s_cadmium_defaultSerialTransactions
                ? CdManagedObjectContext.serialTransactionQueue
                : CdManagedObjectContext.concurrentTransactionQueue;
    }
    
    // Protect against running synchronously inside existing serial queue
    if (queue == CdManagedObjectContext.serialTransactionQueue && currentThread.insideTransaction) {
        queue = CdManagedObjectContext.concurrentTransactionQueue;
    }
    
    __block NSError *error = nil;
    
    dispatch_sync(queue, ^{
        CdManagedObjectContext *newContext = [CdManagedObjectContext newBackgroundContext];
        [newContext performBlockAndWait:^{
            NSThread *currentThread = NSThread.currentThread;
            BOOL prevInside = currentThread.insideTransaction;
            currentThread.insideTransaction = YES;
            error = [Cd _transactOperationFromContext:newContext operation:block];
            currentThread.insideTransaction = prevInside;
        }];
    });
    
    return error;
}





+ (nullable NSError *)_transactOperationFromContext:(nonnull CdManagedObjectContext *)fromContext
                                          operation:(nonnull CdTransactionBlock)block {
    
    NSThread *currentThread = NSThread.currentThread;
    CdManagedObjectContext *attachedContext = currentThread.attachedContext;
    BOOL origNoImplicitCommit = currentThread.noImplicitCommit;
    
    currentThread.attachedContext = fromContext;
    block();
    
    NSError *error = nil;
    if (currentThread.noImplicitCommit == NO) {
        error = [Cd commit];
    }
    
    currentThread.attachedContext = attachedContext;
    currentThread.noImplicitCommit = origNoImplicitCommit;
    
    return error;
}


+ (void)cancelImplicitCommit {
    NSThread *currentThread = NSThread.currentThread;
    if (currentThread.isMainThread) {
        [CdMainThreadAssertion raiseWithFormat:@"The main thread does have a transaction context that can be committed."];
    }
    
    if (!currentThread.attachedContext) {
        [CdException raiseWithFormat:@"You many only cancel a commit from inside a valid transaction."];
    }
    
    currentThread.noImplicitCommit = YES;
}


+ (nonnull CdManagedObjectContext *)transactionContext {
    NSThread *currentThread = NSThread.currentThread;
    if (currentThread.isMainThread) {
        [CdMainThreadAssertion raiseWithFormat:@"The main thread cannot have a valid transaction context."];
    }
    
    CdManagedObjectContext *currentContext = currentThread.attachedContext;
    if (!currentContext) {
        [CdException raiseWithFormat:@"transactionContext is only valid from inside a valid transaction."];
    }
    
    return currentContext;
}


+ (nullable NSError *)commit {
    NSThread *currentThread = NSThread.currentThread;
    if (currentThread.isMainThread) {
        [CdMainThreadAssertion raiseWithFormat:@"You can only commit changes inside of a transaction (the main thread is read-only)."];
    }
    
    CdManagedObjectContext *currentContext = currentThread.attachedContext;
    if (!currentContext) {
        [CdException raiseWithFormat:@"You can only commit changes inside of a transaction."];
    }
    
    NSError *error = nil;
    if (currentContext.hasChanges) {
        [currentContext save:&error];
        
        if (error) {
            return error;
        }
        
        [CdManagedObjectContext saveMasterWriteContext:&error];
        
        if (error) {
            return error;
        }
    }
    
    return nil;
}


+ (void)destroyBatch:(nonnull NSArray<CdManagedObject *> *)objects {
    NSThread *currentThread = NSThread.currentThread;
    if (currentThread.isMainThread) {
        [CdMainThreadAssertion raiseWithFormat:@"You cannot delete an object from the main thread."];
    }
    
    CdManagedObjectContext *currentContext = currentThread.attachedContext;
    if (!currentContext) {
        [CdException raiseWithFormat:@"You may only delete a managed object from inside a transaction."];
    }
    
    for (CdManagedObject *object in objects) {
        if (currentContext != object.managedObjectContext) {
            [CdException raiseWithFormat:@"You may only delete a managed object from inside the transaction it belongs to."];
        }
        
        if (object.managedObjectContext == nil) {
            [CdException raiseWithFormat:@"You cannot delete an object that is not in a context."];
        }
        
        [currentContext deleteObject:object];
    }
}


@end
