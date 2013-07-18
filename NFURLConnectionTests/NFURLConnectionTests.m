//
//  NFURLConnectionTests.m
//  NFURLConnectionTests
//
//  Created by Andrew Williams on 19/12/11.
//  Copyright (c) 2011 NextFaze. All rights reserved.
//

#import "NFURLConnectionTests.h"

// use a site that uses a self-signed certificate
#define SelfSignedURL @"https://www.pcwebshop.co.uk/"

@implementation NFURLConnectionTests

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
    STFail(@"Unit tests are not implemented yet in NFURLConnectionTests");
}

@end
