//
//  WCRecordFDView.m
//  WCRecordFeedback
//
//  Created by disen zhang on 2019/12/22.
//  Copyright © 2019 disen zhang. All rights reserved.
//

#import "FDRecordFDView.h"
#import "FDRecordPillar.h"

@interface FDRecordFDView () <CAAnimationDelegate>

@property (nonatomic, assign) UInt32 pillarsCount;
@property (nonatomic, assign) Float32 maxHeight;
@property (nonatomic, strong) NSData *lastFrequency;

@property (nonatomic, strong) RealtimeAnalyser *analyser;

@end

@implementation FDRecordFDView

- (instancetype)initWithFrame:(CGRect)frame PillarCount:(UInt32)pillarsCount MaxHeight:(Float32)maxHeight {
    if (self = [super initWithFrame:frame]) {
        _maxHeight = maxHeight;
        _pillarsCount = pillarsCount;

        [self initPillars];
    }
    return self;
}

- (void)initPillars {
    CALayer *displayLayer = [CALayer layer];
    displayLayer.position = self.layer.position;
    displayLayer.anchorPoint = self.layer.anchorPoint;
    displayLayer.bounds = self.layer.bounds;

    self.displayLayer = displayLayer;
    [self.layer addSublayer:self.displayLayer];

    self.arrPillars = [NSMutableArray array];

    for (UInt32 i = 0; i < self.pillarsCount; i++) {
        FDRecordPillar *pillar = [[FDRecordPillar alloc] initWithIndex:i SuperLayer:displayLayer];
        pillar.pillarHeight = self.maxHeight / 2;
        [self.arrPillars addObject:pillar];
        [self configWithPillar:pillar Idex:i];
    }
}

- (void)setAnalyser:(RealtimeAnalyser *)analyser {
    _analyser = analyser;
}

- (void)updateFrequencyData:(NSData *)frequency {
    unsigned long length = frequency.length / sizeof(float);
    float *frequencyBuffer = (float *)frequency.bytes;
    float *lastFrequencyBuffer = NULL;
    if (_lastFrequency) {
        lastFrequencyBuffer = (float *)_lastFrequency.bytes;
    }

    for (int i = 0; i < length; i++) {
        FDRecordPillar *pillar = [self.arrPillars objectAtIndex:i];

        float amplitude = frequencyBuffer[i] * 1.3;
        float start = kStrokeStart - amplitude / 2;
        float end = kStrokeEnd + amplitude / 2;

        float lastAmplitude = 0;
        if (lastFrequencyBuffer != NULL) {
            lastAmplitude = lastFrequencyBuffer[i] * 1.3;
        }

        float lastStart = kStrokeStart - lastAmplitude / 2;
        ;
        float lastEnd = kStrokeEnd + lastAmplitude / 2;

        CAAnimationGroup *group = [self getAnimationGroupWithStartFrom:lastStart StartTo:start EndFrom:lastEnd EndTo:end];

        unsigned long long curTimeInMs = [self genCurrentTimeInMs];
        [pillar.layer addAnimation:group forKey:[NSString stringWithFormat:@"recordPillar_%llu", curTimeInMs]];
    }

    _lastFrequency = frequency;
}

- (CAAnimationGroup *)getAnimationGroupWithStartFrom:(float)startFrom StartTo:(float)startTo EndFrom:(float)endFrom EndTo:(float)endTo {
    CABasicAnimation *startAnimation = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
    startAnimation.fromValue = @(startFrom);
    startAnimation.toValue = @(startTo);

    CABasicAnimation *endAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    endAnimation.fromValue = @(endFrom);
    endAnimation.toValue = @(endTo);
    //    endAnimation setTimingFunction:

    CAAnimationGroup *group = [CAAnimationGroup animation];

    //    CAMediaTimingFunction *func = [CAMediaTimingFunction functionWithControlPoints:0.00:0.70:1.00:1.00];
    //    func = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    //
    //    [group setTimingFunction:func];
    [group setAnimations:@[ startAnimation, endAnimation ]];
    //    [group setAutoreverses:YES];
    //    [group setDuration:1];
    //    [group setRemovedOnCompletion:YES];
    group.delegate = self;

    return group;
}

- (UInt32)genCurrentTime {
    return [[NSDate date] timeIntervalSince1970];
}

- (void)configWithPillar:(FDRecordPillar *)pillar Idex:(NSUInteger)i {
    CGFloat halfHeight = 0.5 * self.frame.size.height;

    CGFloat totalWidth = kPillarWidth * self.pillarsCount + kPillarMargin * (self.pillarsCount - 1);
    CGFloat startX = (self.frame.size.width - totalWidth) / 2;
    CGFloat x = startX + i * (kPillarWidth + kPillarMargin);

    CGPoint startPoint = CGPointMake(x, halfHeight - pillar.pillarHeight);
    CGPoint endPoint = CGPointMake(x, halfHeight + pillar.pillarHeight);

    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:startPoint];
    [path addLineToPoint:endPoint];

    pillar.layer.path = path.CGPath;
}

- (void)refreshData {
    [self.analyser getFloatFrequencWithBands:kPillarCount
                                  completion:^(NSData *spectrum) {
                                      if (spectrum == nil) {
                                          return;
                                      }

                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          [self updateFrequencyData:spectrum];
                                      });
                                  }];
}

- (unsigned long long)genCurrentTimeInMs {
    unsigned long long time = CFAbsoluteTimeGetCurrent() * 1000;
    return time;
}

/* Called when the animation begins its active duration. */

- (void)animationDidStart:(CAAnimation *)anim {
}

/* Called when the animation either completes its active duration or
 * is removed from the object it is attached to (i.e. the layer). 'flag'
 * is true if the animation reached the end of its active duration
 * without being removed. */

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    NSLog(@"flag:%u", flag);

    //    [self refreshData];
}

- (void)startAnimateTimer {
}

- (void)stopTimer {
}

- (void)onAnimateTimerCallback {
}

- (CAAnimationGroup *)getAnimationGroup {
    CABasicAnimation *strokeStartAnimation = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
    strokeStartAnimation.fromValue = @(kStrokeStart);
    strokeStartAnimation.toValue = @0.42;

    CABasicAnimation *strokeEndAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];

    strokeEndAnimation.fromValue = @(kStrokeEnd);
    strokeEndAnimation.toValue = @0.58;

    CAAnimationGroup *group = [CAAnimationGroup animation];
    [group setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [group setAnimations:@[ strokeStartAnimation, strokeEndAnimation ]];
    [group setAutoreverses:YES];
    [group setDuration:0.8];
    [group setRemovedOnCompletion:YES];

    return group;
}

@end
