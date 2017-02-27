//
//  CdFetchRequest.m
//  CadmiumObjC
//
//  Created by Jason Fieldman on 2/26/17.
//  Copyright © 2017 Jason Fieldman. All rights reserved.
//

#import "CdFetchRequest.h"
#import "CdManagedObjectContext.h"
#import "NSThread+Cadmium.h"
#import "CdException.h"

@implementation CdFetchRequest {
    NSMutableDictionary<NSString *, NSExpressionDescription *> *_includedExpressions;
    NSMutableSet<NSString *> *_includedProperties;
    NSMutableArray<NSString *> *_includedGroupings;
}


- (nonnull instancetype)initWithEntityName:(nonnull NSString *)entityName; {
    if ((self = [super init])) {
        _nsFetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
    }
    return self;
}


- (void)filterWithPredicate:(nonnull NSPredicate *)predicate {
    if (_nsFetchRequest.predicate) {
        _nsFetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[_nsFetchRequest.predicate, predicate]];
    } else {
        _nsFetchRequest.predicate = predicate;
    }
}

- (void)filterWithFormat:(nonnull NSString * const)format, ... {
    va_list args;
    va_start(args, format);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:format arguments:args];
    va_end(args);
    [self filterWithPredicate:predicate];
}

- (void)orWithPredicate:(nonnull NSPredicate *)predicate {
    if (_nsFetchRequest.predicate) {
        _nsFetchRequest.predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[_nsFetchRequest.predicate, predicate]];
    } else {
        _nsFetchRequest.predicate = predicate;
    }
}

- (void)orWithFormat:(nonnull NSString * const)format, ... {
    va_list args;
    va_start(args, format);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:format arguments:args];
    va_end(args);
    [self orWithPredicate:predicate];
}

- (void)sortByProperty:(nonnull NSString *)property {
    [self sortByProperty:property ascending:YES];
}

- (void)sortByProperty:(nonnull NSString *)property ascending:(BOOL)ascending {
    [self sortByDescriptor:[[NSSortDescriptor alloc] initWithKey:property ascending:ascending]];
}

- (void)sortByDescriptor:(nonnull NSSortDescriptor *)descriptor {
    if (_nsFetchRequest.sortDescriptors == nil) {
        _nsFetchRequest.sortDescriptors = @[descriptor];
    } else {
        NSMutableArray *array = [_nsFetchRequest.sortDescriptors mutableCopy];
        [array addObject:descriptor];
        _nsFetchRequest.sortDescriptors = array;
    }
}


- (void)includeExpressionNamed:(nonnull NSString *)name resultType:(NSAttributeType)type format:(nonnull NSString * const)format, ... {
    va_list args;
    va_start(args, format);
    NSExpression *expression = [NSExpression expressionWithFormat:format arguments:args];
    va_end(args);
    
    NSExpressionDescription *description = [[NSExpressionDescription alloc] init];
    description.expression = expression;
    description.name = name;
    description.expressionResultType = type;
    
    if (!_includedExpressions) {
        _includedExpressions = [NSMutableDictionary dictionary];
    }
    
    _includedExpressions[name] = description;
}

- (void)onlyProperties:(nonnull NSArray<NSString *> *)properties {
    if (!_includedProperties) {
        _includedProperties = [NSMutableSet setWithArray:properties];
    } else {
        [_includedProperties addObjectsFromArray:properties];
    }
}

- (void)groupBy:(nonnull NSArray<NSString *> *)properties {
    if (!_includedGroupings) {
        _includedGroupings = [NSMutableArray arrayWithArray:properties];
    } else {
        [_includedGroupings addObjectsFromArray:properties];
    }
}

- (void)setLimit:(NSUInteger)limit {
    _nsFetchRequest.fetchLimit = limit;
}

- (void)setOffset:(NSUInteger)offset {
    _nsFetchRequest.fetchOffset = offset;
}

- (void)setBatchSize:(NSUInteger)batchSize {
    _nsFetchRequest.fetchBatchSize = batchSize;
}

- (void)setDistinctResults:(BOOL)distinctResults {
    _nsFetchRequest.returnsDistinctResults = distinctResults;
}

- (void)prefetchRelationships:(nonnull NSArray<NSString *> *)relationships {
    _nsFetchRequest.relationshipKeyPathsForPrefetching = relationships;
}




- (nullable NSArray *)fetch:(NSError * _Nullable * _Nullable)error {
    CdManagedObjectContext *currentContext = NSThread.currentThread.attachedContext;
    if (!currentContext) {
        [CdFetchException raiseWithFormat:@"You cannot fetch data from a non-transactional background thread.  You may only query from the main thread or from inside a transaction."];
    }
    
    if (_includedProperties.count > 0) {
        _nsFetchRequest.propertiesToFetch = _includedProperties.allObjects;
    }
    
    if (_includedExpressions.count > 0) {
        [CdFetchException raiseWithFormat:@"You cannot call fetch if you have included custom expressions.  Use fetchDictionaryArray."];
    }
    
    if (_includedGroupings.count > 0) {
        [CdFetchException raiseWithFormat:@"You cannot call fetch if you have included custom groupings.  Use fetchDictionaryArray."];
    }
    
    NSError *internalError = nil;
    NSArray *results = [currentContext executeFetchRequest:_nsFetchRequest error:&internalError];
    
    if (internalError) {
        *error = internalError;
    }
    
    return results;
}

- (nullable NSArray<NSDictionary *> *)fetchDictionaryArray:(NSError * _Nullable * _Nullable)error {
    CdManagedObjectContext *currentContext = NSThread.currentThread.attachedContext;
    if (!currentContext) {
        [CdFetchException raiseWithFormat:@"You cannot fetch data from a non-transactional background thread.  You may only query from the main thread or from inside a transaction."];
    }
    
    _nsFetchRequest.resultType = NSDictionaryResultType;
    
    if (_includedProperties.count > 0) {
        NSMutableArray *actualProperties = [NSMutableArray array];
        for (NSString *propertyName in _includedProperties) {
            if (_includedExpressions[propertyName]) {
                [actualProperties addObject:_includedExpressions[propertyName]];
            } else {
                [actualProperties addObject:propertyName];
            }
        }
        _nsFetchRequest.propertiesToFetch = actualProperties;
    }
    
    if (_includedGroupings.count > 0) {
        for (NSString *groupName in _includedGroupings) {
            if (![_includedProperties containsObject:groupName]) {
                [CdFetchException raiseWithFormat:@"You cannot group by a property name unless you've included it in onlyProperties"];
            }
        }
        _nsFetchRequest.propertiesToGroupBy = _includedGroupings;
    }
    
    NSError *internalError = nil;
    NSArray *results = [currentContext executeFetchRequest:_nsFetchRequest error:&internalError];
    
    if (internalError) {
        *error = internalError;
    }
    
    return results;
}

- (nullable id)fetchOne:(NSError * _Nullable * _Nullable)error {
    _nsFetchRequest.fetchLimit = 1;
    NSArray *result = [self fetch:error];
    if (result.count > 0) {
        return result[0];
    }
    return nil;
}

- (NSUInteger)count:(NSError * _Nullable * _Nullable)error {
    CdManagedObjectContext *currentContext = NSThread.currentThread.attachedContext;
    if (!currentContext) {
        [CdFetchException raiseWithFormat:@"You cannot fetch data from a non-transactional background thread.  You may only query from the main thread or from inside a transaction."];
    }
    
    NSError *internalError = nil;
    NSUInteger result = [currentContext countForFetchRequest:_nsFetchRequest error:&internalError];
    
    if (internalError) {
        *error = internalError;
    }
    
    return result;
}



@end
