//
//  TestModel.m
//  MDCoreDataTemp
//
//  Created by Vladimir on 11/24/16.
//  Copyright © 2016 senla. All rights reserved.
//

#import "TestModel.h"
#import <MDCoreData/MDEntityCachePolicy.h>

@implementation ParentEntity

@dynamic idProp;
@dynamic name;
@dynamic aboutDescription;
@dynamic versionProp;
@dynamic isValidProp;
@dynamic relatedEntities;

@end

@implementation RelatedEntity

@dynamic idProp;
@dynamic name;
@dynamic aboutDescription;
@dynamic versionProp;
@dynamic isValidProp;
@dynamic parent;

@end

@implementation TestModel

- (instancetype)init {
  self = [super init];
  if (self != nil) {

    NSMutableArray *entities = [NSMutableArray new];

    MD_DefineEntity(ParentEntity, ParentEntity, ParentEntity, ParentEntity,
                    caf_identityId, , NSStringFromClass([self class]));
    MD_DefineEntity(RelatedEntity, RelatedEntity, RelatedEntity, RelatedEntity,
                    caf_identityId, , NSStringFromClass([self class]));

    MD_BeginDeclarePropertiesForEntity(ParentEntity);
    MD_AddAttribute(idProp, idProp, NSStringAttributeType, NO, );
    MD_AddAttribute(name, name, NSStringAttributeType, YES, );
    MD_AddAttribute(aboutDescription, aboutDescription, NSStringAttributeType,
                    YES, );
    MD_AddAttribute(versionProp, versionProp, NSDoubleAttributeType, YES, );
    MD_AddAttribute(isValidProp, isValidProp, NSBooleanAttributeType, YES, );
    MD_AddRelationship(relatedEntities, relatedEntities, RelatedEntity,
                       NSNullifyDeleteRule, YES, 0, , YES, parent);
    MD_EndDeclarePropertiesForEntity(ParentEntity);

    MD_BeginDeclarePropertiesForEntity(RelatedEntity);
    MD_AddAttribute(idProp, idProp, NSStringAttributeType, NO, );
    MD_AddAttribute(name, name, NSStringAttributeType, YES, );
    MD_AddAttribute(aboutDescription, aboutDescription, NSStringAttributeType,
                    YES, );
    MD_AddAttribute(versionProp, versionProp, NSDoubleAttributeType, YES, );
    MD_AddAttribute(isValidProp, isValidProp, NSBooleanAttributeType, YES, );
    MD_AddRelationship(parent, parent, ParentEntity, NSNullifyDeleteRule, YES,
                       0, 1, NO, relatedEntities);
    MD_EndDeclarePropertiesForEntity(RelatedEntity);

    [self setEntities:entities];
    [self setVersionIdentifiers:[NSSet setWithObject:NSStringFromClass(
                                                         [self class])]];
  }
  return self;
}

+ (NSArray *)cachePolicies {
  MDEntityCachePolicy *parentEntityCachePolicy = [MDEntityCachePolicy
      entityCachePolicyWithEntityName:NSStringFromClass([ParentEntity class])
                         durationDays:MDCachePolicyUnlimited
                        durationHours:MDCachePolicyUnlimited];
  MDEntityCachePolicy *relatedEntityCachePolicy = [MDEntityCachePolicy
      entityCachePolicyWithEntityName:NSStringFromClass([RelatedEntity class])
                         durationDays:MDCachePolicyUnlimited
                        durationHours:MDCachePolicyUnlimited];
  return @[ parentEntityCachePolicy, relatedEntityCachePolicy ];
}

@end
