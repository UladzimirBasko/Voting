//
//  TestModel.m
//  MDCoreDataTemp
//
//  Created by Vladimir on 11/24/16.
//  Copyright © 2016 senla. All rights reserved.
//

#import <MDCoreData/MDEntityCachePolicy.h>
#import "TestModel.h"

@implementation Participant

@dynamic idProp;
@dynamic name;
@dynamic region;
@dynamic result;

@end

@implementation Region

@dynamic idProp;
@dynamic name;
@dynamic participants;

@end

@implementation Result

@dynamic idProp;
@dynamic count;
@dynamic participant;

@end

@implementation TestModel

- (instancetype)init {
  self = [super init];
  if (self != nil) {
    NSMutableArray *entities = [NSMutableArray new];

    MD_DefineEntity(Participant, Participant, Participant, Participant, caf_identityId, , NSStringFromClass([self class]));
    MD_DefineEntity(Region, Region, Region, Region, caf_identityId, , NSStringFromClass([self class]));
    MD_DefineEntity(Result, Result, Result, Result, caf_identityId, , NSStringFromClass([self class]));

    MD_BeginDeclarePropertiesForEntity(Participant);
    MD_AddAttribute(idProp, idProp, NSStringAttributeType, NO, );
    MD_AddAttribute(name, name, NSStringAttributeType, YES, );
    MD_AddRelationship(region, region, Region, NSNullifyDeleteRule, YES, 0, 1, YES, participants);
    MD_AddRelationship(result, result, Result, NSNullifyDeleteRule, YES, 0, 1, YES, participant);
    MD_EndDeclarePropertiesForEntity(Participant);

    MD_BeginDeclarePropertiesForEntity(Region);
    MD_AddAttribute(idProp, idProp, NSStringAttributeType, NO, );
    MD_AddAttribute(name, name, NSStringAttributeType, YES, );
    MD_AddRelationship(participants, participants, Participant, NSNullifyDeleteRule, YES, 0, , YES, region);
    MD_EndDeclarePropertiesForEntity(Region);

    MD_BeginDeclarePropertiesForEntity(Result);
    MD_AddAttribute(idProp, idProp, NSStringAttributeType, NO, );
    MD_AddAttribute(count, count, NSInteger32AttributeType, YES, 0);
    MD_AddRelationship(participant, participant, Participant, NSNullifyDeleteRule, YES, 0, 1, YES, result);
    MD_EndDeclarePropertiesForEntity(Result);

    [self setEntities:entities];
    [self setVersionIdentifiers:[NSSet setWithObject:NSStringFromClass([self class])]];
  }
  return self;
}

+ (NSArray *)cachePolicies {
  MDEntityCachePolicy *participantEntityCachePolicy = [MDEntityCachePolicy entityCachePolicyWithEntityName:NSStringFromClass([Participant class])
                                                                                              durationDays:MDCachePolicyUnlimited
                                                                                             durationHours:MDCachePolicyUnlimited];
  MDEntityCachePolicy *regionEntityCachePolicy = [MDEntityCachePolicy entityCachePolicyWithEntityName:NSStringFromClass([Region class])
                                                                                         durationDays:MDCachePolicyUnlimited
                                                                                        durationHours:MDCachePolicyUnlimited];
  MDEntityCachePolicy *resultEntityCachePolicy = [MDEntityCachePolicy entityCachePolicyWithEntityName:NSStringFromClass([Result class])
                                                                                         durationDays:MDCachePolicyUnlimited
                                                                                        durationHours:MDCachePolicyUnlimited];
  return @[ participantEntityCachePolicy, regionEntityCachePolicy, resultEntityCachePolicy ];
}

@end
