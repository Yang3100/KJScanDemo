//
//  UIImage+KJFilter.m
//  KJEmitterView
//
//  Created by 杨科军 on 2018/12/1.
//  Copyright © 2018 杨科军. All rights reserved.
//  

#import "UIImage+KJFilter.h"
#import <Accelerate/Accelerate.h>

@implementation UIImage (KJFilter)

#pragma mark - 特效渲染
/**根据图片和颜色返回一张加深颜色以后的图片
 * 图片着色
 */
- (UIImage *)kj_drawingWithColorizeImageWithcolor:(UIColor *)color{
    UIGraphicsBeginImageContext(CGSizeMake(self.size.width*2, self.size.height*2));
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect area = CGRectMake(0, 0, self.size.width * 2, self.size.height * 2);
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -area.size.height);
    CGContextSaveGState(ctx);
    CGContextClipToMask(ctx, area, self.CGImage);
    [color set];
    CGContextFillRect(ctx, area);
    CGContextRestoreGState(ctx);
    CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
    CGContextDrawImage(ctx, area, self.CGImage);
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return destImage;
}

/**马赛克函数 */
- (UIImage *)kj_drawingWithMosaic{
    CIImage *ciImage = [[CIImage alloc]initWithImage:self];   // 这里特别注意的是  必须要用.png格式的图片  否则加载不出来。
    //创建filter 滤镜 马赛克效果
    CIFilter *fileter = [CIFilter filterWithName:@"CIPixellate"];
    [fileter setValue:ciImage forKey:kCIInputImageKey];
    [fileter setDefaults];
    //导出图片
    CIImage *outPutImage = [fileter valueForKey:kCIOutputImageKey];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:outPutImage fromRect:[outPutImage extent]];
    UIImage *showImage = [UIImage imageWithCGImage:cgImage];
    // CGImage 并不支持ARC  需要手动释放
    CGImageRelease(cgImage);
    return showImage;
}

/** 高斯模糊函数 */
- (UIImage *)kj_drawingWithGaussianBlurNumber:(CGFloat)blur{
    int boxSize = (int)(blur * 40);
    boxSize = boxSize - (boxSize % 2) + 1;
    CGImageRef img = self.CGImage;
    vImage_Buffer inBuffer, outBuffer;
    vImage_Error error;
    void *pixelBuffer;
    //从CGImage中获取数据
    CGDataProviderRef inProvider = CGImageGetDataProvider(img);
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);
    //设置从CGImage获取对象的属性
    inBuffer.width = CGImageGetWidth(img);
    inBuffer.height = CGImageGetHeight(img);
    inBuffer.rowBytes = CGImageGetBytesPerRow(img);
    inBuffer.data = (void*)CFDataGetBytePtr(inBitmapData);
    pixelBuffer = malloc(CGImageGetBytesPerRow(img) *
                         CGImageGetHeight(img));
    if(pixelBuffer == NULL)NSLog(@"No pixelbuffer");
    outBuffer.data = pixelBuffer;
    outBuffer.width = CGImageGetWidth(img);
    outBuffer.height = CGImageGetHeight(img);
    outBuffer.rowBytes = CGImageGetBytesPerRow(img);
    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    if (error) {NSLog(@"error from convolution %ld", error);}
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(outBuffer.data,
                                             outBuffer.width,
                                             outBuffer.height,
                                             8,
                                             outBuffer.rowBytes,
                                             colorSpace,
                                             kCGImageAlphaNoneSkipLast);
    CGImageRef imageRef = CGBitmapContextCreateImage (ctx);
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef];
    //clean up
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    free(pixelBuffer);
    CFRelease(inBitmapData);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(imageRef);
    return returnImage;
}

/** 边缘锐化函数 */
- (UIImage *)kj_drawingWithEdgeDetection{
    const size_t width = self.size.width;
    const size_t height = self.size.height;
    const size_t bytesPerRow = width * 4;
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8, bytesPerRow, space, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(space);
    if (!bmContext)
    return nil;
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    if (!data){
        CGContextRelease(bmContext);
        return nil;
    }
    const size_t n = sizeof(UInt8) * width * height * 4;
    void* outt = malloc(n);
    vImage_Buffer src = {data, height, width, bytesPerRow};
    vImage_Buffer dest = {outt, height, width, bytesPerRow};
    vImageConvolve_ARGB8888(&src, &dest, NULL, 0, 0, edgedetect_kernel, 3, 3, 1, backgroundColorBlack, kvImageCopyInPlace);
    memcpy(data, outt, n);
    CGImageRef edgedImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* edged = [UIImage imageWithCGImage:edgedImageRef];
    CGImageRelease(edgedImageRef);
    free(outt);
    CGContextRelease(bmContext);
    return edged;
}

