//
//  RealtimeAnalyser.h
//  AudioQueueService
//
//  Created by disen zhang on 2020/6/16.
//  Copyright © 2020 disen zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RealtimeAnalyser : NSObject

@property (nonatomic, assign) UInt32 sampleRate;
@property (nonatomic, assign, readonly) UInt32 bandsCount;

- (instancetype)initWithFFTSize:(UInt32)fftSize sampleRate:(UInt32)sampleRate;

- (void)cleanCacheData;
- (void)updateSampleRate:(UInt32)sampleRate;
- (void)onRecievePcmData:(NSData *)rawData frameCount:(UInt32)framesToProcess;
- (void)getFloatFrequencWithBands:(UInt32)count completion:(void (^)(NSData *spectrum))completion;

@end

NS_ASSUME_NONNULL_END
