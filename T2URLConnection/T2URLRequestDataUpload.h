//
//  T2URLRequestDataUpload.h
//
//  Created by Andrew Williams on 14/10/11.
//  Copyright (c) 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface T2URLRequestDataUpload : NSObject {
    NSString *contentType;
    NSString *filename;
    NSData *data;
}

@property (nonatomic, retain) NSString *contentType, *filename;
@property (nonatomic, retain) NSData *data;

+ (T2URLRequestDataUpload *)dataWithContentType:(NSString *)contentType data:(NSData *)data;

@end
