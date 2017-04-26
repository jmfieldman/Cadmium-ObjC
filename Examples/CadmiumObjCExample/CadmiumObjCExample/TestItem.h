//
//  TestItem.h
//  CadmiumObjCExample
//
//  Created by Jason Fieldman on 4/26/17.
//  Copyright © 2017 Jason Fieldman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CdManagedObject.h"

@interface TestItem : CdManagedObject

@property (nullable, nonatomic, copy) NSString *title;
@property (nonatomic) int64_t clicks;
    
@end
