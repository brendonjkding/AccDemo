//
//  WQSuspendView.m
//  SuspendView
//
//  Created by 李文强 on 2019/6/6.
//  Copyright © 2019年 WenqiangLI. All rights reserved.
//

#import "WQSuspendView.h"

@interface WQSuspendView  (){
    CGPoint _originalPoint;//之前的位置
}

@property (nonatomic, assign) WQSuspendViewType type;

@end

@implementation WQSuspendView

static WQSuspendView *_suspendView;

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self configurationUI];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame showType:(WQSuspendViewType)type tapBlock:(void (^)(void))tapBlock{
    self = [super initWithFrame:frame];
    if (self) {
        _type = type;
        _tapBlock = tapBlock;
        [self configurationUI];
    }
    return self;
}

- (void)configurationUI{
    //自定义
    self.backgroundColor = [UIColor blackColor];
    //图片~文字等...
    
    //点击手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self addGestureRecognizer:tap];
    //滑动手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self addGestureRecognizer:pan];
}

//移除
+ (void)remove{
    [_suspendView removeFromSuperview];
}

//显示
+ (void)show{
    [self showWithType:WQSuspendViewTypeNone];
}

+ (void)showWithType:(WQSuspendViewType)type{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _suspendView = [[WQSuspendView alloc] initWithFrame:CGRectMake(0, 200, 50, 50) showType:type tapBlock:nil];
    });
    if (!_suspendView.superview) {
        [[UIApplication sharedApplication].keyWindow addSubview:_suspendView];
        [[UIApplication sharedApplication].keyWindow bringSubviewToFront:_suspendView];
    }
}

+ (WQSuspendView*)showWithType:(WQSuspendViewType)type tapBlock:(void (^)(void))tapBlock{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _suspendView = [[WQSuspendView alloc] initWithFrame:CGRectMake(0, 200, 40, 40) showType:type tapBlock:tapBlock];
        _suspendView.layer.cornerRadius = 20;
        _suspendView.layer.masksToBounds = YES;
        //边框宽度
        _suspendView.layer.borderWidth = 3.0;
        //边框颜色
        _suspendView.layer.borderColor = [UIColor whiteColor].CGColor;
        
        UILabel *label=[[UILabel alloc] initWithFrame:CGRectMake(3,-2,34,40)];
        label.text=@"switch";
        label.textColor=[UIColor whiteColor];
        label.adjustsFontSizeToFitWidth=YES;
        [_suspendView addSubview:label];
    });
    if (!_suspendView.superview) {
        [[UIApplication sharedApplication].keyWindow addSubview:_suspendView];
        [[UIApplication sharedApplication].keyWindow bringSubviewToFront:_suspendView];
        if (!_suspendView.superview) {
            [[[[UIApplication sharedApplication] delegate] window] addSubview:_suspendView];
            [[[[UIApplication sharedApplication] delegate] window] bringSubviewToFront:_suspendView];
            
        }
    }
    return _suspendView;
}

//点击事件
- (void)tap:(UITapGestureRecognizer *)tap{
    if (self.tapBlock) {
        self.tapBlock();
    }
}

//滑动事件
- (void)pan:(UIPanGestureRecognizer *)pan{
    //获取当前位置
    CGPoint currentPosition = [pan locationInView:self];
    if (pan.state == UIGestureRecognizerStateBegan) {
        _originalPoint = currentPosition;
    }else if(pan.state == UIGestureRecognizerStateChanged){
        //偏移量(当前坐标 - 起始坐标 = 偏移量)
        CGFloat offsetX = currentPosition.x - _originalPoint.x;
        CGFloat offsetY = currentPosition.y - _originalPoint.y;
        
        //移动后的按钮中心坐标
        CGFloat centerX = self.center.x + offsetX;
        CGFloat centerY = self.center.y + offsetY;
        self.center = CGPointMake(centerX, centerY);
        
        //父试图的宽高
        CGFloat superViewWidth = self.superview.frame.size.width;
        CGFloat superViewHeight = self.superview.frame.size.height;
        CGFloat btnX = self.frame.origin.x;
        CGFloat btnY = self.frame.origin.y;
        CGFloat btnW = self.frame.size.width;
        CGFloat btnH = self.frame.size.height;
        
        //x轴左右极限坐标
        if (btnX > superViewWidth){
            //按钮右侧越界
            CGFloat centerX = superViewWidth - btnW/2;
            self.center = CGPointMake(centerX, centerY);
        }else if (btnX < 0){
            //按钮左侧越界
            CGFloat centerX = btnW * 0.5;
            self.center = CGPointMake(centerX, centerY);
        }
        
        //默认都是有导航条的，有导航条的，父试图高度就要被导航条占据，固高度不够
        CGFloat defaultNaviHeight = 64;
        CGFloat judgeSuperViewHeight = superViewHeight - defaultNaviHeight;
        
        //y轴上下极限坐标
        if (btnY <= 0){
            //按钮顶部越界
            centerY = btnH * 0.7;
            self.center = CGPointMake(centerX, centerY);
        }
        else if (btnY > judgeSuperViewHeight){
            //按钮底部越界
            CGFloat y = superViewHeight - btnH * 0.5;
            self.center = CGPointMake(btnX, y);
        }
    }else if (pan.state == UIGestureRecognizerStateEnded){
        CGFloat btnWidth = self.frame.size.width;
        CGFloat btnHeight = self.frame.size.height;
        CGFloat btnY = self.frame.origin.y;
        //        CGFloat btnX = self.frame.origin.x;
        //按钮靠近右侧
        switch (_type) {
                
            case WQSuspendViewTypeNone:{
                //自动识别贴边
                if (self.center.x >= self.superview.frame.size.width/2) {
                    
                    [UIView animateWithDuration:0.5 animations:^{
                        //按钮靠右自动吸边
                        CGFloat btnX = self.superview.frame.size.width - btnWidth;
                        self.frame = CGRectMake(btnX, btnY, btnWidth, btnHeight);
                    }];
                }else{
                    
                    [UIView animateWithDuration:0.5 animations:^{
                        //按钮靠左吸边
                        CGFloat btnX = 0;
                        self.frame = CGRectMake(btnX, btnY, btnWidth, btnHeight);
                    }];
                }
                break;
            }
            case WQSuspendViewTypeLeft:{
                [UIView animateWithDuration:0.5 animations:^{
                    //按钮靠左吸边
                    CGFloat btnX = 0;
                    self.frame = CGRectMake(btnX, btnY, btnWidth, btnHeight);
                }];
                break;
            }
            case WQSuspendViewTypeRight:{
                [UIView animateWithDuration:0.5 animations:^{
                    //按钮靠右自动吸边
                    CGFloat btnX = self.superview.frame.size.width - btnWidth;
                    self.frame = CGRectMake(btnX, btnY, btnWidth, btnHeight);
                }];
            }
        }
    }
    
}





@end
