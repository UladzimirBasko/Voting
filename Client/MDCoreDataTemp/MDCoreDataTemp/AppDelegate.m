//
//  AppDelegate.m
//  MDCoreDataTemp
//
//  Created by Vladimir on 11/24/16.
//  Copyright © 2016 senla. All rights reserved.
//

#import <MDCoreData/MDCoreData.h>
#import "AppDelegate.h"
#import "TestDataProvider.h"
#import "TestModel.h"

#import "RegistrationController.h"

@interface AppDelegate ()<MDRemoteStoreAuthenticationDelegate>

@property(nonatomic, strong) TestDataProvider *provider;
@property(nonatomic, strong) MDRemoteStore *remoteStore;
@property(nonatomic, strong) MDRemoteStoreOptions *options;
@property(nonatomic, strong) TestModel *model;
@property(nonatomic, strong) MDManagedObjectContext *remoteContext;
@property(nonatomic, strong) MDCredential *credential;
@property(nonatomic, copy) void (^authenticateCompletionBlock)(NSError *error);

- (void)setupRemoteStore;
- (void)continueSetupRemoteStoreWithAuthenticateError:(NSError *)error;
- (NSArray *)loadCredentials;
- (MDCredential *)randomCredential;
- (void)fetchParentEntitiesWithIds:(NSArray<NSString *> *)ids
                            failed:(BOOL)isFailed
                        completion:(void (^)(NSError *error, NSArray<ParentEntity *> *result, BOOL fromCache))completion;
- (void)fetchRelatedEntitiesWithIds:(NSArray<NSString *> *)ids
                             failed:(BOOL)isFailed
                         completion:(void (^)(NSError *error, NSArray<RelatedEntity *> *result, BOOL fromCache))completion;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  [self.window setRootViewController:[RegistrationController new]];
  [self.window makeKeyAndVisible];
  return YES;
}

#pragma mark - Private Interface
- (void)setupRemoteStore {
  self.remoteStore = [[MDRemoteStore alloc] initWithStoreModel:self.model
                                                      storeURL:[NSURL URLWithString:@"http://example.com"]
                                                          user:self.credential
                                               persistentModel:nil
                                                       options:self.options];
  [self.remoteStore addCustomDataProvider:self.provider];
  [self.remoteStore setEntityCachePolicies:[TestModel cachePolicies]];
  [self.remoteStore setAuthenticationDelegate:self];
  __weak typeof(self) weakSelf = self;
  self.authenticateCompletionBlock = ^(NSError *authError) {
    [weakSelf continueSetupRemoteStoreWithAuthenticateError:authError];
  };
  [self.remoteStore authenticateManually];
}

- (void)continueSetupRemoteStoreWithAuthenticateError:(NSError *)error {
  if (error != nil) {
    NSLog(@"Did authenticate with error: %@", [error localizedDescription]);
  } else {
    self.remoteContext = [self.remoteStore remoteStoreContext];
    [self fetchParentEntitiesWithIds:@[ @"1", @"5" ]
                              failed:NO
                          completion:^(NSError *error, NSArray<ParentEntity *> *result, BOOL fromCache){

                          }];
  }
}

- (NSArray *)loadCredentials {
  NSArray *credentials = nil;
  NSInputStream *inputStream = [NSInputStream inputStreamWithURL:[[NSBundle mainBundle] URLForResource:@"TestCredentials" withExtension:@"txt"]];
  if (inputStream != nil) {
    [inputStream open];
    NSError *error = nil;
    credentials = [NSJSONSerialization JSONObjectWithStream:inputStream options:0 error:&error];
    if (error != nil) {
      NSLog(@"Failed to parse credentials input stream: %@", [error localizedDescription]);
    }
  } else {
    NSLog(@"Failed to create input stream to credentials file");
  }
  [inputStream close];
  return credentials;
}

- (MDCredential *)randomCredential {
  MDCredential *credential = nil;
  NSArray *credentials = [self loadCredentials];
  NSDictionary *randCred = [credentials objectAtIndex:arc4random_uniform([credentials count])];
  NSString *login = [randCred objectForKey:@"login"];
  NSString *password = [randCred objectForKey:@"password"];
  if (login == nil || password == nil) {
    credential = [MDCredential credentialWithDefaultUserAllowOfflineLogin:YES];
  } else {
    credential = [MDCredential credentialWithUser:login password:password allowOfflineLogin:YES];
  }
  return credential;
}

