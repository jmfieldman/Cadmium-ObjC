//
//  CadmiumObjCTests.m
//  CadmiumObjCTests
//
//  Created by Jason Fieldman on 2/26/17.
//  Copyright © 2017 Jason Fieldman. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>
#import "Cd.h"
#import "CdFetchRequest.h"
#import "CdException.h"
#import "TestItem.h"

typedef void (^CdExceptionCatchBlock)(void);

@interface CadmiumObjCTests : XCTestCase
@property (atomic, assign) BOOL hasInit;
@end

@implementation CadmiumObjCTests {
    dispatch_queue_t bgQueue;
}

- (nullable CdException *)catchException:(CdExceptionCatchBlock)block {
    @try {
        block();
    }
    @catch (CdException *e) {
        return e;
    }
    return nil;
}

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    bgQueue = dispatch_queue_create("CadmiumTests.backgroundQueue", 0);
    
    [self cleanCd];
    [self initCd];
    [self initData];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

//- (void)testExample {
//    // This is an example of a functional test case.
//    // Use XCTAssert and related functions to verify your tests produce the correct results.
//}
//
//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}


- (void)testBasicQueries {
    NSError *error = nil;
    NSArray<TestItem *> *objs = [[TestItem query:^(CdFetchRequest * _Nonnull config) {
        [config filterWithFormat:@"name = %@", @"C"];
    }] fetch:&error];
    XCTAssertEqual(objs.count, 1, @"Query count equals");
    XCTAssertNil(error, @"Error: %@", error);
    
    objs = [[TestItem query:^(CdFetchRequest * _Nonnull config) {
        [config filterWithFormat:@"name < %@", @"C"];
    }] fetch:&error];
    XCTAssertEqual(objs.count, 2, @"Query count equals");
    XCTAssertNil(error, @"Error: %@", error);
    
    objs = [[TestItem query:^(CdFetchRequest * _Nonnull config) {
        [config filterWithFormat:@"objId = 4"];
    }] fetch:&error];
    XCTAssertEqual(objs.count, 1, @"Query count equals");
    XCTAssertNil(error, @"Error: %@", error);
    
    objs = [[TestItem query:^(CdFetchRequest * _Nonnull config) {
        [config filterWithFormat:@"objId < 4"];
    }] fetch:&error];
    XCTAssertEqual(objs.count, 3, @"Query count equals");
    XCTAssertNil(error, @"Error: %@", error);
    
    objs = [[TestItem query:^(CdFetchRequest * _Nonnull config) {
        [config filterWithFormat:@"objId < 4"];
        [config setLimit:2];
    }] fetch:&error];
    XCTAssertEqual(objs.count, 2, @"Query count equals");
    XCTAssertNil(error, @"Error: %@", error);
}


- (void)testSortingQueries {
    NSError *error = nil;
    NSArray<TestItem *> *objs = [[TestItem query:^(CdFetchRequest * _Nonnull config) {
        [config filterWithFormat:@"objId > %d AND objId < %d", 1, 5];
        [config sortByProperty:@"objId"];
    }] fetch:&error];
    XCTAssertEqual(objs.count, 3, @"Query count equals");
    XCTAssertEqual(objs[0].objId, 2, @"Query sorting");
    XCTAssertEqual(objs[1].objId, 3, @"Query sorting");
    XCTAssertEqual(objs[2].objId, 4, @"Query sorting");
    XCTAssertNil(error, @"Error: %@", error);
    
    objs = [[TestItem query:^(CdFetchRequest * _Nonnull config) {
        [config filterWithFormat:@"objId > %d AND objId < %d", 1, 5];
        [config sortByProperty:@"objId" ascending:NO];
    }] fetch:&error];
    XCTAssertEqual(objs.count, 3, @"Query count equals");
    XCTAssertEqual(objs[0].objId, 4, @"Query sorting");
    XCTAssertEqual(objs[1].objId, 3, @"Query sorting");
    XCTAssertEqual(objs[2].objId, 2, @"Query sorting");
    XCTAssertNil(error, @"Error: %@", error);
}


