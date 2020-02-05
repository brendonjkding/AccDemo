//
//  WQSuspendView.h
//  SuspendView
//
//  Created by 李文强 on 2019/6/6.
//  Copyright © 2019年 WenqiangLI. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSUInteger, WQSuspendViewType) {
    WQSuspendViewTypeNone = 0,  //根据左右距离的一半自动居左局右
    WQSuspendViewTypeLeft,      //居左
    WQSuspendViewTypeRight,     //居右
};

@interface WQSuspendView : UIView

@property (nonatomic, copy) void (^tapBlock)(void);

/** 显示 默认为 WQSuspendViewTypeNone*/
+ (void)show;
/** 显示 + 显示的位置*/
+ (void)showWithType:(WQSuspendViewType)type;
/** 显示 + 位置 + 点击的事件 */
+ (WQSuspendView*)showWithType:(WQSuspendViewType)type tapBlock:(void (^)(void))tapBlock;
/** 移除 */
+ (void)remove;

@end

NS_ASSUME_NONNULL_END
