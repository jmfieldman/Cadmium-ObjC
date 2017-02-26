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

static BOOL s_defaultSerialTransactions = YES;

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
    
    s_defaultSerialTransactions = serialTX;
    
    [Cd initWithSQLStore:momdURL
               sqliteURL:sqliteURL
                 options:options];
    
    
}


@end
