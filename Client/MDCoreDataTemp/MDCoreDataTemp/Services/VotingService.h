//
//  VotingService.h
//  MDCoreDataTemp
//
//  Created by Vladimir on 12/4/16.
//  Copyright © 2016 senla. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VotingService : NSObject

+ (VotingService *)sharedService;

- (void)createRemoteStoreWithUserName:(NSString *)userName
                             password:(NSString *)password
                        andCompletion:(void (^)(NSError *error, BOOL isOfflineLogin))completion;

@end
