//
//  TestModel.h
//  MDCoreDataTemp
//
//  Created by Vladimir on 11/24/16.
//  Copyright © 2016 senla. All rights reserved.
//

#import <CoreData/NSManagedObjectModel.h>
#import <MDCoreData/MDManagedObject.h>
#import <MDCoreData/MDModelDefine.h>

@class ParentEntity, RelatedEntity;
@class MDEntityCachePolicy;

@interface ParentEntity : MDManagedObject

@property(nonatomic, strong) NSString *idProp;
@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSString *aboutDescription;
@property(nonatomic, strong) NSNumber *versionProp;
@property(nonatomic, strong) NSNumber *isValidProp;
@property(nonatomic, strong) NSOrderedSet<RelatedEntity *> *relatedEntities;

@end

@interface RelatedEntity : MDManagedObject

@property(nonatomic, strong) NSString *idProp;
@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSString *aboutDescription;
@property(nonatomic, strong) NSNumber *versionProp;
@property(nonatomic, strong) NSNumber *isValidProp;
@property(nonatomic, strong) ParentEntity *parent;

@end

@interface TestModel : NSManagedObjectModel

+ (NSArray<MDEntityCachePolicy *> *)cachePolicies;

@end
