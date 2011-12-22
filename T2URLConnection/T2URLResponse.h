//
//  T2URLResponse.h
//
//  Created by Andrew Williams on 15/09/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "T2URLRequest.h"

@interface T2URLResponse : NSObject {
    NSError *error;
    NSData *data;
    NSHTTPURLResponse *httpResponse;
    T2URLRequest *request;
}

@property (nonatomic, retain) NSData *data;
@property (nonatomic, retain) NSHTTPURLResponse *httpResponse;
@property (nonatomic, retain) NSError *error;
@property (nonatomic, retain) T2URLRequest *request;

- (NSString *)body;
- (NSString *)contentType;
- (NSDictionary *)headers;
- (id)object;

@end
