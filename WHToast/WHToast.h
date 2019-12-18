//
//  WHToast.h
//  WHToast
//
//  Created by wuhao on 2018/11/15.
//  Copyright © 2018 wuhao. All rights reserved.
//  https://github.com/remember17/WHToast

#import <UIKit/UIKit.h>

@interface WHToast : NSObject

/** 仅文字，展示在屏幕中间 */
+ (void)showMessage:(NSString *)message duration:(NSTimeInterval)duration finishHandler:(dispatch_block_t)handler;

/** 仅文字，自定义frame.origin.y 如果（originY <= 0）会展示在屏幕中间 */
+ (void)showMessage:(NSString *)message originY:(CGFloat)originY duration:(NSTimeInterval)duration finishHandler:(dispatch_block_t)handler;

/** 成功图标和文字，展示在屏幕中间 */
+ (void)showSuccessWithMessage:(NSString *)message duration:(NSTimeInterval)duration finishHandler:(dispatch_block_t)handler;

/** 成功图标和文字，自定义frame.origin.y 如果（originY <= 0）会展示在屏幕中间 */
+ (void)showSuccessWithMessage:(NSString *)message originY:(CGFloat)originY duration:(NSTimeInterval)duration finishHandler:(dispatch_block_t)handler;

/** 失败图标和文字，展示在屏幕中间 */
+ (void)showErrorWithMessage:(NSString *)message duration:(NSTimeInterval)duration finishHandler:(dispatch_block_t)handler;

/** 失败图标和文字，自定义frame.origin.y 如果（originY <= 0）会展示在屏幕中间 */
+ (void)showErrorWithMessage:(NSString *)message originY:(CGFloat)originY duration:(NSTimeInterval)duration finishHandler:(dispatch_block_t)handler;

/** 自定义图片和文字，展示在屏幕中间。 如果message传入nil，则只显示图片 */
+ (void)showImage:(UIImage *)image message:(NSString *)message duration:(NSTimeInterval)duration finishHandler:(dispatch_block_t)handler;

/** 自定义图片和文字，自定义frame.origin.y 如果（originY <= 0）会展示在屏幕中间。如果message传入nil，则只显示图片 */
+ (void)showImage:(UIImage *)image message:(NSString *)message originY:(CGFloat)originY duration:(NSTimeInterval)duration finishHandler:(dispatch_block_t)handler;

/** 主动消失 */
+ (void)hide;


/******************************************************/
/******************  设置全局样式  **********************/
/******************************************************/

/** 是否有背景遮罩，默认有 */
+ (void)setShowMask:(BOOL)showMask;

/** 遮罩颜色，默认透明 */
+ (void)setMaskColor:(UIColor *)maskColor;

/** 遮罩是否遮住导航栏，默认遮住 */
+ (void)setMaskCoverNav:(BOOL)maskCoverNav;

/** 边距，默认12 */
+ (void)setPadding:(CGFloat)padding;

/** 提示图片尺寸，默认（20,20）*/
+ (void)setTipImageSize:(CGSize)tipImageSize;

/** toast圆角，默认7 */
+ (void)setCornerRadius:(CGFloat)cornerRadius;

/** 提示图片圆角，默认0 */
+ (void)setImageCornerRadius:(CGFloat)cornerRadius;

/** 背景颜色，默认[UIColor colorWithWhite:0 alpha:0.8] */
+ (void)setBackColor:(UIColor *)backColor;

/** 成功/失败 图标颜色，默认白色 */
+ (void)setIconColor:(UIColor *)iconColor;

/** 文字颜色，默认白色 */
+ (void)setTextColor:(UIColor *)textColor;

/** 文字大小，默认15 */
+ (void)setFontSize:(CGFloat)fontSize;

/** 恢复默认配置 */
+ (void)resetConfig;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end

