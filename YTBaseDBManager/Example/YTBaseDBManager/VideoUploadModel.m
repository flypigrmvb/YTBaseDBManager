//
//  VideoUploadModel.m
//  Plush
//
//  Created by aron on 2017/9/29.
//  Copyright © 2017年 qingot. All rights reserved.
//

#import "VideoUploadModel.h"
#import "YTBusinessDBManager.h"

@implementation VideoUploadModel

static NSString* videoupload_tableName = @"t_uploadvideo";

- (NSString *)videoPath {
    NSString* videoSavedDir = @"";
    return [videoSavedDir stringByAppendingPathComponent:self.videoLocalName];
}

/**
 *  创建表
 */
+ (void)createTableIfNotExists {
    NSString* sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (itemID INTEGER, orderID TEXT, userId TEXT, contentJsonString TEXT, PRIMARY KEY(itemID));", videoupload_tableName];
    
    [[YTBusinessDBManager sharedInstance].databaseQueue inDatabase:^(FMDatabase *db) {
        BOOL result = [db executeUpdate:sql];
        NSLog(@"==CREATE TABLE %d", result);
    }];
}

/**
 插入一条数据
 */
+ (void)insertData:(VideoUploadModel*)data
             error:(NSError **)pError {
    NSString* contentJsonString = [data yy_modelToJSONString];
    contentJsonString = [contentJsonString stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
    NSMutableString* sql = [NSMutableString stringWithFormat:@"REPLACE INTO %@ (itemID, orderID, userId, contentJsonString) VALUES (%@, '%@', '%@', '%@')",
                            videoupload_tableName,
                            @(data.itemID),
                            (data.orderID),
                            (data.userId),
                            (contentJsonString)];
    [self.class doUpdateWithSql:sql error:pError];
}

/**
 获取数据
 */
+ (void)retriveDatasWithCompletion:(void (^)(NSArray<VideoUploadModel*> *aDatas, NSError *aError))aCompletionBlock {
    NSMutableArray *results = [NSMutableArray array];
    NSMutableString* sql = [NSMutableString stringWithFormat:@"SELECT * FROM %@ WHERE 1=1", videoupload_tableName];
    // [sql appendFormat:@" AND userId = %@", @([AccountManager sharedInstance].account.userID)];
    [[YTBusinessDBManager sharedInstance].databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:sql];
        while (set.next) {
            NSString* contentJsonString = [set objectForColumnName:@"contentJsonString"];
            contentJsonString = [contentJsonString stringByReplacingOccurrencesOfString:@"''" withString:@"'"];
            NSData* jsonData = [contentJsonString dataUsingEncoding: NSUTF8StringEncoding];
            if (jsonData) {
                NSDictionary* dic = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:NULL];
                if (dic) {
                    VideoUploadModel* data = [VideoUploadModel yy_modelWithDictionary:dic];
                    if (data) {
                        [results addObject:data];
                    }
                }
            }
        }
    }];
    !aCompletionBlock ?: aCompletionBlock(results, nil);
}

/**
 获取单条记录
 
 @param orderId OrderID
 */
+ (VideoUploadModel*)retriveDataWithOrderId:(NSString*)orderId completion:(void (^)(VideoUploadModel* aData, NSError *aError))aCompletionBlock {
    NSMutableArray *results = [NSMutableArray array];
    NSMutableString* sql = [NSMutableString stringWithFormat:@"SELECT * FROM %@ WHERE 1=1", videoupload_tableName];
    [sql appendFormat:@" AND orderID = %@", orderId];
    [[YTBusinessDBManager sharedInstance].databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:sql];
        while (set.next) {
            NSString* contentJsonString = [set objectForColumnName:@"contentJsonString"];
            contentJsonString = [contentJsonString stringByReplacingOccurrencesOfString:@"''" withString:@"'"];
            NSData* jsonData = [contentJsonString dataUsingEncoding: NSUTF8StringEncoding];
            if (jsonData) {
                NSDictionary* dic = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:NULL];
                if (dic) {
                    VideoUploadModel* data = [VideoUploadModel yy_modelWithDictionary:dic];
                    if (data) {
                        [results addObject:data];
                    }
                }
            }
        }
    }];
    if (results.count) {
        !aCompletionBlock ?: aCompletionBlock(results.firstObject, nil);
        return results.lastObject;
    } else {
        !aCompletionBlock ?: aCompletionBlock(nil, [self noDataError]);
        return nil;
    }
}


#pragma mark - ......::::::: helper :::::::......

+ (void)doUpdateWithSql:(NSString* )sql error:(NSError **)pError {
    __block BOOL result = NO;
    [[YTBusinessDBManager sharedInstance].databaseQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql];
    }];
    if (result == NO && pError) {
        *pError = [NSError errorWithDomain:@"" code:1 userInfo:nil];
    }
}

+ (NSError*)noDataError {
    return [NSError errorWithDomain:@"com.qinqot.Plush" code:1 userInfo:nil];
}

@end
