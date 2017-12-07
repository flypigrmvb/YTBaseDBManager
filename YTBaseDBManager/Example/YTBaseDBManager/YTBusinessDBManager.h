//
//  YTBusinessDBManager.h
//  YTBaseDBManager
//
//  Created by aron on 2017/12/7.
//  Copyright © 2017年 flypigrmvb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YTBaseDBManager.h"

@interface YTBusinessDBManager : YTBaseDBManager

// 子类的单例
+ (instancetype)sharedInstance;

@end
