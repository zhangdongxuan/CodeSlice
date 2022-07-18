//
//  WCRecordPillar.h
//  WCRecordFeedback
//
//  Created by disen zhang on 2019/12/3.
//  Copyright © 2019 disen zhang. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

static const NSUInteger kPillarCount = 25;
static const CGFloat kPillarMaxHeight = 40;

static const NSUInteger kPillarSmallCount = 11;
static const CGFloat kPillarSmallMaxHeight = 30;

static const NSUInteger kPillarMicroCount = 9;
static const CGFloat kPillarMicroMaxHeight = 26;

static const CGFloat kPillarWidth = 2;
static const CGFloat kPillarMinHeight = 4;

static const CGFloat kPillarMargin = 1;

static const CGFloat kStrokeStart = 0.5 - (kPillarMinHeight / kPillarMaxHeight) / 2;
static const CGFloat kStrokeEnd = 0.5 + (kPillarMinHeight / kPillarMaxHeight) / 2;

@interface FDRecordPillar : NSObject

@property (nonatomic, assign) UInt32 index;
@property (nonatomic, assign) BOOL bSelectedShowHigher;

@property (nonatomic, assign) CGFloat pillarHeight;
@property (nonatomic, strong) CAShapeLayer *layer;

@property (nonatomic, assign) float lastStartTo;
@property (nonatomic, assign) float lastEndTo;

- (instancetype)initWithIndex:(UInt32)index SuperLayer:(CALayer *)superLayer;

@end

NS_ASSUME_NONNULL_END
