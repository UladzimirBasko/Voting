//
//  EntitiesStorage.m
//  MDCoreDataTemp
//
//  Created by Vladimir on 12/1/16.
//  Copyright © 2016 senla. All rights reserved.
//

#import "EntitiesStorage.h"
#import <MDCoreData/MDUtility.h>

static const NSString *parentEntitiesRootKey = @"ParentEntities";
static const NSString *relatedEntitiesRootKey = @"RelatedEntities";
static const NSString *relationshipsRootKey = @"ParentHasRelated";

@interface EntitiesStorage ()

@property(nonatomic, strong) NSDictionary *entities;

- (void)setupStorage;
- (void)saveJSONObject:(id)jsonObject
        withCompletion:
            (void (^)(NSInputStream *inputStream, NSError *error))completion;
- (NSString *)tempDirectoryPath;

@end

@implementation EntitiesStorage

+ (EntitiesStorage *)sharedStorage {
  static EntitiesStorage *sharedStorage = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedStorage = [[EntitiesStorage alloc] init];
  });
  return sharedStorage;
}

- (instancetype)init {
  self = [super init];
  if (self != nil) {
    [self setupStorage];
  }
  return self;
}

#pragma mark - Public Interface
- (void)fetchParentEntititesWithIds:(NSArray<NSString *> *)ids
                         completion:(void (^)(NSInputStream *inputStream,
                                              NSError *error))completion {
  NSDictionary *parentEntitites =
      [self.entities objectForKey:parentEntitiesRootKey];
  NSDictionary *relationships =
      [self.entities objectForKey:relationshipsRootKey];
  NSDictionary *relatedEntities =
      [self.entities objectForKey:relatedEntitiesRootKey];

  NSMutableArray *result = [[NSMutableArray alloc] init];

  for (NSString *parentEntityId in [parentEntitites allKeys]) {
    if ([ids count] == 0 || [ids containsObject:parentEntityId]) {

      NSMutableDictionary *mutParentEntity = [[NSMutableDictionary alloc]
          initWithDictionary:[parentEntitites objectForKey:parentEntityId]];

      NSMutableArray *relatedEntitiesProp = [[NSMutableArray alloc] init];

      if ([[relationships allKeys] containsObject:parentEntityId]) {
        NSArray *relatedEntititesIds =
            [relationships objectForKey:parentEntityId];
        for (NSString *relatedEntityId in relatedEntititesIds) {
          NSDictionary *relatedEntity =
              [relatedEntities objectForKey:relatedEntityId];
          [relatedEntitiesProp addObject:relatedEntity];
        }
      }
      [mutParentEntity setObject:relatedEntitiesProp forKey:@"relatedEntities"];
      [result addObject:mutParentEntity];
    }
  }
  [self saveJSONObject:result withCompletion:completion];
}

- (void)fetchRelatedEntititesWithIds:(NSArray<NSString *> *)ids
                          completion:(void (^)(NSInputStream *inputStream,
                                               NSError *error))completion {
  NSDictionary *relatedEntities =
      [self.entities objectForKey:relatedEntitiesRootKey];

  NSMutableArray *result = [[NSMutableArray alloc] init];
  for (NSString *relatedEntityId in [relatedEntities allKeys]) {
    if ([ids count] == 0 || [ids containsObject:relatedEntityId]) {
      [result addObject:[relatedEntities objectForKey:relatedEntityId]];
    }
  }
  [self saveJSONObject:result withCompletion:completion];
}

- (void)failedFetchWithCompletion:(void (^)(NSInputStream *inputStream,
                                            NSError *error))completion {
  NSError *noInternetConnectionError = [NSError
      errorWithDomain:NSURLErrorDomain
                 code:NSURLErrorNotConnectedToInternet
             userInfo:@{
               NSLocalizedDescriptionKey : @"The connection failed because the "
                                           @"device is not connected to the "
                                           @"internet"
             }];
  if (completion != nil) {
    completion(nil, noInternetConnectionError);
  }
}

#pragma mark - Private Interface
- (void)setupStorage {
  NSString *entitiesFilePath =
      [[NSBundle mainBundle] pathForResource:@"Entities" ofType:@"json"];
  NSInputStream *inputStream =
      [NSInputStream inputStreamWithFileAtPath:entitiesFilePath];
  [inputStream open];
  NSError *serializeError = nil;
  NSDictionary *locEntities =
      [NSJSONSerialization JSONObjectWithStream:inputStream
                                        options:0
                                          error:&serializeError];
  [inputStream close];
  if (serializeError != nil) {
    NSLog(@"Failed to setup storage: %@",
          [serializeError localizedDescription]);
  }
  self.entities = [[NSDictionary alloc] initWithDictionary:locEntities];
}

- (void)saveJSONObject:(id)jsonObject
        withCompletion:
            (void (^)(NSInputStream *inputStream, NSError *error))completion {
  NSString *filePath = [self tempDirectoryPath];
  NSOutputStream *outputStream =
      [NSOutputStream outputStreamToFileAtPath:filePath append:YES];
  [outputStream open];
  NSError *writeError = nil;
  [NSJSONSerialization writeJSONObject:jsonObject
                              toStream:outputStream
                               options:0
                                 error:&writeError];
  NSInputStream *inputStream = nil;
  if (writeError != nil) {
    NSLog(@"Failed to write json object to output stream: %@",
          [writeError localizedDescription]);
  } else {
    inputStream = [NSInputStream inputStreamWithFileAtPath:filePath];
  }
  if (completion != nil) {
    completion(inputStream, writeError);
  }
}

- (NSString *)tempDirectoryPath {
  CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
  NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(
      kCFAllocatorDefault, uuid);
  CFRelease(uuid);
  return [MDTemporaryDirectory() stringByAppendingPathComponent:uuidString];
}

@end
