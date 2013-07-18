//
//  NFURLConnection.h
//
//  Created by Andrew Williams on 15/09/11.
//  Copyright 2011 NextFaze. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NFURLRequest.h"
#import "NFURLResponse.h"

@protocol NFURLConnectionDelegate;

@interface NFURLConnection : NSObject

@property (nonatomic, readonly) NSOperationQueue *queue;
@property (nonatomic, assign) id<NFURLConnectionDelegate> delegate;

- (id)initWithDelegate:(NSObject<NFURLConnectionDelegate> *)delegate;

- (NFURLResponse *)sendSynchronousRequest:(NFURLRequest *)request;
- (void)sendRequest:(NFURLRequest *)request;

- (int)executingRequestCount;
- (int)outstandingRequestCount;
- (void)cancelAllOperations;

@end

@protocol NFURLConnectionDelegate <NSObject>

- (void)NFURLConnection:(NFURLConnection *)connection requestCompleted:(NFURLRequest *)request;

@end
