//
//  CdPrivate.h
//  CadmiumObjC
//
//  Created by Jason Fieldman on 2/26/17.
//  Copyright © 2017 Jason Fieldman. All rights reserved.
//

#ifndef CdPrivate_h
#define CdPrivate_h

#import "CdManagedObjectContext.h"
#import "CdManagedObject.h"
#import "CdFetchRequest.h"

extern BOOL s_cadmium_defaultSerialTransactions;

@interface CdManagedObjectContext (Internal)

+ (nonnull CdManagedObjectContext *)mainThreadContext;
+ (nonnull CdManagedObjectContext *)masterSaveContext;
+ (nonnull CdManagedObjectContext *)newBackgroundContext;
+ (void)saveMasterWriteContext:(NSError * _Nullable * _Nullable)error;

+ (nonnull dispatch_queue_t)serialTransactionQueue;
+ (nonnull dispatch_queue_t)concurrentTransactionQueue;

@end


@interface CdManagedObject (Internal)

@property (nonatomic, assign) BOOL wasInserted;

- (void)notifyUpdateHandlers:(CdManagedObjectUpdateEvent)event;

@end


@interface CdFetchRequest (Internal)

@end



#define CdAssertMainThread() do { \
  if (!NSThread.currentThread.isMainThread) { \
    [CdMainThreadAssertion raiseWithFormat:@"CdMainThreadAssertion failed: this may only be called from the main thread."]; \
  } \
} while (0)

#endif /* CdPrivate_h */
