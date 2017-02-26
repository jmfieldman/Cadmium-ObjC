//
//  CdFetchRequest.h
//  CadmiumObjC
//
//  Created by Jason Fieldman on 2/26/17.
//  Copyright © 2017 Jason Fieldman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CdManagedObject.h"

@interface CdFetchRequest<T: CdManagedObject*> : NSObject

@property (nonatomic, strong) NSFetchRequest * _Nonnull nsFetchRequest;

- (instancetype)initWithEntityName:(nonnull NSString *)entityName;

@end
