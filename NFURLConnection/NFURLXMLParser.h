//
//  NFURLXMLParser.h
//
//  Created by Andrew Williams on 15/09/11.
//  Copyright 2011 NextFaze. All rights reserved.
// 
// based on http://troybrant.net/blog/2010/09/simple-xml-to-nsdictionary-converter/

#import <Foundation/Foundation.h>


@interface NFURLXMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic, retain) NSError *error;

- (NSDictionary *)dictionaryForXMLData:(NSData *)data;
- (NSDictionary *)dictionaryForXMLString:(NSString *)string;

@end
