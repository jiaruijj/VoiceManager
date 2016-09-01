//
//  UILabel+Delay.h
//  FNDebugManagerDemo
//
//  Created by JR on 16/8/12.
//  Copyright © 2016年 JR. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UILabel (Delay)

+ (void)showText:(NSString *)showMessage delay:(NSTimeInterval)delayTime;

@end
