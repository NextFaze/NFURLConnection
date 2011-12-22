//
//  T2URLResponse.m
//
//  Created by Andrew Williams on 15/09/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "T2URLResponse.h"
#import "T2URLXMLParser.h"
#import "SBJson.h"

@implementation T2URLResponse

@synthesize error, request, data, httpResponse;

- (void)dealloc {
    [request release];
    [data release];
    [httpResponse release];
    [error release];
    
    [super dealloc];
}

#pragma mark -

- (NSString *)body {
    NSString *body = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding] autorelease];
    return body;
}

- (NSDictionary *)headers {
    return [httpResponse allHeaderFields];
}

- (NSString *)header:(NSString *)name {
    return [[self headers] objectForKey:name];
}

- (NSString *)contentType {
    NSString *contentType = [self header:@"Content-Type"];
    NSRange charset = [contentType rangeOfString:@"; "];
    if(charset.location)
        contentType = [contentType substringToIndex:charset.location];
    return contentType;
}

// parse and return the response as an NSDictionary or NSArray
- (id)object {
    NSString *contentType = [self contentType];
    NSString *body = [self body];
    id object = nil;
    
    if([contentType isEqualToString:@"application/json"] ||
       [contentType isEqualToString:@"text/json"]) {
        object = [body JSONValue];
    }
    else if([contentType isEqualToString:@"application/xml"] ||
            [contentType isEqualToString:@"text/xml"] ||
            [contentType hasSuffix:@"+xml"]) {
        T2URLXMLParser *parser = [[T2URLXMLParser alloc] init];
        NSDictionary *dict = [parser dictionaryForXMLString:body];
        [parser dealloc];
        object = dict;
    }
    
    return object;
}

@end
