//
//  AudioBandsInfo.m
//  AudioQueueService
//
//  Created by disen zhang on 2020/12/15.
//  Copyright © 2020 disen zhang. All rights reserved.
//

#import "AudioBandsInfo.h"

@interface AudioBandsInfo ()

@property (nonatomic, assign) int startIndex;
@property (nonatomic, assign) int endIndex;

@end

@implementation AudioBandsInfo

+ (instancetype)createWith:(float)lowerFrequency upperFrequency:(float)upperFrequency bandWidth:(float)bandWidth {
    AudioBandsInfo *info = [[AudioBandsInfo alloc] init];
    info.startIndex = round(lowerFrequency / bandWidth);
    info.endIndex = round(upperFrequency / bandWidth);

    return info;
}

- (float)getMaxAmplitude:(float *)amplitudes length:(int)length {
    int startIndex = _startIndex;
    int endIndex = MIN(_endIndex, length - 1);

    if (startIndex >= length || endIndex >= length) {
        return 0;
    }

    if (endIndex == startIndex) {
        return amplitudes[startIndex];
    }

    float maxAmplitude = amplitudes[startIndex];
    for (int i = startIndex; i <= endIndex; i++) {
        if (maxAmplitude < amplitudes[i]) {
            maxAmplitude = amplitudes[i];
        }
    }

    return maxAmplitude;
}

@end
