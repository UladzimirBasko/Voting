//
//  ResultsController.m
//  MDCoreDataTemp
//
//  Created by Vladimir on 12/9/16.
//  Copyright © 2016 senla. All rights reserved.
//

#import "ResultCell.h"
#import "ResultsController.h"
#import "TestModel.h"
#import "VotingService.h"

@interface ResultsController ()<UITableViewDelegate, UITableViewDataSource>

@property(weak, nonatomic) IBOutlet UITableView *tableView;
@property(weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property(nonatomic, strong) NSArray<Result *> *results;
@property(nonatomic, strong) NSArray<Region *> *regions;
@property(nonatomic, strong) NSDictionary *regionResults;

@end

@implementation ResultsController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"Results";
  [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([ResultCell class]) bundle:[NSBundle mainBundle]]
       forCellReuseIdentifier:NSStringFromClass([ResultCell class])];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.tableView setHidden:YES];
  [self.activityIndicator startAnimating];
  __weak typeof(self) weakSelf = self;

  [[VotingService sharedService] fetchResultssWithCompletion:^(NSError *error, NSArray<Result *> *results) {
    dispatch_async(dispatch_get_main_queue(), ^{
      weakSelf.results = results;
      [weakSelf.tableView reloadData];
      [weakSelf.activityIndicator stopAnimating];
      [weakSelf.tableView setHidden:NO];
    });
  }];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
  return UIStatusBarStyleLightContent;
}

#pragma mark - Setters
- (void)setResults:(NSArray<Result *> *)results {
  _results = results;
  NSMutableArray *regions = [NSMutableArray new];
  NSMutableDictionary *regionRes = [NSMutableDictionary new];
  for (Result *result in results) {
    Region *region = result.participant.region;
    if (![regions containsObject:region] && region != nil) {
      [regions addObject:region];
    }
    NSMutableArray *mutRes = [[NSMutableArray alloc] initWithArray:[regionRes objectForKey:region.idProp]];
    [mutRes addObject:result];
    [regionRes setObject:mutRes forKey:region.idProp];
  }
  self.regionResults = regionRes;
  self.regions = regions;
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return [self.regions count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  Region *region = [self.regions objectAtIndex:section];
  NSArray *results = [self.regionResults objectForKey:region.idProp];
  return [results count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 110;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 40;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  UILabel *label = [[UILabel alloc] init];
  [label setTextAlignment:NSTextAlignmentCenter];
  [label setBackgroundColor:[UIColor colorWithWhite:0.5 alpha:0.8]];
  [label setTextColor:[UIColor whiteColor]];
  [label setFont:[UIFont systemFontOfSize:20]];
  [label.layer setCornerRadius:10];
  Region *region = [self.regions objectAtIndex:section];
  [label setText:region.name];
  return label;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  Region *region = [self.regions objectAtIndex:indexPath.section];
  NSArray *results = [self.regionResults objectForKey:region.idProp];
  Result *result = [results objectAtIndex:indexPath.row];

  ResultCell *cell = [self.tableView dequeueReusableCellWithIdentifier:NSStringFromClass([ResultCell class]) forIndexPath:indexPath];
  [cell.partNameLabel setText:result.participant.name];
  [cell.voteCountLabel setText:[result.count stringValue]];
  [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
  return cell;
}

@end
