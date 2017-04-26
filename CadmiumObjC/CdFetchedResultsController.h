//
//  CdFetchedResultsController.h
//  CadmiumObjC
//
//  Created by Jason Fieldman on 4/26/17.
//  Copyright © 2017 Jason Fieldman. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "CdFetchRequest.h"

@interface CdFetchedResultsController : NSFetchedResultsController

- (instancetype)initWithFetchRequest:(CdFetchRequest *)fetchRequest sectionNameKeyPath:(NSString *)sectionNameKeyPath cacheName:(NSString *)name;

@end
