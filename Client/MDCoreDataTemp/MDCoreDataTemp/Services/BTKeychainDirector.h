//
//  BTKeychainDirector.h
//  Taxi
//
//  Created by Roman on 12/16/14.
//  Copyright (c) 2014 Dancosoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MDCredential;

@interface BTKeychainDirector : NSObject

+ (BTKeychainDirector *)sharedDirector;

- (BOOL)containsUserCredential;

- (void)saveCredential:(MDCredential *)credential;
- (MDCredential *)lastCredential;
- (void)removeCredential;

- (void)saveToken:(NSString *)token;
- (NSString *)lastToken;
- (void)removeToken;

@end
