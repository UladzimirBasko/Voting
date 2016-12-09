//
//  AppDelegate.m
//  MDCoreDataTemp
//
//  Created by Vladimir on 11/24/16.
//  Copyright © 2016 senla. All rights reserved.
//

#import "AppDelegate.h"
#import "ParticipantsController.h"
#import "RegistrationController.h"
#import "ResultsController.h"

@interface AppDelegate ()

- (void)showMainScreen;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  __weak typeof(self) weakSelf = self;
  RegistrationController *registController = [RegistrationController new];
  [registController setDidLoginBlock:^{
    [weakSelf showMainScreen];
  }];
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  [self.window setRootViewController:registController];
  [self.window makeKeyAndVisible];
  return YES;
}

#pragma mark - Private Interface
- (void)showMainScreen {
  UITabBarController *tabBarController = [[UITabBarController alloc] init];
  UIImageView *bkgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bkg.png"]];
  [tabBarController.view insertSubview:bkgImageView atIndex:0];
  [tabBarController setViewControllers:@[ [ParticipantsController new], [ResultsController new] ]];
  [tabBarController setSelectedIndex:0];
  [[tabBarController.tabBar.items objectAtIndex:0] setTitle:@"Participants"];
  [[tabBarController.tabBar.items objectAtIndex:0] setImage:[UIImage imageNamed:@"participants.png"]];
  [[tabBarController.tabBar.items objectAtIndex:1] setTitle:@"Results"];
  [[tabBarController.tabBar.items objectAtIndex:1] setImage:[UIImage imageNamed:@"results.png"]];
  [self.window setRootViewController:tabBarController];
}

@end
