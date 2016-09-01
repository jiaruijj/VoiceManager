//
//  FNUser.h
//  FNVoiceDemo
//
//  Created by JR on 16/8/23.
//  Copyright © 2016年 JR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FNUser : NSObject

/**
 *  用户ID
 */
@property (nonatomic,copy) NSString *userID;

/**
 *  用户昵称
 */
@property (nonatomic,copy) NSString *userName;

/**
 *  联系人ID
 */
@property (nonatomic,copy) NSString *contactID;

/**
 *  联系人昵称
 */
@property (nonatomic,copy) NSString *contactName;


@property (nonatomic,copy) NSString *voiceID;

@property (nonatomic,copy) NSString *voiceName;

@property (nonatomic,strong) NSNumber *voiceSize;

@property (nonatomic,strong) NSNumber *voiceDuration;

@property (nonatomic,strong) NSNumber *voiceConvertAmrTime;

+ (instancetype) modalWith:(NSString *)userID
                  userName:(NSString *)userName
                 contactID:(NSString *)contactID
               contactName:(NSString *)contactName
                   voiceID:(NSString *)voiceID
                 voiceName:(NSString *)voiceName
                 voiceSize:(NSNumber *)voiceSize
             voiceDuration:(NSNumber *)voiceDuration
       voiceConvertAmrTime:(NSNumber *)voiceConvertAmrTime;

@end
