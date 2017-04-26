//
//  TestItemTableViewCell.h
//  CadmiumObjCExample
//
//  Created by Jason Fieldman on 4/26/17.
//  Copyright © 2017 Jason Fieldman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TestItem.h"

@interface TestItemTableViewCell : UITableViewCell

@property (nonatomic, strong) TestItem *testItem;

- (void)handleUpdate;

@end
