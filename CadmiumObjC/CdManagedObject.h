//
//  CdManagedObject.h
//  CadmiumObjC
//
//  Created by Jason Fieldman on 2/26/17.
//  Copyright © 2017 Jason Fieldman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Cd.h"

typedef NS_ENUM(NSInteger, CdManagedObjectUpdateEvent) {
    CdManagedObjectUpdateEventRefreshed,
    CdManagedObjectUpdateEventUpdated,
    CdManagedObjectUpdateEventDeleted,
};

@class CdFetchRequest;
@class CdManagedObject;

typedef void (^CdManagedObjectUpdateHandler)(CdManagedObjectUpdateEvent);
typedef void (^CdManagedObjectQueryConfig)(CdFetchRequest * _Nonnull config);
typedef void (^CdObjectTransactionBlock)(CdManagedObject * _Nullable clone, NSError * _Nullable error);

@interface CdManagedObject : NSManagedObject

- (void)addUpdateHandler:(nonnull CdManagedObjectUpdateHandler)handler anchor:(nonnull id)anchor;
- (void)addUpdateHandler:(nonnull CdManagedObjectUpdateHandler)handler;
- (void)removeAllUpdateHandlers;
- (void)removeUpdateHandlersAnchoredBy:(nullable id)anchor;

+ (nonnull CdFetchRequest *)query;
+ (nonnull CdFetchRequest *)queryWith:(nonnull CdManagedObjectQueryConfig)config;

+ (nonnull instancetype)create;
+ (nonnull instancetype)createTransient;
+ (nonnull NSArray *)createBatch:(NSUInteger)quantity;

- (nullable instancetype)cloneForCurrentContext:(NSError * _Nullable * _Nullable)error;
- (void)transact:(nonnull CdObjectTransactionBlock)block;
- (void)transact:(nonnull CdObjectTransactionBlock)block completion:(nullable CdCompletionBlock)completion;
- (void)transactOnQueue:(nonnull dispatch_queue_t)queue block:(nonnull CdObjectTransactionBlock)block completion:(nullable CdCompletionBlock)completion;
- (nullable NSError *)transactAndWait:(nonnull CdObjectTransactionBlock)block;
- (nullable NSError *)transactAndWaitOnQueue:(nonnull dispatch_queue_t)queue block:(nonnull CdObjectTransactionBlock)block;

@end
