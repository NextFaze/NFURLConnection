//
//  NFURLRequest.m
//
//  Created by Andrew Williams on 15/09/11.
//  Copyright 2011 NextFaze. All rights reserved.
//

#import "NFURLRequest.h"
#import "NFURLRequestDataUpload.h"
#import "NFURLResponse.h"
#import "NSString+NFURLConnection.h"

typedef enum {
    NFURLRequestContentTypeForm,
    NFURLRequestContentTypeXML,
    NFURLRequestContentTypeJSON
} NFURLRequestContentType;

@interface NFURLRequest ()
@property (nonatomic, strong) NSString *stringBoundary;
@end

@implementation NFURLRequest

+ (id)request {
    return [[self alloc] init];
}

+ (id)requestWithURL:(NSURL *)url handler:(NFURLResponseHandler)handler {
    NFURLRequest *request = [[self alloc] init];
    request.handler = handler;
    request.URL = url;
    request.maxRetryCount = 2;
    
    return request;
}

+ (id)requestWithHandler:(NFURLResponseHandler)handler {
    return [self requestWithURL:nil handler:handler];
}

- (id)init {
    self = [super init];
    if(self) {
        // create a boundary string for multipart form data
        NSString *uuidString = [[NSUUID UUID] UUIDString];
        _stringBoundary = [NSString stringWithFormat:@"0xKhTmLbOuNdArY-%@", uuidString];
    }
    return self;
}

#pragma mark -

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@", self.HTTPMethod, self.URL];
}

- (void)setHTTPMethod:(NSString *)method parameters:(NSDictionary *)parameters {
    self.HTTPMethod = method;
    self.parameters = parameters;
}

- (void)setParameters:(NSDictionary *)parameters {
    _parameters = parameters;
    
    [self applyParameters];
}

