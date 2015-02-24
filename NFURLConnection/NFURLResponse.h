//
//  NFURLResponse.h
//
//  Created by Andrew Williams on 15/09/11.
//  Copyright 2011 NextFaze. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class NFURLResponse;

typedef void (^NFURLResponseHandler)(NFURLResponse *response);

typedef enum {
    NFURLResponseRemoveNSNulls = (1UL << 0),
    NFURLResponseTrimStrings = (1UL << 1),
    NFURLResponseRemoveEmptyStrings = (1UL << 2),

    NFURLResponseSanitize = NFURLResponseRemoveNSNulls | NFURLResponseTrimStrings | NFURLResponseRemoveEmptyStrings
    
} NFURLResponseReadingOptions;

@interface NFURLResponse : NSObject

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSHTTPURLResponse *httpResponse;
@property (nonatomic, strong) NSError *error;

- (NSString *)body;
- (NSString *)contentType;
- (NSDictionary *)headers;

- (id)object;
- (id)object:(NFURLResponseReadingOptions)options;

- (NSDictionary *)dictionaryObject:(NFURLResponseReadingOptions)options;
- (NSArray *)arrayObject:(NFURLResponseReadingOptions)options;
- (UIImage *)imageObject;

@end
