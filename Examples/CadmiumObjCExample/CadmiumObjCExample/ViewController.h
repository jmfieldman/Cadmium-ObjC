//
//  ViewController.h
//  CadmiumObjCExample
//
//  Created by Jason Fieldman on 4/26/17.
//  Copyright © 2017 Jason Fieldman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "CdFetchedResultsController.h"

@interface ViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) CdFetchedResultsController *resultsController;

@end

