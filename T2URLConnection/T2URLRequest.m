//
//  T2URLRequest.m
//
//  Created by Andrew Williams on 15/09/11.
//  Copyright 2011 NextFaze. All rights reserved.
//

#import "T2URLRequest.h"
#import "T2URLRequestDataUpload.h"
#import "T2URLResponse.h"
#import "SBJson.h"

typedef enum {
    T2URLRequestContentTypeForm,    
    T2URLRequestContentTypeXML,
    T2URLRequestContentTypeJSON
} T2URLRequestContentType;

@implementation T2URLRequest

@synthesize requestType, tag, req, parameters;
@synthesize isExecuting, isFinished;
@synthesize response;

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
        self.contentType = T2URLRequestDefaultContentType;
        
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
    [tag release];
    
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
    req.HTTPMethod = [HTTPMethod uppercaseString];
}

- (NSString *)HTTPMethod {
    return [req.HTTPMethod uppercaseString];
}

- (void)setContentType:(NSString *)contentType {
    [req setValue:contentType forHTTPHeaderField:@"Content-Type"];
}

- (NSString *)contentType {
    return [req valueForHTTPHeaderField:@"Content-Type"];
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

- (NSString *)multipartContentType {
    NSString *charset = (NSString *)CFStringConvertEncodingToIANACharSetName(kCFStringEncodingUTF8);
    return [NSString stringWithFormat:@"multipart/form-data; charset=%@; boundary=%@", charset, stringBoundary];
}

- (void)buildMultipartFormDataPostBody
{
    NSMutableData *data = [NSMutableData data];
    NSData *boundary = [[NSString stringWithFormat:@"--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding];
	NSData *endBoundary = [[NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding];

    // override content type here
    self.contentType = [self multipartContentType];
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

            NSString *partContentType = @"application/octet-stream";
            NSString *filename = @"filename";
            NSData *dataValue = nil;

            if([value isKindOfClass:[T2URLRequestDataUpload class]]) {
                T2URLRequestDataUpload *du = (T2URLRequestDataUpload *)value;
                dataValue = du.data;
                filename = du.filename ? du.filename : filename;
                partContentType = du.contentType;
            }
            else {
                dataValue = value;
            }
            
            NSString *disposition = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, filename];
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
	
    [data appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPBody:data];
}

#pragma mark -

- (T2URLRequestContentType)requestContentType:(NSString *)ct {
    T2URLRequestContentType ctype = T2URLRequestContentTypeForm;  // the default

    if([ct hasSuffix:@"/json"]) {
        ctype = T2URLRequestContentTypeJSON;
    } else if([ct hasSuffix:@"/xml"] || [ct hasSuffix:@"+xml"]) {
        ctype = T2URLRequestContentTypeXML;
    }
    
    return ctype;
}

// return a query string (key=value pairs separated by '&') from the current parameters
// appends to any existing query set on the request object
- (NSString *)queryString {
    NSURL *url = [req URL];
    NSString *query = [url query];
    NSMutableArray *queryList = [NSMutableArray array];

    for(NSString *key in [parameters allKeys]) {
        id<NSObject> value = [parameters valueForKey:key];
        NSString *strValue = nil;
        
        if([value isKindOfClass:[NSString class]]) {
            strValue = (NSString *)value;
        } else if([value respondsToSelector:@selector(stringValue)]) {
            strValue = [value performSelector:@selector(stringValue)];
        } else {
            continue;
        }
        
        NSString *part = [NSString stringWithFormat:@"%@=%@", [self urlEscape:key], [self urlEscape:strValue]];
        [queryList addObject:part];
    }
    NSString *newQuery = [queryList componentsJoinedByString:@"&"];
    
    if([query length]) query = [query stringByAppendingFormat:@"&%@", newQuery];
    else query = newQuery;

    return query;
}

- (NSURLRequest *)urlRequest {
    
    if([self.HTTPMethod isEqualToString:@"GET"]) {
        // assume get requests do not have a body
        // (you can still set the body manually)
        NSString *query = [self queryString];
        
        if([query length]) {
            // remove any existing query from baseURL
            NSString *baseURL = [req.URL absoluteString];
            NSRange queryRange = [baseURL rangeOfString:query options:NSBackwardsSearch];
            if(queryRange.location != NSNotFound) {
                baseURL = [baseURL stringByReplacingCharactersInRange:queryRange withString:@""];
            }
            
            NSString *path = [NSString stringWithFormat:@"%@?%@", baseURL, query];
            NSURL *newURL = [[NSURL alloc] initWithString:path];
            [self.req setURL:newURL];
            [newURL release];
        }
    }
    else if(req.HTTPBody == nil && [parameters count]) {
        // non GET request with no body set - encode body from parameters according to the contentType

        switch ([self requestContentType:self.contentType]) {

            case T2URLRequestContentTypeForm:
                // add parameters to request body
                if([self haveBinaryParameters]) {
                    [self buildMultipartFormDataPostBody];
                }
                else {
                    NSString *query = [self queryString];
                    [req setHTTPBody:[query dataUsingEncoding:NSUTF8StringEncoding]];
                    LOG(@"request body: %@", query);
                }

                break;

            case T2URLRequestContentTypeJSON: {
                SBJsonWriter *writer = [[SBJsonWriter alloc] init];
                req.HTTPBody = [writer dataWithObject:parameters];
                [writer release];
                LOG(@"using http body: %@", [[[NSString alloc] initWithData:req.HTTPBody encoding:NSUTF8StringEncoding] autorelease]);
                break;
            }

            case T2URLRequestContentTypeXML:
                LOG(@"auto-encoding parameters as xml is not supported");
                req.HTTPBody = nil;
                break;

            default:
                LOG(@"unable to encode parameters for content type: %@", self.contentType);
                break;
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

- (void)finish {
    [self setIsExecuting:NO];    
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
    response.data = [NSMutableData dataWithData:data];
    response.error = err;
    
    request.response = response;

    //LOG(@"response body: %@", [response body]);
    LOG(@"response code: %d", [response.httpResponse statusCode]);
    if(response.error) LOG(@"response error: %@", response.error);
    LOG(@"request finished");

    return response;
}

- (void)sendAsynchronousRequest {
    
    self.response = [[[T2URLResponse alloc] init] autorelease];
    response.data = [NSMutableData data];
    
    NSURLRequest *urlRequest = [self urlRequest];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self startImmediately:NO];
    [conn scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [conn start];
    [conn release];

    LOG(@"done");
}

- (void)performRequest {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    LOG(@"starting");
    
    if(![self isCancelled] || [[NSThread currentThread] isCancelled]) {
        [self sendAsynchronousRequest];
        //self.response = [T2URLRequest sendSynchronousRequest:self];
    }

    /*
    if(![self isCancelled] || [[NSThread currentThread] isCancelled]) {
        [self finish];
    }
     */
    
    [pool release];
}

#pragma mark NSOperation

- (void)start {
    if(![self isCancelled]) {
        [self setIsExecuting:YES];
        [self performRequest];
        //[NSThread detachNewThreadSelector:@selector(performRequest) toTarget:self withObject:nil];
    }
}

- (BOOL)isConcurrent {
    return YES;
}


#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)err {
    response.error = err;
    LOG(@"error: %@", err);
    [self finish];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    //LOG(@"connection finished loading");
    [self finish];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)res {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)res;
    if ([res respondsToSelector:@selector(allHeaderFields)]) {
        NSDictionary *dictionary = [httpResponse allHeaderFields];
        int code = [httpResponse statusCode];
        response.httpResponse = httpResponse;
        LOG(@"response code: %d, content length: %@", code, [dictionary valueForKey:@"Content-Length"]);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d {
    //LOG(@"received data");
    if([self isCancelled]) {
        [connection cancel];
        // no call to delegate here
        [self finish];
        return;
    }
    [response.data appendData:d];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    LOG(@"auth challenge: %@", challenge);
    
    if ([challenge previousFailureCount] > 0) {
        // handle bad credentials here
        LOG(@"failure count: %d", [challenge previousFailureCount]);
        [[challenge sender] cancelAuthenticationChallenge:challenge];
        return;
    }
    
    if ([[challenge protectionSpace] authenticationMethod] == NSURLAuthenticationMethodServerTrust) {
        // makes connection work with ssl self signed certificates
        LOG(@"certificate challenge");
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];	
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    // TODO: set error here?
    [self finish];
}


@end
