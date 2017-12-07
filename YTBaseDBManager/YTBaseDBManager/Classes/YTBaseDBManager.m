//
//  YTBaseDBManager.m
//  Pods
//
//  Created by aron on 2017/11/14.
//
//

#import "YTBaseDBManager.h"
#import <sqlite3.h>
#import <pthread.h>
#import <objc/runtime.h>

#define YTBaseDBManager_ValueOrEmpty(value) 	((value)?(value):@"")
static NSString* DB_Version_Key = @"DB_Version_Key";

@interface YTBaseDBManager (){
    pthread_mutex_t _dbLock;
    FMDatabaseQueue *_databaseQueue;
}

@property (nonatomic, copy) NSString* DBFilePath;

@end

@implementation YTBaseDBManager

- (instancetype)init {
    self = [super init];
    if (self) {
        pthread_mutex_init(&_dbLock, NULL);
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(receiveMemoryWarning)
         name:UIApplicationDidReceiveMemoryWarningNotification
         object:nil];
    }
    return self;
}

- (void)dealloc{
    pthread_mutex_destroy(&_dbLock);
}

- (void)receiveMemoryWarning{
    pthread_mutex_lock(&_dbLock);
    _databaseQueue = nil;
    pthread_mutex_unlock(&_dbLock);
}


#pragma mark - ......::::::: public :::::::......

- (FMDatabaseQueue *)databaseQueue {
    if (nil == _DBFilePath) {
        return nil;
    }
    pthread_mutex_lock(&_dbLock);
    if (_databaseQueue == nil) {
        _databaseQueue = [FMDatabaseQueue databaseQueueWithPath:_DBFilePath flags:SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE];
    }
    pthread_mutex_unlock(&_dbLock);
    return _databaseQueue;
}

// 设置数据库文件路径和版本
- (void)setDBFilePath:(NSString *)DBFilePath newDBVersion:(NSString*)newDBVersion {
    // 设置数据库文件路径
    _DBFilePath = DBFilePath;
    [[NSFileManager defaultManager] setAttributes:[NSDictionary dictionaryWithObject:NSFileProtectionNone forKey:NSFileProtectionKey] ofItemAtPath:_DBFilePath error:NULL];
    
    // 数据库版本控制
    // 当前的方法如果是放在初始化方法中
    // versionControlWithNewDBVersion 方法调用 initTables 方法 会使用到当前单例对象
    // 因为初始化未完成，所以会造成死锁的问题，versionControlWithNewDBVersion 方法调用采用延迟的策略
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self versionControlWithNewDBVersion:newDBVersion];
    });
}

// 数据库版本控制主要方法
- (void)versionControlWithNewDBVersion:(NSString*)newDBVersion {
    if (nil == _DBFilePath) {
        return;
    }
    
    // 获取新旧版本
    NSString * version_old = YTBaseDBManager_ValueOrEmpty([self DBVersion]);
    NSString * version_new = [NSString stringWithFormat:@"%@", newDBVersion];
    NSLog(@"dbVersionControl before: %@ after: %@",version_old,version_new);
    
    // 数据库版本升级
    if (version_old != nil && ![version_new isEqualToString:version_old]) {
        
        // 获取数据库中旧的表
        NSArray* existsTables = [self sqliteExistsTables];
        NSMutableArray* tmpExistsTables = [NSMutableArray array];
        
        // 修改表名,添加后缀“_bak”，把旧的表当做备份表
        for (NSString* tablename in existsTables) {
            [tmpExistsTables addObject:[NSString stringWithFormat:@"%@_bak", tablename]];
            [self.databaseQueue inDatabase:^(FMDatabase *db) {
                NSString* sql = [NSString stringWithFormat:@"ALTER TABLE %@ RENAME TO %@_bak", tablename, tablename];
                [db executeUpdate:sql];
            }];
        }
        existsTables = tmpExistsTables;
        
        // 创建新的表
        [self initTables];
        
        // 获取新创建的表
        NSArray* newAddedTables = [self sqliteNewAddedTables];
        
        // 遍历旧的表和新表，对比取出需要迁移的表的字段
        NSDictionary* migrationInfos = [self generateMigrationInfosWithOldTables:existsTables newTables:newAddedTables];
        
        // 数据迁移处理
        [migrationInfos enumerateKeysAndObjectsUsingBlock:^(NSString* newTableName, NSArray* publicColumns, BOOL * _Nonnull stop) {
            NSMutableString* colunmsString = [NSMutableString new];
            for (int i = 0; i<publicColumns.count; i++) {
                [colunmsString appendString:publicColumns[i]];
                if (i != publicColumns.count-1) {
                    [colunmsString appendString:@", "];
                }
            }
            NSMutableString* sql = [NSMutableString new];
            [sql appendString:@"INSERT INTO "];
            [sql appendString:newTableName];
            [sql appendString:@"("];
            [sql appendString:colunmsString];
            [sql appendString:@")"];
            [sql appendString:@" SELECT "];
            [sql appendString:colunmsString];
            [sql appendString:@" FROM "];
            [sql appendFormat:@"%@_bak", newTableName];
            
            [self.databaseQueue inDatabase:^(FMDatabase *db) {
                [db executeUpdate:sql];
            }];
        }];
        
        // 删除备份表
        [self.databaseQueue inDatabase:^(FMDatabase *db) {
            [db beginTransaction];
            for (NSString* oldTableName in existsTables) {
                NSString* sql = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", oldTableName];
                [db executeUpdate:sql];
            }
            [db commit];
        }];
        
        [self setDBVersion:version_new];
        
    } else {
        [self setDBVersion:version_new];
    }
}


