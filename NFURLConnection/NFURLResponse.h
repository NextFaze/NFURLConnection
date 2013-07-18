//
//  NFURLResponse.h
//
//  Created by Andrew Williams on 15/09/11.
//  Copyright 2011 NextFaze. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NFURLResponse : NSObject

@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSHTTPURLResponse *httpResponse;
@property (nonatomic, strong) NSError *error;

- (NSString *)body;
- (NSString *)contentType;
- (NSDictionary *)headers;
- (id)object;

@end
