//
//  D20CloudKitManager.m
//  Pods
//
//  Created by Brian Bowman on 10/4/16.
//
//

#import "D20CloudKitManager.h"

@implementation D20CloudKitManager

+ (instancetype)sharedInstance {
    static D20CloudKitManager *sharedInstance = nil;
    static dispatch_once_t DispatchOnce;
    
    dispatch_once(&DispatchOnce, ^{
        sharedInstance = [[D20CloudKitManager alloc] init];
    });
    return sharedInstance;
}

#pragma mark - database/zone

+ (CKDatabase *)dataBaseFromType:(enum DatabaseType)databaseType {
    return databaseType == DatabaseTypePublic ?
    [[CKContainer defaultContainer] publicCloudDatabase] :
    [[CKContainer defaultContainer] privateCloudDatabase];
}

#pragma mark - saving/deleting items

- (void)saveRecord:(CKRecord *)record
      databaseType:(enum DatabaseType)databaseType
 completionHandler:(void (^)(CKRecord *record, NSError *error))completionHandler {
    [[D20CloudKitManager dataBaseFromType:databaseType] saveRecord:(CKRecord *)record completionHandler:^(CKRecord *record, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            NSLog(@"Successfully saved record");
            completionHandler(record, error);
        });
    }];
}

- (void)deleteRecord:(CKRecord *)record
        databaseType:(enum DatabaseType)databaseType
   completionHandler:(void (^)(CKRecordID *recordID, NSError *error))completionHandler {
    [[D20CloudKitManager dataBaseFromType:databaseType]  deleteRecordWithID:record.recordID completionHandler:^(CKRecordID *recordID, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            NSLog(@"Successfully deleted record");
            completionHandler(recordID, error);
        });
    }];
}

#pragma mark - discoverability

- (void)requestDiscoverabilityPermission:(void (^)(BOOL discoverable, NSError *error))completionHandler {
    [[CKContainer defaultContainer] accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError *error) {
        if (error) {
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(NO, error);
            });
        } else if (accountStatus == CKAccountStatusAvailable) {
            [[CKContainer defaultContainer] requestApplicationPermission:CKApplicationPermissionUserDiscoverability completionHandler:^(CKApplicationPermissionStatus applicationPermissionStatus, NSError *error) {
                 if (error)
                     NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
                 dispatch_async(dispatch_get_main_queue(), ^(void) {
                     completionHandler(applicationPermissionStatus == CKApplicationPermissionStatusGranted, error);
                 });
             }];
        } else if (accountStatus == CKAccountStatusNoAccount) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(NO, [NSError errorWithDomain:@"discoverability" code:404 userInfo:@{NSLocalizedDescriptionKey : @"Sign in to your iCloud account to write records. On the Home screen, launch Settings, tap iCloud, and enter your Apple ID. Turn iCloud Drive on. If you don't have an iCloud account, tap Create a new Apple ID."}]);
            });
        } else  if (accountStatus == CKAccountStatusRestricted){
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(NO, [NSError errorWithDomain:@"discoverability" code:404 userInfo:@{NSLocalizedDescriptionKey : @"Sorry your access is restricted by parental controls."}]);
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(NO, [NSError errorWithDomain:@"discoverability" code:404 userInfo:@{NSLocalizedDescriptionKey : @"Unknown error occurred."}]);
            });
        }
    }];
}

- (void)discoverUserInfoWithRecordId:(CKRecordID *)recordID completionHandler:(void (^)(CKUserIdentity * _Nullable, NSError * _Nullable))completionHandler {
    if (recordID) {
        [[CKContainer defaultContainer] discoverUserIdentityWithUserRecordID:recordID completionHandler:^(CKUserIdentity * _Nullable userInfo, NSError * _Nullable error) {
            if (error)
                NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                completionHandler(userInfo, error);
            });
        }];
    } else {
        [[CKContainer defaultContainer] fetchUserRecordIDWithCompletionHandler:^(CKRecordID *recordID, NSError *error) {
             if (error) {
                 NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
                 dispatch_async(dispatch_get_main_queue(), ^(void) {
                     completionHandler(nil, error);
                 });
             } else {
                 [[CKContainer defaultContainer] discoverUserIdentityWithUserRecordID:recordID completionHandler:^(CKUserIdentity * _Nullable userInfo, NSError * _Nullable error) {
                     if (error)
                         NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
                     
                     dispatch_async(dispatch_get_main_queue(), ^(void) {
                         completionHandler(userInfo, error);
                     });
                 }];
             }
         }];
    }
}

