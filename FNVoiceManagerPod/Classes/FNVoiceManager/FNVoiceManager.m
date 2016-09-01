//
//  FNVoiceManager.m
//  FNVoiceDemo
//
//  Created by JR on 16/8/24.
//  Copyright © 2016年 JR. All rights reserved.
//

#import "FNVoiceManager.h"
#import <AVFoundation/AVFoundation.h>
#import "VoiceConvert/VoiceConverter.h"
#import "FNSqlHelper.h"
#import <UILabel+Delay.h>

/*最小说话时间*/
static NSInteger kMinVoiceDuration = 3;
/*最大cache语音数量*/
static NSInteger kMaxCachePoolCount = 20;
/*转换的语音类型*/
static NSString *kFileType = @"wav";
/*真缓存二级目录*/
static NSString *kFileFolrderName =@"Voice";
/*临时缓存目录*/

/*cache/Voice文件路径*/
#define kTempPath [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES)[0] stringByAppendingPathComponent:kFileFolrderName]

/*Temp/Voice文件路径*/
//#define kTempPath [NSTemporaryDirectory() stringByAppendingPathComponent:kFileFolrderName]


#define kAmrToWavQueue  dispatch_queue_create("kAmrToWavQueueName", NULL)
#define kWavToAmrQueue  dispatch_queue_create("kWavToAmrQueueName", NULL)


@interface FNVoiceManager ()<AVAudioPlayerDelegate>
@property (nonatomic, strong) AVAudioRecorder *recorder;            //录音机
@property (nonatomic, strong) AVAudioPlayer   *player;              //播放器

@property (strong, nonatomic) NSString        *recordFilePath;      //原始文件路径
@property (strong, nonatomic) NSString        *convertPath;         //arm转wav路径

@property (assign, nonatomic) NSInteger       recordFileSize;       //原始文件大小
@property (assign, nonatomic) CGFloat         recordDuration;       //原始文件时长

@property (assign, nonatomic) CGFloat         amrToWavTime;         //amr转wav时长

@property (assign, nonatomic) NSInteger       convertFileSize;      //播放文件大小
@property (assign, nonatomic) CGFloat         convertDuration;      //转换后wav时长

@property (strong, nonatomic) NSTimer         *timer;               //定时器



@end

@implementation FNVoiceManager

+ (instancetype)sharedInstense {
    static FNVoiceManager* manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[FNVoiceManager alloc] init];
        [self createDocumentFolder];
        [self createTempFolder];
    });
    return manager;
}

#pragma mark - 开始录音
- (void)startRecord {
    //根据当前时间生成文件名
    
    self.recordFileName = [self getCurrentTimeStr];
    //获取路径
    self.recordFilePath = [self getPathByFileName:self.recordFileName fileType:kFileType];
    [self recorderSetting];
    self.recorder = [[AVAudioRecorder alloc]initWithURL:[NSURL fileURLWithPath:self.recordFilePath] settings:[VoiceConverter GetAudioRecorderSettingDict] error:nil];
    //准备录音
    [self.recorder prepareToRecord];
    [self.recorder record];
    [self recorderTime];
    
}

#pragma mark - 停止录音
- (void)stopRecord{
    [self.recorder stop];
    [self stopRecorderTime];

    self.recordFileSize = [self getFileSize:self.recordFilePath];
    self.recordDuration = [self getVoiceDuration:self.recordFilePath];
    
}

#pragma mark - 取消录音
- (void)cancelRecord {
    [self.recorder stop];
    [self clearDocumentFile:self.recordFilePath];
    [self clearDocumentFile:self.amrPath];
}

#pragma mark - 定时器操作
/*开始定时器*/
- (void)recorderTime {
    [self.timer setFireDate:[NSDate distantPast]];
}

/*开始计算录音时长*/
- (void)startSecondCount {
    self.secondCount ++;
    DLog(@"%ld",_secondCount);
}

