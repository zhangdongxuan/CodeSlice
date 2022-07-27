//
//  FrequencyView.m
//  AudioQueueService
//
//  Created by disen zhang on 2020/6/30.
//  Copyright © 2020 disen zhang. All rights reserved.
//

#import "FDRecordFeedbackView.h"

static const CGFloat kPillarMinHeight = 2;

@interface FDRecordFeedbackView ()

@property (nonatomic, assign) Float32 maxHeight;
@property (nonatomic, strong) CAShapeLayer *displayLayer;

@end

@implementation FDRecordFeedbackView

- (instancetype)initFrequencyViewWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _maxHeight = kPillarMaxHeight;
    }
    return self;
}

- (CAShapeLayer *)displayLayer {
    if (_displayLayer == nil) {
        CAShapeLayer *displayLayer = [CAShapeLayer layer];
        displayLayer.strokeColor = [UIColor.blackColor colorWithAlphaComponent:0.5].CGColor;
        displayLayer.opacity = 0.8;
        displayLayer.backgroundColor = UIColor.blueColor.CGColor;
        [self.layer addSublayer:displayLayer];

        _displayLayer = displayLayer;
    }

    return _displayLayer;
}

- (void)updateFrequencyData:(NSData *)frequency {
    unsigned long count = frequency.length / sizeof(Float32);
    Float32 *frequencyBuffer = (Float32 *)frequency.bytes;
    
    CGFloat showWidth = self.frame.size.width -  32;
    CGFloat pillarWidth = showWidth / count;
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    
    CGFloat centerY = 0.5 * self.frame.size.height;
    
    CGFloat startX = 16;

    for (int i = 0; i < count; i++) {
        float amplitude = frequencyBuffer[i] * 50;
        CGFloat barHeight = amplitude * _maxHeight * 1.3;
        barHeight = MAX(kPillarMinHeight, barHeight);
        barHeight = MIN(_maxHeight, barHeight);

        CGFloat x = startX + i * pillarWidth;

        CGPoint startPoint = CGPointMake(x, centerY - barHeight / 2);
        CGPoint endPoint = CGPointMake(x, centerY + barHeight / 2);

        [bezierPath moveToPoint:startPoint];
        [bezierPath addLineToPoint:endPoint];
    }

    self.displayLayer.path = bezierPath.CGPath;
}

@end
