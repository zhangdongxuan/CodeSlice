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
#import "AudioRecorderAnalyzer.h"
#import <AVFoundation/AVFoundation.h>

@interface AudioRecorder()

@property(nonatomic, strong) NSString *nsWritePath;
@property(nonatomic, strong) NSOutputStream *outputSteam;
@property(nonatomic, strong) AudioRecorderAnalyzer *analyzer;
@property(nonatomic, strong) NSArray *arrAmplitudes;
@property(nonatomic, strong) NSArray *arrFFTData;

@property(nonatomic, assign) int sampleRate;
@property(nonatomic, assign) int fftSize;

- (void)outputPcmBuffer:(AudioQueueBufferRef)buffer recordTime:(NSTimeInterval)recordTime;

@end

#pragma mark - Buffer callback
static void HandleInputBuffer(void                                 *inUserData,
                              AudioQueueRef                        inAudioQueue,
                              AudioQueueBufferRef                  inBuffer,
                              const AudioTimeStamp                 *inStartTime,
                              UInt32                               inNumPackets,
                              const AudioStreamPacketDescription   *inPacketDesc) {
    
    AudioRecorder *recorder = (__bridge AudioRecorder *)inUserData;
    if (recorder == nil) {
        NSLog(@"recorder is dealloc");
        return;
    }
    
    NSTimeInterval recordTime = inStartTime->mSampleTime / recorder->mAqState.mDataFormat.mSampleRate;
    
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
        self.analyzer = [[AudioRecorderAnalyzer alloc] initWithFFTSize:fftSize sampleRate:sampleRate];
    }
    return self;
}


- (void)outputPcmBuffer:(AudioQueueBufferRef)buffer recordTime:(NSTimeInterval)recordTime {
    
    UInt32 mAudioDataByteSize = buffer->mAudioDataByteSize;
    UInt32 frameCount = mAudioDataByteSize / mAqState.mDataFormat.mBytesPerFrame;

    int16_t *data = (int16_t *)buffer->mAudioData;
    int datalen = mAudioDataByteSize / 2;
    Float32 fft_data[datalen];
    Float32 factor = (1 << (AUDIO_BIT_LEN - 1)) ;
    
    for (int i = 0; i < datalen; i++) {
        int16_t val = data[i];
        Float32 covertVal = val / factor;
        fft_data[i] = covertVal;
    }
    NSMutableArray *arrFFTData = [self.analyzer fft:fft_data frameCount:frameCount];
    self.arrAmplitudes = [self.analyzer analysisAmplitudesWithAmplitudes:arrFFTData];
//    self.arrAmplitudes = [self analysisAmplitudesWithPCMData:fft_data frameCount:frameCount];
    
    self.arrFFTData = [arrFFTData copy];
    [self.delegate onAmplitudesUpdate:self.arrAmplitudes Recorder:self];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(onRecordTimeUpdate:)]) {
        [self.delegate onRecordTimeUpdate:recordTime];
    }
    
    if (self.outputSteam == nil) {
        return;
    }
    
    [self.outputSteam write:(uint8_t *)buffer->mAudioData maxLength:mAudioDataByteSize];
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
    
    mAqState.mDataFormat.mSampleRate = self.sampleRate;     //采样率, 1s采集的次数
    mAqState.mDataFormat.mBitsPerChannel = AUDIO_BIT_LEN;      //在一个数据帧中，每个通道的样本数据的位数。
    mAqState.mDataFormat.mChannelsPerFrame = 1;     //每帧数据通道数(左右声道)
    mAqState.mDataFormat.mFormatID = kAudioFormatLinearPCM; //数据格式 PCM
    mAqState.mDataFormat.mFramesPerPacket = 1;      //每包数据帧数
    mAqState.mDataFormat.mBytesPerFrame = (mAqState.mDataFormat.mBitsPerChannel / 8) * mAqState.mDataFormat.mChannelsPerFrame;
    mAqState.mDataFormat.mBytesPerPacket = mAqState.mDataFormat.mBytesPerFrame * mAqState.mDataFormat.mFramesPerPacket;
    mAqState.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
//    mAqState.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsFloat | kLinearPCMFormatFlagIsPacked ;
    
    UInt32 frameCount = self.fftSize;
    mAqState.bufferByteSize = frameCount * (mAqState.mDataFormat.mBitsPerChannel / 8);
    AudioQueueNewInput(&mAqState.mDataFormat, HandleInputBuffer, (__bridge void *)(self), NULL, kCFRunLoopCommonModes, 0, &mAqState.mQueue);

    UInt32 channels = 0;
    UInt32 channelsSize = 0;
    AudioChannelLayout channelLayout;
    UInt32 layoutSize = sizeof(channelLayout);
    
    AudioQueueGetProperty(mAqState.mQueue, kAudioQueueDeviceProperty_NumberChannels, &channels, &channelsSize);
    AudioQueueGetProperty(mAqState.mQueue, kAudioQueueProperty_ChannelLayout, &channelLayout, &layoutSize);
    
    for (int i = 0; i < kNumberBuffers; i++) {
        AudioQueueAllocateBuffer(mAqState.mQueue, mAqState.bufferByteSize, &mAqState.mBuffers[i]);
        AudioQueueEnqueueBuffer(mAqState.mQueue, mAqState.mBuffers[i], 0, NULL);
    }
    
    mAqState.mIsRunning = 1;
    OSStatus ret = AudioQueueStart(mAqState.mQueue, NULL);
    
    NSLog(@"Start Record  Path:%@ Ret:%d Channels:%u ChannelsLayoutTag:%u bitmap:%u numberChannelDescriptions:%u",
          self.nsWritePath, ret,
          channels,
           channelLayout.mChannelLayoutTag,
           channelLayout.mChannelBitmap,
           channelLayout.mNumberChannelDescriptions);
}

- (void)stop {
    if (mAqState.mIsRunning == NO) {
        return;
    }
    
    OSStatus ret = AudioQueueStop(mAqState.mQueue, YES);
    if (ret != 0) {
        for(int i = 0; i < kNumberBuffers; i++) {
            AudioQueueFreeBuffer(mAqState.mQueue, mAqState.mBuffers[i]);
        }
    }
    else {
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

@end
