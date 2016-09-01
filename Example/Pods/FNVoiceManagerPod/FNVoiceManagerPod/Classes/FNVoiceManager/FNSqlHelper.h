//
//  FNSqlHelper.h
//  FNVoiceDemo
//
//  Created by JR on 16/8/23.
//  Copyright © 2016年 JR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FNUser.h"

@interface FNSqlHelper : NSObject

// 插入模型数据
+ (BOOL)insertModel:(FNUser *)model;

/** 查询数据,如果 传空 默认会查询表中所有数据 */
+ (NSArray *)queryData:(NSString *)querySql;

/** 删除数据,如果 传空 默认会删除表中所有数据 */
+ (BOOL)deleteData:(NSString *)deleteSql;

/** 修改数据 */
+ (BOOL)modifyData:(NSString *)modifySql;

@end
