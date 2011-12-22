//
//  T2URLRequest.m
//
//  Created by Andrew Williams on 15/09/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "T2URLRequest.h"
#import "T2URLRequestDataUpload.h"
#import "T2URLResponse.h"

@implementation T2URLRequest

@synthesize requestType, tag, req, parameters, delegate;
@synthesize isExecuting, isFinished;

+ (T2URLRequest *)requestWithURL:(NSURL *)url {
    return [[[self alloc] initWithURL:url] autorelease];
}
+ (T2URLRequest *)requestWithURL:(NSURL *)url parameters:(NSDictionary *)params {
    return [[[self alloc] initWithURL:url parameters:params] autorelease];
}
+ (T2URLRequest *)requestWithType:(int)requestType {
    return [[[self alloc] initWithRequestType:requestType] autorelease];
}

- (id)init {
    self = [super init];
    if(self) {
        parameters = [[NSMutableDictionary alloc] init];
        req = [[NSMutableURLRequest alloc] init];

        // create a boundary string for multipart form data
        CFUUIDRef uuid = CFUUIDCreate(nil);
        NSString *uuidString = [(NSString*)CFUUIDCreateString(nil, uuid) autorelease];
        CFRelease(uuid);
        stringBoundary = [[NSString stringWithFormat:@"0xKhTmLbOuNdArY-%@", uuidString] retain];
    }
    return self;
}

- (id)initWithURL:(NSURL *)url {
    self = [self init];
    if(self) {
        [req setURL:url];
    }
    return self;
}

- (id)initWithURL:(NSURL *)url parameters:(NSDictionary *)params {
    self = [self initWithURL:url];
    if(self) {
        [parameters setDictionary:params];
    }
    return self;
}

- (id)initWithRequestType:(int)type {
    self = [self init];
    if(self) {
        requestType = type;
    }
    return self;
}

- (void)dealloc {
    [req release];
    [parameters release];
    [stringBoundary release];
    
    [super dealloc];
}

#pragma mark - 

- (void)setURL:(NSURL *)URL {
    req.URL = URL;
}

- (NSURL *)URL {
    return req.URL;
}

- (void)setHTTPMethod:(NSString *)HTTPMethod {
    req.HTTPMethod = HTTPMethod;
}

- (NSString *)HTTPMethod {
    return req.HTTPMethod;
}

- (NSString*)urlEscape:(NSString *)str {            
    return [(NSString *) CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef) str,
                                                                 NULL, CFSTR("￼=,!$&'()*+;@?\n\"<>#\t :/"), kCFStringEncodingUTF8) autorelease];
}

- (BOOL)haveBinaryParameters {
    for(id value in [parameters allValues]) {
        if([value isKindOfClass:[NSData class]] ||
           [value isKindOfClass:[T2URLRequestDataUpload class]])
            return YES;
    }
    return NO;
}