- (void)testBasicModification {
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    dispatch_async(bgQueue, ^{
        NSError *error = [Cd transactAndWait:^{
            NSError *error = nil;
            TestItem *item = [[TestItem query:^(CdFetchRequest * _Nonnull config) {
                [config filterWithFormat:@"objId = 1"];
            }] fetchOne:&error];
            XCTAssertNil(error, @"error: %@", error);
            item.name = @"111";
        }];
        XCTAssertNil(error, @"error: %@", error);
        dispatch_semaphore_signal(sem);
    });
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    NSError *error = nil;
    NSArray<TestItem *> *objs = [[TestItem query:^(CdFetchRequest * _Nonnull config) {
        [config filterWithFormat:@"objId = 1"];
    }] fetch:&error];
    XCTAssertEqual(objs.count, 1, @"Query count equals");
    XCTAssert([objs[0].name isEqualToString:@"111"], @"name");
    XCTAssertNil(error, @"Error: %@", error);
    
    objs = [[TestItem query:^(CdFetchRequest * _Nonnull config) {
        [config filterWithFormat:@"name = \"111\""];
    }] fetch:&error];
    XCTAssertEqual(objs.count, 1, @"Query count equals");
    XCTAssertEqual(objs[0].objId, 1, @"name");
    XCTAssertNil(error, @"Error: %@", error);
}


- (void)testBasicCreate {
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    dispatch_async(bgQueue, ^{
        NSError *error = [Cd transactAndWait:^{
            TestItem *item = [TestItem create];
            item.objId = 1000;
            item.name = @"F";
        }];
        XCTAssertNil(error, @"error: %@", error);
        dispatch_semaphore_signal(sem);
    });
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    NSError *error = nil;
    NSArray<TestItem *> *objs = [[TestItem query] fetch:&error];
    XCTAssertEqual(objs.count, 6, @"Query count equals");
    XCTAssertNil(error, @"Error: %@", error);
    
    objs = [[TestItem query:^(CdFetchRequest * _Nonnull config) {
        [config filterWithFormat:@"name = \"F\""];
    }] fetch:&error];
    XCTAssertEqual(objs.count, 1, @"Query count equals");
    XCTAssertEqual(objs[0].objId, 1000, @"name");
    XCTAssertNil(error, @"Error: %@", error);
}


- (void)testBasicClone {
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    dispatch_async(bgQueue, ^{
        NSError *error = [Cd transactAndWait:^{
            TestItem *item = [TestItem create];
            item.objId = 1000;
            item.name = @"F";
        }];
        XCTAssertNil(error, @"error: %@", error);
        dispatch_semaphore_signal(sem);
    });
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    NSError *error = nil;
    NSArray<TestItem *> *objs = [[TestItem query] fetch:&error];
    XCTAssertEqual(objs.count, 6, @"Query count equals");
    XCTAssertNil(error, @"Error: %@", error);
    
    objs = [[TestItem query:^(CdFetchRequest * _Nonnull config) {
        [config filterWithFormat:@"name = \"F\""];
    }] fetch:&error];
    XCTAssertEqual(objs.count, 1, @"Query count equals");
    XCTAssertEqual(objs[0].objId, 1000, @"name");
    XCTAssertNil(error, @"Error: %@", error);
    
    TestItem *obj = objs[0];
    
    objs = [[TestItem query:^(CdFetchRequest * _Nonnull config) {
        [config filterWithFormat:@"name = \"G\""];
    }] fetch:&error];
    XCTAssertEqual(objs.count, 0, @"Query count equals");
    XCTAssertNil(error, @"Error: %@", error);
    
    
    sem = dispatch_semaphore_create(0);
    dispatch_async(bgQueue, ^{
        NSError *error = [Cd transactAndWait:^{
            NSError *error = nil;
            TestItem *obj2 = [obj cloneForCurrentContext:&error];
            obj2.objId = 1001;
            obj2.name = @"G";
            XCTAssertNil(error, @"Error: %@", error);
        }];
        XCTAssertNil(error, @"error: %@", error);
        dispatch_semaphore_signal(sem);
    });
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    
    sem = dispatch_semaphore_create(0);
    dispatch_async(bgQueue, ^{
        NSError *error = [Cd transactAndWait:^{
            NSError *error = nil;
            NSArray<TestItem *> *objs = [[TestItem query] fetch:&error];
            XCTAssertEqual(objs.count, 6, @"Query count equals");
            XCTAssertNil(error, @"Error: %@", error);
            
            objs = [[TestItem query:^(CdFetchRequest * _Nonnull config) {
                [config filterWithFormat:@"name = \"G\""];
            }] fetch:&error];
            XCTAssertEqual(objs.count, 1, @"Query count equals");
            XCTAssertEqual(objs[0].objId, 1001, @"objid");
            XCTAssertNil(error, @"Error: %@", error);
            
            objs = [[TestItem query:^(CdFetchRequest * _Nonnull config) {
                [config filterWithFormat:@"name = \"F\""];
            }] fetch:&error];
            XCTAssertEqual(objs.count, 0, @"Query count equals");
            XCTAssertNil(error, @"Error: %@", error);
        }];
        XCTAssertNil(error, @"error: %@", error);
        dispatch_semaphore_signal(sem);
    });
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
}

