//
//  NSThread+Cadmium.m
//  CadmiumObjC
//
//  Created by Jason Fieldman on 2/26/17.
//  Copyright © 2017 Jason Fieldman. All rights reserved.
//

#import "NSThread+Cadmium.h"
#import "CdInternal.h"
#import "CdException.h"

static NSString * const kCdThreadPropertyCurrentContext = @"kCdThreadPropertyCurrentContext";
static NSString * const kCdThreadPropertyNoImplicitSave = @"kCdThreadPropertyNoImplicitSave";
static NSString * const kCdThreadPropertyMainSaveNotif  = @"kCdThreadPropertyMainSaveNotif";
static NSString * const kCdThreadPropertyInsideTrans    = @"kCdThreadPropertyInsideTrans";


@implementation NSThread (Internal)

- (nullable CdManagedObjectContext *)attachedContext {
    if (self.isMainThread) {
        return [CdManagedObjectContext mainThreadContext];
    }
    return self.threadDictionary[kCdThreadPropertyCurrentContext];
}

- (void)setAttachedContext:(nullable CdManagedObjectContext *)attachedContext {
    if (self.isMainThread) {
        [CdException raiseWithFormat:@"You cannot explicitly attach a context from the main thread."];
    }
    self.threadDictionary[kCdThreadPropertyCurrentContext] = attachedContext;
}

- (BOOL)noImplicitCommit {
    return [self.threadDictionary[kCdThreadPropertyNoImplicitSave] boolValue];
}

- (void)setNoImplicitCommit:(BOOL)noImplicitCommit {
    self.threadDictionary[kCdThreadPropertyNoImplicitSave] = @(noImplicitCommit);
}

- (BOOL)insideMainThreadChangeNotification {
    return [self.threadDictionary[kCdThreadPropertyMainSaveNotif] boolValue];
}

- (void)setInsideMainThreadChangeNotification:(BOOL)insideMainThreadChangeNotification {
    self.threadDictionary[kCdThreadPropertyMainSaveNotif] = @(insideMainThreadChangeNotification);
}

- (BOOL)insideTransaction {
    return [self.threadDictionary[kCdThreadPropertyInsideTrans] boolValue];
}

- (void)setInsideTransaction:(BOOL)insideTransaction {
    self.threadDictionary[kCdThreadPropertyInsideTrans] = @(insideTransaction);
}

@end
