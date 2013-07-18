//
//  NFURLXMLParser.m
//
//  Created by Andrew Williams on 15/09/11.
//  Copyright 2011 NextFaze. All rights reserved.
//
// based on http://troybrant.net/blog/2010/09/simple-xml-to-nsdictionary-converter/

#import "NFURLXMLParser.h"
//#import "NSMutableString+CharacterEntityConverter.h"

#define NFURLXMLParserTextKey @"text"

@interface NFURLXMLParser ()

@property (nonatomic, strong) NSMutableArray *dictionaryStack;
@property (nonatomic, strong) NSMutableString *textInProgress;
@property (nonatomic, strong) NSXMLParser *parser;

@end

@implementation NFURLXMLParser

#pragma mark -

- (void)dealloc {
    [_parser release];
    [_dictionaryStack release];
    [_textInProgress release];
    [_error release];

    [super dealloc];
}

#pragma mark -
#pragma mark Public methods

- (NSDictionary *)dictionaryForXMLData:(NSData *)data
{
    return [self objectWithData:data];
}

- (NSDictionary *)dictionaryForXMLString:(NSString *)string
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [self dictionaryForXMLData:data];
}

#pragma -

/*
 dictionary/array compaction:
 
 convert: { key1 => { text => 'value1' }, key2 => ( { text => 'value2' }, { text =>  'value3' } ) }
 to:      { key1 => 'value1', key2 => ('value2', 'value3') }
 */

- (id)compactArray:(NSArray *)src {
    NSMutableArray *ret = [NSMutableArray array];
    for(id obj in src) {
        if([obj isKindOfClass:[NSDictionary class]]) {
            obj = [self compactDictionary:obj];
        }
        else if([obj isKindOfClass:[NSArray class]]) {
            obj = [self compactArray:obj];
        }
        [ret addObject:obj];
    }
    return ret;
}

- (id)compactDictionary:(NSDictionary *)src {
    
    NSString *text = [src valueForKey:NFURLXMLParserTextKey];
    if([src count] == 1 && text) {
        // dictionary with single key 'text' - convert to string
        return text;
    }

    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    for(NSString *key in [src allKeys]) {
        id value = [src valueForKey:key];
        if([value isKindOfClass:[NSDictionary class]]) {
            value = [self compactDictionary:value];
        }
        else if([value isKindOfClass:[NSArray class]]) {
            value = [self compactArray:value];
        }
        [ret setValue:value forKey:key];
    }
    return ret;
}

/*
// attempt to fix bad xml data.
// assumes utf8 encoding
- (NSData *)fixBadXML:(NSData *)data {
    NSMutableString *str = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    //match(/&(?!amp;)/)
    // replace unescaped ampersands
    for(;;) {
        NSRange rangeAmp = [str rangeOfString:@"&(?![#\\d\\w]+;)" options:NSLiteralSearch|NSCaseInsensitiveSearch|NSRegularExpressionSearch];
        if(rangeAmp.location == NSNotFound) break;
        LOG(@"found unescaped ampersand at index %d", rangeAmp.location);
        [str replaceCharactersInRange:rangeAmp withString:@"&amp;"];
    }
    [str decodeEntitiesForXML];  // remove &rsquo; etc

    NSData *ret = [str dataUsingEncoding:NSUTF8StringEncoding];
    [str release];
    return ret;
}
*/

#pragma mark -
#pragma mark Parsing

- (NSDictionary *)objectWithData:(NSData *)data
{
    self.dictionaryStack = [NSMutableArray array];
    self.textInProgress = [NSMutableString string];
    
    // Initialize the stack with a fresh dictionary
    [self.dictionaryStack addObject:[NSMutableDictionary dictionary]];
    
    // Parse the XML
    //data = [self fixBadXML:data];
    self.parser = [[NSXMLParser alloc] initWithData:data];
    self.parser.delegate = self;
    BOOL success = [self.parser parse];

    // Return the stack's root dictionary on success
    if (success) {
        NSDictionary *resultDict = [self.dictionaryStack objectAtIndex:0];
        return [self compactDictionary:resultDict];
    }
    
    self.parser = nil;
    self.dictionaryStack = nil;
    self.textInProgress = nil;
    
    return nil;
}

#pragma mark -
#pragma mark NSXMLParserDelegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    // Get the dictionary for the current level in the stack
    NSMutableDictionary *parentDict = [self.dictionaryStack lastObject];
    
    // Create the child dictionary for the new element, and initilaize it with the attributes
    NSMutableDictionary *childDict = [NSMutableDictionary dictionary];
    [childDict addEntriesFromDictionary:attributeDict];
    
    // If there's already an item for this key, it means we need to create an array
    id existingValue = [parentDict objectForKey:elementName];
    if (existingValue)
    {
        NSMutableArray *array = nil;
        if ([existingValue isKindOfClass:[NSMutableArray class]])
        {
            // The array exists, so use it
            array = (NSMutableArray *) existingValue;
        }
        else
        {
            // Create an array if it doesn't exist
            array = [NSMutableArray array];
            [array addObject:existingValue];
            
            // Replace the child dictionary with an array of children dictionaries
            [parentDict setObject:array forKey:elementName];
        }
        
        // Add the new child dictionary to the array
        [array addObject:childDict];
    }
    else
    {
        // No existing value, so update the dictionary
        [parentDict setObject:childDict forKey:elementName];
    }
    
    // Update the stack
    [self.dictionaryStack addObject:childDict];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    // Update the parent dict with text info
    NSMutableDictionary *dictInProgress = [self.dictionaryStack lastObject];
    
    // Set the text property
    if ([self.textInProgress length] > 0)
    {
        NSString *text = [self.textInProgress stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [dictInProgress setObject:text forKey:NFURLXMLParserTextKey];
        
        // Reset the text
        [self.textInProgress release];
        self.textInProgress = [[NSMutableString alloc] init];
    }
    
    // Pop the current dict
    [self.dictionaryStack removeLastObject];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    // Build the text value
    [self.textInProgress appendString:string];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    // Set the error pointer to the parser's error object
    
    self.error = parseError;
}

@end
