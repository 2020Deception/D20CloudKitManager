//
//  D20CloudKitManager.h
//  Pods
//
//  Created by 2020Deceptiononymous on 10/4/16.
//
//

@import Foundation;
@import CloudKit;
@import UIKit;

NS_ENUM(NSInteger, DatabaseType) {
    DatabaseTypePublic,
    DatabaseTypePrivate
};


@interface D20CloudKitManager : NSObject

+ (instancetype _Nonnull)sharedInstance;

#pragma mark - database/zone

/**returns a CKDatabase*/
+ (CKDatabase * _Nonnull)dataBaseFromType:(enum DatabaseType)databaseType;

#pragma mark - save/delete

/**save a new record to a database*/
- (void)saveRecord:(CKRecord * _Nonnull)record
      databaseType:(enum DatabaseType)databaseType
 completionHandler:(void (^ _Nullable)(CKRecord * _Nullable record, NSError * _Nullable error))completionHandler;

/**delete a record*/
- (void)deleteRecord:(CKRecord * _Nonnull)record
        databaseType:(enum DatabaseType)databaseType
   completionHandler:(void (^ _Nullable)(CKRecordID * _Nullable recordID, NSError * _Nullable error))completionHandler;

#pragma mark - discover records (users)

/**request discoverability for the user*/
- (void)requestDiscoverabilityPermission:(void (^ _Nullable)(BOOL discoverable, NSError * _Nullable error))completionHandler;

/**discover user info. Passing nil will return info for the current user*/
- (void)discoverUserInfoWithRecordId:(CKRecordID * _Nullable)recordID
                   completionHandler:(void (^ _Nullable)(CKUserIdentity * _Nullable user, NSError * _Nullable error))completionHandler;

/**discover friends info*/
- (void)discoverAddressBookUsersInfos:(void (^ _Nullable)(NSArray <CKUserIdentity *> * _Nullable userInfos, NSError * _Nullable error))completionHandler;

/**discover info by email*/
- (void)discoverAddressBookUsersEmail:(NSString * _Nonnull)email
                    completionHandler:(void (^ _Nullable)(CKUserIdentity * _Nullable userInfo, NSError * _Nullable error))completionHandler;

#pragma mark - fetch/query for records

/**fetch records based on type*/
- (void)queryRecordsWithType:(NSString * _Nonnull)recordType
                databaseType:(enum DatabaseType)databaseType
                 desiredKeys:(NSArray * _Nonnull)desiredKeys
                resultLimits:(NSUInteger)resultLimits
           completionHandler:(void (^ _Nullable)(CKQueryCursor * _Nullable cursor, NSArray * _Nullable records, NSError * _Nullable error))completionHandler
               progressBlock:(void (^ _Nullable)(NSArray * _Nullable records))progressBlock;

/**get records based on location*/
- (void)queryForRecordsNearLocation:(CLLocation * _Nonnull)location
                       databaseType:(enum DatabaseType)databaseType
                         recordType:(NSString * _Nonnull)recordType
                          predicate:(NSPredicate * _Nonnull)predicate
                        desiredKeys:(NSArray * _Nonnull)desiredKeys
                       resultLimits:(NSUInteger)resultLimits
                  completionHandler:(void (^ _Nullable)(CKQueryCursor * _Nullable cursor, NSArray * _Nullable records, NSError * _Nullable error))completionHandler
                      progressBlock:(void (^ _Nullable)(NSArray * _Nullable records))progressBlock;

/**fetch records based on a predicate and record type*/
- (void)queryForRecordsWithPredicate:(NSPredicate * _Nonnull)predicate
                          recordType:(NSString * _Nonnull)recordType
                        databaseType:(enum DatabaseType)databaseType
                         desiredKeys:(NSArray * _Nonnull)desiredKeys
                        resultLimits:(NSUInteger)resultLimits
                       progressBlock:(void (^ _Nullable)(NSArray * _Nullable records))progressBlock
                   completionHandler:(void (^ _Nullable)(CKQueryCursor * _Nullable cursor, NSArray * _Nullable records, NSError * _Nullable error))completionHandler;