- (void)discoverAddressBookUsersEmail:(NSString *)email completionHandler:(void (^)(CKUserIdentity *userInfo, NSError *error))completionHandler {
    [[CKContainer defaultContainer] discoverUserIdentityWithEmailAddress:email completionHandler:^(CKUserIdentity * _Nullable userInfo, NSError * _Nullable error) {
        if (error)
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionHandler(userInfo, error);
        });
    }];
}

- (void)discoverAddressBookUsersInfos:(void (^)(NSArray<CKUserIdentity *> * _Nullable, NSError * _Nullable))completionHandler {
    [[CKContainer defaultContainer] discoverAllIdentitiesWithCompletionHandler:^(NSArray<CKUserIdentity *> * _Nullable userIdentities, NSError * _Nullable error) {
        if (error)
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionHandler(userIdentities, error);
        });
    }];
}

#pragma mark - queries

- (void)queryForRecordsNearLocation:(CLLocation *)location
                       databaseType:(enum DatabaseType)databaseType
                         recordType:(NSString *)recordType
                          predicate:(NSPredicate *)predicate
                        desiredKeys:(NSArray *)desiredKeys
                       resultLimits:(NSUInteger)resultLimits
                  completionHandler:(void (^)(CKQueryCursor *cursor, NSArray *records, NSError *error))completionHandler
                      progressBlock:(void (^)(NSArray *records))progressBlock {
    
    CKQuery *query = [[CKQuery alloc] initWithRecordType:recordType predicate:predicate];
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    
    queryOperation.desiredKeys = desiredKeys;
    queryOperation.resultsLimit = resultLimits;
    
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    [queryOperation setRecordFetchedBlock:^(CKRecord *record) {
        [results addObject:record];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            progressBlock(results);
        });
    }];
    
    queryOperation.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        if (error)
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionHandler(cursor, results, error);
        });
    };
    
    [[D20CloudKitManager dataBaseFromType:databaseType] addOperation:queryOperation];
}

- (void)queryRecordsWithType:(NSString *)recordType
                databaseType:(enum DatabaseType)databaseType
                 desiredKeys:(NSArray *)desiredKeys
                resultLimits:(NSUInteger)resultLimits
           completionHandler:(void (^)(CKQueryCursor *cursor, NSArray *records, NSError *error))completionHandler
               progressBlock:(void (^)(NSArray *records))progressBlock {
    
    NSPredicate *truePredicate = [NSPredicate predicateWithValue:YES];
    CKQuery *query = [[CKQuery alloc] initWithRecordType:recordType predicate:truePredicate];
    
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    queryOperation.desiredKeys = desiredKeys;
    queryOperation.resultsLimit = resultLimits;
    
    queryOperation.recordFetchedBlock = ^(CKRecord *record) {
        [results addObject:record];
        if (progressBlock)
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                progressBlock(results);
            });
    };
    
    queryOperation.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        if (error)
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionHandler(cursor, results, error);
        });
    };
    
    [[D20CloudKitManager dataBaseFromType:databaseType] addOperation:queryOperation];
}

- (void)fetchRecordWithID:(CKRecordID *)recordID
             databaseType:(enum DatabaseType)databaseType
        completionHandler:(void (^)(CKRecord *record, NSError *error))completionHandler {
    
    [[D20CloudKitManager dataBaseFromType:databaseType] fetchRecordWithID:recordID completionHandler:^(CKRecord *record, NSError *error) {
        
        if (error)
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionHandler(record, error);
        });
    
    }];
}

