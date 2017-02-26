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
            [CdException raiseWithFormat:@"You cannot access a managed object from a background transaction on the main thread."];
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
        [CdException raiseWithFormat:@"You cannot modify a managed object on the main thread.  Only from inside a transaction."];
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
