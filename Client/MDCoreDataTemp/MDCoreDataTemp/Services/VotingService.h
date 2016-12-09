//
//  VotingService.h
//  MDCoreDataTemp
//
//  Created by Vladimir on 12/4/16.
//  Copyright © 2016 senla. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MDCredential, Participant, Result;

@interface VotingService : NSObject

+ (VotingService *)sharedService;

- (void)createRemoteStoreWithUserName:(NSString *)userName
                             password:(NSString *)password
                        andCompletion:(void (^)(NSError *error, MDCredential *credential))completion;

- (void)fetchPartcicipantsWithCompletion:(void (^)(NSError *error, NSArray<Participant *> *participants))completion;
- (void)fetchResultssWithCompletion:(void (^)(NSError *error, NSArray<Result *> *results))completion;
- (void)voteForParticipantWith:(Participant *)participant withCompletion:(void (^)(NSError *error))completion;

@end
