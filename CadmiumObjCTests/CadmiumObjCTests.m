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
#import "TestItem.h"

@interface CadmiumObjCTests : XCTestCase

@end

@implementation CadmiumObjCTests {
    dispatch_queue_t bgQueue;
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

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
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
        
        if (error) {
            XCTFail(@"initData error: %@", error);
        }
        
        dispatch_semaphore_signal(semaphore);
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
    [Cd initWithMomd:@"CadmiumTestModel"
            bundleID:nil
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
