//
//  FrequencyView.m
//  AudioQueueService
//
//  Created by disen zhang on 2020/6/30.
//  Copyright © 2020 disen zhang. All rights reserved.
//

#import "FrequencyView.h"
#import "UIView+EXT.h"

@interface FrequencyView ()

@property(nonatomic, strong) NSArray *arrFrequency;
@property(nonatomic, strong) CAShapeLayer *shapeLayer;

@end


@implementation FrequencyView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.layer addSublayer:self.shapeLayer];
    }
    return self;
}


- (CAShapeLayer *)shapeLayer {
    if (_shapeLayer == nil) {
        _shapeLayer = [CAShapeLayer layer];
        _shapeLayer.frame = self.layer.bounds;
    }
    
    return _shapeLayer;
}

- (void)updateFrequencyData:(NSArray *)arrFrequency {
    self.arrFrequency = arrFrequency;
//    NSLog(@"arrFrequency:%@", arrFrequency);
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    
    float spaceWidth = 40.0;
    float space = spaceWidth / (arrFrequency.count - 1);
    float barWidth = (self.width - spaceWidth) / arrFrequency.count;
    
    float maxHeight = self.height;
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    
    NSUInteger count = [arrFrequency count];
    for (int i = 0; i < count; i++) {
        CGFloat x = i * (barWidth + space) + space;
        CGFloat height = 10 * maxHeight * [[self.arrFrequency objectAtIndex:i] floatValue];
        CGFloat y = self.height - height;
        CGRect rect = CGRectMake(x, y, barWidth, height);
        UIBezierPath *bar = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(barWidth / 2, barWidth / 2)];
        [bezierPath appendPath:bar];
    }
    
    self.shapeLayer.path = bezierPath.CGPath;
    
    [CATransaction commit];
}

@end
