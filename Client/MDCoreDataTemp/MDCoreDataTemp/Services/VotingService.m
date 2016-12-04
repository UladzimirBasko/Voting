//
//  VotingService.m
//  MDCoreDataTemp
//
//  Created by Vladimir on 12/4/16.
//  Copyright © 2016 senla. All rights reserved.
//

#import <MDCoreData/MDCoreData.h>
#import "TestDataProvider.h"
#import "TestModel.h"
#import "VotingService.h"

static NSString *const kTPLManagedRequestCallbackId = @"callbackId";

@interface VotingService ()<MDRemoteStoreAuthenticationDelegate, MDFetchResponseReceiver>

@property(nonatomic, strong) NSManagedObjectContext *childContext;
@property(nonatomic, strong) TestDataProvider *provider;
@property(nonatomic, strong) MDRemoteStore *remoteStore;
@property(nonatomic, strong) MDRemoteStoreOptions *options;
@property(nonatomic, strong) TestModel *model;
@property(nonatomic, strong) MDManagedObjectContext *remoteContext;
@property(nonatomic, strong) NSMutableDictionary *reqeustsCallbacks;
@property(nonatomic, copy) void (^createStoreCompletionBlock)(NSError *error, BOOL isOfflineLogin);

@end

@implementation VotingService

+ (VotingService *)sharedService {
  static VotingService *sharedService = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedService = [[VotingService alloc] init];
  });
  return sharedService;
}

#pragma mark - Public Interface
- (void)createRemoteStoreWithUserName:(NSString *)userName password:(NSString *)password andCompletion:(void (^)(NSError *, BOOL))completion {
  MDCredential *credential = nil;
  if (userName == nil || password == nil) {
    credential = [MDCredential credentialWithDefaultUserAllowOfflineLogin:YES];
  } else {
    credential = [MDCredential credentialWithUser:userName password:password allowOfflineLogin:YES];
  }
  if (self.remoteStore != nil) {
    if ([self.remoteStore authenticated]) {
      if (completion != nil) {
        completion(nil, [self.remoteStore isOfflineMode]);
      }
    } else {
      self.createStoreCompletionBlock = completion;
      [self.remoteStore authenticateManually];
    }
    return;
  }
  self.createStoreCompletionBlock = completion;

  NSString *briefcaseModelPath = [[NSBundle mainBundle] pathForResource:@"BriefcaseModel" ofType:@"momd"];
  NSURL *briefcaseModelURL = [NSURL fileURLWithPath:briefcaseModelPath];
  self.remoteStore = [[MDRemoteStore alloc] initWithStoreModel:self.model
                                                      storeURL:[NSURL URLWithString:@"192.168.1.199:4000"]
                                                          user:credential
                                               persistentModel:[[NSManagedObjectModel alloc] initWithContentsOfURL:briefcaseModelURL]
                                                       options:self.options];
  [self.remoteStore setEntityCachePolicies:[TestModel cachePolicies]];
  [self.remoteStore addCustomDataProvider:self.provider];
  [self.remoteStore setAuthenticationDelegate:self];
  [self.remoteStore authenticateManually];
  self.remoteContext = [self.remoteStore remoteStoreContext];
  self.childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
  [self.childContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
}

#pragma mark - MDRemoteStoreAuthenticationDelegate
- (void)remoteStore:(MDRemoteStore *)remoteStore
    authenticationSuccessForOfflineMode:(BOOL)offlineMode
                               response:(NSHTTPURLResponse *)response
                           responseData:(NSData *)data {
  [self.childContext setParentContext:self.remoteContext];
  if (self.createStoreCompletionBlock != nil) {
    self.createStoreCompletionBlock(nil, offlineMode);
    self.createStoreCompletionBlock = nil;
  }
}

- (void)remoteStore:(MDRemoteStore *)remoteStore
    authenticationFailWithError:(NSError *)error
                       response:(NSHTTPURLResponse *)response
                   responseData:(NSData *)data {
  if (self.createStoreCompletionBlock != nil) {
    self.createStoreCompletionBlock(error, NO);
    self.createStoreCompletionBlock = nil;
  }
}

#pragma mark - MDFetchResponseReceiver
- (void)fetchRequest:(MDFetchRequest *)request didFinishPerformFetchWithResult:(MDFetchResult *)result fromCache:(BOOL)fromCache error:(NSError *)error {
  if (error != nil && [error code] != MDCoreDataInternetUnavailableError) {
    NSLog(@"Did finish fetch request with error: %@", [error localizedDescription]);
  }
  if (!request.inProgress) {
    NSDictionary *requestInfo = [request userInfo];
    NSString *callbackId = [requestInfo objectForKey:kTPLManagedRequestCallbackId];
    void (^callback)(NSError *error, NSArray<MDManagedObject *> *managedObjects) = nil;
    if (callbackId != nil) {
      callback = [self.reqeustsCallbacks objectForKey:callbackId];
    }
    __block NSError *updError = error;
    __weak typeof(self) weakSelf = self;
    [weakSelf.childContext performBlock:^{
      NSArray *items = nil;
      if (updError == nil && [[result items] count] > 0) {
        NSArray *resultItems = [result items];
        NSEntityDescription *entity = [[resultItems firstObject] entity];
        NSArray *itemsIdsProp = [resultItems valueForKey:@"idProp"];

        NSFetchRequest *childFetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *childEntity = [NSEntityDescription entityForName:[entity name] inManagedObjectContext:weakSelf.childContext];
        [childFetchRequest setEntity:childEntity];
        [childFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K IN %@", @"idProp", itemsIdsProp]];
        items = [weakSelf.childContext executeFetchRequest:childFetchRequest error:&updError];
        [weakSelf.childContext refreshAllObjects];
        if (updError != nil) {
          NSLog(@"Failed to execute fetch request from child context: %@", updError);
        }
      }
      dispatch_async(dispatch_get_main_queue(), ^{
        if (callback != nil) {
          callback(updError, items);
          [weakSelf.reqeustsCallbacks removeObjectForKey:callbackId];
        }
      });
    }];
  }
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

- (TestDataProvider *)provider {
  if (_provider == nil) {
    _provider = [[TestDataProvider alloc] initWithEntityNames:@[ NSStringFromClass([ParentEntity class]), NSStringFromClass([RelatedEntity class]) ]];
  }
  return _provider;
}

@end
