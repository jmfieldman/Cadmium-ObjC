//
//  TestItemTableViewCell.m
//  CadmiumObjCExample
//
//  Created by Jason Fieldman on 4/26/17.
//  Copyright © 2017 Jason Fieldman. All rights reserved.
//

#import "TestItemTableViewCell.h"

@implementation TestItemTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setTestItem:(TestItem *)testItem {
    _testItem = testItem;
    [self handleUpdate];
}

- (void)handleUpdate {
    self.textLabel.text = _testItem.title;
    self.detailTextLabel.text = [NSString stringWithFormat:@"Clicks: %lld", _testItem.clicks];
}
    
@end