/*暂停定时器并清除录音时长*/
- (void)stopRecorderTime {
   //关闭
   [self.timer setFireDate:[NSDate distantFuture]];
    if (self.secondCount <= kMinVoiceDuration) {;
        [UILabel showText:@"说话时间太短" delay:1];
        [self cancelRecord];
    }
    self.secondCount = 0;
}



#pragma mark - 录音设置
- (void)recorderSetting
{
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending)
    {
        //7.0第一次运行会提示，是否允许使用麦克风
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *sessionError;
        //AVAudioSessionCategoryPlayAndRecord用于录音和播放
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
        if(session == nil)
            DLog(@"Error creating session: %@", [sessionError description]);
        else
            [session setActive:YES error:nil];
    }
}

#pragma mark - wav转amr并存入数据库
- (void)wavToAmrWithModel :(FNUser *)model  success:(ConvertSuccess)success failure:(ConvertFailure)failure{
    //转换格式
    dispatch_async(kWavToAmrQueue, ^{
        NSDate *date = [NSDate date];
        self.amrPath = [self getPathByFileName:self.recordFileName fileType:@"amr"];
        // wav转amr
        if ([VoiceConverter ConvertWavToAmr:self.recordFilePath amrSavePath:self.amrPath]) {
            DLog(@"wav转amr成功");
            
            self.recordToAmrTime = [[NSDate date] timeIntervalSinceDate:date];
            self.amrFileSize = [self getFileSize:self.amrPath];
            self.amrDuration = [self getVoiceDuration:self.amrPath];
            
            [self saveToDBWithModel:model];
            
            
            if (success) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self clearDocumentFile:self.recordFilePath];
                    success();
                });
            }
            
        } else {
            DLog(@"wav转amr失败");
            
            if (failure) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    failure();
                });
            }
        }
    });
}


#pragma mark - wav转amr
- (void)wavToAmr :(ConvertSuccess)success failure:(ConvertFailure)failure{
    //转换格式
    dispatch_async(kWavToAmrQueue, ^{
        NSDate *date = [NSDate date];
        self.amrPath = [self getPathByFileName:self.recordFileName fileType:@"amr"];
        // wav转amr
        if ([VoiceConverter ConvertWavToAmr:self.recordFilePath amrSavePath:self.amrPath]) {
            DLog(@"wav转amr成功");
            
            self.recordToAmrTime = [[NSDate date] timeIntervalSinceDate:date];
            self.amrFileSize = [self getFileSize:self.amrPath];
            self.amrDuration = [self getVoiceDuration:self.amrPath];
            
            [self saveToDB];
            
            
            if (success) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self clearDocumentFile:self.recordFilePath];
                    success();
                });
            }
            
        } else {
            DLog(@"wav转amr失败");
            
            if (failure) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    failure();
                });
            }
        }
    });
}

#pragma mark - amr转wav
- (void)amrToWav:(NSString *)fileName success:(ConvertSuccess)success failure:(ConvertFailure)failure{
    dispatch_async(kAmrToWavQueue, ^{
        NSDate *date = [NSDate date];
        self.convertPath = [self getTempFileName:fileName];
        NSString *fileNamePath = [self getPathByFileName:fileName fileType:@"amr"];
        // amr转wav
        
        if ([VoiceConverter ConvertAmrToWav:fileNamePath wavSavePath:self.convertPath]) {
            DLog(@"amr转wav成功");
            self.convertFileSize = [self getFileSize:self.convertPath];
            self.convertDuration = [self getVoiceDuration:self.convertPath];
            self.amrToWavTime = [[NSDate date] timeIntervalSinceDate:date];
            if (success) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    success();
                });
            }
        } else {
            if (!fileName) {
                DLog(@"当前没有录音");
            }
            DLog(@"amr转wav失败");
            if (failure) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    failure();
                });
            }
        }
    });
}
#pragma mark - 播放当前录音
- (void)playAction{
    [self playWithName:self.recordFileName];
    
}

