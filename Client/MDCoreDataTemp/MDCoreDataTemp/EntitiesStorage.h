//
//  EntitiesStorage.h
//  MDCoreDataTemp
//
//  Created by Vladimir on 12/1/16.
//  Copyright © 2016 senla. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ParentEntity, RelatedEntity;

@interface EntitiesStorage : NSObject

+ (EntitiesStorage *)sharedStorage;

- (void)fetchParentEntititesWithIds:(NSArray<NSString *> *)ids
                         completion:(void (^)(NSInputStream *inputStream,
                                              NSError *error))completion;
- (void)fetchRelatedEntititesWithIds:(NSArray<NSString *> *)ids
                          completion:(void (^)(NSInputStream *inputStream,
                                               NSError *error))completion;
- (void)failedFetchWithCompletion:(void (^)(NSInputStream *inputStream,
                                            NSError *error))completion;

@end
