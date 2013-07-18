//
//  NFURLResponse.h
//
//  Created by Andrew Williams on 15/09/11.
//  Copyright 2011 NextFaze. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NFURLResponse : NSObject {
    NSError *error;
    NSMutableData *data;
    NSHTTPURLResponse *httpResponse;
}

@property (nonatomic, retain) NSMutableData *data;
@property (nonatomic, retain) NSHTTPURLResponse *httpResponse;
@property (nonatomic, retain) NSError *error;

- (NSString *)body;
- (NSString *)contentType;
- (NSDictionary *)headers;
- (id)object;

@end
