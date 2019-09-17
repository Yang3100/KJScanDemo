//
//  KJScanVC.m
//  KJEmitterView
//
//  Created by 杨科军 on 2019/8/27.
//  Copyright © 2019 杨科军. All rights reserved.
//

#import "KJScanVC.h"
#import "KJScanView.h"

@interface KJScanVC ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong)  KJNativeScanTool * scanTool;
@property (nonatomic, strong)  KJScanView * scanView;
@end

@implementation KJScanVC
#pragma mark - Status bar
- (BOOL)prefersStatusBarHidden {
    return NO;
}
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}
- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [_scanView startScanAnimation];
    [_scanTool sessionStartRunning];
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [_scanView stopScanAnimation];
    [_scanView finishedHandle];
    [_scanView showFlashSwitch:NO];
    [_scanTool sessionStopRunning];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setUI];
}

- (void)setUI{
    //输出流视图
    UIView *preview = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:preview];
    
    //构建扫描样式视图
    CGFloat w = 250;
    _scanView = [[KJScanView alloc] initWithFrame:self.view.bounds];
    _scanView.scanRetangleRect = CGRectMake(kScreenW/2 - w/2, kScreenH/2 - w/2, w, w);
    _scanView.colorAngle = UIColor.redColor;
    _scanView.isNeedShowRetangle = YES;
    _scanView.photoframeAngleW = 20;
    _scanView.photoframeAngleH = 20;
    _scanView.photoframeLineW = 2;
    _scanView.colorRetangleLine = [UIColor whiteColor];
    _scanView.notRecoginitonArea = UIColorFromHEXA(0x000000, 0.3);
    _scanView.animationImage = [UIImage imageNamed:@"KJScan.bundle/scanLine"];
    _scanView.animationImageSize = CGSizeMake(w, 45);
    _scanView.animationImageTime = 2.;
    __weak typeof(self) weakSelf = self;
    _scanView.flashSwitchBlock = ^(BOOL open) {
        [weakSelf.scanTool openFlashSwitch:open];
    };
    [self.view addSubview:_scanView];
    
    //初始化扫描工具
    _scanTool = [[KJNativeScanTool alloc] initWithPreview:preview andScanFrame:_scanView.scanRetangleRect];
    _scanTool.scanFinishedBlock = ^(NSString *scanString) {
//        if (!kStringIsEmpty(scanString)) {
//            //            [weakSelf.scanView handlingResultsOfScan];
//            [weakSelf decodeScanString:scanString];
//        }else{
//            [MBProgressHUD showError:@"无法识别图中二维码"];
//        }
        [weakSelf.scanTool sessionStopRunning];
        [weakSelf.scanTool openFlashSwitch:NO];
    };
    _scanTool.monitorLightBlock = ^(CGFloat brightness) {
        //        NSLog(@"环境光感 ： %f",brightness);
        if (brightness < 0) {
            // 环境太暗，显示闪光灯开关按钮
            [weakSelf.scanView showFlashSwitch:YES];
        }else if(brightness > 0){
            // 环境亮度可以,且闪光灯处于关闭状态时，隐藏闪光灯开关
            if(!weakSelf.scanTool.flashOpen){
                [weakSelf.scanView showFlashSwitch:NO];
            }
        }
    };
    
    [_scanTool sessionStartRunning];
    [_scanView startScanAnimation];
    
//    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    rightButton.frame = CGRectMake(kScreenW - 80 - 10, 15 + kSTATUSBAR_HEIGHT, 80, 14);
//    [rightButton setTitle:@"相册导入" forState:(UIControlStateNormal)];
//    [rightButton setTitleColor:UIColor.whiteColor forState:(UIControlStateNormal)];
//    rightButton.titleLabel.font = [UIFont systemFontOfSize:18];
//    rightButton.titleLabel.textAlignment = NSTextAlignmentRight;
//    [self.view addSubview:rightButton];
//    [rightButton kj_addAction:^(UIButton * _Nonnull kButton) {
//        /// 先判断权限是否打开
//        [KJPhotoTool kj_grantedAssetsAuthorizationStatus:^(BOOL isSuccess) {
//            if (isSuccess) {
//                UIImagePickerController *vc = [[UIImagePickerController alloc] init];
//                vc.delegate = weakSelf;
//                vc.allowsEditing = NO;
//                vc.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
//                [weakSelf presentViewController:vc animated:YES completion:nil];
//            }
//        }];
//    }];
//
//    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    leftButton.frame = CGRectMake(10, 15 + kSTATUSBAR_HEIGHT, 100, 14);
//    [leftButton setTitle:@"扫一扫" forState:(UIControlStateNormal)];
//    [leftButton setTitleColor:UIColor.whiteColor forState:(UIControlStateNormal)];
//    [leftButton setImage:[UIImage imageNamed:@"navigation_white_back"] forState:(UIControlStateNormal)];
//    leftButton.titleLabel.font = [UIFont systemFontOfSize:18];
//    leftButton.kj_Padding = 10;
//    leftButton.kj_ButtonContentLayoutType = KJButtonContentLayoutStyleLeftImageLeft;
//    [self.view addSubview:leftButton];
//    [leftButton kj_addAction:^(UIButton * _Nonnull kButton) {
////        [weakSelf kBaseNavBack];
//        [weakSelf.navigationController popViewControllerAnimated:YES];
//    }];
}

/// 解码扫描结果
- (void)decodeScanString:(NSString*)string{
    NSLog(@"扫码数据：%@",string);
//    NSString *decryptString = [WPAESSecurity aes128DecryptWith:string Key:kWPPulicKey];
//    NSDictionary *dict = [decryptString jsonValueDecoded];
//    if ([dict[@"type"] isEqualToString:@"json"]) {
//        BannerModel *model = [BannerModel yy_modelWithJSON:dict[@"data"]];
//        [KJCustomFunction kJumptoWithBannerModel:model ViewController:self HtmlIsShare:NO];
//    }
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    //    //图片在这里压缩一下
    //    NSData *imageData = UIImageJPEGRepresentation(image, 0.5f);
    //    if (imageData.length/1024 > 1024*20){
    //        //        mAlertView(@"温馨提示", @"请重新选择一张不超过20M的图片");
    //    }else{
    //        //        _imageType = [NSData typeForImageData:imageData];
    //        //        _imageBase64 = [imageData base64EncodedString];
    //    }
    _weakself;
    [picker dismissViewControllerAnimated:YES completion:^{
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        if (image) {
            [weakself.scanTool scanImageQRCode:image];
        }
    }];
}

@end
