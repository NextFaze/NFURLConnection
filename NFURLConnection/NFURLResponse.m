//
//  NFURLResponse.m
//
//  Created by Andrew Williams on 15/09/11.
//  Copyright 2011 NextFaze. All rights reserved.
//

#import "NFURLResponse.h"
#import "NFURLXMLParser.h"
#import <UIKit/UIKit.h>

@implementation NFURLResponse

- (void)dealloc {
    [_data release];
    [_httpResponse release];
    [_error release];
    
    [super dealloc];
}

#pragma mark -

- (NSString *)body {
    NSString *body = [[[NSString alloc] initWithBytes:[self.data bytes] length:[self.data length] encoding:NSUTF8StringEncoding] autorelease];
    return body;
}

- (NSDictionary *)headers {
    return [self.httpResponse allHeaderFields];
}

- (NSString *)header:(NSString *)name {
    return [[self headers] objectForKey:name];
}

- (NSString *)contentType {
    NSString *contentType = [self header:@"Content-Type"];
    NSRange charset = [contentType rangeOfString:@"; "];
    if(charset.location && charset.location != NSNotFound)
        contentType = [contentType substringToIndex:charset.location];
    return contentType;
}

// parse and return the response as an NSDictionary or NSArray
- (id)object {
    NSString *contentType = [self contentType];
    NSString *body = [self body];
    id object = nil;
    
    //LOG(@"content type: %@", contentType);
    
    if([contentType isEqualToString:@"application/json"] ||
       [contentType isEqualToString:@"text/json"]) {
        object = self.data ? [NSJSONSerialization JSONObjectWithData:self.data options:0 error:nil] : nil;
    }
    else if([contentType isEqualToString:@"application/xml"] ||
            [contentType isEqualToString:@"text/xml"] ||
            [contentType hasSuffix:@"+xml"]) {
        NFURLXMLParser *parser = [[NFURLXMLParser alloc] init];
        NSDictionary *dict = [parser dictionaryForXMLString:body];
        [parser release];
        object = dict;
    }
    else if([contentType hasPrefix:@"image/"]) {
        object = [UIImage imageWithData:self.data];
    }
    
    return object;
}

@end
