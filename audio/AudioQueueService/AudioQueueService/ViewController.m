//
//  ViewController.m
//  AudioQueueService
//
//  Created by disen zhang on 2020/4/30.
//  Copyright © 2020 disen zhang. All rights reserved.
//

#import "ViewController.h"
#import "AudioRecorder.h"
#import "FileHelper.h"
#import "AudioFrequencyView.h"
#import "AudioPlayerViewController.h"
#import "AudioFrequencyView.h"
#import "FDRecordFeedbackView.h"
#import "RealtimeAnalyser.h"
#import "UIView+EXT.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource, AudioRecorderDelegate>

@property (nonatomic, assign) float duration;

@property (nonatomic, strong) AudioRecorder *recorder;
@property (nonatomic, strong) NSArray *arrFrequencyData;
@property (nonatomic, strong) FDRecordFeedbackView *frequencyView;

@property (nonatomic, strong) FDRecordFeedbackView *originFrequencyView;

@property (nonatomic, strong) AudioRecorder *recorderWithSampleRate441;
@property (nonatomic, strong) NSArray *arrFrequencyDataWithSampleRate441;

@property (nonatomic, strong) UIButton *recordButton;
@property (nonatomic, strong) UIButton *otherButton;

@property (nonatomic, strong) UILabel *recordShowLabel;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *tableHeaderView;

@property (nonatomic, strong) NSMutableArray *arrAudioFiles;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) RealtimeAnalyser *analyzer;
@property (nonatomic, strong) CADisplayLink *displayLink;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.lightGrayColor;

    [self updateAudioFiles];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    self.tableView.tableHeaderView = self.tableHeaderView;

    [self.view addSubview:self.tableView];

    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];

    return;
}

- (UIView *)tableHeaderView {
    if (_tableHeaderView) {
        return _tableHeaderView;
    }

    _tableHeaderView = [[UIView alloc] init];
    _tableHeaderView.size = CGSizeMake(self.view.width, 430);
    _tableHeaderView.backgroundColor = UIColor.whiteColor;

    [_tableHeaderView addSubview:self.recordShowLabel];

    [_tableHeaderView addSubview:self.frequencyView];
    [_tableHeaderView addSubview:self.originFrequencyView];

    [_tableHeaderView addSubview:self.recordButton];
    [_tableHeaderView addSubview:self.otherButton];

    return _tableHeaderView;
}

- (UILabel *)recordShowLabel {
    if (_recordShowLabel == nil) {
        _recordShowLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
        _recordShowLabel.font = [UIFont systemFontOfSize:17];
        _recordShowLabel.textColor = UIColor.blackColor;
        [_recordShowLabel setText:@" "];
        [_recordShowLabel sizeToFit];
    }

    return _recordShowLabel;
}

- (UIButton *)otherButton {
    if (_otherButton) {
        return _otherButton;
    }

    UIButton *recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [recordButton setTitle:@"其他" forState:UIControlStateNormal];

    [recordButton setBackgroundColor:[UIColor.blackColor colorWithAlphaComponent:0.3]];
    [recordButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [recordButton sizeToFit];

    recordButton.size = CGSizeMake(recordButton.width + 16, recordButton.height + 8);
    recordButton.centerY = self.recordButton.centerY;
    recordButton.right = self.view.width - 24;
    recordButton.accessibilityLabel = @"Other";
    [recordButton addTarget:self action:@selector(onOtherBtnClick:) forControlEvents:UIControlEventTouchUpInside];

    _otherButton = recordButton;

    return _otherButton;
}

- (UIButton *)recordButton {
    if (_recordButton) {
        return _recordButton;
    }

    UIButton *recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [recordButton setTitle:@"Start Record" forState:UIControlStateNormal];
    [recordButton setTitle:@"Pause Record" forState:UIControlStateSelected];

    [recordButton setBackgroundColor:[UIColor.blackColor colorWithAlphaComponent:0.3]];
    [recordButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];

    [recordButton sizeToFit];

    recordButton.size = CGSizeMake(recordButton.width + 16, recordButton.height + 8);
    recordButton.bottom = _tableHeaderView.height - 8;
    recordButton.left = 24;
    recordButton.accessibilityLabel = @"Play";
    [recordButton addTarget:self action:@selector(onRecordBtnClick:) forControlEvents:UIControlEventTouchUpInside];

    _recordButton = recordButton;

    return _recordButton;
}

- (CADisplayLink *)displayLink {
    if (_displayLink == nil) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onDisplayLinkCallback)];
        //        _displayLink.preferredFramesPerSecond = 1;
    }

    return _displayLink;
}

