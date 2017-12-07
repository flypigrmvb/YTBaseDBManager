//
//  YTBaseDBManager.h
//  Pods
//
//  Created by aron on 2017/11/14.
//
//

#import <Foundation/Foundation.h>
#import <FMDB/FMDB.h>

@interface YTBaseDBManager : NSObject

@property (nonatomic, strong, readonly) FMDatabaseQueue *databaseQueue;///<数据库操作Queue

// ！！！设置数据库文件路径和版本号
- (void)setDBFilePath:(NSString *)DBFilePath newDBVersion:(NSString*)newDBVersion;

#pragma mark - ......::::::: 模板方法，子类重写 :::::::......

// 初始化数据表
- (void)initTables;

@end
