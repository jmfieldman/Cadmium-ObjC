//
//  CdUpdateNode.m
//  CadmiumObjC
//
//  Created by Jason Fieldman on 2/26/17.
//  Copyright © 2017 Jason Fieldman. All rights reserved.
//

#import "CdUpdateNode.h"

__strong static NSString * const kUpdateNodeAnonymousAnchor = @"kUpdateNodeAnonymousAnchor";

@implementation CdUpdateNode

- (nonnull instancetype)initWithHandler:(nonnull CdManagedObjectUpdateHandler)handler anchor:(nonnull id)anchor {
    if ((self = [super init])) {
        _handler = handler;
        _anchor  = anchor;
    }
    return self;
}

- (nonnull instancetype)initWithHandler:(nonnull CdManagedObjectUpdateHandler)handler {
    return [self initWithHandler:handler anchor:kUpdateNodeAnonymousAnchor];
}

- (BOOL)isAnchored {
    return _anchor != nil;
}

@end
