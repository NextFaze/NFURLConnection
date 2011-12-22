//
//  T2URLConnection.h
//
//  Created by Andrew Williams on 15/09/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "T2URLRequest.h"
#import "T2URLResponse.h"

@protocol T2URLConnectionDelegate;

@interface T2URLConnection : NSObject <T2URLRequestDelegate> {
    NSObject<T2URLConnectionDelegate> *delegate;
    NSOperationQueue *queue;
}

@property (nonatomic, assign) NSObject<T2URLConnectionDelegate> *delegate;
@property (nonatomic, readonly) NSOperationQueue *queue;

- (id)initWithDelegate:(NSObject<T2URLConnectionDelegate> *)delegate;

- (T2URLResponse *)sendSynchronousRequest:(T2URLRequest *)request;
- (void)sendRequest:(T2URLRequest *)request;

- (int)executingRequestCount;
- (int)outstandingRequestCount;

@end


@protocol T2URLConnectionDelegate <NSObject>

- (void)t2URLConnection:(T2URLConnection *)connection didReceiveResponse:(T2URLResponse *)response;

@end
