//
//  AudioFrequencyView.m
//  AudioQueueService
//
//  Created by disen zhang on 2020/6/17.
//  Copyright © 2020 disen zhang. All rights reserved.
//

#import "AudioFrequencyView.h"
#import "UIView+EXT.h"
#import "AudioServiceDefine.h"

#define FREQUENCY_COUNT (AUDIO_PROCESS_PER_TIMES * AUDIO_SAMPLE_RATE)

@interface AudioFrequencyView ()

@property(nonatomic, strong) NSArray *arrFrequency;
@property(nonatomic, strong) UILabel *labelView;
@property(nonatomic, strong) NSMutableArray<UIView *> *arrBars;


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
        _gradientLayer.colors = @[(id)[UIColor colorWithRed:235/255.0 green:18/255.0 blue:26/255.0 alpha:1.0].CGColor, (id)[UIColor colorWithRed:255/255.0 green:165/255.0 blue:0/255.0 alpha:1.0].CGColor];
        _gradientLayer.locations = @[@0.6, @1.0];
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
    
//    self.arrBars = [NSMutableArray array];
//    for (int i = 0; i < FREQUENCY_COUNT; i ++) {
//        UIView *bar = [[UIView alloc] initWithFrame:CGRectZero];
//        bar.backgroundColor = UIColor.blackColor;
//
//        [self.arrBars addObject:bar];
//        [self addSubview:bar];
//    }
//
//    self.labelView = [[UILabel alloc] init];
//    self.labelView.text = @"FFT Frequency Spectrum";
//    self.labelView.textColor = UIColor.darkGrayColor;
//    self.labelView.backgroundColor = UIColor.clearColor;
//    self.labelView.font = [UIFont systemFontOfSize:10];
//    self.labelView.textAlignment = NSTextAlignmentCenter;
//    [self addSubview:self.labelView];
}


- (CGFloat)translateAmplitudeToYPosition:(float)amplitude {
    CGFloat barHeight = (CGFloat)amplitude * (CGRectGetHeight(self.bounds) - self.marginBottom - self.marginTop);
    return CGRectGetHeight(self.bounds) - self.marginBottom - barHeight;
}


- (void)updateFrequencyData:(NSArray *)arrFrequency {
    self.arrFrequency = arrFrequency;
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    UIBezierPath *leftPath = [UIBezierPath bezierPath];
    NSUInteger count = [arrFrequency count];
    for (int i = 0; i < count; i++) {
        CGFloat x = (CGFloat)i * (self.barWidth + self.space) + self.space;
        CGFloat y = [self translateAmplitudeToYPosition:[arrFrequency[i] floatValue]];
        CGRect rect = CGRectMake(x, y, self.barWidth, CGRectGetHeight(self.bounds) - self.marginBottom -y);
        UIBezierPath *bar = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(self.barWidth/2, self.barWidth/2)];
        [leftPath appendPath:bar];
    }
    
    CAShapeLayer *leftMaskLayer = [CAShapeLayer layer];
    leftMaskLayer.path = leftPath.CGPath;
    self.gradientLayer.frame = CGRectMake(0, self.marginTop, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) - self.marginTop - self.marginBottom);
    self.gradientLayer.mask = leftMaskLayer;
    
    [CATransaction commit];
}

@end

