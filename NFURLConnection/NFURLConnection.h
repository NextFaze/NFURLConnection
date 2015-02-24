//
//  NFURLConnection.h
//
//  Created by Andrew Williams on 15/09/11.
//  Copyright 2011 NextFaze. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NFURLRequest.h"
#import "NFURLResponse.h"

@interface NFURLConnection : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, readonly) int requestCount;

- (void)sendRequest:(NFURLRequest *)request;

- (void)cancelAllOperations;

@end
