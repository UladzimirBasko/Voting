//
//  TestWork.m
//  MDCoreDataTemp
//
//  Created by Vladimir on 11/25/16.
//  Copyright © 2016 senla. All rights reserved.
//

#import "EntitiesStorage.h"
#import "TestModel.h"
#import "TestWork.h"

@interface TestWork ()

- (void)loadParentEntityWithCompletion:
    (void (^_Nonnull)(NSInputStream *_Nullable dataStream,
                      NSError *_Nullable error))completionBlock;
- (void)loadRelatedEntityWithCompletion:
    (void (^_Nonnull)(NSInputStream *_Nullable dataStream,
                      NSError *_Nullable error))completionBlock;
- (NSArray *)parseParentEntityData:(NSInputStream *)inputStream
                intoManagedContext:(NSManagedObjectContext *)context
                       withRequest:(MDFetchRequest *)request
                             error:(NSError *__autoreleasing *)error;
- (NSArray *)parseRelateData:(NSInputStream *)inputStream
          intoManagedContext:(NSManagedObjectContext *)context
                 withRequest:(MDFetchRequest *)request
                       error:(NSError *__autoreleasing *)error;
- (RelatedEntity *)relatedEntityFromDict:(NSDictionary *)dict;
- (ParentEntity *)parentEntityFromDict:(NSDictionary *)dict;

@end

@implementation TestWork

#pragma mark - Private Interface
- (void)loadParentEntityWithCompletion:
    (void (^_Nonnull)(NSInputStream *_Nullable dataStream,
                      NSError *_Nullable error))completionBlock {
  NSDictionary *userInfo = [self.fetchRequest userInfo];
  NSArray *requestedIds = [userInfo objectForKey:@"ids"];
  [[EntitiesStorage sharedStorage] fetchParentEntititesWithIds:requestedIds
                                                    completion:completionBlock];
}

- (void)loadRelatedEntityWithCompletion:
    (void (^_Nonnull)(NSInputStream *_Nullable dataStream,
                      NSError *_Nullable error))completionBlock {
  NSDictionary *userInfo = [self.fetchRequest userInfo];
  NSArray *requestedIds = [userInfo objectForKey:@"ids"];
  [[EntitiesStorage sharedStorage]
      fetchRelatedEntititesWithIds:requestedIds
                        completion:completionBlock];
}

- (NSArray *)parseParentEntityData:(NSInputStream *)inputStream
                intoManagedContext:(NSManagedObjectContext *)context
                       withRequest:(MDFetchRequest *)request
                             error:(NSError *__autoreleasing *)error {
  [inputStream open];
  NSArray *parentObjects = [NSJSONSerialization JSONObjectWithStream:inputStream
                                                             options:0
                                                               error:error];
  NSMutableArray *result = [NSMutableArray new];
  for (NSDictionary *parentObject in parentObjects) {
    ParentEntity *parentEntity = [self parentEntityFromDict:parentObject];
    if (parentEntity != nil) {
      [result addObject:parentEntity];
    }
  }
  return result;
}

- (NSArray *)parseRelateData:(NSInputStream *)inputStream
          intoManagedContext:(NSManagedObjectContext *)context
                 withRequest:(MDFetchRequest *)request
                       error:(NSError *__autoreleasing *)error {
  [inputStream open];
  NSArray *relatedObjects =
      [NSJSONSerialization JSONObjectWithStream:inputStream
                                        options:0
                                          error:error];
  NSMutableArray *result = [NSMutableArray new];
  for (NSDictionary *relatedObject in relatedObjects) {
    RelatedEntity *relatedEntity = [self relatedEntityFromDict:relatedObject];
    if (relatedEntity != nil) {
      [result addObject:relatedEntity];
    }
  }
  return result;
}

- (RelatedEntity *)relatedEntityFromDict:(NSDictionary *)dict {
  RelatedEntity *relatedEntity = nil;
  NSString *idProp = [dict objectForKey:@"idProp"];
  NSString *name = [dict objectForKey:@"name"];
  NSString *aboutDescription = [dict objectForKey:@"aboutDescription"];
  NSNumber *versionProp = [dict objectForKey:@"versionProp"];
  NSNumber *isValidProp = [dict objectForKey:@"isValidProp"];
  if (idProp != nil) {
    relatedEntity = (RelatedEntity *)[self
        instanceOfType:NSStringFromClass([RelatedEntity class])
           andIdentity:idProp];
    [relatedEntity setName:name];
    [relatedEntity setAboutDescription:aboutDescription];
    [relatedEntity setVersionProp:versionProp];
    [relatedEntity setIsValidProp:isValidProp];
  }
  return relatedEntity;
}

