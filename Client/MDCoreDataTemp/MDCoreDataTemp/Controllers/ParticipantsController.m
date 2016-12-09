//
//  ParticipantsController.m
//  MDCoreDataTemp
//
//  Created by Vladimir on 12/9/16.
//  Copyright © 2016 senla. All rights reserved.
//

#import "ParticipantCell.h"
#import "ParticipantsController.h"
#import "TestModel.h"
#import "VotingService.h"

@interface ParticipantsController ()<UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) NSArray<Participant *> *participants;
@property(weak, nonatomic) IBOutlet UITableView *tableView;
@property(nonatomic, strong) ParticipantCell *chosenCell;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *voteBtnButtomConstraint;
@property(weak, nonatomic) IBOutlet UIButton *voteBtn;
@property(weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property(weak, nonatomic) IBOutlet UILabel *regionNameLbl;

- (void)setVoteBtnVisible:(BOOL)visible;
- (void)invalidateChoosenCell;
- (void)showAlertWithMessage:(NSString *)message title:(NSString *)title;
- (IBAction)onVoteBtnTap:(UIButton *)sender;

@end

@implementation ParticipantsController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"Participants";
  [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([ParticipantCell class]) bundle:[NSBundle mainBundle]]
       forCellReuseIdentifier:NSStringFromClass([ParticipantCell class])];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  __weak typeof(self) weakSelf = self;
  [self.tableView setHidden:YES];
  [self.activityIndicator startAnimating];
  [[VotingService sharedService] fetchPartcicipantsWithCompletion:^(NSError *error, NSArray<Participant *> *participants) {
    dispatch_async(dispatch_get_main_queue(), ^{
      weakSelf.participants = participants;
      [weakSelf.tableView reloadData];
      [weakSelf invalidateChoosenCell];
      [weakSelf.activityIndicator stopAnimating];
      [weakSelf.tableView setHidden:NO];
    });
  }];
  [self.voteBtn setBackgroundColor:[UIColor colorWithWhite:0.5 alpha:0.2]];
  [self.voteBtn.layer setCornerRadius:20];
  [self.voteBtn.layer setBorderWidth:1.0];
  [self.voteBtn.layer setBorderColor:[UIColor whiteColor].CGColor];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
  return UIStatusBarStyleLightContent;
}

#pragma mark - Setters
- (void)setChosenCell:(ParticipantCell *)chosenCell {
  _chosenCell = chosenCell;
  [self setVoteBtnVisible:_chosenCell != nil];
}

- (void)setParticipants:(NSArray<Participant *> *)participants {
  _participants = participants;
  if ([_participants count] > 0) {
    Participant *part = [_participants firstObject];
    [self.regionNameLbl setText:part.region.name];
  } else {
    [self.regionNameLbl setText:nil];
  }
}

#pragma mark - Private Interface
- (void)setVoteBtnVisible:(BOOL)visible {
  if (!visible) {
    self.voteBtnButtomConstraint.constant = -(self.voteBtn.frame.size.height);
  } else {
    self.voteBtnButtomConstraint.constant = 70;
  }
  [UIView animateWithDuration:0.5
                   animations:^{
                     [[self.voteBtn superview] layoutIfNeeded];
                   }];
}

- (void)invalidateChoosenCell {
  if (self.chosenCell != nil) {
    [self setChosenCell:nil];
  }
  for (ParticipantCell *cell in [self.tableView visibleCells]) {
    [cell setIsChoosen:NO];
  }
}

- (void)showAlertWithMessage:(NSString *)message title:(NSString *)title {
  UIAlertController *alertControlelr = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
  __weak typeof(self) weakSelf = self;
  [alertControlelr addAction:[UIAlertAction actionWithTitle:@"Ok"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *_Nonnull action) {
                                                      [weakSelf dismissViewControllerAnimated:YES completion:nil];
                                                    }]];
  [self presentViewController:alertControlelr animated:YES completion:nil];
}

#pragma mark - Action
- (IBAction)onVoteBtnTap:(UIButton *)sender {
  Participant *participant = [self.participants objectAtIndex:[[self.tableView visibleCells] indexOfObject:self.chosenCell]];
  if (participant != nil) {
    __weak typeof(self) weakSelf = self;
    [[VotingService sharedService] voteForParticipantWith:participant
                                           withCompletion:^(NSError *error) {
                                             NSString *message = nil;
                                             NSString *title = nil;
                                             if (error != nil) {
                                               message = error.localizedDescription;
                                               title = @"Failed";
                                             } else {
                                               message = @"Your vote has been counted";
                                               title = @"Success";
                                             }
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                               [weakSelf showAlertWithMessage:message title:title];
                                             });
                                           }];
  }
}

#pragma mark - UITableViewDataSource
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 110.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self.participants count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  ParticipantCell *cell = [self.tableView dequeueReusableCellWithIdentifier:NSStringFromClass([ParticipantCell class]) forIndexPath:indexPath];
  Participant *participant = [self.participants objectAtIndex:indexPath.row];
  [cell.partNameLabel setText:participant.name];
  [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  ParticipantCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
  [cell setIsChoosen:!cell.isChoosen];
  if (self.chosenCell != nil) {
    [self.chosenCell setIsChoosen:NO];
    self.chosenCell = nil;
  }
  if (cell.isChoosen) {
    self.chosenCell = cell;
  }
}

@end
