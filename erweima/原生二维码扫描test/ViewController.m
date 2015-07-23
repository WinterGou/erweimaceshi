//
//  ViewController.m
//  原生二维码扫描test
//
//  Created by goudongqian on 15/7/23.
//  Copyright (c) 2015年 goudongqian. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate>
@property (weak, nonatomic) IBOutlet UIView *viewPreview;
@property (weak, nonatomic) IBOutlet UILabel *lblstatus;
@property (weak, nonatomic) IBOutlet UIButton *startBtn;
- (IBAction)startStopReadClick:(id)sender;

@property (nonatomic, strong) UIView *boxView;
@property (nonatomic) BOOL isReading;
@property (nonatomic, strong) CALayer *scanLayer;

- (BOOL)startReading;
- (void)stopReading;

//捕捉会话
@property (nonatomic, strong) AVCaptureSession *captureSession;
//展示layer
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _captureSession = nil;
    _isReading = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)startReading
{
    NSError *error;
    //初始化捕捉设备，类型为AVMediaTypeVideo
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //用捕捉设备创建输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!input)
    {
        NSLog(@"%@",[error localizedDescription]);
        return NO;
    }
    //创建媒体数据输出流
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    //实例化捕捉会话
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession addInput:input];
    [_captureSession addOutput:captureMetadataOutput];
    //创建串行队列，并将媒体输出流添加到队列中 并设置代理
    dispatch_queue_t dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    //设置输媒体数据类型为QRCode
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    //示例化预览图层
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_videoPreviewLayer setFrame:_viewPreview.layer.bounds];
    [_viewPreview.layer addSublayer:_videoPreviewLayer];
    //设置扫描范围
    captureMetadataOutput.rectOfInterest = CGRectMake(0.2, 0.2, 0.8, 0.8);
    //扫描框
    _boxView = [[UIView alloc] initWithFrame:CGRectMake(_viewPreview.bounds.size.width * 0.2f, _viewPreview.bounds.size.height * 0.2f, _viewPreview.bounds.size.width - _viewPreview.bounds.size.width * 0.4f, _viewPreview.bounds.size.height - _viewPreview.bounds.size.height * 0.4f)];
    _boxView.layer.borderColor = [UIColor greenColor].CGColor;
    _boxView.layer.borderWidth = 1.0f;
    [_viewPreview addSubview:_boxView];
    //扫描线
    _scanLayer = [[CALayer alloc] init];
    _scanLayer.frame = CGRectMake(0, 0, _boxView.frame.size.width, 1);
    _scanLayer.backgroundColor = [UIColor brownColor].CGColor;
    [_boxView.layer addSublayer:_scanLayer];
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(moveScanLayer) userInfo:nil repeats:YES];
    [timer fire];
    //开始扫描
    [_captureSession startRunning];
    return YES;
}

- (void)stopReading
{
    [_captureSession stopRunning];
    _captureSession = nil;
    [_scanLayer removeFromSuperlayer];
    [_videoPreviewLayer removeFromSuperlayer];
}

- (IBAction)startStopReadClick:(id)sender
{
    if (!_isReading)
    {
        if ([self startReading])
        {
            [_startBtn setTitle:@"stop" forState:UIControlStateNormal];
            [_lblstatus setText:@"Scanning for QR Code"];
        }
    }
    else
    {
        [self stopReading];
        [_startBtn setTitle:@"start" forState:UIControlStateNormal];
    }
    _isReading = !_isReading;
}

- (void)moveScanLayer
{
    CGRect frame = _scanLayer.frame;
    if (_boxView.frame.size.height < _scanLayer.frame.origin.y)
    {
        frame.origin.y = 0;
        _scanLayer.frame = frame;
    }
    else
    {
        frame.origin.y = frame.origin.y + 5;
        [UIView animateWithDuration:0.1 animations:^{
            _scanLayer.frame = frame;
        }];
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects != nil && [metadataObjects count] > 0)
    {
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects firstObject];
        
        if ([[metadataObject type] isEqualToString:AVMetadataObjectTypeQRCode])
        {
            [_lblstatus performSelectorOnMainThread:@selector(setText:) withObject:metadataObject.stringValue waitUntilDone:NO];
            [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
            _isReading = NO;
        }
    }
}

@end
