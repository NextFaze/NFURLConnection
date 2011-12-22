//
//  T2URLConnection.m
//
//  Created by Andrew Williams on 15/09/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "T2URLConnection.h"

@implementation T2URLConnection

@synthesize delegate, queue;

- (id)init {
    self = [super init];
    if(self) {
        queue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (id)initWithDelegate:(NSObject<T2URLConnectionDelegate> *)d {
    self = [self init];
    if(self) {
        self.delegate = d;
    }
    return self;
}

- (void)dealloc {
    delegate = nil;
    
    for(T2URLRequest *req in [queue operations]) {
        req.delegate = nil;
    }
    [queue cancelAllOperations];
    [queue release];
    
    [super dealloc];
}

#pragma mark -

- (void)notifyResponse:(T2URLResponse *)response {
    [delegate t2URLConnection:self didReceiveResponse:response];
}

#pragma mark -

- (int)executingRequestCount {
    int count = 0;
    for(NSOperation *op in queue.operations) {
        if([op isExecuting]) count++;
    }
    return count;
}

- (int)outstandingRequestCount {
    int count = 0;
    for(NSOperation *op in queue.operations) {
        if(![op isFinished]) count++;
    }
    return count;
}

- (T2URLResponse *)sendSynchronousRequest:(T2URLRequest *)request {
    return [T2URLRequest sendSynchronousRequest:request];
}

- (void)sendRequest:(T2URLRequest *)request {
    request.delegate = self;
    [queue addOperation:request];
}

#pragma mark - T2URLRequestDelegate

- (void)t2URLRequestCompleted:(T2URLRequest *)request response:(T2URLResponse *)response {
    [self performSelectorOnMainThread:@selector(notifyResponse:) withObject:response waitUntilDone:YES];
}

@end