- (ParentEntity *)parentEntityFromDict:(NSDictionary *)dict {
  ParentEntity *parentEntity = nil;
  NSString *idProp = [dict objectForKey:@"idProp"];
  NSString *name = [dict objectForKey:@"name"];
  NSString *aboutDescription = [dict objectForKey:@"aboutDescription"];
  NSNumber *versionProp = [dict objectForKey:@"versionProp"];
  NSNumber *isValidProp = [dict objectForKey:@"isValidProp"];
  NSArray *relatedObjects = [dict objectForKey:@"relatedEntities"];
  if (idProp != nil) {
    parentEntity = (ParentEntity *)[self
        instanceOfType:NSStringFromClass([ParentEntity class])
           andIdentity:idProp];
    [parentEntity setName:name];
    [parentEntity setAboutDescription:aboutDescription];
    [parentEntity setVersionProp:versionProp];
    [parentEntity setIsValidProp:isValidProp];

    NSMutableOrderedSet *relatedEntitites = [NSMutableOrderedSet new];
    for (NSDictionary *relatedObject in relatedObjects) {
      RelatedEntity *relatedEntity = [self relatedEntityFromDict:relatedObject];
      if (relatedEntity != nil) {
        [relatedEntitites addObject:relatedEntity];
      }
    }
    [parentEntity setRelatedEntities:relatedEntitites];
  }
  return parentEntity;
}

#pragma mark - MDNetworkItem
- (BOOL)isNSURLCompatible {
  return NO;
}

- (void)loadRemoteData:
    (void (^_Nonnull)(NSInputStream *_Nullable dataStream,
                      NSError *_Nullable error))completionBlock {
  NSString *requestedName = [[self.fetchRequest entity] name];
  NSNumber *failedRequest =
      [[self.fetchRequest userInfo] objectForKey:@"failedRequest"];
  if (failedRequest.boolValue) {
    [[EntitiesStorage sharedStorage] failedFetchWithCompletion:completionBlock];
  } else if ([requestedName
                 isEqualToString:NSStringFromClass([ParentEntity class])]) {
    [self loadParentEntityWithCompletion:completionBlock];
  } else if ([requestedName
                 isEqualToString:NSStringFromClass([RelatedEntity class])]) {
    [self loadRelatedEntityWithCompletion:completionBlock];
  } else {
    NSError *error = [NSError
        errorWithDomain:@"TestDomain"
                   code:-1
               userInfo:@{
                 NSLocalizedDescriptionKey : @"Requested Entity not found"
               }];
    if (completionBlock != nil) {
      completionBlock(nil, error);
    }
  }
}

- (void)logRequestCompletion:(NSURLRequest *_Nullable)request
                withResponse:(NSHTTPURLResponse *_Nullable)response
                    andError:(NSError *_Nullable)error {
  if (error != nil) {
    NSLog(@"%@", [error localizedDescription]);
  }
}

#pragma mark - MDFetchDataWork
- (NSArray *)parseHttpData:(NSInputStream *)httpData
                forRequest:(MDFetchRequest *)request
          httpDataMimeType:(NSString *)httpDataMimeType
        intoManagedContext:(NSManagedObjectContext *)context
                     error:(NSError *__autoreleasing *)error {
  if (*error != nil) {
    return nil;
  } else {
    NSString *requestedName = [[request entity] name];
    if ([requestedName
            isEqualToString:NSStringFromClass([ParentEntity class])]) {
      return [self parseParentEntityData:httpData
                      intoManagedContext:context
                             withRequest:request
                                   error:error];
    } else if ([requestedName
                   isEqualToString:NSStringFromClass([RelatedEntity class])]) {
      return [self parseRelateData:httpData
                intoManagedContext:context
                       withRequest:request
                             error:error];
    } else {
      return nil;
    }
  }
}

@end
