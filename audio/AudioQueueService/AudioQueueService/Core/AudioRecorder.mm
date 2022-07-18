//
//  AudioRecorder.m
//  AudioQueueService
//
//  Created by disen zhang on 2020/4/30.
//  Copyright © 2020 disen zhang. All rights reserved.
//

#import "AudioRecorder.h"
#import "FileHelper.h"
#import "AQDumpData.h"
#import "RealtimeAnalyser.h"
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>

@interface AudioRecorder ()

@property (nonatomic, strong) NSString *nsWritePath;
@property (nonatomic, strong) NSArray *arrAmplitudes;
@property (nonatomic, strong) NSArray *arrFFTData;

@property (nonatomic, assign) int sampleRate;
@property (nonatomic, assign) int fftSize;
@property(nonatomic, strong) NSOutputStream *outputSteam;

- (void)outputPcmBuffer:(AudioQueueBufferRef)buffer recordTime:(NSTimeInterval)recordTime;

@end

#pragma mark - Buffer callback
static void HandleInputBuffer(void *inUserData,
                              AudioQueueRef inAudioQueue,
                              AudioQueueBufferRef inBuffer,
                              const AudioTimeStamp *inStartTime,
                              UInt32 inNumPackets,
                              const AudioStreamPacketDescription *inPacketDesc) {
    AudioRecorder *recorder = (__bridge AudioRecorder *)inUserData;
    if (recorder == nil) {
        NSLog(@"recorder is dealloc");
        return;
    }

    NSTimeInterval recordTime = inStartTime->mSampleTime / recorder->mAqState.mDataFormat.mSampleRate;
    //    NSLog(@"inNumPackets:%d record time:%f", inNumPackets, recordTime);

    if (inNumPackets > 0) {
        [recorder outputPcmBuffer:inBuffer recordTime:recordTime];
    }

    if (recorder->mAqState.mIsRunning) {
        AudioQueueEnqueueBuffer(recorder->mAqState.mQueue, inBuffer, 0, NULL);
    }
};

@implementation AudioRecorder

- (instancetype)initWithWritePath:(NSString *)nsWritePath sampleRate:(int)sampleRate fftSize:(int)fftSize {
    self = [super init];
    if (self) {
        self.nsWritePath = nsWritePath;
        self.sampleRate = sampleRate;
        self.fftSize = fftSize;
    }
    return self;
}

- (void)start {
    if (mAqState.mIsRunning) {
        NSLog(@"start failed : mIsRunning");
        return;
    }
    
    if (self.outputSteam) {
        [self.outputSteam close];
        self.outputSteam = nil;
    }

    if(self.nsWritePath.length > 0) {
        if ([FileHelper fileExist:self.nsWritePath] == NO) {
            [FileHelper createFile:self.nsWritePath];
        }
        
        self.outputSteam = [[NSOutputStream alloc] initToFileAtPath:self.nsWritePath append:YES];
        [self.outputSteam open];
    }

    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];

    mAqState.mDataFormat.mSampleRate = self.sampleRate; //采样率, 1s采集的次数
    mAqState.mDataFormat.mBitsPerChannel = AUDIO_BIT_LEN; //在一个数据帧中，每个通道的样本数据的位数。
    mAqState.mDataFormat.mChannelsPerFrame = 1; //每帧数据通道数(左右声道)
    mAqState.mDataFormat.mFormatID = kAudioFormatLinearPCM; //数据格式 PCM
    mAqState.mDataFormat.mFramesPerPacket = 1; //每包数据帧数
    mAqState.mDataFormat.mBytesPerFrame = (mAqState.mDataFormat.mBitsPerChannel / 8) * mAqState.mDataFormat.mChannelsPerFrame;
    mAqState.mDataFormat.mBytesPerPacket = mAqState.mDataFormat.mBytesPerFrame * mAqState.mDataFormat.mFramesPerPacket;
    mAqState.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    //    mAqState.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsFloat | kLinearPCMFormatFlagIsPacked ;

    UInt32 frameCount = self.fftSize;

    NSLog(@"buffer per sec:%.2f", (float)frameCount / self.sampleRate);

    mAqState.bufferByteSize = frameCount * (mAqState.mDataFormat.mBitsPerChannel / 8);

    AudioQueueNewInput(&mAqState.mDataFormat, HandleInputBuffer, (__bridge void *)(self), NULL, kCFRunLoopCommonModes, 0, &mAqState.mQueue);

    UInt32 channels = 0;
    UInt32 channelsSize = 0;

    AudioQueueGetProperty(mAqState.mQueue, kAudioQueueDeviceProperty_NumberChannels, &channels, &channelsSize);

    AudioChannelLayout channelLayout;
    UInt32 layoutSize = sizeof(channelLayout);
    AudioQueueGetProperty(mAqState.mQueue, kAudioQueueProperty_ChannelLayout, &channelLayout, &layoutSize);

    NSLog(@"Channels:%u LayoutTag:%u bitmap:%u numberChannelDescriptions:%u",
          channels,
          channelLayout.mChannelLayoutTag,
          channelLayout.mChannelBitmap,
          channelLayout.mNumberChannelDescriptions);

    for (int i = 0; i < kNumberBuffers; i++) {
        AudioQueueAllocateBuffer(mAqState.mQueue, mAqState.bufferByteSize, &mAqState.mBuffers[i]);
        AudioQueueEnqueueBuffer(mAqState.mQueue, mAqState.mBuffers[i], 0, NULL);
    }

    mAqState.mIsRunning = 1;
    OSStatus ret = AudioQueueStart(mAqState.mQueue, NULL);

    NSLog(@"start record with path:%@ ret:%d", self.nsWritePath, ret);
}

- (void)stop {
    if (mAqState.mIsRunning == NO) {
        return;
    }

    OSStatus ret = AudioQueueStop(mAqState.mQueue, YES);
    if (ret != 0) {
        for (int i = 0; i < kNumberBuffers; i++) {
            AudioQueueFreeBuffer(mAqState.mQueue, mAqState.mBuffers[i]);
        }
    } else {
        AudioQueueDispose(mAqState.mQueue, true);
        mAqState.mQueue = NULL;
    }
}

- (void)pause {
    AudioQueuePause(mAqState.mQueue);
    NSLog(@"pause record");
}

- (void)resume {
    AudioQueueStart(mAqState.mQueue, NULL);
    NSLog(@"resume record");
}

- (NSArray *)getAmplitudes {
    return [self.arrAmplitudes copy];
}

- (NSArray *)getFFTData {
    return [self.arrFFTData copy];
}

- (void)outputPcmBuffer:(AudioQueueBufferRef)buffer recordTime:(NSTimeInterval)recordTime {
    int length = buffer->mAudioDataByteSize / mAqState.mDataFormat.mBytesPerFrame;
    NSData *data = [NSData dataWithBytes:buffer->mAudioData length:buffer->mAudioDataByteSize];

    if (self.outputSteam) {
        [self.outputSteam write:(uint8_t *)buffer->mAudioData maxLength:buffer->mAudioDataByteSize];
    }

    [self.analyzer onRecievePcmData:data frameCount:length];
}

@end
