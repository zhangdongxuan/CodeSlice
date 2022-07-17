//
//  AudioPlayService.m
//  AudioQueueService
//
//  Created by disen zhang on 2020/5/6.
//  Copyright © 2020 disen zhang. All rights reserved.
//

#import "AudioPlayer.h"
#import <AVFoundation/AVFoundation.h>

static void HandleOutputCallback(void * __nullable       inUserData,
                                       AudioQueueRef           inAQ,
                                       AudioQueueBufferRef     inBuffer) {
    
    AudioPlayState *mAqState = (AudioPlayState *)inUserData;
    if (mAqState->mIsRunning == false) {
        return;
    }
    
    CGFloat sec = mAqState->mCurrentPacket / mAqState->mPacketPerSec;
    [mAqState->delegate onPlayTimeUpdate:sec];

    NSData *data = [mAqState->mFileHandle readDataOfLength:mAqState->mBufferByteSize];
    UInt32 readBytes = (UInt32)data.length;
    NSLog(@"readBytes:%u", readBytes);
    
    if (readBytes > 0) {
        inBuffer->mAudioDataByteSize = readBytes;
        memcpy(inBuffer->mAudioData, data.bytes, inBuffer->mAudioDataByteSize);
        
        int ret = AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
        if (ret != noErr) {
            NSLog(@"enqueue buffer error");
        }
        
        UInt32 packetCount = readBytes / mAqState->mDataFormat.mBytesPerPacket;
        mAqState->mCurrentPacket += packetCount;
    }
    else {
        
        mAqState->mIsRunning = false;
        AudioQueueStop(inAQ, NO);
        [mAqState->delegate onPlayToEnd];
    }

}

@interface AudioPlayer()

@property(nonatomic, strong) NSString *nsFilePath;

@end

@implementation AudioPlayer

- (instancetype)initWithPCMFile:(NSString *)path delegate:(id<AudioPlayerDelegate>)delegate {
    if (self = [super init]) {
        self.nsFilePath = path;
        
        [self updateSetting];
        mAqState.delegate = delegate;
    }
    
    return self;
}


-(void) updateSetting {
    
    pthread_mutex_init(&mAqState.mQueueMutex, NULL);
    mAqState.mCurrentPacket = 0;
    mAqState.mFileHandle = [NSFileHandle fileHandleForReadingAtPath:self.nsFilePath];
    
    mAqState.mDataFormat.mSampleRate = 16000.0;     //采样率, 1s采集的次数
    mAqState.mDataFormat.mBitsPerChannel = 16;      //在一个数据帧中，每个通道的样本数据的位数。
    mAqState.mDataFormat.mChannelsPerFrame = 1;     //每帧数据通道数(左右声道)
    mAqState.mDataFormat.mFormatID = kAudioFormatLinearPCM; //数据格式 PCM
    mAqState.mDataFormat.mFramesPerPacket = 1;      //每包数据帧数
    mAqState.mDataFormat.mBytesPerFrame = (mAqState.mDataFormat.mBitsPerChannel / 8) * mAqState.mDataFormat.mChannelsPerFrame;
    mAqState.mDataFormat.mBytesPerPacket = mAqState.mDataFormat.mBytesPerFrame * mAqState.mDataFormat.mFramesPerPacket;
    mAqState.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    
    mAqState.mBufferByteSize = AUDIO_PROCESS_PER_TIMES * mAqState.mDataFormat.mSampleRate * (mAqState.mDataFormat.mBitsPerChannel / 8);
    // 每秒的packet数 = 每秒采样的帧数 / 每个packet对应的帧数；
    mAqState.mPacketPerSec = mAqState.mDataFormat.mSampleRate / mAqState.mDataFormat.mFramesPerPacket;
    
    OSStatus ret = AudioQueueNewOutput(&mAqState.mDataFormat, HandleOutputCallback, (void *)&mAqState, NULL, NULL, 0, &mAqState.mQueue);
    NSLog(@"ret:%D", ret);
    
    if (mAqState.mQueue == NULL) {
        NSLog(@"ERROR new out put error");
        return;
    }
    
    for (unsigned int i = 0; i < kNumberBuffers; ++i){
        AudioQueueAllocateBuffer(mAqState.mQueue, mAqState.mBufferByteSize, &mAqState.mBuffers[i]);//此时为buffer分配了内存空间
        AudioQueueEnqueueBuffer(mAqState.mQueue, mAqState.mBuffers[i], 0, NULL);
    }
}

-(BOOL) isPlaying {
    return mAqState.mIsRunning;
}

-(void) play {
    [self playFromOffsetms:0];
}

-(void) stop {
    
    mAqState.mIsRunning = false;
    
    AudioQueueStop(mAqState.mQueue, true);
    AudioQueueDispose(mAqState.mQueue, true);
    mAqState.mQueue = NULL;
}

-(void) pause {
    mAqState.mIsRunning = false;
    AudioQueuePause(mAqState.mQueue);
}

- (void) playFromOffsetms:(UInt32)timems {
    if (mAqState.mQueue == NULL || mAqState.mIsRunning) {
        return;
    }
    
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    timems = timems / 1000 * 1000;
    if(timems != 0) {
        mAqState.mCurrentPacket = timems * mAqState.mPacketPerSec;
        unsigned long long offset = mAqState.mCurrentPacket * mAqState.mDataFormat.mBytesPerPacket;
        [mAqState.mFileHandle seekToFileOffset:offset];
    }
    
    mAqState.mIsRunning = true;
    mAqState.mIsDataOver = false;
    AudioQueueStart(mAqState.mQueue, NULL);
    
    for (int i = 0; i < kNumberBuffers; ++i) {
        HandleOutputCallback(&mAqState, mAqState.mQueue, mAqState.mBuffers[i]);
    }
}

-(void) resume {
    mAqState.mIsRunning = true;
    mAqState.mIsDataOver = false;
    AudioQueueStart(mAqState.mQueue, NULL);
    
    for (int i = 0; i < kNumberBuffers; ++i) {
        HandleOutputCallback(&mAqState, mAqState.mQueue, mAqState.mBuffers[i]);
    }
}

-(float) getCurrentTime {
    float currentSec = mAqState.mCurrentPacket / mAqState.mPacketPerSec;
    return currentSec;
}

@end

