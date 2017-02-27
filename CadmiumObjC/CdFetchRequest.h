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

- (nonnull instancetype)initWithEntityName:(nonnull NSString *)entityName;
- (void)filterWithPredicate:(nonnull NSPredicate *)predicate;
- (void)filterWithFormat:(nonnull NSString * const)format, ...;
- (void)orWithPredicate:(nonnull NSPredicate *)predicate;
- (void)orWithFormat:(nonnull NSString * const)format, ...;
- (void)sortByProperty:(nonnull NSString *)property;
- (void)sortByProperty:(nonnull NSString *)property ascending:(BOOL)ascending;
- (void)sortByDescriptor:(nonnull NSSortDescriptor *)descriptor;
- (void)includeExpressionNamed:(nonnull NSString *)name resultType:(NSAttributeType)type format:(nonnull NSString * const)format, ...;
- (void)onlyProperties:(nonnull NSArray<NSString *> *)properties;
- (void)groupBy:(nonnull NSArray<NSString *> *)properties;
- (void)setLimit:(NSUInteger)limit;
- (void)setOffset:(NSUInteger)offset;
- (void)setBatchSize:(NSUInteger)batchSize;
- (void)setDistinctResults:(BOOL)distinctResults;
- (void)prefetchRelationships:(nonnull NSArray<NSString *> *)relationships;

- (nullable NSArray<T> *)fetch:(NSError * _Nullable * _Nullable)error;
- (nullable NSArray<NSDictionary *> *)fetchDictionaryArray:(NSError * _Nullable * _Nullable)error;
- (nullable T)fetchOne:(NSError * _Nullable * _Nullable)error;

@end
