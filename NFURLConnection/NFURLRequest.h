//
//  NFURLRequest.h
//
//  Created by Andrew Williams on 15/09/11.
//  Copyright 2011 NextFaze. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NFURLResponse.h"

#define NFURLRequestDefaultContentType @"application/x-www-form-urlencoded"

@interface NFURLRequest : NSOperation <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, retain) NSMutableURLRequest *req;
@property (nonatomic, assign) int requestType;
@property (nonatomic, retain) id tag;
@property (nonatomic, retain) NSDictionary *parameters;
@property (nonatomic, retain) NSURL *URL;
@property (nonatomic, retain) NSString *HTTPMethod, *contentType;
@property (nonatomic, readonly) BOOL isExecuting, isFinished;
@property (nonatomic, retain) NFURLResponse *response;

+ (NFURLRequest *)request;
+ (NFURLRequest *)requestWithURL:(NSURL *)url;
+ (NFURLRequest *)requestWithURL:(NSURL *)url parameters:(NSDictionary *)params;
+ (NFURLRequest *)requestWithType:(int)requestType;

+ (NFURLResponse *)sendSynchronousRequest:(NFURLRequest *)request;

- (id)initWithURL:(NSURL *)url parameters:(NSDictionary *)params;
- (id)initWithURL:(NSURL *)url;
- (id)initWithRequestType:(int)requestType;

- (void)setParameterValue:(id)value forKey:(NSString *)key;

- (NSURLRequest *)urlRequest;

@end
