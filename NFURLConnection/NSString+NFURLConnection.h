//
//  NSString+NFURLConnection.h
//  NFURLConnection
//
//  Created by Andrew Williams on 1/10/2014.
//  Copyright (c) 2014 NextFaze. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (NFURLConnection)
- (NSString *)nfuc_trim;
- (NSString *)nfuc_urlEncodeUsingEncoding:(NSStringEncoding)encoding;
- (BOOL)nfuc_hasSubstring:(NSString *)substring;

- (NSString *)nfuc_sub:(NSRegularExpression *)regex with:(NSString *)with;
- (NSRegularExpression *)nfuc_toRegex;

@end
