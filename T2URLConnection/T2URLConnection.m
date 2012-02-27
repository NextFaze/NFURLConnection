//
//  T2URLConnection.m
//
//  Created by Andrew Williams on 15/09/11.
//  Copyright 2011 NextFaze. All rights reserved.
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

    [self cancelAllOperations];
    [queue release];
    
    [super dealloc];
}

#pragma mark -

- (void)notifyDelegate:(T2URLRequest *)req {
    [delegate t2URLConnection:self requestCompleted:req];
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

- (void)cancelAllOperations {
    LOG(@"cancelling all operations");
    for(NSOperation *op in queue.operations) {
        if(!([op isFinished] || [op isCancelled])) {
            LOG(@"cancelling operation: %@", op);
            [op removeObserver:self forKeyPath:@"isFinished"];
            [op cancel];
        }
    }
    LOG(@"cancelling queue operations");
    [queue cancelAllOperations];
    LOG(@"done");
}

- (T2URLResponse *)sendSynchronousRequest:(T2URLRequest *)request {
    return [T2URLRequest sendSynchronousRequest:request];
}

- (void)sendRequest:(T2URLRequest *)request {
    [request addObserver:self forKeyPath:@"isFinished" options:0 context:nil];
    [queue addOperation:request];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"isFinished"]) {
        T2URLRequest *req = object;
        [self performSelectorOnMainThread:@selector(notifyDelegate:) withObject:req waitUntilDone:YES];
    }
}

@end