/** 浮雕函数 */
- (UIImage *)kj_drawingWithEmboss{
    const size_t width = self.size.width;
    const size_t height = self.size.height;
    const size_t bytesPerRow = width * 4;
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8, bytesPerRow, space, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(space);
    if (!bmContext)
    return nil;
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    if (!data){
        CGContextRelease(bmContext);
        return nil;
    }
    const size_t n = sizeof(UInt8) * width * height * 4;
    void* outt = malloc(n);
    vImage_Buffer src = {data, height, width, bytesPerRow};
    vImage_Buffer dest = {outt, height, width, bytesPerRow};
    vImageConvolve_ARGB8888(&src, &dest, NULL, 0, 0, emboss_kernel, 3, 3, 1, NULL, kvImageCopyInPlace);
    memcpy(data, outt, n);
    free(outt);
    CGImageRef embossImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* emboss = [UIImage imageWithCGImage:embossImageRef];
    CGImageRelease(embossImageRef);
    CGContextRelease(bmContext);
    return emboss;
}

/** 锐化函数 */
- (UIImage *)kj_drawingWithSharpen{
    const size_t width = self.size.width;
    const size_t height = self.size.height;
    const size_t bytesPerRow = width * 4;
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8, bytesPerRow, space, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(space);
    if (!bmContext)
    return nil;
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    if (!data){
        CGContextRelease(bmContext);
        return nil;
    }
    const size_t n = sizeof(UInt8) * width * height * 4;
    void* outt = malloc(n);
    vImage_Buffer src = {data, height, width, bytesPerRow};
    vImage_Buffer dest = {outt, height, width, bytesPerRow};
    vImageConvolve_ARGB8888(&src, &dest, NULL, 0, 0, sharpen_kernel, 3, 3, 1, NULL, kvImageCopyInPlace);
    memcpy(data, outt, n);
    free(outt);
    CGImageRef sharpenedImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* sharpened = [UIImage imageWithCGImage:sharpenedImageRef];
    CGImageRelease(sharpenedImageRef);
    CGContextRelease(bmContext);
    return sharpened;
}

/** 进一步锐化函数 */
- (UIImage *)kj_drawingWithNnsharpen{
    const size_t width = self.size.width;
    const size_t height = self.size.height;
    const size_t bytesPerRow = width * 4;
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8, bytesPerRow, space, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(space);
    if (!bmContext)
    return nil;
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    if (!data){
        CGContextRelease(bmContext);
        return nil;
    }
    const size_t n = sizeof(UInt8) * width * height * 4;
    void* outt = malloc(n);
    vImage_Buffer src = {data, height, width, bytesPerRow};
    vImage_Buffer dest = {outt, height, width, bytesPerRow};
    vImageConvolve_ARGB8888(&src, &dest, NULL, 0, 0, unsharpen_kernel, 3, 3, 9, NULL, kvImageCopyInPlace);
    memcpy(data, outt, n);
    free(outt);
    CGImageRef unsharpenedImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* unsharpened = [UIImage imageWithCGImage:unsharpenedImageRef];
    CGImageRelease(unsharpenedImageRef);
    CGContextRelease(bmContext);
    return unsharpened;
}

//转成黑白图像
- (UIImage*)kj_drawingWithGrayImage{
    int width = self.size.width;
    int height = self.size.height;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate (nil,width,height,8,0,colorSpace,kCGImageAlphaNone);
    CGColorSpaceRelease(colorSpace);
    
    if (context == NULL) {
        return nil;
    }
    
    CGContextDrawImage(context,CGRectMake(0, 0, width, height), self.CGImage);
    CGImageRef contextRef = CGBitmapContextCreateImage(context);
    UIImage *grayImage = [UIImage imageWithCGImage:contextRef];
    CGContextRelease(context);
    CGImageRelease(contextRef);
    
    return grayImage;
}


#pragma mark - 形态操作
/** 形态膨胀/扩张 */
- (UIImage *)kj_drawingWithDilate{
    const size_t width = self.size.width;
    const size_t height = self.size.height;
    const size_t bytesPerRow = width * 4;
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8, bytesPerRow, space, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(space);
    if (!bmContext)
    return nil;
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    if (!data){
        CGContextRelease(bmContext);
        return nil;
    }
    const size_t n = sizeof(UInt8) * width * height * 4;
    void* outt = malloc(n);
    vImage_Buffer src = {data, height, width, bytesPerRow};
    vImage_Buffer dest = {outt, height, width, bytesPerRow};
    vImageDilate_ARGB8888(&src, &dest, 0, 0, morphological_kernel, 3, 3, kvImageCopyInPlace);
    memcpy(data, outt, n);
    free(outt);
    CGImageRef dilatedImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* dilated = [UIImage imageWithCGImage:dilatedImageRef];
    CGImageRelease(dilatedImageRef);
    CGContextRelease(bmContext);
    return dilated;
}
- (UIImage *)kj_drawingWithDilateIterations:(int)iterations{
    UIImage *dstImage = self;
    for (int i=0; i<iterations; i++) {
        dstImage = [dstImage kj_drawingWithDilate];
    }
    return dstImage;
}

