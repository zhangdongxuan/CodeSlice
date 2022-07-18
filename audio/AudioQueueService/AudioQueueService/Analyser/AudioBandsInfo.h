//
//  AudioBandsInfo.h
//  AudioQueueService
//
//  Created by disen zhang on 2020/12/15.
//  Copyright © 2020 disen zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioBandsInfo : NSObject

+ (instancetype)createWith:(float)lowerFrequency upperFrequency:(float)upperFrequency bandWidth:(float)bandWidth;

- (float)getMaxAmplitude:(float *)amplitudes length:(int)length;

@end

NS_ASSUME_NONNULL_END
