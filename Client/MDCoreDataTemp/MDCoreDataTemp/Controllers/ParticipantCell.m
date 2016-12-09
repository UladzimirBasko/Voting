//
//  ParticipantCell.m
//  MDCoreDataTemp
//
//  Created by Vladimir on 12/9/16.
//  Copyright © 2016 senla. All rights reserved.
//

#import "ParticipantCell.h"

@interface ParticipantCell ()

@property(weak, nonatomic) IBOutlet UIImageView *partImageView;
@property(weak, nonatomic) IBOutlet UIView *contView;
@property(weak, nonatomic) IBOutlet UIImageView *checkImageView;

@end

@implementation ParticipantCell

- (void)awakeFromNib {
  [super awakeFromNib];
  [self.partImageView.layer setCornerRadius:self.partImageView.frame.size.height / 2];
  [self.partSelectedBtn.layer setCornerRadius:self.partImageView.frame.size.height / 2];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  [self.contentView layoutSubviews];
  self.contView.layer.cornerRadius = 10;
}

- (void)setIsChoosen:(BOOL)isChoosen {
  _isChoosen = isChoosen;
  [self.checkImageView setHidden:!_isChoosen];
}

- (IBAction)onSelectedBtnTap:(UIButton *)sender {
  if (self.didTapBlock != nil) {
    self.didTapBlock();
  }
}

@end