/**get a record based on a record Id*/
- (void)fetchRecordWithID:(CKRecordID * _Nonnull)recordID
             databaseType:(enum DatabaseType)databaseType
        completionHandler:(void (^ _Nullable)(CKRecord * _Nullable record, NSError * _Nullable error))completionHandler;

#pragma mark - update records

/**update records*/
- (void)updateRecordsWithRecordsToSave:(NSArray * _Nonnull)recordsToSave
                     recordIdsToDelete:(NSArray * _Nonnull)recordIdsToDelete
                          databaseType:(enum DatabaseType)databaseType
                            savePolicy:(CKRecordSavePolicy)savePolicy
                     completionHandler:(void (^ _Nullable)(NSArray * _Nullable savedRecords, NSArray * _Nullable deletedRecords, NSError * _Nullable error))completionHandler;

#pragma mark - subscriptions

/**fetch subscription with ID*/
- (void)fetchSubscriptionWithID:(NSString * _Nonnull)subscriptionID
                   databaseType:(enum DatabaseType)databaseType
              completionHandler:(void (^ _Nullable)(CKSubscription * _Nullable subscription, NSError * _Nullable error))completionHandler;

/**fetch all user subscriptions*/
- (void)fetchAllSubscriptionsForDatabaseType:(enum DatabaseType)databaseType
                       withCompletionHandler:(void (^ _Nullable)(NSArray <CKSubscription *> * _Nullable subscriptions, NSError * _Nullable error))completionHandler;

/**creates a subscription*/
- (void)subscribeWithSubscription:(CKSubscription * _Nonnull)subscription
                     databaseType:(enum DatabaseType)databaseType
                completionHandler:(void (^ _Nullable)(CKSubscription * _Nullable subscription, NSError * _Nullable error))completionHandler;

/**removes a subscription*/
- (void)unsubscribeWithSubscriptionID:(NSString * _Nonnull)subscriptionID
                         databaseType:(enum DatabaseType)databaseType
                    completionHandler:(void (^ _Nullable)(NSArray * _Nullable savedSubscriptions, NSArray * _Nullable deletedSubscriptionIDs, NSError * _Nullable error))completionHandler;

#pragma mark - handleErrors
/**handle cloudkit errors
 @param serverFailureBlock returned if there is conflict saving the record on the server
 @param retryCallBlock returned if the error contains a retryWaitTime to retry the call
 @param retryUploadBlock returned if the server returns the more recent record on the server than the one that is to be modified
 @param partialFailureBlock returned if there was a partial error during an upload. THe dictionary is CKRecordId object as the key and CKRecord as the value
 @param errorDisplayBlock returned if the error requires some user interaction or display
 */
- (void)handleError:(NSError * _Nonnull)error
 serverFailureBlock:(void (^ _Nullable)(BOOL errorAncestorRecordKey, BOOL errorServerRecordKey, BOOL errorClientRecordKey, CKErrorCode code, NSError * _Nullable error))serverFailureBlock
     retryCallBlock:(void (^ _Nullable)(BOOL retryFromTimeOut, NSNumber * _Nullable retryWaitTime, CKErrorCode code, NSError * _Nullable error))retryCallBlock
   retryUploadBlock:(void (^ _Nullable)(BOOL retryUpload, CKRecord * _Nullable recordToRetry, CKErrorCode code, NSError * _Nullable error))retryUploadBlock
partialFailureBlock:(void (^ _Nullable)(NSDictionary * _Nullable failedItemsInfo, CKErrorCode code, NSError * _Nullable error))partialFailureBlock
  errorDisplayBlock:(void (^ _Nullable)(CKErrorCode code, NSError * _Nullable error))errorDisplayBlock;

@end
