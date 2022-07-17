//
//  UIView+EXT.h
//  AudioQueueService
//
//  Created by disen zhang on 2020/5/17.
//  Copyright © 2020 disen zhang. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView(EXT)

@property CGPoint origin;
@property CGSize size;

@property (readonly) CGPoint bottomLeft;
@property (readonly) CGPoint bottomRight;
@property (readonly) CGPoint topRight;

@property CGFloat height;
@property CGFloat width;

@property CGFloat top;
@property CGFloat left;

@property CGFloat bottom;
@property CGFloat right;

@property CGFloat x ;
@property CGFloat y ;
@property CGFloat centerX;
@property CGFloat centerY;

- (UIEdgeInsets)realSafeAreaInsets;

- (void)setX:(CGFloat)x andY:(CGFloat)y;

- (void) moveBy: (CGPoint) delta;
- (void) scaleBy: (CGFloat) scaleFactor;
- (void) fitInSize: (CGSize) aSize;

@end

NS_ASSUME_NONNULL_END
