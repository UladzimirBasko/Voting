//
//  ResultCell.m
//  MDCoreDataTemp
//
//  Created by Vladimir on 12/9/16.
//  Copyright © 2016 senla. All rights reserved.
//

#import "ResultCell.h"

@interface ResultCell ()

@property(weak, nonatomic) IBOutlet UIImageView *partImageView;
@property(weak, nonatomic) IBOutlet UIView *contView;

@end

@implementation ResultCell

- (void)awakeFromNib {
  [super awakeFromNib];
  [self.partImageView.layer setCornerRadius:self.partImageView.frame.size.height / 2];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  [self.contentView layoutSubviews];
  self.contView.layer.cornerRadius = 10;
}

@end
