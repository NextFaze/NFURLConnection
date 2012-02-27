//
//  T2URLRequestDataUpload.m
//
//  Created by Andrew Williams on 14/10/11.
//  Copyright (c) 2011 NextFaze. All rights reserved.
//

#import "T2URLRequestDataUpload.h"

@implementation T2URLRequestDataUpload

@synthesize contentType, data, filename;

+ (T2URLRequestDataUpload *)dataWithContentType:(NSString *)contentType data:(NSData *)data {
    T2URLRequestDataUpload *p = [[[self alloc] init] autorelease];
    p.contentType = contentType;
    p.data = data;
    return p;
}

- (void)dealloc {
    [contentType release];
    [data release];
    [filename release];
    
    [super dealloc];
}

@end
