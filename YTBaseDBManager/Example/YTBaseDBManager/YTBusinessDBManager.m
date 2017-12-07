//
//  YTBusinessDBManager.m
//  YTBaseDBManager
//
//  Created by aron on 2017/12/7.
//  Copyright © 2017年 flypigrmvb. All rights reserved.
//

#import "YTBusinessDBManager.h"
#import "VideoUploadModel.h"

/** 数据库保存的缓存目录 */
static NSString* kDBCache = @"DBCache";
/** 数据库文件名称 */
static NSString* DB_NAME = @"YTDB.sqlite";
/** 当前使用的数据库版本，程序会根据版本号的改变升级数据库以及迁移旧的数据 */
static NSString* DB_Version = @"1.0.1";

@implementation YTBusinessDBManager

// 子类的单例
+ (instancetype)sharedInstance{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 创建数据库文件
        NSString* cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *DBDir = [cachePath stringByAppendingPathComponent:kDBCache];
        BOOL isDir = NO;
        if (!([[NSFileManager defaultManager] fileExistsAtPath:DBDir isDirectory:&isDir] && isDir)) {
            [[NSFileManager defaultManager] createDirectoryAtPath:DBDir withIntermediateDirectories :YES attributes :nil error :nil];
        }
        NSString* DBPath = [DBDir stringByAppendingPathComponent:DB_NAME];
        
        // 设置数据库路径，包含了数据库升级的逻辑
        [self setDBFilePath:DBPath newDBVersion:DB_Version];
    }
    return self;
}

// 初始化数据表
- (void)initTables {
    // TODO: 在这里做初始化表的操作
    [VideoUploadModel createTableIfNotExists];
}

@end
