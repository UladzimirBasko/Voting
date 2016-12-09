//
//  RegistrationController.m
//  MDCoreDataTemp
//
//  Created by Vladimir on 12/4/16.
//  Copyright © 2016 senla. All rights reserved.
//

#import <MDCoreData/MDCredential.h>
#import "BTKeychainDirector.h"
#import "BTKeychainDirector.h"
#import "RegistrationController.h"
#import "TPKeyboardAvoidingScrollView.h"
#import "VotingService.h"
#import "VotingService.h"

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
@property(weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property(weak, nonatomic) IBOutlet TPKeyboardAvoidingScrollView *scrollView;

- (void)setupBackground;
- (void)setupTextFields;
- (void)setupRememberBtn;
- (void)showAlertWithMessage:(NSString *)message;
- (void)login;
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
  //
  //  MDCredential *lastCredential = [[BTKeychainDirector sharedDirector] lastCredential];
  //  if (lastCredential != nil) {
  //    [self.scrollView setHidden:YES];
  //    [self onRememberBtnTap:nil];
  //    [self.usernameTF setText:lastCredential.user];
  //    [self.passwordTF setText:lastCredential.password];
  //    [self onLogInBtnTap:nil];
  //  }
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

- (void)showAlertWithMessage:(NSString *)message {
  UIAlertController *alertControlelr = [UIAlertController alertControllerWithTitle:@"Sorry" message:message preferredStyle:UIAlertControllerStyleAlert];
  __weak typeof(self) weakSelf = self;
  [alertControlelr addAction:[UIAlertAction actionWithTitle:@"Ok"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *_Nonnull action) {
                                                      [weakSelf dismissViewControllerAnimated:YES completion:nil];
                                                    }]];
  [self presentViewController:alertControlelr animated:YES completion:nil];
}

- (void)login {
  if (self.usernameTF.text.length == 0) {
    [self showAlertWithMessage:@"Username should not be empty"];
  } else if (self.passwordTF.text.length == 0) {
    [self showAlertWithMessage:@"Password should not be empty"];
  } else {
    __weak typeof(self) weakSelf = self;
    [weakSelf.activityIndicator startAnimating];
    [UIView animateWithDuration:1
                     animations:^{
                       [weakSelf.scrollView setContentOffset:CGPointMake(0, weakSelf.scrollView.frame.size.height)];
                     }];
    [[VotingService sharedService] createRemoteStoreWithUserName:self.usernameTF.text
                                                        password:self.passwordTF.text
                                                   andCompletion:^(NSError *error, MDCredential *credential) {
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                       [weakSelf.activityIndicator stopAnimating];
                                                       if (error != nil) {
                                                         [weakSelf showAlertWithMessage:@"Something went wrong. Try again"];
                                                         [weakSelf.scrollView setHidden:NO];
                                                         [weakSelf.scrollView setContentOffset:CGPointMake(0, 0)];
                                                       } else {
                                                         __strong typeof(weakSelf) strongSelf = weakSelf;
                                                         if (strongSelf->needRemember_) {
                                                           [[BTKeychainDirector sharedDirector] saveCredential:credential];
                                                         } else {
                                                           [[BTKeychainDirector sharedDirector] removeCredential];
                                                         }
                                                         if (weakSelf.didLoginBlock != nil) {
                                                           weakSelf.didLoginBlock();
                                                         }
                                                       }
                                                     });
                                                   }];
  }
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
  [self login];
}

- (IBAction)onSignUpBtnTap:(UIButton *)sender {
  [self onLogInBtnTap:sender];
}

@end
