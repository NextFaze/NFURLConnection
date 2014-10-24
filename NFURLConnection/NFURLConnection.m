//
//  NFURLConnection.m
//
//  Created by Andrew Williams on 15/09/11.
//  Copyright 2011 NextFaze. All rights reserved.
//

#import "NFURLConnection.h"

@implementation NFURLConnection

- (id)init {
    self = [super init];
    if(self) {
        _queue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (id)initWithDelegate:(NSObject<NFURLConnectionDelegate> *)d {
    self = [self init];
    if(self) {
        self.delegate = d;
    }
    return self;
}

- (void)dealloc {
    _delegate = nil;

    [self cancelAllOperations];
}

#pragma mark -

- (void)notifyDelegate:(NFURLRequest *)req {
    [self.delegate NFURLConnection:self requestCompleted:req];
}

#pragma mark -

- (int)executingRequestCount {
    int count = 0;
    for(NSOperation *op in self.queue.operations) {
        if([op isExecuting]) count++;
    }
    return count;
}

- (int)outstandingRequestCount {
    int count = 0;
    for(NSOperation *op in self.queue.operations) {
        if(![op isFinished]) count++;
    }
    return count;
}

- (void)cancelAllOperations {
    LOG(@"cancelling all operations");
    for(NSOperation *op in self.queue.operations) {
        if(!([op isFinished] || [op isCancelled])) {
            LOG(@"cancelling operation: %@", op);
            [op removeObserver:self forKeyPath:@"isFinished"];
            [op cancel];
        }
    }
    LOG(@"cancelling queue operations");
    [self.queue cancelAllOperations];
    LOG(@"done");
}

- (NFURLResponse *)sendSynchronousRequest:(NFURLRequest *)request {
    return [NFURLRequest sendSynchronousRequest:request];
}

- (void)sendRequest:(NFURLRequest *)request {
    [request addObserver:self forKeyPath:@"isFinished" options:0 context:nil];
    
    @try {
        [self.queue addOperation:request];
    }
    @catch (NSException *exception) {
        LOG(@"Operation error %@", exception);
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"isFinished"]) {
        NFURLRequest *req = object;
        [self performSelectorOnMainThread:@selector(notifyDelegate:) withObject:req waitUntilDone:YES];
    }
}

@end