#pragma mark - 播放指定录音文件名
- (void)playWithName:(NSString *)fileName {
    [self stopPlayAction];
    WS(weakSelf)
    if (self.voiceMode == FNVoiceModeSpeaker) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    } else {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    }
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
        NSString *wavPath = [self searchTempFileName:fileName];
    if (wavPath) {
        DLog(@"播放临时缓存文件,无需转换");
        [self openMonitoring];
        self.player = [weakSelf.player initWithContentsOfURL:[NSURL URLWithString:wavPath] error:nil];
        self.player.delegate = weakSelf;
        [self.player play];
    } else {
        wavPath = [self getTempFileName:fileName];
        [self amrToWav:fileName success:^{
            [weakSelf openMonitoring];
            weakSelf.player = [weakSelf.player initWithContentsOfURL:[NSURL URLWithString:wavPath] error:nil];
            weakSelf.player.delegate = weakSelf;
            [weakSelf.player play];
        } failure:^{
            
        }];
    }
    
}

#pragma mark - 停止播放
- (void)stopPlayAction{
    if (_player) {
        [_player stop];
    }
}


#pragma mark - 文件操作
// 文件路径
- (NSString *)getPathByFileName:(NSString *)fileName fileType:(NSString *)fileType{
    NSString *directory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    directory = [directory stringByAppendingPathComponent:kFileFolrderName];
    NSString *path = [[[directory stringByAppendingPathComponent:fileName]
                       stringByAppendingPathExtension:fileType]
                      stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return path;
}


// 播放后的文件放入沙盒cache目录
- (NSString *)getTempFileName :(NSString *)fileName {
    if (!fileName) return nil;
    NSString *directory = kTempPath;
    NSString *path = [[[directory stringByAppendingPathComponent:fileName]
                       stringByAppendingPathExtension:kFileType]
                      stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return path;
}

//查找cache文件下下面是否有已经转换的临时缓存文件

- (NSString *)searchTempFileName :(NSString *)fileName {
    if (!fileName) return nil;
    NSFileManager *manager = [[NSFileManager alloc]init];
    NSMutableArray *nameArray = [NSMutableArray arrayWithArray:[manager contentsOfDirectoryAtPath:kTempPath error:nil]];
    
    if (nameArray.count > kMaxCachePoolCount) {
        //删除文件修改时间最早的文件
        [self clearDocumentFile:[self earliestModiFileFilePath:kTempPath]];
    }
    __block NSString *tempFileName;
    [nameArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *fileNames = obj;
        if ([fileNames containsString:fileName]) {
            tempFileName = fileName;
        }

    }];
    if (!tempFileName) return nil;

    return [[[kTempPath stringByAppendingPathComponent:fileName]
             stringByAppendingPathExtension:kFileType]
            stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];;

}

//临时缓存堆,默认最多存放20条语音,先进先出,保留最近20条,返回应该删除的路径
- (NSString *)earliestModiFileFilePath:(NSString *)path {
    NSError *error;
    NSArray *attributes = [NSArray arrayWithObjects:NSURLContentModificationDateKey,nil];
    //预处理修改时间
    NSFileManager *manager = [[NSFileManager alloc]init];
    NSArray *pathArray = [manager
                          contentsOfDirectoryAtURL:[NSURL fileURLWithPath:path]
                          includingPropertiesForKeys:attributes
                          options:0
                          error:&error];
    
    NSMutableArray *dateAndNameArray = [NSMutableArray array];
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [pathArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSURL *url = obj;
        NSDictionary *attributesDictionary = [url resourceValuesForKeys:attributes error:nil];
        //获取最近修改日期
        NSDate *lastModifiedDate = [attributesDictionary objectForKey:NSURLContentModificationDateKey];
        NSNumber *modifyTimeNum= [NSNumber numberWithDouble:[lastModifiedDate timeIntervalSince1970]];
        [dateAndNameArray addObject:modifyTimeNum];
        [dic setObject:url  forKey:modifyTimeNum];
    }];
    //得到修改时间最早的文件名
    NSNumber *minmodyfyTimeNum =  [dateAndNameArray valueForKeyPath:@"@min.intValue"];
    NSString *shouldDeletePath = [dic objectForKey:minmodyfyTimeNum];
    return shouldDeletePath;
}