/**
 *  侵蚀
 */
- (UIImage *)kj_drawingWithErode{
    const size_t width = self.size.width;
    const size_t height = self.size.height;
    const size_t bytesPerRow = width * 4;
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8, bytesPerRow, space, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(space);
    if (!bmContext)
    return nil;
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    if (!data){
        CGContextRelease(bmContext);
        return nil;
    }
    const size_t n = sizeof(UInt8) * width * height * 4;
    void* outt = malloc(n);
    vImage_Buffer src = {data, height, width, bytesPerRow};
    vImage_Buffer dest = {outt, height, width, bytesPerRow};
    vImageErode_ARGB8888(&src, &dest, 0, 0, morphological_kernel, 3, 3, kvImageCopyInPlace);
    memcpy(data, outt, n);
    free(outt);
    CGImageRef erodedImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* eroded = [UIImage imageWithCGImage:erodedImageRef];
    CGImageRelease(erodedImageRef);
    CGContextRelease(bmContext);
    return eroded;
}
- (UIImage *)kj_drawingWithErodeIterations:(int)iterations{
    UIImage *dstImage = self;
    for (int i=0; i<iterations; i++) {
        dstImage = [dstImage kj_drawingWithErode];
    }
    return dstImage;
}

- (UIImage *)kj_drawingWithGradientIterations:(int)iterations{
    UIImage *dilated = [self kj_drawingWithDilateIterations:iterations];
    UIImage *eroded = [self kj_drawingWithErodeIterations:iterations];
    UIImage *dstImage = [dilated kj_imageBlendedWithImage:eroded blendMode:kCGBlendModeDifference alpha:1.0];
    return dstImage;
}

- (UIImage *)kj_drawingWithTophatIterations:(int)iterations {
    UIImage *dilated = [self kj_drawingWithDilateIterations:iterations];
    UIImage *dstImage = [self kj_imageBlendedWithImage:dilated blendMode:kCGBlendModeDifference alpha:1.0];
    return dstImage;
}

- (UIImage *)kj_drawingWithBlackhatIterations:(int)iterations {
    UIImage *eroded = [self kj_drawingWithErodeIterations:iterations];
    UIImage *dstImage = [eroded kj_imageBlendedWithImage:self blendMode:kCGBlendModeDifference alpha:1.0];
    return dstImage;
}

- (UIImage *)kj_drawingWithEqualization{
    const size_t width = self.size.width;
    const size_t height = self.size.height;
    const size_t bytesPerRow = width * 4;
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8, bytesPerRow, space, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(space);
    if (!bmContext)
    return nil;
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    if (!data){
        CGContextRelease(bmContext);
        return nil;
    }
    vImage_Buffer src = {data, height, width, bytesPerRow};
    vImage_Buffer dest = {data, height, width, bytesPerRow};
    vImageEqualization_ARGB8888(&src, &dest, kvImageNoFlags);
    CGImageRef destImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* destImage = [UIImage imageWithCGImage:destImageRef];
    CGImageRelease(destImageRef);
    CGContextRelease(bmContext);
    return destImage;
}

#pragma mark - 复用函数
// 混合函数
- (UIImage *)kj_imageBlendedWithImage:(UIImage *)overlayImage blendMode:(CGBlendMode)blendMode alpha:(CGFloat)alpha {
    UIGraphicsBeginImageContext(self.size);
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    [self drawInRect:rect];
    [overlayImage drawAtPoint:CGPointMake(0, 0) blendMode:blendMode alpha:alpha];
    UIImage *blendedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return blendedImage;
}

//static int16_t gaussianblur_kernel[25] = {
//    1, 4, 6, 4, 1,
//    4, 16, 24, 16, 4,
//    6, 24, 36, 24, 6,
//    4, 16, 24, 16, 4,
//    1, 4, 6, 4, 1
//};

static int16_t edgedetect_kernel[9] = {
    -1, -1, -1,
    -1, 8, -1,
    -1, -1, -1
};

static int16_t emboss_kernel[9] = {
    -2, 0, 0,
    0, 1, 0,
    0, 0, 2
};

static int16_t sharpen_kernel[9] = {
    -1, -1, -1,
    -1, 9, -1,
    -1, -1, -1
};

static int16_t unsharpen_kernel[9] = {
    -1, -1, -1,
    -1, 17, -1,
    -1, -1, -1
};

static uint8_t backgroundColorBlack[4] = {0,0,0,0};

static unsigned char morphological_kernel[9] = {
    1, 1, 1,
    1, 1, 1,
    1, 1, 1,
};

@end
