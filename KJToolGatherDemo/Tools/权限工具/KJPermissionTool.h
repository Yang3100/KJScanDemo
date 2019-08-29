//
//  KJPermissionTool.h
//  KJToolGatherDemo
//
//  Created by 杨科军 on 2019/8/29.
//  Copyright © 2019 杨科军. All rights reserved.
//  权限工具

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//权限类型
typedef enum : NSUInteger{
    PermissionTypeCamera,           //相机权限
    PermissionTypeMic,              //麦克风权限
    PermissionTypePhoto,            //相册权限
    PermissionTypeLocationWhen,     //获取地理位置When
    PermissionTypeCalendar,         //日历
    PermissionTypeContacts,         //联系人
    PermissionTypeBlue,             //蓝牙
    PermissionTypeRemaine,          //提醒
    PermissionTypeHealth,           //健康
    PermissionTypeMediaLibrary      //多媒体
}PermissionType;
/// 回调
typedef void (^KJPermissionToolBlock) (BOOL granted, id _Nullable  data);

@interface KJPermissionTool : NSObject
/* 单例 */
+ (instancetype)shareInstance;
/* 提示 */
@property(nonatomic,strong)NSString *tip;

/* 获取权限 */
- (void)kj_permissonType:(PermissionType)type Block:(KJPermissionToolBlock)block;

@end

NS_ASSUME_NONNULL_END
