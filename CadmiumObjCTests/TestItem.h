//
//  TestItem.h
//  CadmiumObjC
//
//  Created by Jason Fieldman on 2/26/17.
//  Copyright © 2017 Jason Fieldman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CdManagedObject.h"

@interface TestItem : CdManagedObject

@property (nonatomic, assign) int64_t objId;
@property (nonatomic, strong) NSString * _Nonnull name;

@end
