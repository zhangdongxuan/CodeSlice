//
//  FrequencyView.m
//  AudioQueueService
//
//  Created by disen zhang on 2020/6/30.
//  Copyright © 2020 disen zhang. All rights reserved.
//

#import "FDRecordFeedbackView.h"
#import "FDRecordFDView.h"

static const CGFloat kPillarWidth = 2;
static const CGFloat kPillarMinHeight = 4;
static const CGFloat kPillarMargin = 1;

@interface FDRecordFeedbackView ()

@property (nonatomic, assign) Float32 maxHeight;
@property (nonatomic, strong) CAShapeLayer *displayLayer;
@property (nonatomic, strong) FDRecordFDView *pillarsView;

@end

@implementation FDRecordFeedbackView

- (instancetype)initFrequencyViewWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _maxHeight = kPillarMaxHeight;
        _pillarsView = [[FDRecordFDView alloc] initWithFrame:self.bounds PillarCount:kPillarCount MaxHeight:kPillarMaxHeight];
        [self addSubview:_pillarsView];
    }
    return self;
}

- (CAShapeLayer *)displayLayer {
    if (_displayLayer == nil) {
        CAShapeLayer *displayLayer = [CAShapeLayer layer];
        displayLayer.lineCap = kCALineCapRound;
        displayLayer.lineWidth = kPillarWidth;
        displayLayer.strokeColor = [UIColor.blackColor colorWithAlphaComponent:0.5].CGColor;
        displayLayer.opacity = 0.8;
        displayLayer.backgroundColor = UIColor.blueColor.CGColor;
        [self.layer addSublayer:displayLayer];

        _displayLayer = displayLayer;
    }

    return _displayLayer;
}

- (void)updateFrequencyData:(NSData *)frequency {
    [_pillarsView updateFrequencyData:frequency];
}

- (void)updateAnimateWithFrequency:(NSData *)frequency {
    //    [CATransaction begin];

    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    unsigned long length = frequency.length / sizeof(float);
    float *frequencyBuffer = (float *)frequency.bytes;

    CGFloat centerY = 0.5 * self.frame.size.height;
    CGFloat totalWidth = kPillarWidth * length + kPillarMargin * (length - 1);
    CGFloat startX = (self.frame.size.width - totalWidth) / 2;

    for (int i = 0; i < length; i++) {
        float amplitude = frequencyBuffer[i];
        CGFloat barHeight = amplitude * _maxHeight * 1.3;
        barHeight = MAX(kPillarMinHeight, barHeight);

        barHeight = MIN(_maxHeight, barHeight);

        CGFloat x = startX + i * (kPillarWidth + kPillarMargin);

        CGPoint startPoint = CGPointMake(x, centerY - barHeight / 2);
        CGPoint endPoint = CGPointMake(x, centerY + barHeight / 2);

        [bezierPath moveToPoint:startPoint];
        [bezierPath addLineToPoint:endPoint];
    }

    self.displayLayer.path = bezierPath.CGPath;

    //    [CATransaction commit];
}

- (void)setAnalyser:(RealtimeAnalyser *)analyser {
    [_pillarsView setAnalyser:analyser];
}

@end
