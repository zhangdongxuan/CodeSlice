//
//  AudioFrequencyView.m
//  AudioQueueService
//
//  Created by disen zhang on 2020/6/17.
//  Copyright © 2020 disen zhang. All rights reserved.
//
#import "AudioFrequencyView.h"
#import "AudioServiceDefine.h"
#import "UIView+EXT.h"

#define FREQUENCY_COUNT (AUDIO_PROCESS_PER_TIMES * AUDIO_SAMPLE_RATE)

@interface AudioFrequencyView ()

@property (nonatomic, strong) NSArray *arrFrequency;
@property (nonatomic, assign) CGFloat space;
@property (nonatomic, assign) CGFloat barWidth;
@property (nonatomic, assign) CGFloat marginTop;
@property (nonatomic, assign) CGFloat marginBottom;

@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@end

@implementation AudioFrequencyView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initSubView];
    }
    return self;
}

- (CAGradientLayer *)gradientLayer {
    if (_gradientLayer == nil) {
        _gradientLayer = [CAGradientLayer layer];
        //        _gradientLayer.colors = @[(id)[UIColor colorWithRed:235/255.0 green:18/255.0 blue:26/255.0 alpha:1.0].CGColor, (id)[UIColor colorWithRed:255/255.0 green:165/255.0 blue:0/255.0 alpha:1.0].CGColor];
        //        _gradientLayer.locations = @[@0.6, @1.0];
        _gradientLayer.backgroundColor = UIColor.redColor.CGColor;
    }

    return _gradientLayer;
}

- (void)initSubView {
    self.marginTop = 0;
    self.marginBottom = 0;
    CGFloat barSpace = self.frame.size.width / (CGFloat)(80 * 3 - 1);
    self.barWidth = barSpace * 2;
    self.space = barSpace;

    [self.layer addSublayer:self.gradientLayer];
}

- (CGFloat)translateAmplitudeToYPosition:(float)amplitude {
    CGFloat barHeight = (CGFloat)amplitude * (CGRectGetHeight(self.bounds) - self.marginBottom - self.marginTop);
    return CGRectGetHeight(self.bounds) - self.marginBottom - barHeight;
}

- (void)updateFrequencyData:(NSData *)frequency {
    unsigned long length = frequency.length / sizeof(float);
    float *frequencyBuffer = (float *)frequency.bytes;

    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    NSUInteger count = length;
    float width = count * (self.barWidth + self.space);
    float originX = (self.width - width) / 2;

    UIBezierPath *leftPath = [UIBezierPath bezierPath];
    for (int i = 0; i < count; i++) {
        float amplitude = frequencyBuffer[i];
        amplitude = MIN(1, amplitude);
        CGFloat barHeight = amplitude * CGRectGetHeight(self.bounds) * 0.8;
        barHeight = MAX(barHeight, 10);

        CGFloat x = (CGFloat)i * (self.barWidth + self.space) + self.space + originX;
        CGFloat y = (self.height - barHeight) / 2;

        CGRect rect = CGRectMake(x, y, _barWidth, barHeight);
        UIBezierPath *barPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:self.barWidth / 2];
        [leftPath appendPath:barPath];
    }

    CAShapeLayer *leftMaskLayer = [CAShapeLayer layer];
    leftMaskLayer.path = leftPath.CGPath;
    self.gradientLayer.frame =
    CGRectMake(0, self.marginTop, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) - self.marginTop - self.marginBottom);
    self.gradientLayer.mask = leftMaskLayer;

    [CATransaction commit];
}

@end
