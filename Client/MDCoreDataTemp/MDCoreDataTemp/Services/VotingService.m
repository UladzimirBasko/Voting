//
//  VotingService.m
//  MDCoreDataTemp
//
//  Created by Vladimir on 12/4/16.
//  Copyright © 2016 senla. All rights reserved.
//

#import <MDCoreData/MDCoreData.h>
#import "Constants.h"
#import "LTHTTPClient.h"
#import "TestDataProvider.h"
#import "TestModel.h"
#import "VotingService.h"

static NSString *const kTPLManagedRequestCallbackId = @"callbackId";

@interface VotingService ()<MDRemoteStoreAuthenticationDelegate, MDFetchResponseReceiver>

@property(nonatomic, strong) TestDataProvider *provider;
@property(nonatomic, strong) MDRemoteStore *remoteStore;
@property(nonatomic, strong) MDRemoteStoreOptions *options;
@property(nonatomic, strong) TestModel *model;
@property(nonatomic, strong) MDManagedObjectContext *remoteContext;
@property(nonatomic, strong) NSMutableDictionary *reqeustsCallbacks;
@property(nonatomic, copy) void (^createStoreCompletionBlock)(NSError *error, MDCredential *credential);
@property(nonatomic, strong) MDCredential *credential;

@end

@implementation VotingService

- (NSString *)generateUuidString {
  CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
  NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
  CFRelease(uuid);
  return uuidString;
}

+ (VotingService *)sharedService {
  static VotingService *sharedService = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedService = [[VotingService alloc] init];
  });
  return sharedService;
}

- (instancetype)init {
  self = [super init];
  if (self != nil) {
    self.reqeustsCallbacks = [NSMutableDictionary new];
  }
  return self;
}

#pragma mark - Public Interface
- (void)createRemoteStoreWithUserName:(NSString *)userName
                             password:(NSString *)password
                        andCompletion:(void (^)(NSError *, MDCredential *credential))completion {
  if (userName == nil || password == nil) {
    self.credential = [MDCredential credentialWithDefaultUserAllowOfflineLogin:YES];
  } else {
    self.credential = [MDCredential credentialWithUser:userName password:password allowOfflineLogin:YES];
  }
  if (self.remoteStore != nil) {
    if ([self.remoteStore authenticated]) {
      if (completion != nil) {
        completion(nil, nil);
      }
    } else {
      self.createStoreCompletionBlock = completion;
      [self.remoteStore authenticateManually];
    }
    return;
  }
  self.createStoreCompletionBlock = completion;

  self.remoteStore = [[MDRemoteStore alloc] initWithStoreModel:self.model
                                                      storeURL:[NSURL URLWithString:kServerPath]
                                                          user:self.credential
                                               persistentModel:nil
                                                       options:self.options];
  [self.remoteStore setEntityCachePolicies:[TestModel cachePolicies]];
  [self.remoteStore addCustomDataProvider:self.provider];
  [self.remoteStore setAuthenticationDelegate:self];
  [self.remoteStore authenticateManually];
  self.remoteContext = [self.remoteStore remoteStoreContext];
}

- (void)fetchPartcicipantsWithCompletion:(void (^)(NSError *error, NSArray<Participant *> *participants))completion {
  NSString *callbackId = [self generateUuidString];
  MDFetchRequest *partRequest = [MDFetchRequest fetchRequestWithCachePolicy:MDFetchRequestReloadIgnoringCacheData];
  [partRequest setEntity:[NSEntityDescription entityForName:NSStringFromClass([Participant class]) inManagedObjectContext:[self remoteContext]]];
  [partRequest setUserInfo:@{kTPLManagedRequestCallbackId : callbackId}];
  [partRequest setReceiver:self];
  [self.reqeustsCallbacks setObject:completion forKey:callbackId];
  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    [weakSelf.remoteContext executeFetchRequest:partRequest];
  });
}

- (void)fetchResultssWithCompletion:(void (^)(NSError *error, NSArray<Result *> *results))completion {
  NSString *callbackId = [self generateUuidString];
  MDFetchRequest *restulRequest = [MDFetchRequest fetchRequestWithCachePolicy:MDFetchRequestReloadIgnoringCacheData];
  [restulRequest setEntity:[NSEntityDescription entityForName:NSStringFromClass([Result class]) inManagedObjectContext:[self remoteContext]]];
  [restulRequest setUserInfo:@{ kTPLManagedRequestCallbackId : callbackId, @"all" : @(YES) }];
  [restulRequest setReceiver:self];
  [self.reqeustsCallbacks setObject:completion forKey:callbackId];
  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    [weakSelf.remoteContext executeFetchRequest:restulRequest];
  });
}

- (void)voteForParticipantWith:(Participant *)participant withCompletion:(void (^)(NSError *error))completion {
  NSDictionary *body = @{ @"participantId" : participant.idProp, @"passportNumber" : self.credential.user };
  [[LTHTTPClient sharedClient] POSTRequestOperationWithPath:@"/vote"
      body:body
      successBlock:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *response = responseObject;
        NSString *status = [response objectForKey:@"status"];
        NSString *message = [response objectForKey:@"message"];
        if ([status isEqualToString:@"OK"]) {
          if (completion != nil) {
            completion(nil);
          }
        } else {
          if (completion != nil) {
            completion([NSError errorWithDomain:@"VotingErrorDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey : message}]);
          }
        }
      }
      failBlock:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion != nil) {
          completion(error);
        }
      }];
}

#pragma mark - MDRemoteStoreAuthenticationDelegate
- (void)remoteStore:(MDRemoteStore *)remoteStore
    authenticationSuccessForOfflineMode:(BOOL)offlineMode
                               response:(NSHTTPURLResponse *)response
                           responseData:(NSData *)data {
  if (self.createStoreCompletionBlock != nil) {
    self.createStoreCompletionBlock(nil, self.credential);
    self.createStoreCompletionBlock = nil;
  }
}

- (void)remoteStore:(MDRemoteStore *)remoteStore
    authenticationFailWithError:(NSError *)error
                       response:(NSHTTPURLResponse *)response
                   responseData:(NSData *)data {
  if (self.createStoreCompletionBlock != nil) {
    self.createStoreCompletionBlock(error, nil);
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
      if (callback != nil) {
        callback(error, result.items);
      }
      [self.reqeustsCallbacks removeObjectForKey:callbackId];
    }
  }
}

#pragma mark - Getters / Setters
- (MDRemoteStoreOptions *)options {
  if (_options == nil) {
    _options = [MDRemoteStoreOptions remoteStoreOptions];
    _options.checkHostAvailability = NO;
    _options.hostReachabilityType = MDHostReachabilityTypeNative;
    _options.communicationProtocol = MDRemoteStoreCommunicationProtocolCustom;
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
    _provider = [[TestDataProvider alloc]
        initWithEntityNames:@[ NSStringFromClass([Participant class]), NSStringFromClass([Region class]), NSStringFromClass([Result class]) ]];
  }
  return _provider;
}

@end