- (void)testMultiCreate {
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    dispatch_async(bgQueue, ^{
        NSError *error = [Cd transactAndWait:^{
            NSArray<TestItem *> *items = [TestItem createBatch:10];
            for (TestItem *item in items) {
                item.name = @"B";
            }
        }];
        XCTAssertNil(error, @"error: %@", error);
        dispatch_semaphore_signal(sem);
    });
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    NSError *error = nil;
    NSArray<TestItem *> *objs = [[TestItem query] fetch:&error];
    XCTAssertEqual(objs.count, 15, @"Query count equals");
    XCTAssertNil(error, @"Error: %@", error);
}


- (void)testBasicDictionary {
    NSError *error = nil;
    NSArray<NSDictionary *> *objs = [[TestItem query] fetchDictionaryArray:&error];
    XCTAssertEqual(objs.count, 5, @"Query count equals");
    XCTAssertNil(error, @"Error: %@", error);
}


- (void)testDictionaryExpressionGrouping {
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    dispatch_async(bgQueue, ^{
        NSError *error = [Cd transactAndWait:^{
            NSArray<TestItem *> *items = [TestItem createBatch:10];
            int i = 1;
            for (TestItem *item in items) {
                item.name = @"TEST";
                item.objId = i;
                i++;
            }
            
            i = 1;
            items = [TestItem createBatch:10];
            for (TestItem *item in items) {
                item.name = @"TEST2";
                item.objId = i;
                i++;
            }
        }];
        XCTAssertNil(error, @"error: %@", error);
        dispatch_semaphore_signal(sem);
    });
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    dispatch_async(bgQueue, ^{
        NSError *error = [Cd transactAndWait:^{
            
            NSError *error = nil;
            BOOL caught = NO;
            @try {
                NSArray<NSDictionary *> *objs = [[TestItem query:^(CdFetchRequest * _Nonnull config) {
                    [config groupBy:@[@"name"]];
                }] fetchDictionaryArray:&error];
                XCTAssertEqual(objs.count, 1, @"This shouldn't assert because it will try/catch before");
            }
            @catch (CdException *c) {
                caught = YES;
            }
            XCTAssertEqual(caught, YES, @"should have caught exception for grouping w/o properties");
            
            
            NSArray<NSDictionary *> *objs = [[TestItem query:^(CdFetchRequest * _Nonnull config) {
                [config includeExpressionNamed:@"sum" resultType:NSInteger64AttributeType format:@"@sum.objId"];
                [config includeExpressionNamed:@"count" resultType:NSInteger64AttributeType format:@"name.@count"];
                [config onlyProperties:@[@"name", @"sum", @"count"]];
                [config groupBy:@[@"name"]];
            }] fetchDictionaryArray:&error];
            XCTAssertEqual(objs.count, 7, @"Query count equals");
            
            int wastested = 0;
            for (NSDictionary *dic in objs) {
                if ([@"TEST" isEqualToString:dic[@"name"]]) {
                    XCTAssertEqual([dic[@"sum"] integerValue], 55, "sum difference");
                    XCTAssertEqual([dic[@"count"] integerValue], 10, "sum difference");
                    wastested = 1;
                }
                
                if ([@"TEST2" isEqualToString:dic[@"name"]]) {
                    XCTAssertEqual([dic[@"sum"] integerValue], 55, "sum difference");
                    XCTAssertEqual([dic[@"count"] integerValue], 10, "sum difference");
                }
            }
            XCTAssertEqual(wastested, 1, @"not tested");
            
        }];
        XCTAssertNil(error, @"error: %@", error);
        dispatch_semaphore_signal(sem);
    });
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
}

