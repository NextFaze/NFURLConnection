//
//  NFURLConnection.m
//
//  Created by Andrew Williams on 15/09/11.
//  Copyright 2011 NextFaze. All rights reserved.
//

#import "NFURLConnection.h"

#define NETWORK_TIMEOUT 30

@interface NFURLConnection ()
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, assign) int requestCount;
@end

@implementation NFURLConnection

- (id)init {
    self = [super init];
    if(self) {
        [self setupSession];
    }
    return self;
}

- (void)dealloc {
    [self cancelAllOperations];
}

- (void)setupSession {
    [self.session finishTasksAndInvalidate];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.HTTPMaximumConnectionsPerHost = 3;
    config.HTTPShouldUsePipelining = YES;
    config.timeoutIntervalForRequest = NETWORK_TIMEOUT;
    
    self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
}

#pragma mark -

- (void)cancelAllOperations {
    LOG(@"cancelling all operations");
    [self.session invalidateAndCancel];
    LOG(@"done");
}

- (void)updateNetworkCount:(int)count {
    self.requestCount += count;
    //[BJApp sharedApplication].networkActivityIndicatorVisible = self.requestCount > 0;
}

- (void)sendRequest:(NFURLRequest *)request {
    [self sendRequest:request handler:nil];
}

- (void)sendRequest:(NFURLRequest *)request handler:(NFURLResponseHandler)handler {
    [self updateNetworkCount:1];
    NSURLSessionTask *task = [self.session dataTaskWithRequest:request completionHandler:
                              ^(NSData *data, NSURLResponse *response, NSError *error) {
                                  [self handleResponse:response data:data error:error request:request];
                                  [self updateNetworkCount:-1];
                              }];
    [task resume];
}

- (void)handleResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *)error request:(NFURLRequest *)request
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NFURLResponse *r = [[NFURLResponse alloc] init]; //responseWithResponse:response data:data error:error];
    r.data = data;
    r.error = error;
    r.httpResponse = httpResponse;

    if(request.handler)
        request.handler(r);
}

@end