- (void)buildMultipartFormDataPostBody
{
	NSString *charset = (NSString *)CFStringConvertEncodingToIANACharSetName(kCFStringEncodingUTF8);
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; charset=%@; boundary=%@", charset, stringBoundary];
    NSMutableData *data = [NSMutableData data];
    NSData *boundary = [[NSString stringWithFormat:@"--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding];
	NSData *endBoundary = [[NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding];
    
    [req setValue:contentType forHTTPHeaderField:@"Content-Type"];
    [data appendData:boundary];
    
    NSArray *keys = [parameters allKeys];
	for (int i = 0; i < [keys count]; i++) {
        NSString *key = [keys objectAtIndex:i];
        id value = [parameters valueForKey:key];
        
        if([value isKindOfClass:[NSString class]]) {
            NSString *strValue = (NSString *)value;
            
            [data appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
            [data appendData:[strValue dataUsingEncoding:NSUTF8StringEncoding]];
            LOG(@"added string param %@", key);
        }
        else if([value isKindOfClass:[NSData class]] ||
                [value isKindOfClass:[T2URLRequestDataUpload class]]) {

            NSString *contentType = @"application/octet-stream";
            NSString *filename = @"filename";
            NSData *dataValue = nil;

            if([value isKindOfClass:[T2URLRequestDataUpload class]]) {
                T2URLRequestDataUpload *du = (T2URLRequestDataUpload *)value;
                dataValue = du.data;
                filename = du.filename ? du.filename : filename;
                contentType = du.contentType;
            }
            else {
                dataValue = value;
            }
            
            NSString *disposition = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, filename];
            [data appendData:[disposition dataUsingEncoding:NSUTF8StringEncoding]];
            [data appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", contentType] dataUsingEncoding:NSUTF8StringEncoding]];

            [data appendData:dataValue];
            LOG(@"added data param %@", key);
        }
        
        // Only add the boundary if this is not the last item in the post body
        if (i != [keys count] - 1) {
            [data appendData:endBoundary];
        }
	}
	
    [data appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPBody:data];
}

#pragma mark -

- (NSURLRequest *)urlRequest {
    NSURL *url = [req URL];
    NSString *query = [url query];
    NSMutableArray *queryList = [NSMutableArray array];

    for(NSString *key in [parameters allKeys]) {
        id value = [parameters valueForKey:key];
        if(![value isKindOfClass:[NSString class]]) continue;
        
        NSString *strValue = (NSString *)value;
        NSString *part = [NSString stringWithFormat:@"%@=%@", [self urlEscape:key], [self urlEscape:strValue]];
        [queryList addObject:part];
    }
    NSString *newQuery = [queryList componentsJoinedByString:@"&"];
    
    if([query length]) query = [query stringByAppendingFormat:@"&%@", newQuery];
    else query = newQuery;
    
    if([query length]) {
        if([[[req HTTPMethod] uppercaseString] isEqualToString:@"GET"]) {
            // GET request

            // remove query from baseURL
            NSString *baseURL = [url absoluteString];
            NSRange queryRange = [baseURL rangeOfString:query options:NSBackwardsSearch];
            if(queryRange.location != NSNotFound) {
                baseURL = [baseURL stringByReplacingCharactersInRange:queryRange withString:@""];
            }
            
            NSString *path = [NSString stringWithFormat:@"%@?%@", baseURL, query];
            NSURL *newURL = [[NSURL alloc] initWithString:path];
            [self.req setURL:newURL];
            [newURL release];
        }
        else {
            // add parameters to request body
            if([self haveBinaryParameters]) {
                [self buildMultipartFormDataPostBody];
            }
            else {
                [req setHTTPBody:[query dataUsingEncoding:NSUTF8StringEncoding]];
            }
        }
    }
    
    LOG(@"request: %@ %@", req.HTTPMethod, req.URL);
    return req;
}

- (void)setParameters:(NSDictionary *)params {
    [parameters setDictionary:params];
}

- (void)setParameterValue:(id)value forKey:(NSString *)key {
    [parameters setValue:value forKey:key];
}


#pragma mark -

- (void)setIsExecuting:(BOOL)value {
    if(isExecuting == value) return;
    [self willChangeValueForKey:@"isExecuting"];
    isExecuting = value;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)setIsFinished:(BOOL)value {
    if(isFinished == value) return;
    [self willChangeValueForKey:@"isFinished"];
    isFinished = YES;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)finish:(T2URLResponse *)response {
    [self setIsExecuting:NO];
    
    LOG(@"calling complete on delegate");
    [delegate t2URLRequestCompleted:self response:response];
    
    [self setIsFinished:YES];
    LOG(@"finished");
}

+ (T2URLResponse *)sendSynchronousRequest:(T2URLRequest *)request {
    NSError *err = nil;
    NSURLRequest *req = [request urlRequest];
    NSURLResponse *res = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
    
    T2URLResponse *response = [[[T2URLResponse alloc] init] autorelease];
    response.httpResponse = (NSHTTPURLResponse *)res;
    response.data = data;
    response.request = request;
    response.error = err;
    
    //LOG(@"response body: %@", [response body]);
    LOG(@"response code: %d", [response.httpResponse statusCode]);
    if(response.error) LOG(@"response error: %@", response.error);
    
    return response;
}

- (void)performRequest {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    LOG(@"starting");
    T2URLResponse *response = [T2URLRequest sendSynchronousRequest:self];
    LOG(@"request finished");
    if(![[NSThread currentThread] isCancelled])
        [self finish:response];
    
    [pool release];
}

#pragma mark NSOperation

- (void)start {
    [self setIsExecuting:YES];
    
    [NSThread detachNewThreadSelector:@selector(performRequest) toTarget:self withObject:nil];
}

- (BOOL)isConcurrent {
    return YES;
}

@end
