//
//  FrequencyView.h
//  AudioQueueService
//
//  Created by disen zhang on 2020/6/30.
//  Copyright © 2020 disen zhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RealtimeAnalyser.h"

NS_ASSUME_NONNULL_BEGIN

static const NSUInteger kPillarCount = 60;
static const NSUInteger kPillarSmallCount = 11;

static const CGFloat kPillarMaxHeight = 40;
static const CGFloat kPillarSmallMaxHeight = 30;

@interface FDRecordFeedbackView : UIView

- (instancetype)initFrequencyViewWithFrame:(CGRect)frame;
- (void)updateFrequencyData:(NSData *)frequency;

@end

NS_ASSUME_NONNULL_END
