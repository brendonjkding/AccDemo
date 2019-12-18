//
//  WHToastView.m
//  WHToast
//
//  Created by wuhao on 2018/11/15.
//  Copyright © 2018 wuhao. All rights reserved.
//  https://github.com/remember17/WHToast

#define kBundlePath @"/Library/MobileSubstrate/DynamicLibraries/com.brend0n.accdemo.bundle"

#import "WHToastView.h"
#import "WHToastConfig.h"
#import "UIImage+WHToast.h"

@interface WHToastView()
@property (nonatomic, strong) UIImageView *tipImageView;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIImage *displayImage;
@property (nonatomic, assign) CGFloat padding;
@end

@implementation WHToastView

+ (instancetype)toastWithMessage:(NSString *)message type:(WHToastType)type originY:(CGFloat)originY tipImage:(UIImage *)image {
    WHToastView *toastView = [[WHToastView alloc] init];
    toastView.displayImage = image;
    toastView.padding = message ? kToastConfig.padding : 0;
    [toastView setCommonWithMessage:message type:type];
    [toastView setFrameWithMessage:message type:type originY:originY];
    return toastView;
}

- (void)setCommonWithMessage:(NSString *)message type:(WHToastType)type {
    NSBundle *bundle = [[NSBundle alloc] initWithPath:kBundlePath];
    
    self.backgroundColor = kToastConfig.backColor;
    UIImage *successImage = [[UIImage imageNamed:@"whtoast_success" inBundle:bundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImage *errorImage = [[UIImage imageNamed:@"whtoast_error" inBundle:bundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.tipImageView.image = (type == WHToastTypeSuccess) ? successImage : errorImage;
    if (self.displayImage && type == WHToastTypeImage) {
        self.tipImageView.image = kToastConfig.imageCornerRadius > 0 ? [self.displayImage whToast_imageWithCornerRadius:kToastConfig.imageCornerRadius size:kToastConfig.tipImageSize] : self.displayImage;
    } else {
        self.tipImageView.tintColor = kToastConfig.iconColor;
    }
    self.layer.cornerRadius = kToastConfig.cornerRadius;
    self.layer.masksToBounds = YES;
    self.messageLabel.text = message;
    [self.messageLabel setTextColor:kToastConfig.textColor];
    self.messageLabel.font = [UIFont systemFontOfSize:kToastConfig.fontSize];
    
}

- (void)setFrameWithMessage:(NSString *)message type:(WHToastType)type originY:(CGFloat)originY {
    CGSize toastSize = [self getToastSizeWithMessage:message type:type];
    CGFloat space = Toast_isIphoneX() ? 34 : 0;
    CGFloat y = (originY > 0) ? originY : ((kWHToastScreenHeight - toastSize.height) / 2);
    if (Toast_isIphoneX() && y < space) { y = space; }
    y = ((y + toastSize.height) > (kWHToastScreenHeight - space)) ? (kWHToastScreenHeight - toastSize.height - space) : y;
    CGFloat toastWidth = kToastConfig.minWidth > toastSize.width ? kToastConfig.minWidth : toastSize.width;
    self.frame = CGRectMake((kWHToastScreenWidth - toastWidth) / 2, y, toastWidth, toastSize.height);
    [self addConstraintWithType:type message:message];
}

- (CGSize)getToastSizeWithMessage:(NSString *)message type:(WHToastType)type {
    CGFloat normalPadding = 2 * self.padding;
    if (type == WHToastTypeImage && !message) {
        return CGSizeMake(kToastConfig.tipImageSize.width + normalPadding, kToastConfig.tipImageSize.height + normalPadding);
    }
    UIFont *font = [UIFont systemFontOfSize:kToastConfig.fontSize];
    CGSize textSize = kWHToastMultilineTextSize(message, font, CGSizeMake(0.7 * kWHToastScreenWidth, 0.7 * kWHToastScreenHeight));
    CGFloat labelWidth = textSize.width + 1;
    CGFloat labelHeight = textSize.height + 1;
    CGFloat heightPadding = (type == WHToastTypeWords) ? (2 * self.padding) : (2.5 * self.padding);
    CGSize imageSize = (type == WHToastTypeWords) ? CGSizeMake(0, 0) : kToastConfig.tipImageSize;
    CGFloat toastHeight = imageSize.height + heightPadding + labelHeight;
    CGFloat toastWidth = ((labelWidth > imageSize.width) || (type == WHToastTypeWords)) ? labelWidth + (2 * self.padding) : imageSize.width + (2 * self.padding);
    return CGSizeMake(toastWidth, toastHeight);
}

- (void)addConstraintWithType:(WHToastType)type message:(NSString *)message {
    if (type == WHToastTypeImage && !message) {
        [self addSubview:self.tipImageView];
        [self.tipImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.tipImageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:self.padding]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.tipImageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:self.padding]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.tipImageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-self.padding]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.tipImageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:-self.padding]];
        return;
    }
    [self addSubview:self.messageLabel];
    [self.messageLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    if (type == WHToastTypeWords) {
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.messageLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:self.padding]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.messageLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:self.padding]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.messageLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-self.padding]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.messageLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:-self.padding]];
    } else {
        [self addSubview:self.tipImageView];
        [self.tipImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.tipImageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:self.padding]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.tipImageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.tipImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:kToastConfig.tipImageSize.width]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.tipImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:kToastConfig.tipImageSize.height]];

        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.messageLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.tipImageView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:self.padding / 2]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.messageLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:self.padding]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.messageLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-self.padding]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.messageLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:-self.padding]];
    }
}

#pragma mark - property

- (UIImageView *)tipImageView {
    if (!_tipImageView) {
        _tipImageView = [[UIImageView alloc] init];
    }
    return _tipImageView;
}

- (UILabel *)messageLabel {
    if (!_messageLabel) {
        _messageLabel = [[UILabel alloc] init];
        _messageLabel.numberOfLines = 0;
        _messageLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _messageLabel;
}

@end
