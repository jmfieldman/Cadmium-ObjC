//
//  CdException.h
//  CadmiumObjC
//
//  Created by Jason Fieldman on 2/26/17.
//  Copyright © 2017 Jason Fieldman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CdException : NSException
+ (void)raiseWithFormat:(NSString*)format, ...;
@end

@interface CdInvalidMOMDException : CdException
@end

@interface CdPersistentStoreError : CdException
@end

@interface CdMainThreadAssertion : CdException
@end