- (void)queryForRecordsWithPredicate:(NSPredicate *)predicate
                          recordType:(NSString *)recordType
                        databaseType:(enum DatabaseType)databaseType
                         desiredKeys:(NSArray *)desiredKeys
                        resultLimits:(NSUInteger)resultLimits
                       progressBlock:(void (^)(NSArray *records))progressBlock
                   completionHandler:(void (^)(CKQueryCursor *cursor, NSArray *records, NSError *error))completionHandler {
    
    CKQuery *query = [[CKQuery alloc] initWithRecordType:recordType predicate:predicate];
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    // Just request the name field for all records
    queryOperation.resultsLimit = resultLimits;
    queryOperation.desiredKeys = desiredKeys;
    
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    queryOperation.recordFetchedBlock = ^(CKRecord *record) {
        [results addObject:record];
        if (progressBlock)
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                progressBlock(results);
            });
    };
    
    queryOperation.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        if (error)
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionHandler(cursor, results, error);
        });
    };
    
    [[D20CloudKitManager dataBaseFromType:databaseType] addOperation:queryOperation];
}

#pragma mark - update records

- (void)updateRecordsWithRecordsToSave:(NSArray *)recordsToSave
                     recordIdsToDelete:(NSArray *)recordIdsToDelete
                          databaseType:(enum DatabaseType)databaseType
                            savePolicy:(CKRecordSavePolicy)savePolicy
                     completionHandler:(void (^)(NSArray *savedRecords, NSArray *deletedRecords, NSError *error))completionHandler {
    CKModifyRecordsOperation *updateRecords = [[CKModifyRecordsOperation alloc]
                                               initWithRecordsToSave:recordsToSave
                                               recordIDsToDelete:recordIdsToDelete];
    
    updateRecords.savePolicy = savePolicy;
    updateRecords.modifyRecordsCompletionBlock = ^(NSArray *savedRecords, NSArray *deletedRecords, NSError *error) {
        if (error)
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (completionHandler)
                completionHandler(savedRecords, deletedRecords, error);
        });
    };
    
    [[D20CloudKitManager dataBaseFromType:databaseType] addOperation:updateRecords];
}

#pragma mark - subscriptions


- (void)fetchSubscriptionWithID:(NSString *)subscriptionID
                   databaseType:(enum DatabaseType)databaseType
              completionHandler:(void (^)(CKSubscription * _Nullable subscription, NSError *error))completionHandler {
    CKFetchSubscriptionsOperation *operation = [[CKFetchSubscriptionsOperation alloc] initWithSubscriptionIDs:@[subscriptionID]];
    
    operation.fetchSubscriptionCompletionBlock = ^(NSDictionary<NSString *, CKSubscription *> * _Nullable subscriptionsBySubscriptionID,
                                                   NSError * _Nullable operationError) {
        if (operationError)
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), operationError);

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (completionHandler)
                completionHandler(subscriptionsBySubscriptionID[subscriptionID], operationError);
        });
    };
    
    [[D20CloudKitManager dataBaseFromType:databaseType] addOperation:operation];
}
                                                              

- (void)fetchAllSubscriptionsForDatabaseType:(enum DatabaseType)databaseType
                       withCompletionHandler:(void (^)(NSArray <CKSubscription *> *subscriptions, NSError *error))completionHandler {
    [[D20CloudKitManager dataBaseFromType:databaseType] fetchAllSubscriptionsWithCompletionHandler:^(NSArray *subscriptions, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(subscriptions, error);
            });
    }];
}

- (void)subscribeWithSubscription:(CKSubscription *)subscription
                     databaseType:(enum DatabaseType)databaseType
                completionHandler:(void (^)(CKSubscription *subscription, NSError *error))completionHandler {
    [[D20CloudKitManager dataBaseFromType:databaseType] saveSubscription:subscription completionHandler:^(CKSubscription *subscription, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionHandler(subscription, error);
        });
    }];
}

- (void)unsubscribeWithSubscriptionID:(NSString *)subscriptionID
                         databaseType:(enum DatabaseType)databaseType
                    completionHandler:(void (^)(NSArray *savedSubscriptions, NSArray *deletedSubscriptionIDs, NSError *error))completionHandler {
    CKModifySubscriptionsOperation *modifyOperation = [[CKModifySubscriptionsOperation alloc] init];
    modifyOperation.subscriptionIDsToDelete = @[subscriptionID];
    modifyOperation.modifySubscriptionsCompletionBlock = ^(NSArray *savedSubscriptions, NSArray *deletedSubscriptionIDs, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionHandler(savedSubscriptions, deletedSubscriptionIDs, error);
        });
    };
    [[D20CloudKitManager dataBaseFromType:databaseType] addOperation:modifyOperation];
}

