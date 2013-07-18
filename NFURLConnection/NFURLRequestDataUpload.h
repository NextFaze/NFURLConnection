//
//  NFURLRequestDataUpload.h
//
//  Created by Andrew Williams on 14/10/11.
//  Copyright (c) 2011 NextFaze. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NFURLRequestDataUpload : NSObject {
    NSString *contentType;
    NSString *filename;
    NSData *data;
}

@property (nonatomic, retain) NSString *contentType, *filename;
@property (nonatomic, retain) NSData *data;

+ (NFURLRequestDataUpload *)dataWithContentType:(NSString *)contentType data:(NSData *)data;

@end
