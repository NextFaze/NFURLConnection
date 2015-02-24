//
//  NFURLRequest.h
//
//  Created by Andrew Williams on 15/09/11.
//  Copyright 2011 NextFaze. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NFURLResponse.h"

#define NFURLRequestDefaultContentType @"application/x-www-form-urlencoded"

@interface NFURLRequest : NSMutableURLRequest

@property (nonatomic, strong) NFURLResponseHandler handler;
@property (nonatomic, readonly) NSDictionary *parameters;
@property (nonatomic, assign) int retries;
@property (nonatomic, assign) int maxRetryCount;

+ (id)requestWithHandler:(NFURLResponseHandler)handler;
+ (id)requestWithURL:(NSURL *)url handler:(NFURLResponseHandler)handler;

- (void)setHTTPMethod:(NSString *)method parameters:(NSDictionary *)parameters;

@end
