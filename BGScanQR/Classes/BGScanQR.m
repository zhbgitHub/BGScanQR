//
//  BGScanQR.m
//  QRScan
//
//  Created by ioszhb on 2015/7/19.
//  Copyright © 2015年 developzhb. All rights reserved.
//  This is a tool that supports iOS7.0

#import "BGScanQR.h"
#import <AVFoundation/AVFoundation.h>


@interface BGScanQR ()<AVCaptureMetadataOutputObjectsDelegate>


@property (assign,nonatomic) AVCaptureDevice         * device;
@property (strong,nonatomic) AVCaptureDeviceInput    * input;
@property (strong,nonatomic) AVCaptureMetadataOutput * output;//扫码输出管理
@property (strong,nonatomic) AVCaptureSession        * session;
@property (strong,nonatomic) AVCaptureVideoPreviewLayer *previewLayer;//

@property (nonatomic,weak) UIView *videoView; //视频预览显示视图
@property(nonatomic,copy)void (^backBlock)(NSArray<NSDictionary *> *array);//扫码成功后-回调block
@property (nonatomic, strong) NSArray *metaDataObjTypeArray;

@property (nonatomic, strong) NSMutableArray *resultArray;
@end


@implementation BGScanQR
@synthesize metaDataObjTypeArray = _metaDataObjTypeArray;
@synthesize torch = _torch;

#pragma mark -- life cycle
- (void)dealloc
{
    [self.device removeObserver:self forKeyPath:@"torchMode" context:@"start"];
    [self.device removeObserver:self forKeyPath:@"torchMode" context:@"stop"];
}

- (instancetype)initWithView:(UIView *)videoView rect:(CGRect)rect metaDataObjTypes:(NSArray *)metaDataObjTypeArray successed:(void(^)(NSArray<NSDictionary *> *array))block
{
    if (self = [super init]) {
        [self configerDeviceUseVideoView:videoView rect:rect ObjectTypes:metaDataObjTypeArray successed:block];
    }
    return self;
}

- (instancetype)initWithView:(UIView *)videoView successed:(void(^)(NSArray<NSDictionary *> *array))block
{
    return [self initWithView:videoView rect:CGRectZero metaDataObjTypes:self.metaDataObjTypeArray successed:block];
}

#pragma mark -- kvo
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
#ifdef DEBUG
    NSLog(@"torchMode 改变了===%@", change);
#endif
}

#pragma mark -- system dataSource and delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    [self.resultArray removeAllObjects];
    //识别扫码类型
    for(AVMetadataObject *current in metadataObjects) {
        if ([current isKindOfClass:[AVMetadataMachineReadableCodeObject class]] ) {
            NSLog(@"type:%@",current.type);
            NSString *resultStr = [(AVMetadataMachineReadableCodeObject *) current stringValue];
            if (resultStr && ![resultStr isEqualToString:@""]) {
                NSMutableDictionary *mDict = [NSMutableDictionary dictionary];
                [mDict setObject:resultStr forKey:@"resultStr"];
                [mDict setObject:current.type forKey:@"type"];
                [self.resultArray addObject:mDict];
                break;
            }
            //测试可以同时识别多个二维码
        }
    }
    
    //若获取的结果为nil,继续扫描.
    if (self.resultArray.count <= 0) {
        return;
    }
    
    [self stopScan];
    
    if (_backBlock) {
        _backBlock(self.resultArray);
    }
    
    //TODO: 后期增加需求_捕获图片,,在此判断处理
}

#pragma mark -- event response
- (void)startScan
{
    if (self.input && !self.session.isRunning) {
        [_session startRunning];
        [self.videoView.layer insertSublayer:self.previewLayer atIndex:0];
        //给input.device添加监听者--kvo
        [self.device addObserver:self forKeyPath:@"torchMode" options:0 context:@"start"];
    }
}

- (void)stopScan
{
    if (self.input && self.session.isRunning) {
        [_session stopRunning];
        //给input.device添加监听者--kvo
        [self.device addObserver:self forKeyPath:@"torchMode" options:0 context:@"stop"];
    }
}

- (void)changeTorch
{
    if([self.device hasTorch] && [self.device hasFlash]) {
        AVCaptureTorchMode torch = self.device.torchMode;
        AVCaptureFlashMode flash = self.device.flashMode;
        if(self.device.torchMode != AVCaptureTorchModeOff) {
            torch = AVCaptureTorchModeOff;
            flash = AVCaptureFlashModeOff;
        }
        else {
            torch = AVCaptureTorchModeOn;
            flash = AVCaptureFlashModeOn;
        }
        
        [self.session beginConfiguration];
        [self.device lockForConfiguration:nil];
        [self.device setTorchMode:torch];
        [self.device setFlashMode:flash];
        [self.device unlockForConfiguration];
        [self.session commitConfiguration];
    }
}

+ (BOOL)authenticateCamera
{
    //相机权限
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus ==AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied) {
        return NO;
    }
    return YES;
}

+ (void)authenticateCameraWithSuccessBlock:(void(^)())sblock failBlock:(void(^)())fBlock
{
    //相机权限
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus ==AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied) {
        if (fBlock) {
            fBlock();
        }
    }
    else {
        // 暂时不做任何处理...
    }
}

