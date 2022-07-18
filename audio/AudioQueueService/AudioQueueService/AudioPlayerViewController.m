//
//  AudioPlayerViewController.m
//  AudioQueueService
//
//  Created by disen zhang on 2020/6/17.
//  Copyright © 2020 disen zhang. All rights reserved.
//

#import "AudioPlayerViewController.h"
#import "AudioPlayer.h"
#import "FileHelper.h"
#import "UIView+EXT.h"

@interface AudioPlayerViewController () <AudioPlayerDelegate>

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) AudioPlayer *player;

@property (nonatomic, strong) UIView *frequencyView;

@property (nonatomic, assign) float currentPlayTime;

@end

@implementation AudioPlayerViewController

- (instancetype)initWithFilePath:(NSString *)filePath {
    self = [super init];
    if (self) {
        self.filePath = filePath;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColor.whiteColor;

    [self.view addSubview:self.frequencyView];

    //    self.slider = [[UISlider alloc] init];
    //    self.slider.size = CGSizeMake(260, 40);
    //    self.slider.top = 680;
    //
    //    self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    //    [self.playButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    //    self.playButton.size = CGSizeMake(40, 40);
    //    self.playButton.left = 32;
    //    self.slider.left = self.playButton.right + 12;
    //    self.playButton.centerY = self.slider.centerY;
    //
    //    [self.playButton addTarget:self action:@selector(onStartPlayBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    //
    //    [self.view addSubview:self.playButton];
    //    [self.view addSubview:self.slider];
    //
    //    [self setPlayerControlHidden:YES];
}

- (UIView *)frequencyView {
    if (_frequencyView == nil) {
        _frequencyView = [[UIView alloc] init];
        _frequencyView.width = self.view.width;
        _frequencyView.height = 320;
        _frequencyView.top = 88;
        _frequencyView.backgroundColor = [UIColor.cyanColor colorWithAlphaComponent:0.3];
    }

    NSData *rawdata = [NSData dataWithContentsOfFile:self.filePath];
    uint16_t *data = (uint16_t *)rawdata.bytes;

    UIBezierPath *linePath = [UIBezierPath bezierPath];

    float barwidth = self.view.width / (rawdata.length / 2);
    float centerY = _frequencyView.height / 2;

    for (int i = 0; i < rawdata.length / 2; i++) {
        int16_t val = data[i];
        val = abs(val);

        float height = _frequencyView.height * val / (1 << 15);

        [linePath moveToPoint:CGPointMake(i * barwidth, centerY - height / 2)];
        [linePath addLineToPoint:CGPointMake(i * barwidth, centerY + height / 2)];
    }

    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.lineWidth = barwidth;
    shapeLayer.strokeColor = [UIColor blackColor].CGColor;
    shapeLayer.path = linePath.CGPath;

    [_frequencyView.layer addSublayer:shapeLayer];

    return _frequencyView;
    ;
}

- (void)setPlayerControlHidden:(BOOL)hidden {
    self.playButton.hidden = hidden;
    self.slider.hidden = hidden;
}

- (void)onStartPlayBtnClick:(id)sender {
    if (self.filePath.length == 0 || [FileHelper fileExist:self.filePath] == NO) {
        return;
    }

    if (self.player) {
        if (self.player.isPlaying) {
            [self.player pause];
            [self.playButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        } else {
            [self.player playFromOffsetms:self.currentPlayTime];
            [self.playButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
        }

        return;
    }

    self.player = [[AudioPlayer alloc] initWithPCMFile:self.filePath delegate:self];
    [self.player play];
    [self.playButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
}

- (void)onPlayToEnd {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.slider setValue:0];
        [self.playButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        self.player = nil;
    });
}

- (void)onPlayTimeUpdate:(float)time {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentPlayTime = time;
        [self.slider setValue:time];
    });
}

@end
