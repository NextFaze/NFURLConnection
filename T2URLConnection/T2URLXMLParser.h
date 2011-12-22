//
//  T2URLXMLParser.h
//
//  Created by Andrew Williams on 15/09/11.
//  Copyright 2011 2moro mobile. All rights reserved.
// 
// based on http://troybrant.net/blog/2010/09/simple-xml-to-nsdictionary-converter/

#import <Foundation/Foundation.h>


@interface T2URLXMLParser : NSObject <NSXMLParserDelegate>
{
    NSMutableArray *dictionaryStack;
    NSMutableString *textInProgress;
    NSError *error;
    NSXMLParser *parser;
}

@property (nonatomic, retain) NSError *error;

- (NSDictionary *)dictionaryForXMLData:(NSData *)data;
- (NSDictionary *)dictionaryForXMLString:(NSString *)string;

@end