#pragma mark - ......::::::: Override :::::::......

// 初始化数据表
-(void)initTables {
    // 子类需要重写该方法
}


#pragma mark - ......::::::: Private :::::::......

#pragma mark 数据库版本

- (void)setDBVersion:(NSString*)DBVersion {
    [[NSUserDefaults standardUserDefaults] setObject:DBVersion forKey:DB_Version_Key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString*)DBVersion {
    return [[NSUserDefaults standardUserDefaults] objectForKey:DB_Version_Key];
}

#pragma mark 数据库操作

// 遍历旧的表和新表，对比取出需要迁移的表的字段
- (NSDictionary*)generateMigrationInfosWithOldTables:(NSArray*)oldTables newTables:(NSArray*)newTables {
    NSMutableDictionary<NSString*, NSArray* >* migrationInfos = [NSMutableDictionary dictionary];
    for (NSString* newTableName in newTables) {
        NSString* oldTableName = [NSString stringWithFormat:@"%@_bak", newTableName];
        if ([oldTables containsObject:oldTableName]) {
            // 获取表数据库字段信息
            NSArray* oldTableColumns = [self sqliteTableColumnsWithTableName:oldTableName];
            NSArray* newTableColumns = [self sqliteTableColumnsWithTableName:newTableName];
            NSArray* publicColumns = [self publicColumnsWithOldTableColumns:oldTableColumns newTableColumns:newTableColumns];
            
            if (publicColumns.count > 0) {
                [migrationInfos setObject:publicColumns forKey:newTableName];
            }
        }
    }
    return migrationInfos;
}

// 提取新表和旧表的共同表字段，表字段相同列的才需要进行数据迁移处理
- (NSArray*)publicColumnsWithOldTableColumns:(NSArray*)oldTableColumns newTableColumns:(NSArray*)newTableColumns {
    NSMutableArray* publicColumns = [NSMutableArray array];
    for (NSString* oldTableColumn in oldTableColumns) {
        if ([newTableColumns containsObject:oldTableColumn]) {
            [publicColumns addObject:oldTableColumn];
        }
    }
    return publicColumns;
}

// 获取数据库表的所有的表字段名
- (NSArray*)sqliteTableColumnsWithTableName:(NSString*)tableName {
    __block NSMutableArray<NSString*>* tableColumes = [NSMutableArray array];
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        NSString* sql = [NSString stringWithFormat:@"PRAGMA table_info('%@')", tableName];
        FMResultSet *rs = [db executeQuery:sql];
        while ([rs next]) {
            NSString* columnName = [rs stringForColumn:@"name"];
            [tableColumes addObject:columnName];
        }
    }];
    return tableColumes;
}

// 获取数据库中旧的表
- (NSArray*)sqliteExistsTables {
    __block NSMutableArray<NSString*>* existsTables = [NSMutableArray array];
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        NSString* sql = @"SELECT * from sqlite_master WHERE type='table'";
        FMResultSet *rs = [db executeQuery:sql];
        while ([rs next]) {
            NSString* tablename = [rs stringForColumn:@"name"];
            [existsTables addObject:tablename];
        }
    }];
    return existsTables;
}

// 获取新创建的表
- (NSArray*)sqliteNewAddedTables {
    __block NSMutableArray<NSString*>* newAddedTables = [NSMutableArray array];
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        NSString* sql = @"SELECT * from sqlite_master WHERE type='table' AND name NOT LIKE '%_bak'";
        FMResultSet *rs = [db executeQuery:sql];
        while ([rs next]) {
            NSString* tablename = [rs stringForColumn:@"name"];
            [newAddedTables addObject:tablename];
        }
    }];
    return newAddedTables;
}

@end