- (void)fetchParentEntitiesWithIds:(NSArray<NSString *> *)ids
                            failed:(BOOL)isFailed
                        completion:(void (^)(NSError *error, NSArray<ParentEntity *> *result, BOOL fromCache))completion {
  MDFetchRequest *parentEntitiesRequest = [MDFetchRequest fetchRequestWithCachePolicy:MDFetchRequestReturnCacheDataDontLoad];
  [parentEntitiesRequest setEntity:[NSEntityDescription entityForName:NSStringFromClass([ParentEntity class]) inManagedObjectContext:self.remoteContext]];
  [parentEntitiesRequest setDidFinishPerformFetchBlock:^(MDFetchRequest *fetchRequest, MDFetchResult *result, BOOL fromCache, NSError *error) {
    if (completion != nil) {
      completion(error, [result items], fromCache);
    }
  }];
  NSMutableDictionary *requestInfo = [NSMutableDictionary new];
  [requestInfo setObject:@(isFailed) forKey:@"failedRequest"];
  if ([ids count] > 0) {
    [requestInfo setObject:ids forKey:@"ids"];
    [parentEntitiesRequest setPredicate:[NSPredicate predicateWithFormat:@"idProp IN %@", ids]];
  }
  [parentEntitiesRequest setUserInfo:requestInfo];
  [self.remoteContext executeFetchRequest:parentEntitiesRequest];
}

- (void)fetchRelatedEntitiesWithIds:(NSArray<NSString *> *)ids
                             failed:(BOOL)isFailed
                         completion:(void (^)(NSError *error, NSArray<RelatedEntity *> *result, BOOL fromCache))completion {
  MDFetchRequest *relatedEntitiesRequest = [MDFetchRequest fetchRequestWithCachePolicy:MDFetchRequestReturnCacheDataThenLoad];
  [relatedEntitiesRequest setEntity:[NSEntityDescription entityForName:NSStringFromClass([RelatedEntity class]) inManagedObjectContext:self.remoteContext]];
  [relatedEntitiesRequest setDidFinishPerformFetchBlock:^(MDFetchRequest *fetchRequest, MDFetchResult *result, BOOL fromCache, NSError *error) {
    if (completion != nil) {
      completion(error, [result items], fromCache);
    }
  }];
  NSMutableDictionary *requestInfo = [NSMutableDictionary new];
  [requestInfo setObject:@(isFailed) forKey:@"failedRequest"];
  if ([ids count] > 0) {
    [requestInfo setObject:ids forKey:@"ids"];
    [relatedEntitiesRequest setPredicate:[NSPredicate predicateWithFormat:@"idProp IN %@", ids]];
  }
  [relatedEntitiesRequest setUserInfo:requestInfo];
  [self.remoteContext executeFetchRequest:relatedEntitiesRequest];
}

#pragma mark - Getters / Setters
- (MDRemoteStoreOptions *)options {
  if (_options == nil) {
    _options = [MDRemoteStoreOptions remoteStoreOptions];
    _options.checkHostAvailability = YES;
    _options.hostReachabilityType = MDHostReachabilityTypeNative;
    _options.communicationProtocol = MDRemoteStoreCommunicationProtocolCustom;
    _options.authenticationMethod = @"POST";
    _options.removeCacheIfExists = NO;
    _options.authenticationFailStatusCode = 403;
  }
  return _options;
}

- (NSManagedObjectModel *)model {
  if (_model == nil) {
    _model = [TestModel new];
  }
  return _model;
}

- (MDCredential *)credential {
  if (_credential == nil) {
    _credential = [self randomCredential];
  }
  return _credential;
}

- (TestDataProvider *)provider {
  if (_provider == nil) {
    _provider = [[TestDataProvider alloc] initWithEntityNames:@[ NSStringFromClass([ParentEntity class]), NSStringFromClass([RelatedEntity class]) ]];
  }
  return _provider;
}

#pragma mark - MDRemoteStoreAuthenticationDelegate
- (void)remoteStore:(MDRemoteStore *)remoteStore
    authenticationSuccessForOfflineMode:(BOOL)offlineMode
                               response:(NSHTTPURLResponse *)response
                           responseData:(NSData *)data {
  if (self.authenticateCompletionBlock != nil) {
    self.authenticateCompletionBlock(nil);
  }
}

- (void)remoteStore:(MDRemoteStore *)remoteStore
    authenticationFailWithError:(NSError *)error
                       response:(NSHTTPURLResponse *)response
                   responseData:(NSData *)data {
  if (self.authenticateCompletionBlock != nil) {
    self.authenticateCompletionBlock(error);
  }
}

@end
