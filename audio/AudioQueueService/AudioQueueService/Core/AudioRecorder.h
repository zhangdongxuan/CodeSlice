//
//  AudioRecorder.h
//  AudioQueueService
//
//  Created by disen zhang on 2020/4/30.
//  Copyright © 2020 disen zhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioServiceDefine.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AudioRecorderDelegate <NSObject>

- (void)onRecordTimeUpdate:(float)recordTime;
- (void)onAmplitudesUpdate:(NSArray *)arrAmplitudes Recorder:(id)sender;

@end

@interface AudioRecorder : NSObject {
    @public
    AudioRecordState mAqState;
}

@property(nonatomic, weak) id<AudioRecorderDelegate> delegate;

- (instancetype)initWithWritePath:(NSString *)nsWritePath sampleRate:(int)sampleRate fftSize:(int)fftSize;
- (void)start;
- (void)stop;
- (void)pause;
- (void)resume;
- (NSArray *)getAmplitudes;
- (NSArray *)getFFTData;

@end

NS_ASSUME_NONNULL_END