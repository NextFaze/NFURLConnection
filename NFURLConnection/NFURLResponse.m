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

- (id)object {
    return [self object:0];
}

// parse and return the response as an NSDictionary or NSArray
- (id)object:(NFURLResponseReadingOptions)options {
    NSString *contentType = [self contentType];
    NSString *body = [self body];
    id object = nil;
    
    //LOG(@"content type: %@", contentType);
    
    if([contentType isEqualToString:@"application/json"] ||
       [contentType isEqualToString:@"text/json"]) {
        NSJSONReadingOptions opts = NSJSONReadingMutableContainers;
        object = self.data ? [NSJSONSerialization JSONObjectWithData:self.data options:opts error:nil] : nil;
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

    [self processObjectContainer:object options:options];

    return object;
}

- (NSDictionary *)dictionaryObject:(NFURLResponseReadingOptions)options {
    return [self objectOfClass:[NSDictionary class] options:options];
}

- (NSArray *)arrayObject:(NFURLResponseReadingOptions)options {
    return [self objectOfClass:[NSArray class] options:options];
}

- (UIImage *)imageObject:(NFURLResponseReadingOptions)options {
    return [self objectOfClass:[UIImage class] options:options];
}

#pragma mark -

- (id)processObject:(id)object options:(NFURLResponseReadingOptions)options {

    if([object isKindOfClass:[NSDictionary class]] || [object isKindOfClass:[NSArray class]]) {
        object = [self processObjectContainer:object options:options];
    }
    else {
        BOOL isString = [object isKindOfClass:[NSString class]];
        if((options & NFURLResponseTrimStrings) && isString) {
            object = [object stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        if((options & NFURLResponseRemoveEmptyStrings) && isString) {
            if([object length] == 0) object = nil;
        }
        if((options & NFURLResponseRemoveNSNulls) && [object isKindOfClass:[NSNull class]]) {
            object = nil;
        }
    }
    return object;
}

- (id)processObjectContainer:(id)object options:(NFURLResponseReadingOptions)options {
    if(options == 0) return object;
    
    if([object isKindOfClass:[NSMutableDictionary class]]) {
        for(NSString *key in [object allKeys]) {
            id value = object[key];
            id newValue = [self processObject:value options:options];
            if(newValue != value)
                [object setValue:newValue forKey:key];
        }
    }
    else if([object isKindOfClass:[NSMutableArray class]]) {
        for(int i = 0; i < [object count]; i++) {
            id value = object[i];
            id newValue = [self processObject:value options:options];
            if(newValue != value)
                [object replaceObjectAtIndex:i withObject:newValue];
        }
    }
    
    return object;
}

- (id)objectOfClass:(Class)klass options:(NFURLResponseReadingOptions)options {
    id object = [self object:options];
    return [object isKindOfClass:klass] ? object : nil;
}

@end
