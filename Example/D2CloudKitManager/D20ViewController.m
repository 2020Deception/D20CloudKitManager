//
//  D20ViewController.m
//  D2CloudKitManager
//
//  Created by Brian Bowman on 10/04/2016.
//  Copyright (c) 2016 Brian Bowman. All rights reserved.
//

#import "D20ViewController.h"

#import "D20CloudKitManager.h"

@interface D20ViewController ()

@end

@implementation D20ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[D20CloudKitManager sharedInstance] requestDiscoverabilityPermission:^(BOOL discoverable, NSError * _Nullable error) {
        if (discoverable) {
            [[D20CloudKitManager sharedInstance] discoverUserInfoWithRecordId:nil completionHandler:^(CKUserIdentity * _Nullable user, NSError * _Nullable error) {
                if (error) {
                    [[D20CloudKitManager sharedInstance] handleError:error serverFailureBlock:nil retryCallBlock:nil retryUploadBlock:nil partialFailureBlock:nil errorDisplayBlock:nil];
                }
                
                NSLog(@"%@ %@ %@", user.nameComponents.givenName, user.nameComponents.familyName, user.lookupInfo.emailAddress);
            }];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
