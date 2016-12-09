//
//  BTKeychainDirector.m
//  Taxi
//
//  Created by Roman on 12/16/14.
//  Copyright (c) 2014 Dancosoft. All rights reserved.
//

#import <MDCoreData/MDCredential.h>
#import "BTKeychainDirector.h"
#import "FXKeychain.h"

NSString *const kLTCredentialKey = @"lastCredential";
NSString *const kLTAccessTokenKey = @"lastAccessToken";
NSString *const kLTLoginKey = @"login";
NSString *const kLTPasswordKey = @"password";

@interface BTKeychainDirector ()
@property(nonatomic, strong) FXKeychain *keychain;

@end

@implementation BTKeychainDirector

#pragma mark - Public methods
+ (BTKeychainDirector *)sharedDirector {
  static BTKeychainDirector *sharedKeychain = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedKeychain = [[BTKeychainDirector alloc] init];
    sharedKeychain.keychain = [FXKeychain defaultKeychain];
  });
  return sharedKeychain;
}

- (BOOL)containsUserCredential {
  return ([self lastCredential] != nil);
}

- (void)saveCredential:(MDCredential *)credential {
  [self.keychain setObject:@{ kLTLoginKey : credential.user, kLTPasswordKey : credential.password } forKey:kLTCredentialKey];
}

- (MDCredential *)lastCredential {
  NSDictionary *dictionary = [self.keychain objectForKey:kLTCredentialKey];
  return (dictionary == nil)
             ? nil
             : [MDCredential credentialWithUser:[dictionary objectForKey:kLTLoginKey] password:[dictionary objectForKey:kLTPasswordKey] allowOfflineLogin:YES];
}

- (void)removeCredential {
  [self.keychain removeObjectForKey:kLTCredentialKey];
}

- (void)saveToken:(NSString *)token {
  [self.keychain setObject:token forKey:kLTAccessTokenKey];
}

- (NSString *)lastToken {
  return [self.keychain objectForKey:kLTAccessTokenKey];
}

- (void)removeToken {
  [self.keychain removeObjectForKey:kLTAccessTokenKey];
}

@end
