//
//  KJNativeScanTool.m
//  优司雇
//
//  Created by 杨科军 on 2019/3/11.
//  Copyright © 2019 杨科军. All rights reserved.
//


#import "KJNativeScanTool.h"
#import <AudioToolbox/AudioToolbox.h> //声音提示

@interface KJNativeScanTool()<AVCaptureMetadataOutputObjectsDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *session;
/** 扫描中心识别区域范围 */
@property (nonatomic, assign) CGRect scanFrame;
/** 展示输出流的视图——即照相机镜头下的内容 */
@property (nonatomic, strong) UIView *preview;
/** 闪光灯的状态,不需要设置，仅供外边判断状态使用 */
@property (nonatomic, assign) BOOL flashOpen;
@end

@implementation KJNativeScanTool
//初始化采集配置信息
- (void)config{
    AVCaptureVideoPreviewLayer *layer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    layer.frame = self.preview.layer.bounds;
    [self.preview.layer insertSublayer:layer atIndex:0];
}
- (instancetype)initWithPreview:(UIView *)preview andScanFrame:(CGRect)scanFrame{
    if (self == [super init]) {
        self.preview = preview;
        self.scanFrame = scanFrame;
        [self config];
    }
    return self;
}

#pragma mark - public
/** 闪光灯开关 */
- (void)openFlashSwitch:(BOOL)open{
    if (self.flashOpen == open) return;
    self.flashOpen = open;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch] && [device hasFlash]){
        [device lockForConfiguration:nil];
        if (self.flashOpen){
            device.torchMode = AVCaptureTorchModeOn;
//            device.flashMode = AVCaptureFlashModeOn;
        }else{
            device.torchMode = AVCaptureTorchModeOff;
//            device.flashMode = AVCaptureFlashModeOff;
        }
        [device unlockForConfiguration];
    }
}
/** 开始扫描 */
- (void)sessionStartRunning{
    [_session startRunning];
}
/** 结束扫描 */
- (void)sessionStopRunning{
    [_session stopRunning];
}
/** 识别图中二维码 */
- (void)scanImageQRCode:(UIImage *)imageCode{
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy:CIDetectorAccuracyHigh}];
    NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:imageCode.CGImage]];
    if (features.count >= 1){
        CIQRCodeFeature *feature = [features firstObject];
        if(self.scanFinishedBlock != nil){
            self.scanFinishedBlock(feature.messageString);
        }
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"KJScan.bundle/scanSuccess.wav" withExtension:nil];
        //2.加载音效文件，创建音效ID（SoundID,一个ID对应一个音效文件）
        SystemSoundID soundID = 8787;
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &soundID);
        //3.播放音效文件
        //下面的两个函数都可以用来播放音效文件，第一个函数伴随有震动效果
        AudioServicesPlayAlertSound(soundID);
        AudioServicesPlaySystemSound(8787);
    }else{
        NSLog(@"无法识别图中二维码");
        if(self.scanFinishedBlock != nil){
            self.scanFinishedBlock(@"");
        }
    }
}

/** 生成自定义样式二维码
 注意：有些颜色结合生成的二维码识别不了
 @param codeString 字符串
 @param size 大小
 @param backColor  背景色
 @param frontColor 前景色
 @param centerImage 中心图片
 @return image二维码
 */
