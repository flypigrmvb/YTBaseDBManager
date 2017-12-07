//
//  VideoUploadModel.h
//  Plush
//
//  Created by aron on 2017/9/29.
//  Copyright © 2017年 qingot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YYModel.h>

@interface VideoUploadModel : NSObject <YYModel>

@property (nonatomic, assign) NSInteger itemID;
@property (nonatomic, strong) NSString* userId;
@property (nonatomic, strong) NSString* videoPath;
@property (nonatomic, strong) NSString* videoLocalName;
@property (nonatomic, strong) NSString* videoId; //视频文件id
@property (nonatomic, strong) NSString* videoURL; //视频播放地址
@property (nonatomic, strong) NSString* coverURL; //封面存储地址
@property (nonatomic, assign) NSInteger uploadBytes;
@property (nonatomic, assign) NSInteger totalBytes;
@property (nonatomic, strong) NSString* orderID;
@property (nonatomic, assign) BOOL isUploadSuccess;//是否上传到云端
@property (nonatomic, assign) BOOL isAsync;//是否同步到业务服务器

/**
 *  创建表
 */
+ (void)createTableIfNotExists;

/**
 插入一条数据
 */
+ (void)insertData:(VideoUploadModel*)data
              error:(NSError **)pError;

/**
 获取全部数据
 */
+ (void)retriveDatasWithCompletion:(void (^)(NSArray<VideoUploadModel*> *aDatas, NSError *aError))aCompletionBlock;

/**
 获取单条记录

 @param orderId OrderID
 */
+ (VideoUploadModel* )retriveDataWithOrderId:(NSString*)orderId completion:(void (^)(VideoUploadModel* aData, NSError *aError))aCompletionBlock;

@end
