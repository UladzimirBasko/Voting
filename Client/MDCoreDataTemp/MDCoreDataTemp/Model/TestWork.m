//
//  TestWork.m
//  MDCoreDataTemp
//
//  Created by Vladimir on 11/25/16.
//  Copyright © 2016 senla. All rights reserved.
//

#import "Constants.h"
#import "TestModel.h"
#import "TestWork.h"

@interface TestWork ()

- (NSMutableURLRequest *)participantsURLRequestWithId:(NSString *)participantId;
- (NSMutableURLRequest *)regionResultsURLRequest;
- (NSMutableURLRequest *)allResultsURLRequest;

- (NSArray<MDManagedObject *> *)parseParticipantsEntries:(NSArray *)entries error:(NSError **)error inContext:(NSManagedObjectContext *)context;
- (NSArray<MDManagedObject *> *)parseResultsEntries:(NSArray *)entries error:(NSError **)error inContext:(NSManagedObjectContext *)context;
- (NSArray *)parseStream:(NSInputStream *)stream error:(NSError **)error;

- (Participant *)participantFromDict:(NSDictionary *)participantDict;
- (Participant *)participantWithRegionFromDict:(NSDictionary *)participantDict;
- (Region *)regionFromDict:(NSDictionary *)regionDict;
- (Result *)resultFromDict:(NSDictionary *)resultDict;

@end

@implementation TestWork

#pragma mark - Private Interface
- (NSMutableURLRequest *)participantsURLRequestWithId:(NSString *)participantId {
  NSString *stringURL = [kServerPath stringByAppendingPathComponent:kParticipantsPath];
  if (participantId != nil) {
    stringURL = [stringURL stringByAppendingPathComponent:participantId];
  }
  return [NSMutableURLRequest requestWithURL:[NSURL URLWithString:stringURL]];
}

- (NSMutableURLRequest *)regionResultsURLRequest {
  return [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[kServerPath stringByAppendingPathComponent:kRestultsRegionPath]]];
}

- (NSMutableURLRequest *)allResultsURLRequest {
  return [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[kServerPath stringByAppendingPathComponent:kRestultsAllPath]]];
}

- (NSArray<MDManagedObject *> *)parseParticipantsEntries:(NSArray *)entries error:(NSError **)error inContext:(NSManagedObjectContext *)context {
  NSMutableArray *managedObjects = [NSMutableArray new];
  for (NSDictionary *participantDict in entries) {
    Participant *participant = [self participantWithRegionFromDict:participantDict];
    [managedObjects addObject:participant];
  }
  return managedObjects;
}

- (NSArray<MDManagedObject *> *)parseResultsEntries:(NSArray *)entries error:(NSError **)error inContext:(NSManagedObjectContext *)context {
  NSMutableArray *managedObjects = [NSMutableArray new];
  for (NSDictionary *resultDict in entries) {
    Result *result = [self resultFromDict:resultDict];
    NSDictionary *participantDict = [resultDict objectForKey:@"participant"];
    Participant *participant = [self participantWithRegionFromDict:participantDict];
    [participant setResult:result];
    [managedObjects addObject:result];
  }
  return managedObjects;
}

- (NSArray *)parseStream:(NSInputStream *)stream error:(NSError **)error {
  [stream open];
  NSArray *entries = nil;
  @try {
    entries = [NSJSONSerialization JSONObjectWithStream:stream options:0 error:error];
    if (*error == nil) {
      if ([entries isKindOfClass:[NSArray class]]) {
        return entries;
      } else if ([entries isKindOfClass:[NSDictionary class]]) {
        return @[ entries ];
      } else {
        return nil;
      }
    }
  } @catch (NSException *exception) {
    *error = [NSError errorWithDomain:@"TestWorkDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey : exception.reason}];
  }
  return entries;
}

- (Participant *)participantFromDict:(NSDictionary *)participantDict {
  NSNumber *participantIdProp = [participantDict objectForKey:@"id"];
  NSString *participantName = [participantDict objectForKey:@"name"];
  Participant *participant = (Participant *)[self instanceOfType:NSStringFromClass([Participant class]) andIdentity:[participantIdProp stringValue]];
  [participant setIdProp:[participantIdProp stringValue]];
  [participant setName:participantName];
  return participant;
}

- (Participant *)participantWithRegionFromDict:(NSDictionary *)participantDict {
  NSDictionary *regionDict = [participantDict objectForKey:@"region"];
  Region *region = [self regionFromDict:regionDict];
  Participant *participant = [self participantFromDict:participantDict];
  [participant setRegion:region];
  return participant;
}

- (Region *)regionFromDict:(NSDictionary *)regionDict {
  NSNumber *regionIdProp = [regionDict objectForKey:@"id"];
  NSString *regionName = [regionDict objectForKey:@"name"];
  Region *region = (Region *)[self instanceOfType:NSStringFromClass([Region class]) andIdentity:[regionIdProp stringValue]];
  [region setIdProp:[regionIdProp stringValue]];
  [region setName:regionName];
  return region;
}

- (Result *)resultFromDict:(NSDictionary *)resultDict {
  NSNumber *restultIdProp = [resultDict objectForKey:@"id"];
  NSNumber *voteCount = [resultDict objectForKey:@"voteCount"];
  Result *result = (Result *)[self instanceOfType:NSStringFromClass([Result class]) andIdentity:[restultIdProp stringValue]];
  [result setIdProp:[restultIdProp stringValue]];
  [result setCount:voteCount];
  return result;
}

#pragma mark - MDNetworkItem
- (BOOL)isNSURLCompatible {
  return YES;
}

#pragma mark - MDFetchDataWork
- (NSMutableURLRequest *)urlRequestForFetchRequest:(MDFetchRequest *)fetchRequest {
  NSMutableURLRequest *urlRequest = nil;
  NSDictionary *userInfo = fetchRequest.userInfo;
  NSString *entityName = fetchRequest.entity.name;
  if ([entityName isEqualToString:NSStringFromClass([Participant class])]) {
    NSString *participantId = [userInfo objectForKey:@"id"];
    urlRequest = [self participantsURLRequestWithId:participantId];
  } else if ([entityName isEqualToString:NSStringFromClass([Result class])]) {
    NSNumber *needFetchAllRequest = [userInfo objectForKey:@"all"];
    if ([needFetchAllRequest boolValue]) {
      urlRequest = [self allResultsURLRequest];
    } else {
      urlRequest = [self regionResultsURLRequest];
    }
  }
  return urlRequest;
}

- (NSArray *)parseHttpData:(NSInputStream *)httpData
                forRequest:(MDFetchRequest *)request
          httpDataMimeType:(NSString *)httpDataMimeType
        intoManagedContext:(NSManagedObjectContext *)theContext
              httpResponce:(NSHTTPURLResponse *)responce
                     error:(__autoreleasing NSError **)error {
  if (*error != nil) {
    return nil;
  } else {
    NSArray *entries = [self parseStream:httpData error:error];
    NSString *entityName = request.entity.name;
    if ([entityName isEqualToString:NSStringFromClass([Participant class])]) {
      return [self parseParticipantsEntries:entries error:error inContext:theContext];
    } else if ([entityName isEqualToString:NSStringFromClass([Result class])]) {
      return [self parseResultsEntries:entries error:error inContext:theContext];
    } else {
      return nil;
    }
  }
}

@end
