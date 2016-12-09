//
//  LTHTTPClient.h
//  LondonTalks
//
//  Created by Vladimir on 10/5/15.
//  Copyright (c) 2015 Dario Banno. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"

@interface LTHTTPClient : AFHTTPRequestOperationManager

+ (LTHTTPClient *)sharedClient;
- (void)resetClient;

- (void)POSTRequestOperationWithPath:(NSString *)path
                                body:(NSDictionary *)body
                        successBlock:(void (^)(AFHTTPRequestOperation *operation, id responseObject))successBlock
                           failBlock:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failBlock;

@end
