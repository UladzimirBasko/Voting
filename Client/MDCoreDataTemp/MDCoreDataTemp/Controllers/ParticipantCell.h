//
//  ParticipantCell.h
//  MDCoreDataTemp
//
//  Created by Vladimir on 12/9/16.
//  Copyright © 2016 senla. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ParticipantCell : UITableViewCell

@property(weak, nonatomic) IBOutlet UILabel *partNameLabel;
@property(weak, nonatomic) IBOutlet UIButton *partSelectedBtn;
@property(nonatomic, assign) BOOL isChoosen;
@property(nonatomic, copy) void (^didTapBlock)();

@end
