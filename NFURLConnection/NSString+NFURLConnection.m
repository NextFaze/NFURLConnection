//
//  NSString+NFURLConnection.m
//  NFURLConnection
//
//  Created by Andrew Williams on 1/10/2014.
//  Copyright (c) 2014 NextFaze. All rights reserved.
//

#import "NSString+NFURLConnection.h"

@implementation NSString (NFURLConnection)

- (NSString *)nfuc_trim {
    NSString *value = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return value.length ? value : nil;
}

- (NSString *)nfuc_urlEncodeUsingEncoding:(NSStringEncoding)encoding {
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                               (CFStringRef)self,
                                                               NULL,
                                                               (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                               CFStringConvertNSStringEncodingToEncoding(encoding)));
}

- (BOOL)nfuc_hasSubstring:(NSString *)substring {
    if(substring == nil)
        return NO;
    
    if([self respondsToSelector:@selector(containsString:)]) {
        return [self containsString:substring];
    }
    else {
        NSRange range = [self rangeOfString:substring];
        return range.location != NSNotFound;
    }
}

#pragma mark - Regex

- (NSString *)nfuc_sub:(NSRegularExpression *)regex with:(NSString *)with {
    NSString *string = self;
    string = [regex stringByReplacingMatchesInString:string
                                             options:0
                                               range:NSMakeRange(0, string.length)
                                        withTemplate:with];
    return string;
}

- (NSRegularExpression *)nfuc_toRegex {
    NSError *error = nil;
    NSRegularExpressionOptions opts = (NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators);
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:self options:opts error:&error];
    
    if(error) {
        LOG(@"regex: %@", self);
        LOG(@"regex error: %@", error);
        return nil;
    }
    return regexp;
}

@end
