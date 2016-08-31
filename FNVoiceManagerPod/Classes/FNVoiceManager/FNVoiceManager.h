//
//  FNVoiceManager.h
//  FNVoiceDemo
//
//  Created by JR on 16/8/24.
//  Copyright © 2016年 JR. All rights reserved.
//

#import <UIKit/UIKit.h>

#define WS(weakSelf)  __weak __typeof(&*self)weakSelf = self;
#define VoiceManager [FNVoiceManager sharedInstense]

#ifdef DEBUG
#define DLog(...) NSLog(__VA_ARGS__)
#else
#define DLog(...)
#endif

typedef void(^ConvertSuccess)();
typedef void(^ConvertFailure)();

typedef NS_ENUM (NSInteger,FNVoiceMode) {
    FNVoiceModeSpeaker,
    FNVoiceModeReceiver
};

@protocol FNVoiceManagerDelegate <NSObject>
- (void)voiceLongPressed;
@end

@class FNUser;
@interface FNVoiceManager : NSObject
@property (strong, nonatomic) NSString        *recordFileName;      //文件名
@property (strong, nonatomic) NSString        *amrPath;             //wav转arm文件路径
@property (assign, nonatomic) CGFloat         recordToAmrTime;      //原始文件转amr时长
@property (assign, nonatomic) NSInteger       amrFileSize;          //amr文件大小
@property (assign, nonatomic) CGFloat         amrDuration;          //amr文件时长

@property (strong, nonatomic) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (weak,   nonatomic) id<FNVoiceManagerDelegate> delegate;
@property (assign, nonatomic) NSInteger       secondCount;         //记录当前录音的时长
@property (assign, nonatomic) FNVoiceMode      voiceMode;          //当前播放模式


+ (instancetype)sharedInstense;

/**
 *  开始录音
 */
- (void)startRecord;

/**
 *  停止录音   保留文件路径
 */
- (void)stopRecord;

/**
 *  取消录音   清空文件路径
 */
- (void)cancelRecord;

/**
 *  播放语音   将amr转换wav播放
 */
- (void)playAction;

/**
 *  停止播放语音  播放完删除wav文件
 */
- (void)stopPlayAction;

/**
 *  播放指定文件
 *
 *  @param fileName 文件名
 */
- (void)playWithName:(NSString *)fileName;

/**
 *  删除缓存AMR文件并清除缓存
 *
 */
- (void)deleteAmrFile:(NSString*)path;

/**
 *  缓存数据库
 *
 *  @param model FNUser模型
 */
- (void)saveToDBWithModel:(FNUser *)model;
/**
 *  当前wav转amr 异步转换  转换后删除原有amr文件
 *
 *  @param success 回到主线程block
 *  @param failure 回到主线程block
 */
- (void)wavToAmr :(ConvertSuccess)success failure:(ConvertFailure)failure;

/**
 *  amr转wav
 *
 *  @param fileName 指定文件名
 *  @param success 回到主线程block
 *  @param failure 回到主线程block
 */
- (void)amrToWav:(NSString *)fileName success:(ConvertSuccess)success failure:(ConvertFailure)failure;

/**
 *  根据文件名得到录音的详细信息(已经删除的信息为0)
 *
 *  @param filePath    文件路径
 *  @param convertTime 转换时长
 *
 *  @return 文件信息
 */
- (NSString *)getVoicefileInfoByPath:(NSString *)filePath convertTime:(NSTimeInterval)convertTime;

/**
 *  获取录音文件路径
 *
 *  @param fileName 文件名
 *  @param fileType 文件类型
 *
 *  @return 文件路径
 */
- (NSString *)getPathByFileName:(NSString *)fileName fileType:(NSString *)fileType;


/**
 *  获取语音时长
 *
 *  @param filePath 文件路径
 *
 *  @return 语音时长(秒)
 */
- (NSTimeInterval)getVoiceDuration:(NSString *)filePath;

/**
 *  获取语音大小(kb)
 *
 *  @param path 文件路径
 *
 *  @return 语音大小
 */
- (NSInteger)getFileSize:(NSString*) path;

/**
 *  沙盒目录下随机amr文件
 *
 */
- (NSString *)rmdVoiceName;

/**
 *  切换听筒和扬声器,默认扬声器
 *
 */
- (void)switchSpeakerMode;

@end
