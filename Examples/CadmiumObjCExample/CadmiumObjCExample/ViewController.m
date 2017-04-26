//
//  ViewController.m
//  CadmiumObjCExample
//
//  Created by Jason Fieldman on 4/26/17.
//  Copyright © 2017 Jason Fieldman. All rights reserved.
//

#import "ViewController.h"
#import "TestItemTableViewCell.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Navigation Bar Stuff
    self.title = @"Cadmium Example";
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"+"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(_handleAdd:)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Rename"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(_renameAll:)];
    
    // Initialize fetched results controller
    CdFetchRequest *request = [TestItem query:^(CdFetchRequest * _Nonnull config) {
        [config sortByProperty:@"title"];
    }];
    
    _resultsController = [[CdFetchedResultsController alloc] initWithFetchRequest:request
                                                               sectionNameKeyPath:nil
                                                                        cacheName:nil];
    
    [_resultsController performFetch:nil];
    _resultsController.delegate = self;
    
    // Table Config
    
    //[self.tableView setEditing:YES];
}

- (void)_handleAdd:(UIBarButtonItem *)button {
    [Cd transact:^{
        TestItem *newItem = [TestItem create];
        newItem.title = [[NSUUID alloc] init].UUIDString;
        newItem.clicks = 0;
    }];
}

- (void)_renameAll:(UIBarButtonItem *)button {
    [Cd transact:^{
        for (TestItem *item in [[TestItem query] fetch:nil]) {
            item.title = [[NSUUID alloc] init].UUIDString;
        }
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _resultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _resultsController.sections[section].numberOfObjects;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TestItemTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[TestItemTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    cell.testItem = [_resultsController objectAtIndexPath:indexPath];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    TestItem *item = [_resultsController objectAtIndexPath:indexPath];
    [Cd transact:^{
        TestItem *txItem = [item cloneForCurrentContext:nil];
        txItem.clicks++;
    }];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
                                            forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        TestItem *itemToDelete = [_resultsController objectAtIndexPath:indexPath];
        [Cd transact:^{
            [[itemToDelete cloneForCurrentContext:nil] destroy];
        }];
    }
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type {
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    switch (type) {
            
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [((TestItemTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath]) handleUpdate];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

@end
