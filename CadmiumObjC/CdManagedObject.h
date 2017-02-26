//
//  CdManagedObject.h
//  CadmiumObjC
//
//  Created by Jason Fieldman on 2/26/17.
//  Copyright © 2017 Jason Fieldman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef NS_ENUM(NSInteger, CdManagedObjectUpdateEvent) {
    CdManagedObjectUpdateEventRefreshed,
    CdManagedObjectUpdateEventUpdated,
    CdManagedObjectUpdateEventDeleted,
};

typedef void (^CdManagedObjectUpdateHandler)(CdManagedObjectUpdateEvent);


@interface CdManagedObject : NSManagedObject

- (void)addUpdateHandler:(nonnull CdManagedObjectUpdateHandler)handler anchor:(nonnull id)anchor;
- (void)addUpdateHandler:(nonnull CdManagedObjectUpdateHandler)handler;
- (void)removeAllUpdateHandlers;
- (void)removeUpdateHandlersAnchoredBy:(nullable id)anchor;

@end