- (void)setHTTPMethod:(NSString *)HTTPMethod {
    [super setHTTPMethod:HTTPMethod];
    
    if([self paramsInBody:HTTPMethod]) {
        [self setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    }
    [self applyParameters];
}

#pragma mark -

- (void)applyParameters {
    
    if ([self paramsInBody:self.HTTPMethod]) {
        // replace body with parameters
        NSString *paramString = [[self class] stringWithEncodedQueryParameters:self.parameters];
        if(paramString.length) {
            self.HTTPBody = [paramString dataUsingEncoding:NSUTF8StringEncoding];
        } else {
            self.HTTPBody = nil;
        }
    }
    else {
        // replace query string with parameters
        NSString *paramString = [[self class] stringWithEncodedQueryParameters:self.parameters];
        NSURL *url = self.URL;
        NSURL *newURL = [[NSURL alloc] initWithScheme:[url scheme]
                                                 host:[url host]
                                                 path:[url path]];
        NSString *urlString = [newURL absoluteString];
        if(paramString.length)
            urlString = [urlString stringByAppendingFormat:@"?%@", paramString];
        
        self.URL = [NSURL URLWithString:urlString];
    }
}

- (BOOL)paramsInBody:(NSString *)method {
    return [@[@"POST", @"PUT", @"PATCH"] containsObject:[method uppercaseString]];
}

// added support for arrays of parameters
+ (NSString *)stringWithEncodedQueryParameters:(NSDictionary *)parameters
{
    NSMutableArray *parameterPairs = [NSMutableArray array];
    for (NSString *key in [parameters allKeys]) {
        id value = [parameters valueForKey:key];
        NSArray *valueList = nil;
        if([value isKindOfClass:[NSArray class]]) {
            valueList = value;
        }
        else {
            valueList = @[value];
        }
        for(value in valueList) {
            if(![value isKindOfClass:[NSString class]]) {
                value = [value description];
            }
            NSString *pair = [NSString stringWithFormat:@"%@=%@",
                              [key nfuc_urlEncodeUsingEncoding:NSUTF8StringEncoding],
                              [value nfuc_urlEncodeUsingEncoding:NSUTF8StringEncoding]];
            [parameterPairs addObject:pair];
        }
    }
    return [parameterPairs componentsJoinedByString:@"&"];
}

#pragma mark -

- (void)setContentType:(NSString *)contentType {
    [self setValue:contentType forHTTPHeaderField:@"Content-Type"];
}

- (BOOL)haveBinaryParameters {
    for(id value in [self.parameters allValues]) {
        if([value isKindOfClass:[NSData class]] ||
           [value isKindOfClass:[NFURLRequestDataUpload class]])
            return YES;
    }
    return NO;
}

- (NSString *)multipartContentType {
    NSString *charset = (NSString *)CFStringConvertEncodingToIANACharSetName(kCFStringEncodingUTF8);
    return [NSString stringWithFormat:@"multipart/form-data; charset=%@; boundary=%@", charset, self.stringBoundary];
}

- (void)buildMultipartFormDataPostBody
{
    NSMutableData *data = [NSMutableData data];
    NSData *boundary = [[NSString stringWithFormat:@"--%@\r\n", self.stringBoundary] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *endBoundary = [[NSString stringWithFormat:@"\r\n--%@\r\n", self.stringBoundary] dataUsingEncoding:NSUTF8StringEncoding];
    
    // override content type here
    self.contentType = [self multipartContentType];
    [data appendData:boundary];

    NSArray *keys = [self.parameters allKeys];
    for (int i = 0; i < [keys count]; i++) {
        NSString *key = [keys objectAtIndex:i];
        id value = [self.parameters valueForKey:key];
        
        if([value isKindOfClass:[NSString class]]) {
            NSString *strValue = (NSString *)value;
            
            [data appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
            [data appendData:[strValue dataUsingEncoding:NSUTF8StringEncoding]];
            LOG(@"added string param %@", key);
        }
        else if([value isKindOfClass:[NSData class]] ||
                [value isKindOfClass:[NFURLRequestDataUpload class]]) {
            
            NSString *partContentType = @"application/octet-stream";
            NSString *filename = nil;
            NSData *dataValue = nil;
            
            if([value isKindOfClass:[NFURLRequestDataUpload class]]) {
                NFURLRequestDataUpload *du = (NFURLRequestDataUpload *)value;
                dataValue = du.data;
                filename = du.filename;
                partContentType = du.contentType;
            }
            else {
                dataValue = value;
            }
            
            NSMutableString *disposition = [NSMutableString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"", key];
            if(filename) {
                [disposition appendFormat:@"; filename=\"%@\"", filename];
            }
            [disposition appendFormat:@"\r\n"];
            
            [data appendData:[disposition dataUsingEncoding:NSUTF8StringEncoding]];
            [data appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", partContentType] dataUsingEncoding:NSUTF8StringEncoding]];
            
            [data appendData:dataValue];
            LOG(@"added data param %@", key);
        }
        
        // Only add the boundary if this is not the last item in the post body
        if (i != [keys count] - 1) {
            [data appendData:endBoundary];
        }
    }
    
    [data appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", self.stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [self setHTTPBody:data];
}

#pragma mark -

- (NFURLRequestContentType)requestContentType:(NSString *)ct {
    NFURLRequestContentType ctype = NFURLRequestContentTypeForm;  // the default
    
    if([ct hasSuffix:@"/json"]) {
        ctype = NFURLRequestContentTypeJSON;
    } else if([ct hasSuffix:@"/xml"] || [ct hasSuffix:@"+xml"]) {
        ctype = NFURLRequestContentTypeXML;
    }
    
    return ctype;
}

/*
- (NSURLRequest *)urlRequest {
    
    if([self.HTTPMethod isEqualToString:@"GET"]) {
        // assume get requests do not have a body
        // (you can still set the body manually)
        NSString *query = [self queryString];
        
        if([query length]) {
            // remove any existing query from baseURL
            NSString *baseURL = [self.req.URL absoluteString];
            NSRange queryRange = [baseURL rangeOfString:query options:NSBackwardsSearch];
            if(queryRange.location != NSNotFound) {
                baseURL = [baseURL stringByReplacingCharactersInRange:queryRange withString:@""];
            }
            
            NSString *path = [NSString stringWithFormat:@"%@?%@", baseURL, query];
            NSURL *newURL = [[NSURL alloc] initWithString:path];
            [self.req setURL:newURL];
        }
    }
    else if(self.req.HTTPBody == nil && [self.parameters count]) {
        // non GET request with no body set - encode body from parameters according to the contentType
        
        switch ([self requestContentType:self.contentType]) {
                
            case NFURLRequestContentTypeForm:
                // add parameters to request body
                if([self haveBinaryParameters]) {
                    [self buildMultipartFormDataPostBody];
                }
                else {
                    NSString *query = [self queryString];
                    [self.req setHTTPBody:[query dataUsingEncoding:NSUTF8StringEncoding]];
                    LOG(@"request body: %@", query);
                }
                
                break;
                
            case NFURLRequestContentTypeJSON: {
                self.req.HTTPBody = [NSJSONSerialization dataWithJSONObject:self.parameters options:0 error:nil];
                LOG(@"using http body: %@", [[NSString alloc] initWithData:self.req.HTTPBody encoding:NSUTF8StringEncoding]);
                break;
            }
                
            case NFURLRequestContentTypeXML:
                LOG(@"auto-encoding parameters as xml is not supported");
                self.req.HTTPBody = nil;
                break;
                
            default:
                LOG(@"unable to encode parameters for content type: %@", self.contentType);
                break;
        }
    }
    
    LOG(@"request: %@ %@", self.req.HTTPMethod, self.req.URL);
    return self.req;
}
 */

@end
