//
//  T2URLRequest.h
//
//  Created by Andrew Williams on 15/09/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@class T2URLResponse;
@class T2URLRequest;

@protocol T2URLRequestDelegate <NSObject>
- (void)t2URLRequestCompleted:(T2URLRequest *)request response:(T2URLResponse *)response;
@end

@interface T2URLRequest : NSOperation {
    int requestType;
    int tag;
    NSMutableURLRequest *req;
    NSMutableDictionary *parameters;
    NSString *stringBoundary;
    
    // TODO: remove this delegate and use KVO
    NSObject<T2URLRequestDelegate> *delegate;

    @private
    BOOL isExecuting, isFinished;
}

@property (nonatomic, retain) NSMutableURLRequest *req;
@property (nonatomic, assign) int requestType, tag;
@property (nonatomic, retain) NSDictionary *parameters;
@property (nonatomic, retain) NSURL *URL;
@property (nonatomic, retain) NSString *HTTPMethod;
@property (nonatomic, assign) id<T2URLRequestDelegate> delegate;
@property (nonatomic, readonly) BOOL isExecuting, isFinished;

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
