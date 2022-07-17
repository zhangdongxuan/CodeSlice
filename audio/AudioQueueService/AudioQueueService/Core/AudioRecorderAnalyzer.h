//
//  AudioRecorderAnalyzer.h
//  AudioQueueService
//
//  Created by disen zhang on 2020/6/16.
//  Copyright © 2020 disen zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioRecorderAnalyzer : NSObject

- (instancetype)initWithFFTSize:(UInt32)fftSize sampleRate:(UInt32)sampleRate;
- (NSMutableArray *)fft:(float *)buffer frameCount:(UInt32)frameCount;
- (NSMutableArray *)analysisAmplitudesWithAmplitudes:(NSMutableArray *)arrAmplitudes;

- (NSMutableArray *)analysisAmplitudesWithPCMData:(float *)rawData audioFrameCount:(UInt32)frameCount;

@end

NS_ASSUME_NONNULL_END
