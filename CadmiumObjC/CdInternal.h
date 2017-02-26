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

@interface CdManagedObjectContext (Internal)

+ (nonnull CdManagedObjectContext *)mainThreadContext;
+ (nonnull CdManagedObjectContext *)masterSaveContext;
+ (nonnull CdManagedObjectContext *)newBackgroundContext;
+ (void)saveMasterWriteContext:(NSError * _Nullable * _Nullable)error;


@end


@interface CdManagedObject (Internal)

- (void)notifyUpdateHandlers:(CdManagedObjectUpdateEvent)event;

@end



#define CdAssertMainThread() do { \
  if (!NSThread.currentThread.isMainThread) { \
    [CdMainThreadAssertion raiseWithFormat:@"CdMainThreadAssertion failed: this may only be called from the main thread."]; \
  } \
} while (0)

#endif /* CdPrivate_h */
