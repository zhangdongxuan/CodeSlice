//
//  RecorderViewController.m
//  AudioSpectrumDemo
//
//  Created by user on 2019/5/21.
//  Copyright © 2019 adu. All rights reserved.
//

#import "RecorderViewController.h"
#import "SpectrumView.h"
#import "AudioSpectrumRecorder.h"
#import "UIView+EXT.h"
#import "AudioFrequencyView.h"

@interface RecorderViewController () <AudioSpectrumRecorderDelegate>

@property(nonatomic, strong) UIButton *recordButton;
@property (nonatomic, strong) AudioSpectrumRecorder *recorder;
@property (nonatomic, strong) SpectrumView *spectrumView;

@property (nonatomic, strong) AudioFrequencyView *frequencyView;

@end

@implementation RecorderViewController


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.recorder stop];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self configInit];
    [self buildUI];
}

- (UIButton *)recordButton {
    if (_recordButton) {
        return _recordButton;
    }
    
    UIImage *recordIconImage = [UIImage imageNamed:@"record_icon"];
    UIImage *pauseIconImage = [UIImage imageNamed:@"record_pause"];
    
    UIButton *recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [recordButton setImage:recordIconImage forState:UIControlStateNormal];
    [recordButton setImage:pauseIconImage forState:UIControlStateSelected];
    
    recordButton.size = CGSizeMake(80, 80);
    recordButton.centerX = self.view.centerX;
    recordButton.bottom = 200;
    [recordButton addTarget:self action:@selector(startRecord:) forControlEvents:UIControlEventTouchUpInside];
    
    _recordButton = recordButton;
    
    return _recordButton;
}

- (void)configInit {
    self.title = @"录音";
}

- (void)buildUI {
    
    self.spectrumView = [[SpectrumView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, 200)];
    [self.view addSubview:self.spectrumView];
    
    [self.view addSubview:self.recordButton];
    
    [self.view addSubview:self.frequencyView];
}


- (AudioFrequencyView *)frequencyView {
    if (_frequencyView == nil) {
        _frequencyView = [[AudioFrequencyView alloc] initWithFrame:CGRectMake(0, self.spectrumView.bottom + 16, self.view.width, 200)];
        _frequencyView.backgroundColor = UIColor.cyanColor;
    }
    
    return _frequencyView;
}

- (void)startRecord:(id)sender {
    
     if (self.recordButton.selected) {
         [self.recorder stop];
         self.recordButton.selected = NO;
         return;
     }
    
    
    [self.recorder startRecord];
    self.recordButton.selected = YES;
}


#pragma mark - AudioSpectrumRecorderDelegate
- (void)recorderDidGenerateSpectrum:(NSArray *)spectrums {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.spectrumView updateSpectra:spectrums withStype:ADSpectraStyleRound];
        [self.frequencyView updateFrequencyData:[spectrums firstObject]];
    });
}

- (AudioSpectrumRecorder *)recorder {
    if (!_recorder) {
        _recorder = [[AudioSpectrumRecorder alloc] init];
        _recorder.delegate = self;
    }
    return _recorder;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
