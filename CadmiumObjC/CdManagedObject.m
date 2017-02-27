//
//  CdManagedObject.m
//  CadmiumObjC
//
//  Created by Jason Fieldman on 2/26/17.
//  Copyright © 2017 Jason Fieldman. All rights reserved.
//

#import "CdManagedObject.h"
#import "CdUpdateNode.h"
#import "CdException.h"
#import "CdInternal.h"
#import "CdFetchRequest.h"
#import "NSThread+Cadmium.h"

@implementation CdManagedObject {
    NSMutableSet<CdUpdateNode *> *_updateNodes;
}

- (void)addUpdateHandler:(nonnull CdManagedObjectUpdateHandler)handler anchor:(id)anchor {
    CdAssertMainThread();
    if (!_updateNodes) {
        _updateNodes = [NSMutableSet set];
    }
    [_updateNodes addObject:[[CdUpdateNode alloc] initWithHandler:handler anchor:anchor]];
}

- (void)addUpdateHandler:(nonnull CdManagedObjectUpdateHandler)handler {
    CdAssertMainThread();
    if (!_updateNodes) {
        _updateNodes = [NSMutableSet set];
    }
    [_updateNodes addObject:[[CdUpdateNode alloc] initWithHandler:handler]];
}

- (void)removeAllUpdateHandlers {
    CdAssertMainThread();
    _updateNodes = nil;
}

- (void)removeUpdateHandlersAnchoredBy:(id)anchor {
    CdAssertMainThread();
    
    if (_updateNodes.count == 0) {
        return;
    }
    
    NSMutableSet<CdUpdateNode *> *newNodes = [_updateNodes mutableCopy];
    
    for (CdUpdateNode *node in _updateNodes) {
        if (node.anchor == anchor) {
            [newNodes removeObject:node];
        }
    }
    
    _updateNodes = newNodes;
}



- (void)willAccessValueForKey:(NSString *)key {
    NSManagedObjectContext *myManangedObjectContext = self.managedObjectContext;
    if (!myManangedObjectContext) {
        [super willAccessValueForKey:key];
        return;
    }
    
    if (myManangedObjectContext == CdManagedObjectContext.masterSaveContext) {
        [super willAccessValueForKey:key];
        return;
    }
    
    NSThread *currentThread = NSThread.currentThread;
    CdManagedObjectContext *currentContext = currentThread.attachedContext;
    if (myManangedObjectContext != currentContext) {
        if (myManangedObjectContext == CdManagedObjectContext.mainThreadContext) {
            [CdException raiseWithFormat:@"You cannot access a managed object from the main thread context on a background thread."];
        } else if (currentThread.attachedContext == nil) {
            [CdException raiseWithFormat:@"You cannot access a managed object from a thread that does not have a managed object context."];
        } else if (currentThread.attachedContext == CdManagedObjectContext.mainThreadContext) {
            [CdMainThreadAssertion raiseWithFormat:@"You cannot access a managed object from a background transaction on the main thread."];
        } else {
            [CdException raiseWithFormat:@"You cannot access a managed object from a background transaction outside of its transaction."];
        }
    }
    
    [super willAccessValueForKey:key];
}


- (void)willChangeValueForKey:(NSString *)key {
    NSManagedObjectContext *myManangedObjectContext = self.managedObjectContext;
    if (!myManangedObjectContext) {
        [super willChangeValueForKey:key];
        return;
    }
    
    NSThread *currentThread = NSThread.currentThread;
    if (currentThread.isMainThread && !currentThread.insideMainThreadChangeNotification) {
        [CdMainThreadAssertion raiseWithFormat:@"You cannot modify a managed object on the main thread.  Only from inside a transaction."];
    }
    
    if (myManangedObjectContext == CdManagedObjectContext.masterSaveContext) {
        [super willChangeValueForKey:key];
        return;
    }
    
    CdManagedObjectContext *currentContext = currentThread.attachedContext;
    if (myManangedObjectContext != currentContext) {
        if (currentThread.attachedContext == nil) {
            [CdException raiseWithFormat:@"You cannot modify a managed object from a thread that does not have a managed object context."];
        } else {
            [CdException raiseWithFormat:@"You cannot modify a managed object outside of its original transaction."];
        }
    }
    
    [super willChangeValueForKey:key];
}


