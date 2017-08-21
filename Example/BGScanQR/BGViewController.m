//
//  BGViewController.m
//  BGScanQR
//
//  Created by zhb_mymail@163.com on 08/21/2017.
//  Copyright (c) 2017 zhb_mymail@163.com. All rights reserved.
//

#import "BGViewController.h"
#import "BGScanQR.h"

@interface BGViewController ()
@property (nonatomic, strong) UIView *scanView;
@property (nonatomic, strong) BGScanQR *scanQr;
@end

@implementation BGViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.scanView = [[UIView alloc] init];
    [self.view addSubview:self.scanView];
    self.scanView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-100);
    
    self.scanView.layer.borderColor = [UIColor orangeColor].CGColor;
    self.scanView.layer.borderWidth = 1;
    
    
    
    _scanQr = [[BGScanQR alloc] initWithView:self.scanView rect:CGRectMake(0, 100, 200, 50) metaDataObjTypes:nil successed:^(NSArray<NSDictionary *> *array) {
        NSLog(@"array === %@", array);
    }];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.scanQr startScan];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.scanQr stopScan];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [BGScanQR authenticateCameraWithSuccessBlock:^{
        // 暂不做任何处理..
    } failBlock:^{
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
