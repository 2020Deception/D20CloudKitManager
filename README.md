# D2CloudKitManager

[![CI Status](http://img.shields.io/travis/Brian Bowman/D2CloudKitManager.svg?style=flat)](https://travis-ci.org/Brian Bowman/D2CloudKitManager)
[![Version](https://img.shields.io/cocoapods/v/D2CloudKitManager.svg?style=flat)](http://cocoapods.org/pods/D2CloudKitManager)
[![License](https://img.shields.io/cocoapods/l/D2CloudKitManager.svg?style=flat)](http://cocoapods.org/pods/D2CloudKitManager)
[![Platform](https://img.shields.io/cocoapods/p/D2CloudKitManager.svg?style=flat)](http://cocoapods.org/pods/D2CloudKitManager)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

D2CloudKitManager is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "D2CloudKitManager"
```

## Author

Brian Bowman, brian.bowman@carrotcreative.com

## License

D2CloudKitManager is available under the MIT license. See the LICENSE file for more info.

## Usage

First you'll want to enable CloudKit on the capabilities tab of your project and add it to your app ID.  
To get started, place some code like this into your project:

```objc
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
```
