//
//  HomeTableViewController.m
//  SecureTouch
//
//  Created by Vedran Burojevic on 28/09/15.
//  Copyright © 2015 Infinum. All rights reserved.
//

#import "HomeTableViewController.h"

@interface HomeTableViewController ()

@end

@implementation HomeTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureUI];
}

#pragma mark - Configuration

- (void)configureUI
{
    // Title
    self.title = @"Secure Touch";
    
    // Table view
    self.tableView.tableFooterView = [UIView new];
}

@end
