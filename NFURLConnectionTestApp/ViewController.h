//
//  ViewController.h
//  NFURLConnectionTestApp
//
//  Created by Andrew Williams on 27/02/12.
//  Copyright (c) 2012 NextFaze. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NFURLConnection.h"

@interface ViewController : UIViewController <NFURLConnectionDelegate, UITextFieldDelegate> {
    UIButton *goButton;
    UITextField *textField;
    UIScrollView *scrollView;
    UILabel *label;
    
    NFURLConnection *connection;
}

@property (nonatomic, retain) IBOutlet UIButton *goButton;
@property (nonatomic, retain) IBOutlet UITextField *textField;
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UILabel *label;

- (IBAction)buttonPressed:(id)sender;

@end
