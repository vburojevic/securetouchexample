//
//  KeychainAuthenticationViewController.m
//  SecureTouch
//
//  Created by Vedran Burojevic on 28/09/15.
//  Copyright © 2015 Infinum. All rights reserved.
//

#import "KeychainAuthenticationViewController.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface KeychainAuthenticationViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation KeychainAuthenticationViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureUI];
}

#pragma mark - Configuration

- (void)configureUI
{
    // Title
    self.title = @"Keychain Authentication";
}

#pragma mark - IBActions

- (IBAction)addButtonHandler:(UIButton *)sender
{
    [self addTouchIDItemAsync];
}

- (IBAction)updateButtonHandler:(UIButton *)sender
{
    [self updateItemAsync];
}

- (IBAction)deleteButtonHandler:(UIButton *)sender
{
    [self deleteItemAsync];
}

- (IBAction)printButtonHandler:(UIButton *)sender
{
    [self copyMatchingAsync];
}

#pragma mark - Keychain

- (void)addTouchIDItemAsync {
    CFErrorRef error = NULL;
    
    SecAccessControlRef sacObject = nil;
    
    // Should be the secret invalidated when passcode is removed? If not then use kSecAttrAccessibleWhenUnlocked
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                    kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                    kSecAccessControlTouchIDAny, &error);
    } else {
        sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                    kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                    kSecAccessControlUserPresence, &error);
    }
    
    if (sacObject == NULL || error != NULL) {
        NSString *errorString = [NSString stringWithFormat:@"SecItemAdd can't create sacObject: %@", error];
        
        self.textView.text = [self.textView.text stringByAppendingString:errorString];
        
        return;
    }
    
    NSData *secretPasswordTextData = [@"SECRET_PASSWORD_TEXT" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *attributes = @{
                                 (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                 (__bridge id)kSecAttrService: @"SampleService",
                                 (__bridge id)kSecValueData: secretPasswordTextData,
                                 (__bridge id)kSecUseNoAuthenticationUI: @YES,
                                 (__bridge id)kSecAttrAccessControl: (__bridge_transfer id)sacObject
                                 };
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status =  SecItemAdd((__bridge CFDictionaryRef)attributes, nil);
        
        NSString *message = [NSString stringWithFormat:@"SecItemAdd status: %@", [self keychainErrorToString:status]];
        
        [self printMessageInTextView:message];
    });
}

- (void)copyMatchingAsync {
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: @"SampleService",
                            (__bridge id)kSecReturnData: @YES,
                            (__bridge id)kSecUseOperationPrompt: @"Authenticate to access service password",
                            };
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CFTypeRef dataTypeRef = NULL;
        NSString *message;
        
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)(query), &dataTypeRef);
        if (status == errSecSuccess) {
            NSData *resultData = (__bridge_transfer NSData *)dataTypeRef;
            
            NSString *result = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
            
            message = [NSString stringWithFormat:@"Result: %@\n", result];
        }
        else {
            message = [NSString stringWithFormat:@"SecItemCopyMatching status: %@", [self keychainErrorToString:status]];
        }
        
        [self printMessageInTextView:message];
    });
}

- (void)updateItemAsync {
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: @"SampleService",
                            (__bridge id)kSecUseOperationPrompt: @"Authenticate to update your password"
                            };
    
    NSData *updatedSecretPasswordTextData = [@"UPDATED_SECRET_PASSWORD_TEXT" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *changes = @{
                              (__bridge id)kSecValueData: updatedSecretPasswordTextData
                              };
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)changes);
        
        NSString *errorString = [self keychainErrorToString:status];
        NSString *message = [NSString stringWithFormat:@"SecItemUpdate status: %@", errorString];
        
        [self printMessageInTextView:message];
    });
}

- (void)deleteItemAsync {
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: @"SampleService"
                            };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
        
        NSString *errorString = [self keychainErrorToString:status];
        NSString *message = [NSString stringWithFormat:@"SecItemDelete status: %@", errorString];
        
        [self printMessageInTextView:message];
    });
}

#pragma mark - Convenience

- (void)printMessageInTextView:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Update the result in the main queue because we are calling from a background queue.
        self.textView.text = [self.textView.text stringByAppendingString:[NSString stringWithFormat:@"%@\n", message]];
        
        [self.textView scrollRangeToVisible:NSMakeRange([self.textView.text length], 0)];
    });
}

- (NSString *)keychainErrorToString:(OSStatus)error {
    NSString *message = [NSString stringWithFormat:@"%ld", (long)error];
    
    switch (error) {
        case errSecSuccess:
            message = @"success";
            break;
            
        case errSecDuplicateItem:
            message = @"error item already exists";
            break;
            
        case errSecItemNotFound :
            message = @"error item not found";
            break;
            
        case errSecAuthFailed:
            message = @"error item authentication failed";
            break;
            
        default:
            break;
    }
    
    return message;
}

@end
