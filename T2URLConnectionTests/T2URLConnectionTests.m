//
//  T2URLConnectionTests.m
//  T2URLConnectionTests
//
//  Created by Andrew Williams on 19/12/11.
//  Copyright (c) 2011 NextFaze. All rights reserved.
//

#import "T2URLConnectionTests.h"

// use a site that uses a self-signed certificate
#define SelfSignedURL @"https://www.pcwebshop.co.uk/"

@implementation T2URLConnectionTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testSelfSignedSSL
{
    STFail(@"Unit tests are not implemented yet in T2URLConnectionTests");
}

@end
