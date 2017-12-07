# YTBaseDBManager
IOS数据库升级数据数据迁移的解决方案

### 原理分析
[IOS 数据库升级数据迁移解决方案](https://my.oschina.net/FEEDFACF/blog/901765)

### 安装

使用 Pod 导入，因为是开发库，所以需要指定 :path 参数
```ruby
pod 'YTBaseDBManager', :path => '../'
```

### 使用

客户端使用的DEMO代码如下  
1. 客户端使用方法 `[self setDBFilePath:DBPath newDBVersion:DB_Version];` 设置数据库路径
2. 客户端重写模板方法 `initTables` 执行创建表的逻辑
3. 底层库会自动分析新表和旧表，自动进行数据迁移的操作

```objc
/** 数据库保存的缓存目录 */
static NSString* kDBCache = @"DBCache";
/** 数据库文件名称 */
static NSString* DB_NAME = @"YTDB.sqlite";
/** 当前使用的数据库版本，程序会根据版本号的改变升级数据库以及迁移旧的数据 */
static NSString* DB_Version = @"1.0.0";

@implementation YTBusinessDBManager

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
    [VideoUploadModel createTableIfNotExists];
}

```