#pragma mark -- private methods
- (void)configerDeviceUseVideoView:(UIView *)videoView rect:(CGRect)rect ObjectTypes:(NSArray *)array successed:(void(^)(NSArray<NSDictionary *> *array))block
{
    if (!BGAssertNoNil(videoView, @"video 不能为空")) return;
    if (!BGAssertNoNil(block, @"block 不能为空")) return;
    if (!BGAssertNoNil(self.device, @"设备不支持")) return;
    if (!BGAssertNoNil(self.input, @"摄像头/相机设备不可用!")) return;
    
    
    // 1.备份数据
    self.videoView            = videoView;
    self.backBlock            = block;
    self.metaDataObjTypeArray = array;
    
    if (NO == CGRectEqualToRect(rect,CGRectZero)) {
        _output.rectOfInterest = rect;
    }
    
    if ([self.session canAddInput:self.input]) {
        [self.session addInput:_input];
    }
    
    if ([self.session canAddOutput:self.output]) {
        [self.session addOutput:_output];
    }
    
    //warning:metadataObjectTypes只能在 [session addOutput:output]之后调用
    if (self.output != nil) {
        self.output.metadataObjectTypes = self.metaDataObjTypeArray;
    }
    
    // self.previewLayer
    CGRect frame            = videoView.frame;
    frame.origin            = CGPointZero;
    self.previewLayer.frame = frame;
    [videoView.layer insertSublayer:self.previewLayer atIndex:0];
    
    // 4.开启自动对焦
    [self openAutoFocusMode];
}

/**
 先进行判断是否支持控制对焦,不开启自动对焦功能，很难识别二维码。
 */
- (void)openAutoFocusMode
{
    //判断是否支持自动对焦
    if (self.device.isFocusPointOfInterestSupported &&[self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        [self.input.device lockForConfiguration:nil];
        [self.input.device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        [self.input.device unlockForConfiguration];
    }
}

#pragma mark -- getters and setters
- (NSArray *)metaDataObjTypeArray
{
    if (_metaDataObjTypeArray == nil) {
        NSMutableArray *types = [@[AVMetadataObjectTypeQRCode,
                                   AVMetadataObjectTypeUPCECode,
                                   AVMetadataObjectTypeCode39Code,
                                   AVMetadataObjectTypeCode39Mod43Code,
                                   AVMetadataObjectTypeEAN13Code,
                                   AVMetadataObjectTypeEAN8Code,
                                   AVMetadataObjectTypeCode93Code,
                                   AVMetadataObjectTypeCode128Code,
                                   AVMetadataObjectTypePDF417Code,
                                   AVMetadataObjectTypeAztecCode] mutableCopy];
        
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_0) {
            [types addObject:AVMetadataObjectTypeInterleaved2of5Code];
            [types addObject:AVMetadataObjectTypeITF14Code];
            [types addObject:AVMetadataObjectTypeDataMatrixCode];
        }
        _metaDataObjTypeArray = [types copy];
    }
    return _metaDataObjTypeArray;
}

- (AVCaptureDevice *)device
{
    if (_device == nil) {
        _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    return _device;
}

- (AVCaptureDeviceInput *)input
{
    if (_input == nil) {
        _input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    }
    return _input;
}

- (AVCaptureMetadataOutput *)output
{
    if (_output == nil) {
        _output = [[AVCaptureMetadataOutput alloc]init];
        [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    }
    return _output;
    
}

- (AVCaptureSession *)session
{
    if (_session == nil) {
        _session = [[AVCaptureSession alloc]init];
        [_session setSessionPreset:AVCaptureSessionPresetHigh];
    }
    return _session;
    
}

- (AVCaptureVideoPreviewLayer *)previewLayer
{
    if (_previewLayer == nil) {
        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _previewLayer;
    
}

- (NSMutableArray *)resultArray
{
    if (_resultArray == nil) {
        _resultArray = [NSMutableArray arrayWithCapacity:1];
    }
    return _resultArray;
}

- (void)setTorch:(BOOL)torch
{
    if([self.device hasTorch] && [self.device hasFlash]) {
        [self.session beginConfiguration];
        [self.device lockForConfiguration:nil];
        self.device.torchMode = torch ? AVCaptureTorchModeOn : AVCaptureTorchModeOff;
        self.device.flashMode = torch ? AVCaptureFlashModeOn : AVCaptureFlashModeOff;
        [self.device unlockForConfiguration];
        [self.session commitConfiguration];
    }
}

- (BOOL)isTorch
{
    if([self.device hasTorch] && [self.device hasFlash]) {
        if(self.device.torchMode == AVCaptureTorchModeOn) {
            return YES;
        }
    }
    return NO;
}

#pragma mark -- other
/**
 //TODO: 后期:研究cocoapods + XCAssert
 */
BOOL BGAssertNoNil(id obj, NSString *msg)
{
    if (obj  == nil) {
#ifdef DEBUG
        NSLog(@"%@",msg);
#endif
        return NO;
    }
    else {
        return YES;
    }
}

@end
