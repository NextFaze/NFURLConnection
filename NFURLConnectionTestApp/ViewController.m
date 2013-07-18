//
//  ViewController.m
//  NFURLConnectionTestApp
//
//  Created by Andrew Williams on 27/02/12.
//  Copyright (c) 2012 NextFaze. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (nonatomic, strong) NFURLConnection *connection;
@end

@implementation ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) {
        _connection = [[NFURLConnection alloc] init];
        _connection.delegate = self;
        self.title = @"NFURLConnection";
    }
    return self;
}

- (id)init {
    return [self initWithNibName:@"ViewController" bundle:nil];
}

- (void)dealloc {
    [_goButton release];
    [_label release];
    [_textField release];
    [_scrollView release];

    _connection.delegate = nil;
    [_connection release];

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
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
    if(sender == self.goButton) {
        [self.textField resignFirstResponder];
        
        NSURL *url = [NSURL URLWithString:self.textField.text];
        NFURLRequest *req = [NFURLRequest requestWithURL:url];
        [self.connection sendRequest:req];
        
        LOG(@"sending request to: %@", url);
    }
}

#pragma mark - NFURLConnectionDelegate

- (void)NFURLConnection:(NFURLConnection *)connection requestCompleted:(NFURLRequest *)request {
    CGRect frame = self.label.frame;
    
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

    self.label.text = request.response.body;
    frame.size = [self.label.text sizeWithFont:self.label.font constrainedToSize:CGSizeMake(frame.size.width, 9999)];
    LOG(@"label frame: (%.0f,%.0f)", frame.size.width, frame.size.height);
    self.label.frame = frame;
    self.scrollView.contentSize = frame.size;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldEndEditing:(UITextField *)tf {
    [tf resignFirstResponder];
    return YES;
}

@end
