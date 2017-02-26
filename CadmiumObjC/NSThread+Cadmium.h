//
//  NSThread+Cadmium.h
//  CadmiumObjC
//
//  Created by Jason Fieldman on 2/26/17.
//  Copyright © 2017 Jason Fieldman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CdManagedObjectContext.h"

@interface NSThread (Internal)

@property (nonatomic, assign) CdManagedObjectContext * _Nullable attachedContext;
@property (nonatomic, assign) BOOL noImplicitCommit;
@property (nonatomic, assign) BOOL insideMainThreadChangeNotification;
@property (nonatomic, assign) BOOL insideTransaction;

@end
