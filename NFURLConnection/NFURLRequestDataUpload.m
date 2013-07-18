//
//  NFURLRequestDataUpload.m
//
//  Created by Andrew Williams on 14/10/11.
//  Copyright (c) 2011 NextFaze. All rights reserved.
//

#import "NFURLRequestDataUpload.h"

@implementation NFURLRequestDataUpload

@synthesize contentType, data, filename;

+ (NFURLRequestDataUpload *)dataWithContentType:(NSString *)contentType data:(NSData *)data {
    NFURLRequestDataUpload *p = [[[self alloc] init] autorelease];
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