- (void)willChangeValueForKey:(NSString *)inKey withSetMutation:(NSKeyValueSetMutationKind)inMutationKind usingObjects:(NSSet *)inObjects {
    NSManagedObjectContext *myManangedObjectContext = self.managedObjectContext;
    if (!myManangedObjectContext) {
        [super willChangeValueForKey:inKey withSetMutation:inMutationKind usingObjects:inObjects];
        return;
    }
    
    NSThread *currentThread = NSThread.currentThread;
    if (currentThread.isMainThread && !currentThread.insideMainThreadChangeNotification) {
        [CdException raiseWithFormat:@"You cannot modify a managed object on the main thread.  Only from inside a transaction."];
    }
    
    if (myManangedObjectContext == CdManagedObjectContext.masterSaveContext) {
        [super willChangeValueForKey:inKey withSetMutation:inMutationKind usingObjects:inObjects];
        return;
    }
    
    CdManagedObjectContext *currentContext = currentThread.attachedContext;
    if (myManangedObjectContext != currentContext) {
        if (currentThread.attachedContext == nil) {
            [CdException raiseWithFormat:@"You cannot modify a managed object from a thread that does not have a managed object context."];
        } else {
            [CdException raiseWithFormat:@"You cannot modify a managed object outside of its original transaction."];
        }
    }
    
    for (CdManagedObject *object in inObjects) {
        if (object.managedObjectContext != myManangedObjectContext) {
            [CdException raiseWithFormat:@"You are attempting to create a relationship between objects from different contexts."];
        }
    }
    
    [super willChangeValueForKey:inKey withSetMutation:inMutationKind usingObjects:inObjects];
}



+ (nonnull CdFetchRequest *)query {
    return [[CdFetchRequest alloc] initWithEntityName:NSStringFromClass([self class])];
}

+ (nonnull CdFetchRequest *)queryWith:(nonnull CdManagedObjectQueryConfig)config {
    CdFetchRequest *request = [[CdFetchRequest alloc] initWithEntityName:self._entityName];
    config(request);
    return request;
}

+ (nonnull NSString *)_entityName {
    return NSStringFromClass([self class]);
}

+ (nonnull instancetype)create {
    NSThread *currentThread = NSThread.currentThread;
    if (currentThread.isMainThread) {
        [CdMainThreadAssertion raiseWithFormat:@"You cannot create a non-transient object in the main thread."];
    }
    
    CdManagedObjectContext *currentContext = currentThread.attachedContext;
    if (!currentContext) {
        [CdCreateException raiseWithFormat:@"You may only create a new managed object from inside a valid transaction."];
    }
    
    NSEntityDescription *desc = [NSEntityDescription entityForName:self._entityName inManagedObjectContext:currentContext];
    
    CdManagedObject *object = [[CdManagedObject alloc] initWithEntity:desc insertIntoManagedObjectContext:currentContext];
    
    NSError *error;
    [currentContext obtainPermanentIDsForObjects:@[object] error:&error];
    
    if (error) {
        [CdCreateException raiseWithFormat:@"Could not obtain ID for object: %@", error];
    }
    
    return object;
}

+ (nonnull instancetype)createTransient {
    NSEntityDescription *desc = [NSEntityDescription entityForName:self._entityName
                                            inManagedObjectContext:[CdManagedObjectContext mainThreadContext]];
    
    return [[CdManagedObject alloc] initWithEntity:desc insertIntoManagedObjectContext:nil];
}

