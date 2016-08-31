//
//  FNSqlHelper.m
//  FNVoiceDemo
//
//  Created by JR on 16/8/23.
//  Copyright © 2016年 JR. All rights reserved.
//

#import "FNSqlHelper.h"
#import "FMDB.h"

#define FNSQLITE_NAME @"modals.sqlite"

@implementation FNSqlHelper

static FMDatabase *_fmdb;

+ (void)initialize {
    // 执行打开数据库和创建表操作
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:FNSQLITE_NAME];
    _fmdb = [FMDatabase databaseWithPath:filePath];
    
    [_fmdb open];
    
   // 必须先打开数据库才能创建表
    [_fmdb executeUpdate:@"CREATE TABLE IF NOT EXISTS t_modals(id INTEGER PRIMARY KEY, userID TEXT NOT NULL, userName TEXT NOT NULL, contactID TEXT NOT NULL, contactName TEXT NOT NULL, voiceID TEXT NOT NULL, voiceName TEXT NOT NULL, voiceSize REAL NOT NULL, voiceDuration REAL NOT NULL, voiceConvertAmrTime REAL NOT NULL);"];
}

+ (BOOL)insertModel:(FNUser *)model {
    NSString *insertSql = [NSString stringWithFormat:@"INSERT INTO t_modals(userID, userName, contactID,contactName,voiceID,voiceName,voiceSize,voiceDuration,voiceConvertAmrTime) VALUES ('%@', '%@', '%@',  '%@', '%@', '%@','%@','%@', '%@');", model.userID, model.userName, model.contactID,model.contactName,model.voiceID,model.voiceName,model.voiceSize,model.voiceDuration,model.voiceConvertAmrTime];
    return [_fmdb executeUpdate:insertSql];
}

+ (NSArray *)queryData:(NSString *)querySql {
    
    if (querySql == nil) {
        querySql = @"SELECT * FROM t_modals;";
    }
    
    NSMutableArray *arrM = [NSMutableArray array];
    FMResultSet *set = [_fmdb executeQuery:querySql];
    
    while ([set next]) {
        
        NSString *userID = [set stringForColumn:@"userID"];
        NSString *userName = [set stringForColumn:@"userName"];
        NSString *contactID = [set stringForColumn:@"contactID"];
        NSString *contactName = [set stringForColumn:@"contactName"];
        NSString *voiceID = [set stringForColumn:@"voiceID"];
        NSString *voiceName = [set stringForColumn:@"voiceName"];
        NSNumber *voiceSize = @([set intForColumn:@"voiceSize"]);
        NSNumber *voiceDuration = @([set doubleForColumn:@"voiceDuration"]);
        NSNumber *voiceConvertAmrTime = @([set doubleForColumn:@"voiceConvertAmrTime"]);
        
        FNUser *modal = [FNUser modalWith:userID userName:userName contactID:contactID contactName:contactName voiceID:voiceID voiceName:voiceName voiceSize:voiceSize voiceDuration:voiceDuration voiceConvertAmrTime:voiceConvertAmrTime];
        [arrM addObject:modal];
    }
    return arrM;
}

+ (BOOL)deleteData:(NSString *)deleteSql {
    
    if (deleteSql == nil) {
        deleteSql = @"DELETE FROM t_modals";
    }
    
    return [_fmdb executeUpdate:deleteSql];
    
}

+ (BOOL)modifyData:(NSString *)modifySql {
    
    if (modifySql == nil) {
        modifySql = @"UPDATE t_modals SET contactName = '789789' WHERE userName = 'jiarui'";
    }
    return [_fmdb executeUpdate:modifySql];
}


@end
