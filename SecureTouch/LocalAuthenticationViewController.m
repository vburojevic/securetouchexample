//
//  LocalAuthenticationViewController.m
//  SecureTouch
//
//  Created by Vedran Burojevic on 28/09/15.
//  Copyright © 2015 Infinum. All rights reserved.
//

#import <LocalAuthentication/LocalAuthentication.h>

#import "LocalAuthenticationViewController.h"

@interface LocalAuthenticationViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation LocalAuthenticationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self configureUI];
}

#pragma mark - Configuration

- (void)configureUI
{
    // Title
    self.title = @"Local Authentication";
}

#pragma mark - IBActions

- (IBAction)verifyButtonHandler:(UIButton *)sender
{
    [self authenticateUser];
}

#pragma mark - Local authentication

- (void)authenticateUser
{
    // Create new local authentication context
    LAContext *context = [[LAContext alloc] init];
    
    NSError *error = nil;
    
    // Evaluate policy
    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                localizedReason:@"Identify yourself!"
                          reply:^(BOOL success, NSError *error) {
                              
                              if (success) {
                                  // User is authenticated, show success alert
                                  [self printMessageInTextView:@"Authentication succeeded"];
                                  [self showAuthenticationSuccessAlert];
                              } else {
                                  // Authentication failed, log the error
                                  switch (error.code) {
                                      case LAErrorAuthenticationFailed:
                                          [self printMessageInTextView:@"Authentication failed, user didn't provide valid credentials"];
                                          break;
                                          
                                      case LAErrorUserCancel:
                                          [self printMessageInTextView:@"Authentication was canceled by user"];
                                          break;
                                          
                                      case LAErrorUserFallback:
                                          [self printMessageInTextView:@"Authentication was canceled, user tapped the fallback button"];
                                          break;
                                          
                                      case LAErrorSystemCancel:
                                          [self printMessageInTextView:@"Authentication was canceled by system"];
                                          break;
                                          
                                          
                                      default:
                                          [self printMessageInTextView:@"Authentication failed"];
                                          break;
                                  }
                              }
                          }
         
         
         ];
    } else {
        // Device can't use Touch ID, show error message
        [self printMessageInTextView:@"Device can't use Touch ID"];
    }
}

#pragma mark - Convenience

- (void)showAuthenticationSuccessAlert
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // Update the result in the main queue because we are calling from a background queue
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Great success"
                                              message:@"You're verified"
                                              preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Nice!" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:okAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    });
}

- (void)printMessageInTextView:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Update the result in the main queue because we are calling from a background queue
        self.textView.text = [self.textView.text stringByAppendingString:[NSString stringWithFormat:@"%@\n", message]];
        
        [self.textView scrollRangeToVisible:NSMakeRange([self.textView.text length], 0)];
    });
}

@end