// 创建Document/Voice目录
+ (void)createDocumentFolder {
    NSString *pathDocuments = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    [self createFloder:pathDocuments createFilderName:kFileFolrderName];
}


// 创建Cache/Voice目录
+ (void)createTempFolder {
    [self createFloder:kTempPath createFilderName:@""];
}

// 判断文件夹是否存在，如果不存在，则创建
+ (void)createFloder:(NSString *)existsPath createFilderName:(NSString *)createFilderName {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSString *pathDocuments = existsPath;
    NSString *createPath = [NSString stringWithFormat:@"%@/%@", pathDocuments,createFilderName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:createPath]) {
        [fileManager createDirectoryAtPath:createPath withIntermediateDirectories:YES attributes:nil error:nil];
        DLog(@"%@创建文件夹成功",createFilderName);
    } else {
        DLog(@"%@文件夹已存在",createFilderName);
    }
}

// 生成当前时间字符串
- (NSString *)getCurrentTimeStr {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy_MM_dd_HH_mm_ss"];
    return [dateFormatter stringFromDate:[NSDate date]];
}

// 获取音频文件信息
- (NSString *)getVoicefileInfoByPath:(NSString *)filePath convertTime:(NSTimeInterval)convertTime {
    NSInteger size = [self getFileSize:filePath];
    NSString *info = [NSString stringWithFormat:@"文件名:%@\n文件大小:%ldkb\n",filePath.lastPathComponent,size];
    
    NSTimeInterval duration = [self getVoiceDuration:filePath];
    info = [info stringByAppendingFormat:@"文件时长:%f\n",duration];
    self.recordDuration = duration;
    
    if (convertTime > 0) {
        info = [info stringByAppendingFormat:@"转换时间:%f",convertTime];
    }
    return info;
}

// 获取语音时长
- (NSTimeInterval)getVoiceDuration:(NSString *)filePath {
    AVAudioPlayer *play = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL URLWithString:filePath] error:nil];
    return play.duration;
}


// 获取文件大小
- (NSInteger)getFileSize:(NSString*) path{
    NSFileManager * filemanager = [[NSFileManager alloc]init];
    if([filemanager fileExistsAtPath:path]){
        NSDictionary * attributes = [filemanager attributesOfItemAtPath:path error:nil];
        NSNumber *theFileSize;
        if ( (theFileSize = [attributes objectForKey:NSFileSize]) )
            return  [theFileSize intValue]/1024;
        else
            return -1;
    }
    else{
        return -1;
    }
}

// 获取随机语音名
- (NSString *)rmdVoiceName {
    NSFileManager *manager = [[NSFileManager alloc]init];
    NSString *path =  NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    path = [path stringByAppendingPathComponent:kFileFolrderName];
    NSMutableArray *nameArray = [NSMutableArray arrayWithArray:[manager contentsOfDirectoryAtPath:path error:nil]];
    [nameArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *fileName = obj;
        if (![fileName containsString:@"amr"]) {
            [nameArray removeObject:obj];
        }
    }];
    if (nameArray.count == 0) return nil;
    int index = arc4random_uniform((u_int32_t)nameArray.count);
    NSString *fileName = [nameArray[index] stringByDeletingPathExtension];
    DLog(@"播放随机语音:%@",fileName);
    return fileName;
}

//缓存数据库
- (void)saveToDBWithModel:(FNUser *)model {
    [FNSqlHelper insertModel:model];
}


- (void)saveToDB {
    FNUser *user = [[FNUser alloc]init];
    user.userID = @"user01";
    user.userName = @"jiarui";
    user.contactID = @"contact01";
    user.contactName = @"frend1";
    user.voiceID = @"123";
    user.voiceName = [self.recordFileName stringByAppendingPathExtension:@"amr"];
    user.voiceSize = @(self.amrFileSize);
    user.voiceDuration = @(self.amrDuration);
    user.voiceConvertAmrTime = @(self.recordToAmrTime);
    [FNSqlHelper insertModel:user];
}

