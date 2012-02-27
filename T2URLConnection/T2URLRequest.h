//
//  T2URLRequest.h
//
//  Created by Andrew Williams on 15/09/11.
//  Copyright 2011 NextFaze. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "T2URLResponse.h"

#define T2URLRequestDefaultContentType @"application/x-www-form-urlencoded"

@interface T2URLRequest : NSOperation <NSURLConnectionDelegate> {
    int requestType;
    id tag;
    NSMutableURLRequest *req;
    NSMutableDictionary *parameters;
    NSString *stringBoundary;
    
    T2URLResponse *response;

    @private
    BOOL isExecuting, isFinished;
}

@property (nonatomic, retain) NSMutableURLRequest *req;
@property (nonatomic, assign) int requestType;
@property (nonatomic, retain) id tag;
@property (nonatomic, retain) NSDictionary *parameters;
@property (nonatomic, retain) NSURL *URL;
@property (nonatomic, retain) NSString *HTTPMethod, *contentType;
@property (nonatomic, readonly) BOOL isExecuting, isFinished;
@property (nonatomic, retain) T2URLResponse *response;

+ (T2URLRequest *)requestWithURL:(NSURL *)url;
+ (T2URLRequest *)requestWithURL:(NSURL *)url parameters:(NSDictionary *)params;
+ (T2URLRequest *)requestWithType:(int)requestType;

+ (T2URLResponse *)sendSynchronousRequest:(T2URLRequest *)request;

- (id)initWithURL:(NSURL *)url parameters:(NSDictionary *)params;
- (id)initWithURL:(NSURL *)url;
- (id)initWithRequestType:(int)requestType;

- (void)setParameters:(NSDictionary *)params;
- (void)setParameterValue:(id)value forKey:(NSString *)key;

- (NSURLRequest *)urlRequest;

@end
