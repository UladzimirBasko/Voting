//
//  RegistrationController.m
//  MDCoreDataTemp
//
//  Created by Vladimir on 12/4/16.
//  Copyright © 2016 senla. All rights reserved.
//

#import "RegistrationController.h"

static const CGFloat kInterpolationEffectOffset = 20.0;

@interface RegistrationController ()

@property(weak, nonatomic) IBOutlet UIImageView *bkgImageView;
@property(strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *bkgImageViewConstraints;
@property(weak, nonatomic) IBOutlet UITextField *usernameTF;
@property(weak, nonatomic) IBOutlet UITextField *passwordTF;
@property(weak, nonatomic) IBOutlet UIButton *rememberBtn;
@property(weak, nonatomic) IBOutlet UIButton *signUpBtn;
@property(weak, nonatomic) IBOutlet UIButton *logInBtn;
@property(weak, nonatomic) IBOutlet UIView *signUpContainerView;

- (void)setupBackground;
- (void)setupTextFields;
- (void)setupRememberBtn;
- (IBAction)onRememberBtnTap:(UIButton *)sender;
- (IBAction)onLogInBtnTap:(UIButton *)sender;
- (IBAction)onSignUpBtnTap:(UIButton *)sender;

@end

@implementation RegistrationController {
  BOOL needRemember_;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupBackground];
  [self setupTextFields];
  [self setupRememberBtn];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
  return UIStatusBarStyleLightContent;
}

#pragma mark - Private Interface
- (void)setupBackground {
  for (NSLayoutConstraint *constrain in self.bkgImageViewConstraints) {
    constrain.constant = -kInterpolationEffectOffset;
  }

  UIInterpolatingMotionEffect *verticalMotionEffect =
      [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
  verticalMotionEffect.minimumRelativeValue = @(-kInterpolationEffectOffset / 2);
  verticalMotionEffect.maximumRelativeValue = @(kInterpolationEffectOffset);
  UIInterpolatingMotionEffect *horizontalMotionEffect =
      [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
  horizontalMotionEffect.minimumRelativeValue = @(-kInterpolationEffectOffset);
  horizontalMotionEffect.maximumRelativeValue = @(kInterpolationEffectOffset);
  UIMotionEffectGroup *group = [UIMotionEffectGroup new];
  group.motionEffects = @[ horizontalMotionEffect, verticalMotionEffect ];
  [self.bkgImageView addMotionEffect:group];

  [self.bkgImageView.superview layoutIfNeeded];
}

- (void)setupTextFields {
  UIColor *color = [UIColor whiteColor];
  self.usernameTF.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Username" attributes:@{NSForegroundColorAttributeName : color}];
  self.passwordTF.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Password" attributes:@{NSForegroundColorAttributeName : color}];
}

- (void)setupRememberBtn {
  [self.rememberBtn.layer setBorderWidth:1.0];
  [self.rememberBtn.layer setBorderColor:self.signUpContainerView.backgroundColor.CGColor];
}

#pragma mark - Actions
- (IBAction)onRememberBtnTap:(UIButton *)sender {
  needRemember_ = !needRemember_;
  UIColor *bkgColor = nil;
  if (!needRemember_) {
    bkgColor = [UIColor clearColor];
  } else {
    bkgColor = [UIColor colorWithCGColor:sender.layer.borderColor];
  }
  [UIView animateWithDuration:0.5
                   animations:^{
                     [sender setBackgroundColor:bkgColor];
                   }];
}

- (IBAction)onLogInBtnTap:(UIButton *)sender {
}

- (IBAction)onSignUpBtnTap:(UIButton *)sender {
}

@end