+ (UIImage *_Nullable)kj_createQRCodeImageWithString:(nonnull NSString *)codeString Size:(CGSize)size BackColor:(nullable UIColor *)backColor FrontColor:(nullable UIColor *)frontColor CenterImage:(nullable UIImage *)centerImage{
    NSData *stringData = [codeString dataUsingEncoding:NSUTF8StringEncoding];
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [qrFilter setValue:stringData forKey:@"inputMessage"];
    [qrFilter setValue:@"M" forKey:@"inputCorrectionLevel"];
    
    CIImage *qrImage = qrFilter.outputImage;
    //放大并绘制二维码 (上面生成的二维码很小，需要放大)
    CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:qrImage fromRect:qrImage.extent];
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    //翻转一下图片 不然生成的QRCode就是上下颠倒的
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, CGContextGetClipBoundingBox(context), cgImage);
    UIImage *codeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGImageRelease(cgImage);
    
    //绘制颜色
    CIFilter *colorFilter = [CIFilter filterWithName:@"CIFalseColor" keysAndValues:
                             @"inputImage",[CIImage imageWithCGImage:codeImage.CGImage],
                             @"inputColor0",[CIColor colorWithCGColor:frontColor == nil ? [UIColor clearColor].CGColor : frontColor.CGColor],
                             @"inputColor1",[CIColor colorWithCGColor:backColor == nil ? [UIColor blackColor].CGColor : backColor.CGColor],
                             nil];
    UIImage * colorCodeImage = [UIImage imageWithCIImage:colorFilter.outputImage];
    
    //中心添加图片
    if (centerImage != nil) {
        UIGraphicsBeginImageContext(colorCodeImage.size);
        [colorCodeImage drawInRect:CGRectMake(0, 0, colorCodeImage.size.width, colorCodeImage.size.height)];
        UIImage *image = centerImage;
        CGFloat imageW = 50;
        CGFloat imageX = (colorCodeImage.size.width - imageW) * 0.5;
        CGFloat imgaeY = (colorCodeImage.size.height - imageW) * 0.5;
        [image drawInRect:CGRectMake(imageX, imgaeY, imageW, imageW)];
        UIImage *centerImageCode = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return centerImageCode;
    }
    return colorCodeImage;
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
//扫描完成后执行
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects.count > 0){
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects firstObject];
        // 扫描完成后的字符
        if(self.scanFinishedBlock != nil){
            self.scanFinishedBlock(metadataObject.stringValue);
        }
    }
}
#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate的方法
//扫描过程中执行，主要用来判断环境的黑暗程度
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    if (self.monitorLightBlock == nil) return;
    CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL,sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
    CFRelease(metadataDict);
    NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
    float brightnessValue = [[exifMetadata objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
    // 根据brightnessValue的值来判断是否需要打开和关闭闪光灯
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    BOOL result = [device hasTorch];// 判断设备是否有闪光灯
    if ((brightnessValue < 0) && result) {
        // 环境太暗，可以打开闪光灯了
    }else if((brightnessValue > 0) && result){
        // 环境亮度可以
    }
    if (self.monitorLightBlock != nil) {
        self.monitorLightBlock(brightnessValue);
    }
}

#pragma mark - lazy
- (AVCaptureSession *)session{
    if (_session == nil){
        //获取摄像设备
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        //创建输入流
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
        if (!input) return nil;
        //创建二维码扫描输出流
        AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
        //设置代理 在主线程里刷新
        [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        //设置采集扫描区域的比例 默认全屏是（0，0，1，1）
        //rectOfInterest 填写的是一个比例，输出流视图preview.frame为 x , y, w, h, 要设置的矩形快的scanFrame 为 x1, y1, w1, h1. 那么rectOfInterest 应该设置为 CGRectMake(y1/y, x1/x, h1/h, w1/w)。
        CGFloat x = CGRectGetMinX(self.scanFrame)/CGRectGetWidth(self.preview.frame);
        CGFloat y = CGRectGetMinY(self.scanFrame)/CGRectGetHeight(self.preview.frame);
        CGFloat w = CGRectGetWidth(self.scanFrame)/CGRectGetWidth(self.preview.frame);
        CGFloat h = CGRectGetHeight(self.scanFrame)/CGRectGetHeight(self.preview.frame);
        output.rectOfInterest = CGRectMake(y, x, h, w);
        
        // 创建环境光感输出流
        AVCaptureVideoDataOutput *lightOutput = [[AVCaptureVideoDataOutput alloc] init];
        [lightOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
        
        _session = [[AVCaptureSession alloc] init];
        //高质量采集率
        [_session setSessionPreset:AVCaptureSessionPresetHigh];
        [_session addInput:input];
        [_session addOutput:output];
        [_session addOutput:lightOutput];
        
        //设置扫码支持的编码格式(这里设置条形码和二维码兼容)
        output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    }
    return _session;
}


@end
