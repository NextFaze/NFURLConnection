NFURLConnection
===============

NFURLConnection - basic framework for sending network requests and parsing responses

NFURLConnection has a similar architecture to NSURLConnection, but with extra features:
* an NSOperationQueue to control concurrent network requests, set up dependencies, and priorities etc.
* constructs query part of url request from given parameters
* automatically decode XML and JSON responses.
* automatically encode parameters to a JSON body when sending a non-GET request with a JSON content type.
* ability to construct multipart form body (including binary data) for POST requests
* network responses are tied to the original request, so calling code can easily work with multiple concurrent requests.

External requirements:

* json-framework

Installation
------------

    > git clone git://github.com/NextFaze/NFURLConnction.git
    > cd NFURLConnction
    > git submodule init
    > git submodule update

NFURLConnction is a Cocoa Touch Static Library project, and can be incorporated into other xcode projects in the usual ways.

Notes:
- ensure NFURLConnection is added as Target Dependency
- ensure libNFURLSConnection.a is added to Link Binary With Libraries
- in Build Settings, Other Linker Flags, add: -all_load

Synopsis
--------

    // optionally: define an enumeration of request types
    typedef enum {
       RequestType1,    
       RequestType2,
       RequestType2
    } RequestType;

    // create a url connection:
    NFURLConnection *conn = [[NFURLConnection alloc] init];
    conn.delegate = self;   // optional

to create a request object    

    NFURLRequest *req = [NFURLRequest requestWithURL:@"http://www.google.com/"];
    req.HTTPMethod = @"GET"; 
    req.requestType = RequestType1;   // optionally assign a request type
    [req setParameterValue:@"foo" forKey:@"bar"];  // optionally assign parameters

to create a multipart form upload;
if the request content type is NFURLRequestContentTypeForm (the default) and contains binary parameter data (either as NSData objects or NFURLRequestDataUpload objects), the body of the request will be encoded as multipart form data.

    NSData *imageData = UIImagePNGRepresentation(image);
    NFURLRequestDataUpload *upload = [NFURLRequestDataUpload dataWithContentType:@"image/png" data:imageData];
    NFURLRequest *req = [NFURLRequest requestWithURL:@"http://example.com/upload"];
    req.HTTPMethod = @"POST";
    [req setParameterValue:imageData forKey:@"image"];

to send a request asynchronously

    [conn sendRequest:req];

to send a request synchronously

    NFURLResponse *response = [conn sendSynchronousRequest:req];

access data structures from the response 

    id data = response.object;   // NSArray or NSDictionary if response body is json or xml

differentiating responses based on the request

    NSLog(@"request type is: %d", response.request.requestType);

When using a delegate and asynchronous requests, implement the NFURLConnectionDelegate protocol:

    // delegate method
    - (void)NFURLConnection:(NFURLConnection *)connection requestCompleted:(NFURLRequest *)request {
        NFURLResponse *response = request.response;
        
        ...
    }

Network Queue
-------------

The queue property of NFURLConnection is a NSOperationQueue, and can be accessed to modify the number of concurrent network operations sent by the connection (when sending asynchronous requests).  Each NFURLRequest is a NSOperation, and dependencies can be set up between them in the normal way.

License
-------
Copyright 2011 NextFaze
see also LICENSE.txt

