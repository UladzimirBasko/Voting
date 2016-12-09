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

@class MDEntityCachePolicy;
@class Region, Participant, Result;

@interface Participant : MDManagedObject

@property(nonatomic, strong) NSString *idProp;
@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) Region *region;
@property(nonatomic, strong) Result *result;

@end

@interface Region : MDManagedObject

@property(nonatomic, strong) NSString *idProp;
@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSOrderedSet<Participant *> *participants;

@end

@interface Result : MDManagedObject

@property(nonatomic, strong) NSString *idProp;
@property(nonatomic, strong) NSNumber *count;
@property(nonatomic, strong) Participant *participant;

@end

@interface TestModel : NSManagedObjectModel

+ (NSArray<MDEntityCachePolicy *> *)cachePolicies;

@end
