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
