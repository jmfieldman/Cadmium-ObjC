//
//  CdFetchedResultsController.m
//  CadmiumObjC
//
//  Created by Jason Fieldman on 4/26/17.
//  Copyright © 2017 Jason Fieldman. All rights reserved.
//

#import "CdFetchedResultsController.h"
#import "CdInternal.h"

@implementation CdFetchedResultsController

- (instancetype)initWithFetchRequest:(CdFetchRequest *)fetchRequest sectionNameKeyPath:(NSString *)sectionNameKeyPath cacheName:(NSString *)name {
    return [super initWithFetchRequest:fetchRequest.nsFetchRequest
                  managedObjectContext:[CdManagedObjectContext mainThreadContext]
                    sectionNameKeyPath:sectionNameKeyPath
                             cacheName:name];
}

@end