- (FDRecordFeedbackView *)frequencyView {
    if (_frequencyView) {
        return _frequencyView;
    }

    _frequencyView = [[AudioFrequencyView alloc] initWithFrame:CGRectMake(0, 8, self.view.width, 180)];
    _frequencyView.backgroundColor = UIColor.cyanColor;

    UILabel *tipsLabel = [[UILabel alloc] init];
    tipsLabel.font = [UIFont systemFontOfSize:12];
    tipsLabel.textColor = UIColor.blackColor;
    tipsLabel.text = @"sample rate:16000";
    [tipsLabel sizeToFit];
    tipsLabel.origin = CGPointMake(4, 4);

    [_frequencyView addSubview:tipsLabel];

    return _frequencyView;
}

- (FDRecordFeedbackView *)originFrequencyView {
    if (_originFrequencyView) {
        return _originFrequencyView;
    }

    _originFrequencyView =
    [[FDRecordFeedbackView alloc] initFrequencyViewWithFrame:CGRectMake(0, self.frequencyView.bottom + 8, self.view.width, 180)];
    _originFrequencyView.backgroundColor = UIColor.cyanColor;

    UILabel *tipsLabel = [[UILabel alloc] init];
    tipsLabel.font = [UIFont systemFontOfSize:12];
    tipsLabel.textColor = UIColor.blackColor;
    tipsLabel.text = @"原始波形 sample rate:16000";
    [tipsLabel sizeToFit];
    tipsLabel.origin = CGPointMake(4, 4);

    [_originFrequencyView addSubview:tipsLabel];

    return _originFrequencyView;
}

- (void)reloadTable {
    [self updateAudioFiles];
    [self.tableView reloadData];
}

- (void)onDisplayLinkCallback {
    [self.analyzer getFloatFrequencWithBands:kPillarCount completion:^(NSData  *spectrum, NSData *amplitudesData) {
        if (spectrum == nil) {
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.frequencyView updateFrequencyData:spectrum];
            [self.originFrequencyView updateFrequencyData:amplitudesData];
        });
    }];
}

- (void)updateAudioFiles {
    NSString *nsAudioDirPath = [FileHelper getAudioDirPath];

    NSArray *arrFilePaths = [FileHelper getAllFilesWithDirPath:nsAudioDirPath];
    self.arrAudioFiles = [NSMutableArray arrayWithArray:arrFilePaths];

    NSDateFormatter *dateFmt = [[NSDateFormatter alloc] init];
    [dateFmt setDateFormat:@"yyyyMMDD_HHmmss"];

    [self.arrAudioFiles sortUsingComparator:^NSComparisonResult(NSString *filePath1, NSString *filePath2) {
        NSString *nsTime1 = [[filePath1 lastPathComponent] stringByDeletingPathExtension];
        NSString *nsTime2 = [[filePath1 lastPathComponent] stringByDeletingPathExtension];

        NSDate *date1 = [dateFmt dateFromString:nsTime1];
        NSDate *date2 = [dateFmt dateFromString:nsTime2];

        if (date1.timeIntervalSinceNow > date2.timeIntervalSinceNow) {
            return NSOrderedDescending;
        }
        return NSOrderedAscending;
    }];

    while (self.arrAudioFiles.count > 10) {
        NSString *nsFilePath = [self.arrAudioFiles lastObject];
        [FileHelper removeFile:nsFilePath];
        [self.arrAudioFiles removeLastObject];
    }
}

- (void)onOtherBtnClick:(id)sender {
    //    if (self.analyzer.bandsCount == kPillarCount) {
    //        [self.analyzer updateFrequencyBandsCount:kPillarSmallCount];
    //    }
    //    else {
    //        [self.analyzer updateFrequencyBandsCount:kPillarCount];
    //    }
}

- (void)onRecordBtnClick:(id)sender {
    if (self.recordButton.selected) {
        [self.recorder stop];
        [self.recorderWithSampleRate441 stop];

        self.recordButton.selected = NO;
        [self reloadTable];
        return;
    }

    self.recorder = [[AudioRecorder alloc] initWithWritePath:[FileHelper getAudioWriteFilePath] sampleRate:16000 fftSize:1024];
    self.recorder.delegate = self;
    [self.recorder start];
    self.analyzer = [[RealtimeAnalyser alloc] initWithFFTSize:1024 sampleRate:16000];
    self.recorder.analyzer = self.analyzer;

    self.recordButton.selected = YES;
}

- (void)onRecordTimeUpdate:(float)recordTime {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.recordShowLabel.text = [NSString stringWithFormat:@"%.1f s", recordTime];
        [self.recordShowLabel sizeToFit];
        self.duration = recordTime;
    });
}

#pragma mark - tableView
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *TableSampleIdentifier = @"TableSampleIdentifier";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TableSampleIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TableSampleIdentifier];
    }

    NSUInteger row = [indexPath row];

    NSString *filePath = [self.arrAudioFiles objectAtIndex:row];
    cell.textLabel.text = [filePath lastPathComponent];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 45;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.arrAudioFiles.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"click");

    NSUInteger row = [indexPath row];
    NSString *filePath = [self.arrAudioFiles objectAtIndex:row];

    AudioPlayerViewController *vc = [[AudioPlayerViewController alloc] initWithFilePath:filePath];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
