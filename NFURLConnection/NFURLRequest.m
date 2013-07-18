//
//  NFURLRequest.m
//
//  Created by Andrew Williams on 15/09/11.
//  Copyright 2011 NextFaze. All rights reserved.
//

#import "NFURLRequest.h"
#import "NFURLRequestDataUpload.h"
#import "NFURLResponse.h"

typedef enum {
    NFURLRequestContentTypeForm,    
    NFURLRequestContentTypeXML,
    NFURLRequestContentTypeJSON
} NFURLRequestContentType;

@interface NFURLRequest ()
@property (nonatomic, strong) NSString *stringBoundary;
@end

@implementation NFURLRequest

+ (NFURLRequest *)request {
    return [[[self alloc] init] autorelease];
}
+ (NFURLRequest *)requestWithURL:(NSURL *)url {
    return [[[self alloc] initWithURL:url] autorelease];
}
+ (NFURLRequest *)requestWithURL:(NSURL *)url parameters:(NSDictionary *)params {
    return [[[self alloc] initWithURL:url parameters:params] autorelease];
}
+ (NFURLRequest *)requestWithType:(int)requestType {
    return [[[self alloc] initWithRequestType:requestType] autorelease];
}

- (id)init {
    self = [super init];
    if(self) {
        _parameters = [[NSMutableDictionary alloc] init];
        _req = [[NSMutableURLRequest alloc] init];
        self.contentType = NFURLRequestDefaultContentType;
        
        // create a boundary string for multipart form data
        CFUUIDRef uuid = CFUUIDCreate(nil);
        NSString *uuidString = [(NSString*)CFUUIDCreateString(nil, uuid) autorelease];
        CFRelease(uuid);
        _stringBoundary = [[NSString stringWithFormat:@"0xKhTmLbOuNdArY-%@", uuidString] retain];
    }
    return self;
}

- (id)initWithURL:(NSURL *)url {
    self = [self init];
    if(self) {
        [self.req setURL:url];
    }
    return self;
}

- (id)initWithURL:(NSURL *)url parameters:(NSDictionary *)params {
    self = [self initWithURL:url];
    if(self) {
        self.parameters = params;
    }
    return self;
}

- (id)initWithRequestType:(int)type {
    self = [self init];
    if(self) {
        self.requestType = type;
    }
    return self;
}

- (void)dealloc {
    [_req release];
    [_parameters release];
    [_stringBoundary release];
    [_tag release];
    
    [super dealloc];
}

#pragma mark - 

- (void)setURL:(NSURL *)URL {
    self.req.URL = URL;
}

- (NSURL *)URL {
    return self.req.URL;
}

- (void)setHTTPMethod:(NSString *)HTTPMethod {
    self.req.HTTPMethod = [HTTPMethod uppercaseString];
}

- (NSString *)HTTPMethod {
    return [self.req.HTTPMethod uppercaseString];
}

- (void)setContentType:(NSString *)contentType {
    [self.req setValue:contentType forHTTPHeaderField:@"Content-Type"];
}

- (NSString *)contentType {
    return [self.req valueForHTTPHeaderField:@"Content-Type"];
}

- (NSString*)urlEscape:(NSString *)str {            
    return [(NSString *) CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef) str,
                                                                 NULL, CFSTR("￼=,!$&'()*+;@?\n\"<>#\t :/"), kCFStringEncodingUTF8) autorelease];
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
            NSString *filename = @"filename";
            NSData *dataValue = nil;

            if([value isKindOfClass:[NFURLRequestDataUpload class]]) {
                NFURLRequestDataUpload *du = (NFURLRequestDataUpload *)value;
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
	
    [data appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", self.stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.req setHTTPBody:data];
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

// return a query string (key=value pairs separated by '&') from the current parameters
// appends to any existing query set on the request object
- (NSString *)queryString {
    NSURL *url = [self.req URL];
    NSString *query = [url query];
    NSMutableArray *queryList = [NSMutableArray array];

    for(NSString *key in [self.parameters allKeys]) {
        id<NSObject> value = [self.parameters valueForKey:key];
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
            NSString *baseURL = [self.req.URL absoluteString];
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
                LOG(@"using http body: %@", [[[NSString alloc] initWithData:self.req.HTTPBody encoding:NSUTF8StringEncoding] autorelease]);
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

- (void)setParameterValue:(id)value forKey:(NSString *)key {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:self.parameters];
    [dict setValue:value forKey:key];
    self.parameters = dict;
}

#pragma mark -

- (void)setIsExecuting:(BOOL)value {
    if(_isExecuting == value) return;
    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = value;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)setIsFinished:(BOOL)value {
    if(_isFinished == value) return;
    [self willChangeValueForKey:@"isFinished"];
    _isFinished = YES;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)finish {
    [self setIsExecuting:NO];    
    [self setIsFinished:YES];
    LOG(@"finished");
}

+ (NFURLResponse *)sendSynchronousRequest:(NFURLRequest *)request {
    NSError *err = nil;
    NSURLRequest *req = [request urlRequest];
    NSURLResponse *res = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
    
    NFURLResponse *response = [[[NFURLResponse alloc] init] autorelease];
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
    
    self.response = [[[NFURLResponse alloc] init] autorelease];
    self.response.data = [NSMutableData data];
    
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
        //self.response = [NFURLRequest sendSynchronousRequest:self];
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
    self.response.error = err;
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
        self.response.httpResponse = httpResponse;
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
    [self.response.data appendData:d];
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
