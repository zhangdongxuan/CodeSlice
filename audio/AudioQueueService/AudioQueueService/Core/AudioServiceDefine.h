//
//  AudioServiceDefine.h
//  AudioQueueService
//
//  Created by disen zhang on 2020/5/6.
//  Copyright © 2020 disen zhang. All rights reserved.
//

#ifndef AudioServiceDefine_h
#define AudioServiceDefine_h

#import <AudioToolbox/AudioToolbox.h>
#include <pthread.h>

#define kNumberBuffers 3

#define AUDIO_PROCESS_FFT_SIZE 1024
#define AUDIO_SAMPLE_RATE 16000
#define AUDIO_PROCESS_PER_TIMES (AUDIO_PROCESS_FFT_SIZE / AUDIO_SAMPLE_RATE)

#define AUDIO_BIT_LEN 16

typedef struct AudioRecordState {
    AudioStreamBasicDescription mDataFormat;
    AudioQueueRef mQueue;
    AudioQueueBufferRef mBuffers[kNumberBuffers];
    AudioFileID mAudioFile;
    UInt32 bufferByteSize;
    /* ---------- status ----------------- */
    bool mIsRunning;
    pthread_mutex_t mQueueMutex;
    UInt32 mCurrentPacket;
    NSInputStream *mInputStream;

} AudioRecordState;

typedef struct AudioPlayState {
    AudioStreamBasicDescription mDataFormat;
    AudioQueueRef mQueue;
    AudioQueueBufferRef mBuffers[kNumberBuffers];
    AudioFileID mAudioFile;
    UInt32 mBufferByteSize;
    UInt32 mPacketPerSec;
    /* ---------- status ----------------- */
    bool mIsRunning; /* AudioQueue的运行状态，可作为不精确的播放状态 */
    bool mIsDataOver; /* 数据处理结束 */
    bool mIsPlayOver; /* 播放正常结束 */

    pthread_mutex_t mQueueMutex;
    UInt32 mCurrentPacket;
    NSInputStream *mInputStream;
    NSFileHandle *mFileHandle;
    id delegate;

} AudioPlayState;

#endif /* AudioServiceDefine_h */