//用户自己删除文件,并删除数据库
- (void)deleteAmrFile:(NSString*)path
{
    if ([path containsString:@".amr"]) {
        [self clearDocumentFile:path];
        NSString *sql = [NSString stringWithFormat:@"delete from t_madal where voiceName = '%@'",path];
        [FNSqlHelper deleteData:sql];
    }
}

//删除临时转换文件
- (void)clearDocumentFile:(NSString*)path
{
    if(!path) return;
    NSError *error;
    BOOL deleted = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    if (deleted) {
        DLog(@"delete\n%@",path);
    }
    if (!deleted) {
        DLog(@"删除文件失败!\n原因:%@",error.userInfo[NSUnderlyingErrorKey]);
    }
}

#pragma mark - 红外感应
//处理监听触发事件
- (void)sensorStateChange:(NSNotificationCenter *)notification;
{
    //如果此时手机靠近面部放在耳朵旁，那么声音将通过听筒输出，并将屏幕变暗
    if ([[UIDevice currentDevice] proximityState] == YES)
    {
        DLog(@"听筒模式");
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        
    }
    else //离开
    {
        if (self.voiceMode == FNVoiceModeReceiver) {
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        DLog(@"听筒模式");
        }
        else if(self.voiceMode == FNVoiceModeSpeaker)
        {
        DLog(@"扬声器模式");
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        }
    }
}


//打开红外感应和通知
- (void)closeMonitoring {
    
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceProximityStateDidChangeNotification object:nil];
}


//关闭红外感应和通知
- (void)openMonitoring {
    
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    //添加监听
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sensorStateChange:)
                                                 name:UIDeviceProximityStateDidChangeNotification
                                               object:nil];
}


#pragma mark - 扬声器/听筒 模式切换
//切换模式
- (void)switchSpeakerMode
{
    DLog(@"voice long Pressed");
    
    if ([[[AVAudioSession sharedInstance] category] isEqualToString:AVAudioSessionCategoryPlayback])
    {
        //切换为听筒播放
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [UILabel showText:@"切换为听筒模式" delay:1.0];
        self.voiceMode = FNVoiceModeReceiver;
    }
    else
    {
        //切换为扬声器播放
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [UILabel showText:@"切换为扬声器模式" delay:1.0];
        self.voiceMode = FNVoiceModeSpeaker;
    }
}

//长按事件
-(void)longPressed:(UILongPressGestureRecognizer *) gestureRecognizer
{
    switch (gestureRecognizer.state)
    {
        case UIGestureRecognizerStateEnded:
            
            break;
        case UIGestureRecognizerStateCancelled:
            
            break;
        case UIGestureRecognizerStateFailed:
            
            break;
        case UIGestureRecognizerStateBegan:
            if ([self.delegate respondsToSelector:@selector(voiceLongPressed)])
            {
                [self.delegate voiceLongPressed];
            }
            
            break;
        case UIGestureRecognizerStateChanged:
            
            break;
        default:
            break;
    }
}


#pragma mark - getter

- (AVAudioPlayer *)player {
    if (!_player) {
        _player = [[AVAudioPlayer alloc] init];
    }
    return _player;
}

- (NSTimer *)timer {
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(startSecondCount) userInfo:nil repeats:YES];
    }
    return _timer;
}

- (UILongPressGestureRecognizer *)longPressGestureRecognizer {
    if (!_longPressGestureRecognizer) {
        UILongPressGestureRecognizer *longPressGestureRecognizer  = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                                  action:@selector(longPressed:)];
        [longPressGestureRecognizer setMinimumPressDuration:1.0f];
        [longPressGestureRecognizer setAllowableMovement:50.0];
        _longPressGestureRecognizer = longPressGestureRecognizer;
    }
    return _longPressGestureRecognizer;
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    if (flag) {
        [self closeMonitoring];
    }
}



@end
