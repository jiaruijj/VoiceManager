//
//  UILabel+Delay.m
//  FNDebugManagerDemo
//
//  Created by JR on 16/8/12.
//  Copyright © 2016年 JR. All rights reserved.
//

#import "UILabel+Delay.h"

#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define SCREEN_WIDTH  [UIScreen mainScreen].bounds.size.width

@implementation UILabel (Delay)

+ (void)showText:(NSString *)showMessage delay:(NSTimeInterval)delayTime
{
    CGSize size = [self sizeOfText:showMessage fontSize:18];
    UILabel *label = [[UILabel alloc] init];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.90f];
    label.numberOfLines = 0;
    label.layer.cornerRadius = 5;
    label.clipsToBounds = YES;
    label.bounds = CGRectMake(0, 0, size.width, size.height+30);
    label.center = CGPointMake(SCREEN_WIDTH/2.0, SCREEN_HEIGHT/2.0);
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont boldSystemFontOfSize:17];
    [[UIApplication sharedApplication].keyWindow addSubview:label];
    [[UIApplication sharedApplication].keyWindow bringSubviewToFront:label];
    label.text = showMessage;
    
    [label performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1.0];
}

+ (CGSize)sizeOfText:(NSString *)text fontSize:(CGFloat)fontSize
{
    return [text boundingRectWithSize:CGSizeMake(300, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:fontSize]} context:nil].size;
}

@end
