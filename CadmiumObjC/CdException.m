//
//  CdException.m
//  CadmiumObjC
//
//  Created by Jason Fieldman on 2/26/17.
//  Copyright © 2017 Jason Fieldman. All rights reserved.
//

#import "CdException.h"

@implementation CdException

+ (void)raiseWithFormat:(NSString*)format, ... {
    NSString *nameString = NSStringFromClass([self class]);
    
    va_list args;
    va_start(args, format);
    NSString *reasonString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    NSException *exp = [self exceptionWithName:nameString reason:reasonString userInfo:nil];
    [exp raise];
}

@end

@implementation CdInvalidMOMDException
@end

@implementation CdPersistentStoreError
@end

@implementation CdMainThreadAssertion
@end

