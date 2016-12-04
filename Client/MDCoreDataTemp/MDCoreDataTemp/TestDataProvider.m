//
//  TestDataProvider.m
//  MDCoreDataTemp
//
//  Created by Vladimir on 11/25/16.
//  Copyright © 2016 senla. All rights reserved.
//

#import "TestDataProvider.h"
#import "TestWork.h"

@implementation TestDataProvider

- (MDCustomWork *)customWorkForFetchRequest:(MDFetchRequest *)fetchRequest {
  return [TestWork new];
}

@end