- (void)testBasicDelete {
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    dispatch_async(bgQueue, ^{
        NSError *error = [Cd transactAndWait:^{
            
            TestItem *item = [[TestItem query] fetchOne:nil];
            [item destroy];
            
        }];
        XCTAssertNil(error, @"error: %@", error);
        dispatch_semaphore_signal(sem);
    });
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    NSError *error = nil;
    NSArray<TestItem *> *objs = [[TestItem query] fetch:&error];
    XCTAssertEqual(objs.count, 4, @"Query count equals");
    XCTAssertNil(error, @"Error: %@", error);
}

- (void)testMultiDelete {
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    dispatch_async(bgQueue, ^{
        NSError *error = [Cd transactAndWait:^{
            
            NSArray<TestItem *> *items = [[TestItem query] fetch:nil];
            [Cd destroyBatch:items];
            
        }];
        XCTAssertNil(error, @"error: %@", error);
        dispatch_semaphore_signal(sem);
    });
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    NSError *error = nil;
    NSArray<TestItem *> *objs = [[TestItem query] fetch:&error];
    XCTAssertEqual(objs.count, 0, @"Query count equals");
    XCTAssertNil(error, @"Error: %@", error);
}


- (void)testCreateTransientMainInsertLater {
    
    TestItem *item = [TestItem createTransient];
    item.name = @"asdf";
    item.objId = 1000;
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    dispatch_async(bgQueue, ^{
        NSError *error = [Cd transactAndWait:^{
            
            [Cd transactAndWait:^{
                [item insert];
            }];
            
        }];
        XCTAssertNil(error, @"error: %@", error);
        dispatch_semaphore_signal(sem);
    });
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    NSError *error = nil;
    NSArray<TestItem *> *objs = [[TestItem query] fetch:&error];
    XCTAssertEqual(objs.count, 6, @"Query count equals");
    XCTAssertNil(error, @"Error: %@", error);
    
    objs = [[TestItem query:^(CdFetchRequest * _Nonnull config) {
        [config filterWithFormat:@"objId = 1000"];
    }] fetch:&error];
    XCTAssertEqual(objs.count, 1, @"Query count equals");
    XCTAssertNil(error, @"Error: %@", error);
}



- (void)testForbidModificationOnMainThread {
    NSError *error = nil;
    TestItem *objs = [[TestItem query] fetchOne:&error];
    XCTAssertNil(error, @"Error: %@", error);
    
    CdException *e = [self catchException:^{
        objs.name = @"moo";
    }];
    
    XCTAssert([e isKindOfClass:[CdMainThreadAssertion class]]);
}


- (void)testForModificationMainInOtherTx {
    NSError *error = nil;
    TestItem *objs = [[TestItem query] fetchOne:&error];
    XCTAssertNil(error, @"Error: %@", error);
    
    {
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        dispatch_async(bgQueue, ^{
            NSError *error = [Cd transactAndWait:^{
                
                [Cd transactAndWait:^{
                    CdException *e = [self catchException:^{
                        objs.name = @"moo";
                    }];
                    
                    XCTAssert([e isKindOfClass:[CdException class]]);
                }];
                
            }];
            XCTAssertNil(error, @"error: %@", error);
            dispatch_semaphore_signal(sem);
        });
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    }
}

- (void)testForModificationInOtherTx {
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    dispatch_async(bgQueue, ^{
        NSError *error = [Cd transactAndWait:^{
            
            __block TestItem *item;
            
            [Cd transactAndWait:^{
                item = [TestItem create];
                item.name = @"bob";
                item.objId = 1;
            }];
            
            [Cd transactAndWait:^{
                CdException *e = [self catchException:^{
                    item.name = @"moo";
                }];
                
                XCTAssert([e isKindOfClass:[CdException class]]);
            }];
            
        }];
        XCTAssertNil(error, @"error: %@", error);
        dispatch_semaphore_signal(sem);
    });
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

}

- (void)testForModificationInOtherTx2 {
    __block BOOL wasTested = NO;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    dispatch_async(bgQueue, ^{
        NSError *error = [Cd transactAndWait:^{
            
            __block TestItem *item;
            __block NSManagedObjectContext *c_holder;
            
            [Cd transactAndWait:^{
                item = [TestItem create];
                item.name = @"bob";
                item.objId = 1;
                c_holder = item.managedObjectContext;
            }];
            
            [Cd transactAndWait:^{
                CdException *e = [self catchException:^{
                    item.name = @"moo";
                }];
                
                XCTAssert([e isKindOfClass:[CdException class]]);
                wasTested = YES;
            }];
            
        }];
        XCTAssertNil(error, @"error: %@", error);
        dispatch_semaphore_signal(sem);
    });
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    XCTAssert(wasTested, @"Not tested");
}


