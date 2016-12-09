//
//  LTHTTPClient.m
//  LondonTalks
//
//  Created by Vladimir on 10/5/15.
//  Copyright (c) 2015 Dario Banno. All rights reserved.
//

#import "Constants.h"
#import "LTHTTPClient.h"

@interface LTHTTPClient ()

- (void)clearCookies;

@end

@implementation LTHTTPClient

+ (LTHTTPClient *)sharedClient {
  static LTHTTPClient *sharedClinet = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedClinet = [[LTHTTPClient alloc] init];
  });
  return sharedClinet;
}

- (instancetype)init {
  self = [super initWithBaseURL:[NSURL URLWithString:kServerPath]];
  if (self != nil) {
    [self setUpClient];
  }
  return self;
}

- (void)resetClient {
  [self.operationQueue cancelAllOperations];
  [self clearCookies];
  [self setUpClient];
}

- (void)POSTRequestOperationWithPath:(NSString *)path
                                body:(NSDictionary *)body
                        successBlock:(void (^)(AFHTTPRequestOperation *operation, id responceObject))successBlock
                           failBlock:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failBlock {
  NSLog(@"REQUEST method:POST path:%@\nrequest headers:\n%@\n body:\n%@", [NSString stringWithFormat:@"%@%@", self.baseURL, path],
        self.requestSerializer.HTTPRequestHeaders, body);

  void (^successBlockWithLogging)(AFHTTPRequestOperation *operation, id responceObject) = ^(AFHTTPRequestOperation *operation, id responceObject) {
    NSLog(@"RESPONCE SUCCESS mehtod:POST path:%@\nresponce headers:\n%@\n body:\n%@",
          [NSString stringWithFormat:@"%@%@", self.baseURL, operation.request.URL.path], operation.request.allHTTPHeaderFields, responceObject);
    if (successBlock != nil) {
      successBlock(operation, responceObject);
    }
  };

  void (^failureBlockWithLogging)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error) {
    NSLog(@"RESPONCE FAILURE mehtod:POST path:%@\nresponce headers:\n%@\nerror: \n%@",
          [NSString stringWithFormat:@"%@%@", self.baseURL, operation.request.URL.path], operation.request.allHTTPHeaderFields, error);
    if (failBlock != nil) {
      failBlock(operation, error);
    }
  };

  [self POST:path parameters:body success:successBlockWithLogging failure:failureBlockWithLogging];
}

#pragma mark - Private Methods
- (void)setUpClient {
  AFJSONRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
  [requestSerializer setTimeoutInterval:180];
  [requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
  [requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  [self setRequestSerializer:requestSerializer];

  AFJSONResponseSerializer *responceSerializer = [AFJSONResponseSerializer serializer];
  [self setResponseSerializer:responceSerializer];
}

- (void)clearCookies {
  NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
  [self.requestSerializer clearAuthorizationHeader];
  NSURL *baseURL = [self baseURL];
  NSArray *cookies = [storage cookiesForURL:baseURL];
  for (NSHTTPCookie *cookie in cookies) {
    [storage deleteCookie:cookie];
  }
}

@end
