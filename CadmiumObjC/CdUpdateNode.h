//
//  CdUpdateNode.h
//  CadmiumObjC
//
//  Created by Jason Fieldman on 2/26/17.
//  Copyright © 2017 Jason Fieldman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CdManagedObject.h"

@interface CdUpdateNode : NSObject

@property (nonatomic, strong) CdManagedObjectUpdateHandler _Nonnull handler;
@property (nonatomic, weak) id _Nullable anchor;

- (nonnull instancetype)initWithHandler:(nonnull CdManagedObjectUpdateHandler)handler anchor:(nonnull id)anchor;
- (nonnull instancetype)initWithHandler:(nonnull CdManagedObjectUpdateHandler)handler;

- (BOOL)isAnchored;

@end
