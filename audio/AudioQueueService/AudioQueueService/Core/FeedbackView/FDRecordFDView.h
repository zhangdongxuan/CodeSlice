//
//  WCRecordFDView.h
//  WCRecordFeedback
//
//  Created by disen zhang on 2019/12/22.
//  Copyright © 2019 disen zhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RealtimeAnalyser.h"

NS_ASSUME_NONNULL_BEGIN

static const CGFloat kPowerCount = 3;
static const CGFloat kDelayFactor = 120;
static const float kSlientPeakPower = 0.05;

@class FDRecordPillar;

@interface FDRecordFDView : UIView

@property (nonatomic, strong) CALayer *displayLayer;
@property (nonatomic, strong) NSMutableArray *curFeedbackPillars;
@property (nonatomic, strong) NSMutableArray<FDRecordPillar *> *arrPillars;

- (instancetype)initWithFrame:(CGRect)frame PillarCount:(UInt32)pillarsCount MaxHeight:(Float32)maxHeight;

- (void)initPillars;
- (void)updateFrequencyData:(NSData *)frequency;
- (void)setAnalyser:(RealtimeAnalyser *)analyser;

@end

NS_ASSUME_NONNULL_END