- (void)handleError:(NSError *)error
 serverFailureBlock:(void (^)(BOOL errorAncestorRecordKey, BOOL errorServerRecordKey, BOOL errorClientRecordKey, CKErrorCode code, NSError *error))serverFailureBlock
     retryCallBlock:(void (^)(BOOL retryFromTimeOut, NSNumber *retryWaitTime, CKErrorCode code, NSError *error))retryCallBlock
   retryUploadBlock:(void (^)(BOOL retryUpload, CKRecord *recordToRetry, CKErrorCode code, NSError *error))retryUploadBlock
partialFailureBlock:(void (^)(NSDictionary *failedItemsInfo, CKErrorCode code, NSError *error))partialFailureBlock
  errorDisplayBlock:(void (^)(CKErrorCode code, NSError *error))errorDisplayBlock {
    NSLog(@"handle error %@: %@ %@ %lu", NSStringFromSelector(_cmd), error, error.domain, (long)error.code);
    if (error) {
        switch (error.code) {
            case CKErrorRequestRateLimited:
                if (error.userInfo[CKErrorRetryAfterKey]) {
                    NSLog(@"retry call block %@: %@", NSStringFromSelector(_cmd), error);
                    if (retryCallBlock)
                        dispatch_after([error.userInfo[CKErrorRetryAfterKey] integerValue], dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                            retryCallBlock(YES, error.userInfo[CKErrorRetryAfterKey], error.code, error);
                        });
                    return;
                }
            case CKErrorServiceUnavailable:
                if (error.userInfo[CKErrorRetryAfterKey]) {
                    NSLog(@"retry call block %@: %@", NSStringFromSelector(_cmd), error);
                    if (retryCallBlock)
                        retryCallBlock(YES, error.userInfo[CKErrorRetryAfterKey], error.code, error);
                    return;
                }
            case CKErrorZoneBusy: {
                if (error.userInfo[CKErrorRetryAfterKey]) {
                    NSLog(@"retry call block %@: %@", NSStringFromSelector(_cmd), error);
                    if (retryCallBlock)
                        retryCallBlock(YES, @10, error.code, error);
                    return;
                }
            }
            case CKErrorAssetFileModified:
                if (error.userInfo[CKRecordChangedErrorServerRecordKey]) {
                    NSLog(@"retry upload block %@: %@", NSStringFromSelector(_cmd), error);
                    if (retryUploadBlock)
                        retryUploadBlock(YES, error.userInfo[CKRecordChangedErrorServerRecordKey], error.code, error);
                    return;
                }
            case CKErrorPartialFailure:
                if (error.userInfo[CKPartialErrorsByItemIDKey]) {
                    NSLog(@"partial failure block %@: %@", NSStringFromSelector(_cmd), error);
                    if (partialFailureBlock)
                        partialFailureBlock(error.userInfo[CKPartialErrorsByItemIDKey], error.code, error);
                    return;
                }
                
            case CKErrorServerRecordChanged:
                if (serverFailureBlock) {
                    serverFailureBlock(error.userInfo[CKRecordChangedErrorAncestorRecordKey] != nil,
                                       error.userInfo[CKRecordChangedErrorServerRecordKey] != nil,
                                       error.userInfo[CKRecordChangedErrorClientRecordKey] != nil, error.code, error);
                    return;
                }
                
            case CKErrorLimitExceeded:
            case CKErrorChangeTokenExpired:
            case CKErrorIncompatibleVersion:
            case CKErrorNotAuthenticated:
            case CKErrorOperationCancelled:
            case CKErrorPermissionFailure:
            case CKErrorUserDeletedZone:
            case CKErrorZoneNotFound:
            case CKErrorInternalError:
            case CKErrorServerRejectedRequest:
            case CKErrorNetworkFailure:
            case CKErrorNetworkUnavailable:
            case CKErrorAssetFileNotFound:
            case CKErrorBadContainer:
            case CKErrorBadDatabase:
            case CKErrorBatchRequestFailed:
            case CKErrorUnknownItem:
            case CKErrorInvalidArguments:
            case CKErrorConstraintViolation:
            case CKErrorQuotaExceeded:
                break;
        }
        
        NSLog(@"error display block %@: %@ %@ %lu", NSStringFromSelector(_cmd), error, error.domain, (long)error.code);
        errorDisplayBlock(error.code, error);
    }
}

@end