- (void)testForbidReusingTransient {
    __block BOOL wasTested = NO;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    dispatch_async(bgQueue, ^{
        NSError *error = [Cd transactAndWait:^{
            
            __block TestItem *item;
            
            [Cd transactAndWait:^{
                item = [TestItem createTransient];
                item.name = @"bob";
                item.objId = 1;
            }];
            
            [Cd transactAndWait:^{
                CdException *e = [self catchException:^{
                    item = [item cloneForCurrentContext:nil];
                }];
                
                XCTAssert([e isKindOfClass:[CdException class]]);
                wasTested = YES;
            }];
            
        }];
        XCTAssertNil(error, @"error: %@", error);
        dispatch_semaphore_signal(sem);
    });
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    XCTAssert(wasTested, @"Not tested");
}


- (void)testForbidCreateMain {
    CdException *e = [self catchException:^{
        TestItem *item = [TestItem create];
        item.objId = 1;
    }];
    
    XCTAssert([e isKindOfClass:[CdException class]]);
}

- (void)testForbidDeleteMain {
    TestItem *item = [[TestItem query] fetchOne:nil];
    CdException *e = [self catchException:^{
        [item destroy];
    }];
    
    XCTAssert([e isKindOfClass:[CdException class]]);
}


- (NSArray<NSNumber *> *)helperRunParallelInc:(int)maxMillionths
                                      onQueue:(dispatch_queue_t)queue {
    
    srand((unsigned int)time(0));
    
    NSMutableArray<NSNumber *> *result = [NSMutableArray array];
    NSLock *lock = [[NSLock alloc] init];
    
    dispatch_queue_t bgqueue = dispatch_queue_create("parallel", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t group = dispatch_group_create();
    
    for (int t1 = 0; t1 < 25; t1++) {
        for (int t2 = 0; t2 < 40; t2++) {
            dispatch_group_async(group, bgqueue, ^{
                
                [Cd transactAndWaitOnQueue:queue block:^{
                    
                    TestItem *obj = [[TestItem query:^(CdFetchRequest * _Nonnull config) {
                        [config filterWithFormat:@"name = %@", @"A"];
                    }] fetchOne:nil];
                    
                    double delaytime = (rand() % maxMillionths) / 1000000.0;
                    [NSThread sleepForTimeInterval:delaytime];
                    
                    int64_t curId = obj.objId;
                    
                    [NSThread sleepForTimeInterval:delaytime];
                    
                    [lock lock];
                    [result addObject:@(curId)];
                    [lock unlock];
                    
                    obj.objId = curId + 1;
                }];
                
            });
        }
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    }
    
    return result;
}

- (NSArray<NSNumber *> *)helperRunParallelIncNormal:(int)maxMillionths
                                            onQueue:(dispatch_queue_t)queue {
    
    srand((unsigned int)time(0));
    
    NSMutableArray<NSNumber *> *result = [NSMutableArray array];
    NSLock *lock = [[NSLock alloc] init];
    
    dispatch_queue_t bgqueue = dispatch_queue_create("parallel", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t group = dispatch_group_create();
    
    for (int t1 = 0; t1 < 40; t1++) {
        for (int t2 = 0; t2 < 25; t2++) {
        
            dispatch_group_enter(group);
            [Cd transactOnQueue:queue block:^{
                
            
                TestItem *obj = [[TestItem query:^(CdFetchRequest * _Nonnull config) {
                    [config filterWithFormat:@"name = %@", @"A"];
                }] fetchOne:nil];
                
                double delaytime = (rand() % maxMillionths) / 1000000.0;
                [NSThread sleepForTimeInterval:delaytime];
                
                int64_t curId = obj.objId;
                
                [NSThread sleepForTimeInterval:delaytime];
                
                [lock lock];
                [result addObject:@(curId)];
                [lock unlock];
                
                obj.objId = curId + 1;
                
                dispatch_async(bgqueue, ^{
                    dispatch_group_leave(group);
                });
            } completion:nil];
            
        }
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    }
    
    return result;
}


- (void)testParallelNoCrash {
    NSArray<NSNumber *> *result = [self helperRunParallelInc:10 onQueue:nil];
    
    BOOL dupfound = NO;
    NSMutableSet<NSNumber *> *already = [NSMutableSet set];
    for (NSNumber *n in result) {
        if ([already containsObject:n]) {
            dupfound = YES;
            break;
        }
        [already addObject:n];
    }
    
    XCTAssertEqual(result.count, 1000, @"did not get 1000 results");
    XCTAssertEqual(dupfound, true, @"results ran serially");
}


- (void)testParallelSerialNoCrash {
    NSArray<NSNumber *> *result = [self helperRunParallelInc:10 onQueue:dispatch_queue_create("s", 0)];
    
    BOOL dupfound = NO;
    NSMutableSet<NSNumber *> *already = [NSMutableSet set];
    for (NSNumber *n in result) {
        if ([already containsObject:n]) {
            dupfound = YES;
            break;
        }
        [already addObject:n];
    }
    
    XCTAssertEqual(result.count, 1000, @"did not get 1000 results");
    XCTAssertEqual(dupfound, false, @"results did not run serially");
}


- (void)testParallelNoCrash2 {
    NSArray<NSNumber *> *result = [self helperRunParallelIncNormal:10 onQueue:nil];
    
    BOOL dupfound = NO;
    NSMutableSet<NSNumber *> *already = [NSMutableSet set];
    for (NSNumber *n in result) {
        if ([already containsObject:n]) {
            dupfound = YES;
            break;
        }
        [already addObject:n];
    }
    
    XCTAssertEqual(result.count, 1000, @"did not get 1000 results");
    XCTAssertEqual(dupfound, true, @"results ran serially");
}


- (void)testParallelSerialNoCrash2 {
    NSArray<NSNumber *> *result = [self helperRunParallelIncNormal:10 onQueue:dispatch_queue_create("s", 0)];
    
    BOOL dupfound = NO;
    NSMutableSet<NSNumber *> *already = [NSMutableSet set];
    for (NSNumber *n in result) {
        if ([already containsObject:n]) {
            dupfound = YES;
            break;
        }
        [already addObject:n];
    }
    
    XCTAssertEqual(result.count, 1000, @"did not get 1000 results");
    XCTAssertEqual(dupfound, false, @"results did not run serially");
}


- (void)initData {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    dispatch_async(bgQueue, ^{
        NSError *error = [Cd transactAndWait:^{
            NSArray<TestItem *> *items = [TestItem createBatch:5];
            
            items[0].objId = 1;
            items[0].name  = @"A";
            items[1].objId = 2;
            items[1].name  = @"B";
            items[2].objId = 3;
            items[2].name  = @"C";
            items[3].objId = 4;
            items[3].name  = @"D";
            items[4].objId = 5;
            items[4].name  = @"E";
        }];
        
        dispatch_semaphore_signal(semaphore);
        
        if (error) {
            XCTFail(@"initData error: %@", error);
        }
    });
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

- (NSString *)cleanName {
    NSString *n = self.name ?: @"unknownTestName";
    n = [n stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    n = [n stringByReplacingOccurrencesOfString:@"[" withString:@""];
    n = [n stringByReplacingOccurrencesOfString:@"]" withString:@""];
    n = [n stringByReplacingOccurrencesOfString:@"-" withString:@""];
    return n;
}

- (void)initCd {
    if (self.hasInit) { return; }
    self.hasInit = YES;
    
    [Cd initWithMomd:@"CadmiumTestModel"
            bundleID:@"org.fieldman.CadmiumObjCTests"
      sqliteFilename:[NSString stringWithFormat:@"%@.sqlite", self.cleanName]
             options:@{
                       NSSQLitePragmasOption: @{
                               @"journal_mode": @"MEMORY"
                               }
                       }
            serialTX:NO];
}

- (void)cleanCd {
    NSArray<NSURL *> *urls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *docDir = urls[0];
    
    NSArray<NSURL *> *files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:docDir
                                                            includingPropertiesForKeys:nil
                                                                               options:0
                                                                                 error:nil];
    
    for (NSURL *file in files) {
        NSRange range = [file.description rangeOfString:[NSString stringWithFormat:@"%@.sqlite", self.cleanName]];
        if (range.location != NSNotFound) {
            [[NSFileManager defaultManager] removeItemAtURL:file error:nil];
        }
    }
}

@end
