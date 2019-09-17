//
//  UIButton+KJBlock.h
//  KJEmitterView
//
//  Created by 杨科军 on 2019/4/4.
//  Copyright © 2019 杨科军. All rights reserved.
//  点击事件ButtonBlock

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^KJButtonBlock)(UIButton *kButton);
@interface UIButton (KJBlock)

/** button 添加点击事件，默认UIControlEventTouchUpInside方式 */
- (void)kj_addAction:(KJButtonBlock)block;

/** button 添加事件
 *  @param controlEvents 点击的方式 */
- (void)kj_addAction:(KJButtonBlock)block forControlEvents:(UIControlEvents)controlEvents;
@end

NS_ASSUME_NONNULL_END
