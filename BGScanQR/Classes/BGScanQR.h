//
//  BGScanQR.h
//  QRScan
//
//  Created by ioszhb on 2015/7/19.
//  Copyright © 2015年 developzhb. All rights reserved.
//  This is a tool that supports iOS7.0

/* Instructions: 说明必要条件
   使用之前必须配置info.plist
   NSCameraUsageDescription
   NSPhotoLibraryUsageDescription
 */



#import <Foundation/Foundation.h>

@interface BGScanQR : NSObject

/**
 创建扫描工具对象---!warning:暂时不支持除此之外的其他创建方式

 @param videoView 相机展示layer的依托,
 @param rect 识别区域，值CGRectZero 全屏识别
 @param metaDataObjTypeArray 识别码的类型(AVMetadataObjectTypeQRCode,AVMetadataObjectTypeCode93Cod),可是nil,默认全部类型
 @param block 扫码成功后的回调,不可为nil
 @return BGScanQR
 */
- (instancetype)initWithView:(UIView *)videoView rect:(CGRect)rect metaDataObjTypes:(NSArray *)metaDataObjTypeArray successed:(void(^)(NSArray<NSDictionary *> *array))block;

/**
 创建扫描工具对象---!warning:暂时不支持除此之外的其他创建方式

 @param videoView 相机展示layer的依托,
 @param block 扫码成功后的回调,不可为nil
 @return BGScanQR
 */
- (instancetype)initWithView:(UIView *)videoView successed:(void(^)(NSArray<NSDictionary *> *array))block;

/**
 开始扫码
 */
- (void)startScan;

/**
 停止扫码
 */
- (void)stopScan;

/**
 是否开启闪光灯,默认NO:关闭, YES:开启
 */
@property (nonatomic, assign, getter=isTorch) BOOL torch;

/**
 自动根据闪关灯状态去改变,用途:1.取反状态 2.sos模式
 */
- (void)changeTorch;

/**
 相机授权
*/
+ (BOOL)authenticateCamera;

+ (void)authenticateCameraWithSuccessBlock:(void(^)())sblock failBlock:(void(^)())fBlock;

@end
