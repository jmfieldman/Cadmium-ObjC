//
//  Cd.h
//  CadmiumObjC
//
//  Created by Jason Fieldman on 2/26/17.
//  Copyright © 2017 Jason Fieldman. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^CdTransactionBlock)();
typedef void (^CdCompletionBlock)(NSError * _Nullable error);

@class CdManagedObjectContext;
@class CdManagedObject;

@interface Cd : NSObject


+ (void)initWithSQLStore:(nonnull NSURL*)momdURL
               sqliteURL:(nonnull NSURL*)sqliteURL
                 options:(nullable NSDictionary*)options;

+ (void)initWithSQLStore:(nonnull NSURL*)momdURL
               sqliteURL:(nonnull NSURL*)sqliteURL
                 options:(nullable NSDictionary*)options
                serialTX:(BOOL)serialTX;

+ (void)initWithMomd:(nonnull NSString*)momdName
            bundleID:(nullable NSString*)bundleID
      sqliteFilename:(nonnull NSString*)sqliteFilename
             options:(nullable NSDictionary *)options
            serialTX:(BOOL)serialTX;

+ (void)transact:(nonnull CdTransactionBlock)block;
+ (void)transact:(nonnull CdTransactionBlock)block completion:(nullable CdCompletionBlock)completion;
+ (void)transactOnQueue:(nonnull dispatch_queue_t)queue block:(nonnull CdTransactionBlock)block completion:(nullable CdCompletionBlock)completion;
+ (nullable NSError *)transactAndWait:(nonnull CdTransactionBlock)block;
+ (nullable NSError *)transactAndWaitOnQueue:(nonnull dispatch_queue_t)queue block:(nonnull CdTransactionBlock)block;

+ (void)cancelImplicitCommit;
+ (nonnull CdManagedObjectContext *)transactionContext;
+ (nullable NSError *)commit;

+ (void)destroyBatch:(nonnull NSArray<CdManagedObject *> *)objects;

@end