+ (nonnull NSArray *)createBatch:(NSUInteger)quantity {
    NSThread *currentThread = NSThread.currentThread;
    if (currentThread.isMainThread) {
        [CdMainThreadAssertion raiseWithFormat:@"You cannot create a non-transient object in the main thread."];
    }
    
    CdManagedObjectContext *currentContext = currentThread.attachedContext;
    if (!currentContext) {
        [CdCreateException raiseWithFormat:@"You may only create a new managed object from inside a valid transaction."];
    }
    
    NSEntityDescription *desc = [NSEntityDescription entityForName:self._entityName inManagedObjectContext:currentContext];
    
    NSMutableArray *objects = [NSMutableArray arrayWithCapacity:quantity];
    
    for (NSUInteger i = quantity; i > 0; i++) {
        CdManagedObject *object = [[CdManagedObject alloc] initWithEntity:desc insertIntoManagedObjectContext:currentContext];
        [objects addObject:object];
    }
    
    NSError *error;
    [currentContext obtainPermanentIDsForObjects:objects error:&error];
    
    if (error) {
        [CdCreateException raiseWithFormat:@"Could not obtain IDs for objects: %@", error];
    }
    
    return objects;
}


- (nullable instancetype)cloneForCurrentContext:(NSError * _Nullable * _Nullable)error {
    CdManagedObjectContext *currentContext = NSThread.currentThread.attachedContext;
    if (!currentContext) {
        [CdException raiseWithFormat:@"You may only call useInCurrentContext from the main thread, or inside a valid transaction."];
    }
    
    NSManagedObjectContext *originalContext = self.managedObjectContext;
    if (originalContext.hasChanges && originalContext != CdManagedObjectContext.mainThreadContext) {
        [CdException raiseWithFormat:@"You cannot transfer an object from a context that has pending changes.  Make sure you call [Cd commit] from your transaction first."];
    }
    
    if (self.objectID.isTemporaryID) {
        [CdException raiseWithFormat:@"You cannot transfer an object without a permanent object ID.  This object may be transient or unsaved in its current context."];
    }
    
    NSError *internalError = nil;
    CdManagedObject *clone = [currentContext existingObjectWithID:self.objectID error:&internalError];
    
    if (error) {
        *error = internalError;
    }
    
    if (clone) {
        [currentContext refreshObject:clone mergeChanges:YES];
        return clone;
    }
    
    return nil;
}

- (void)transact:(nonnull CdObjectTransactionBlock)block {
    [self transact:block completion:nil];
}

- (void)transact:(nonnull CdObjectTransactionBlock)block completion:(nullable CdCompletionBlock)completion {
    dispatch_queue_t queue = s_cadmium_defaultSerialTransactions
                             ? CdManagedObjectContext.serialTransactionQueue
                             : CdManagedObjectContext.concurrentTransactionQueue;
    [self transactOnQueue:queue block:block completion:completion];
}

- (void)transactOnQueue:(nonnull dispatch_queue_t)queue block:(nonnull CdObjectTransactionBlock)block completion:(nullable CdCompletionBlock)completion {
    [Cd transactOnQueue:queue block:^{
        NSError *internalError = nil;
        CdManagedObject *clone = [self cloneForCurrentContext:&internalError];
        block(clone, internalError);
    } completion:completion];
}

- (nullable NSError *)transactAndWait:(nonnull CdObjectTransactionBlock)block {
    dispatch_queue_t queue = s_cadmium_defaultSerialTransactions
                             ? CdManagedObjectContext.serialTransactionQueue
                             : CdManagedObjectContext.concurrentTransactionQueue;
    return [self transactAndWaitOnQueue:queue block:block];
}

- (nullable NSError *)transactAndWaitOnQueue:(nonnull dispatch_queue_t)queue block:(nonnull CdObjectTransactionBlock)block {
    
    return [Cd transactAndWaitOnQueue:queue block:^{
        NSError *internalError = nil;
        CdManagedObject *clone = [self cloneForCurrentContext:&internalError];
        block(clone, internalError);
    }];
}



@end



@implementation CdManagedObject (Internal)

- (void)notifyUpdateHandlers:(CdManagedObjectUpdateEvent)event {
    CdAssertMainThread();
    BOOL needsCleaning = NO;
    for (CdUpdateNode *node in _updateNodes) {
        if (node.anchor == nil) {
            needsCleaning = YES;
        } else {
            node.handler(event);
        }
    }
    
    if (needsCleaning) {
        [self removeUpdateHandlersAnchoredBy:nil];
    }
}

@end
