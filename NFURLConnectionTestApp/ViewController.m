//
//  ViewController.m
//  NFURLConnectionTestApp
//
//  Created by Andrew Williams on 27/02/12.
//  Copyright (c) 2012 NextFaze. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize goButton, label, textField, scrollView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) {
        connection = [[NFURLConnection alloc] init];
        connection.delegate = self;
        self.title = @"NFURLConnection";
    }
    return self;
}

- (id)init {
    return [self initWithNibName:@"ViewController" bundle:nil];
}

- (void)deallocView {
    self.goButton = nil;
    self.label = nil;
    self.textField = nil;
    self.scrollView = nil;
}

- (void)dealloc {
    connection.delegate = nil;
    [connection release];
    [self deallocView];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    [self deallocView];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - Actions

- (IBAction)buttonPressed:(id)sender {
    if(sender == goButton) {
        [textField resignFirstResponder];
        
        NSURL *url = [NSURL URLWithString:textField.text];
        NFURLRequest *req = [NFURLRequest requestWithURL:url];
        [connection sendRequest:req];
        
        LOG(@"sending request to: %@", url);
    }
}

#pragma mark - NFURLConnectionDelegate

- (void)NFURLConnection:(NFURLConnection *)connection requestCompleted:(NFURLRequest *)request {
    CGRect frame = label.frame;
    
    LOG(@"request completed");
    LOG(@"response: %@", request.response.body);
    LOG(@"response content type: %@", request.response.contentType);
    
    if(request.response.error) {
        UIAlertView *alert = [[UIAlertView alloc] init];
        alert.title = @"Error";
        alert.message = [request.response.error localizedDescription];
        [alert addButtonWithTitle:@"Ok"];
        [alert show];
        [alert release];
    }

    label.text = request.response.body;
    frame.size = [label.text sizeWithFont:label.font constrainedToSize:CGSizeMake(frame.size.width, 9999)];
    LOG(@"label frame: (%.0f,%.0f)", frame.size.width, frame.size.height);
    label.frame = frame;
    scrollView.contentSize = frame.size;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldEndEditing:(UITextField *)tf {
    [tf resignFirstResponder];
    return YES;
}

@end
