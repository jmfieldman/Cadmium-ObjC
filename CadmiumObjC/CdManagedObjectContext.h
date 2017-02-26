//
//  CdManagedObjectContext.h
//  CadmiumObjC
//
//  Created by Jason Fieldman on 2/26/17.
//  Copyright © 2017 Jason Fieldman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CdManagedObjectContext : NSManagedObjectContext

+ (void)initializeMasterContexts:(NSPersistentStoreCoordinator * _Nonnull)coordinator;

@end
