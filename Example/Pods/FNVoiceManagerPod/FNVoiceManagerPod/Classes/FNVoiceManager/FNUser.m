//
//  FNUser.m
//  FNVoiceDemo
//
//  Created by JR on 16/8/23.
//  Copyright © 2016年 JR. All rights reserved.
//

#import "FNUser.h"

@implementation FNUser

+ (instancetype) modalWith:(NSString *)userID
                  userName:(NSString *)userName
                 contactID:(NSString *)contactID
               contactName:(NSString *)contactName
                   voiceID:(NSString *)voiceID
                 voiceName:(NSString *)voiceName
                 voiceSize:(NSNumber *)voiceSize
             voiceDuration:(NSNumber *)voiceDuration
       voiceConvertAmrTime:(NSNumber *)voiceConvertAmrTime
{
    FNUser *user = [[FNUser alloc]init];
    user.userID = userID;
    user.userName = userName;
    user.contactID = contactID;
    user.contactName = contactName;
    user.voiceID = voiceID;
    user.voiceName = voiceName;
    user.voiceSize = voiceSize;
    user.voiceDuration = voiceDuration;
    user.voiceConvertAmrTime = voiceConvertAmrTime;
    return user;
}

@end
