T2URLConnection
===============

T2URLConnection - basic framework for sending network requests and parsing responses

External requirements:

* json-framework

Installation
------------

    > git clone git://github.com/2moro/T2URLConnction.git
    > cd T2URLConnction
    > git submodule init
    > git submodule update

T2URLConnction is a Cocoa Touch Static Library project, and can be incorporated into other xcode projects in the usual ways.

Notes:
- ensure T2URLConnection is added as Target Dependency
- ensure libT2URLSConnection.a is added to Link Binary Wiht Libraries
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
    T2URLConnection *conn = [[T2URLConnection alloc] init];
    conn.delegate = self;   // optional
    
    // create a request
    T2URLRequest *req = [[[T2URLRequest alloc] init] autorelease];
    req.path = [NSString stringWithFormat:@"parties/%d.json", party.sid];
    req.HTTPMethod = @"GET"; 
    req.requestType = RequestType1;   // optionally assign a request type
    [req setParameterValue:@"foo" forKey:@"bar"];  // optionally assign parameters

    // send a request asynchronously
    [conn sendRequest:req];

    // send a request synchronously
    T2URLResponse *response = [conn sendSynchronousRequest:req];
    
    // accessing data structures from the response
    id data = response.object;   // NSArray or NSDictionary if response body is json or xml

    // differentiating responses based on the request
    // the response object contains a reference to the request:
    NSLog(@"request type is: %d", response.request.requestType);

Network Queue
-------------

The queue property of T2URLConnection is a NSOperationQueue, and can be accessed to modify the number of concurrent network operations sent by the connection (when sending asynchronous requests).  Each T2URLRequest is a NSOperation, and dependencies can be set up between them in the normal way.

License
-------
Copyright 2011 2moro mobile
see also LICENSE.txt

