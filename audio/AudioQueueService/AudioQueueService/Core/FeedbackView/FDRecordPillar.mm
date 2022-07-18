//
//  WCRecordPillar.m
//  WCRecordFeedback
//
//  Created by disen zhang on 2019/12/3.
//  Copyright © 2019 disen zhang. All rights reserved.
//

#import "FDRecordPillar.h"

@interface FDRecordPillar ()

@property (nonatomic, weak) CALayer *superLayer;

@end

@implementation FDRecordPillar

- (instancetype)initWithIndex:(UInt32)index SuperLayer:(CALayer *)superLayer {
    self = [super init];
    if (self) {
        self.superLayer = superLayer;
        self.lastStartTo = kStrokeStart;
        self.lastEndTo = kStrokeEnd;

        self.layer = [self getShapeLayer];
        [self.superLayer addSublayer:self.layer];
    }

    return self;
}

- (CAShapeLayer *)getShapeLayer {
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    layer.lineCap = kCALineCapRound;
    layer.lineWidth = kPillarWidth;
    layer.strokeStart = kStrokeStart;
    layer.strokeEnd = kStrokeEnd;
    layer.strokeColor = [UIColor.blackColor colorWithAlphaComponent:0.5].CGColor;
    layer.opacity = 0.8;

    return layer;
}

@end
