//
//  AudioSpectrumRecorder.m
//  AudioSpectrumDemo
//
//  Created by user on 2019/5/21.
//  Copyright © 2019 adu. All rights reserved.
//

#import "AudioSpectrumRecorder.h"
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>
#import "RealtimeAnalyzer.h"

@interface AudioSpectrumRecorder ()

@property (nonatomic,strong) AVAudioEngine *engine;
@property (nonatomic, strong) RealtimeAnalyzer *analyzer;
@property (nonatomic, assign) int bufferSize;

@end

@implementation AudioSpectrumRecorder

- (instancetype)init {
    if (self = [super init]) {
        [self configInit];
        [self setupRecorder];
    }
    return self;
}

- (void)configInit {
    self.bufferSize = 2048;
    self.analyzer = [[RealtimeAnalyzer alloc] initWithFFTSize:self.bufferSize];
}

- (void)setupRecorder {
    AVAudioInputNode *inputNode = self.engine.inputNode;
    AVAudioMixerNode *mixerNode = self.engine.mainMixerNode;
    
    AVAudioFormat *inputFormat = [inputNode inputFormatForBus:0];
    const AudioStreamBasicDescription *streamDescription = inputFormat.streamDescription;
    
    UInt32 mBitsPerChannel = streamDescription->mBitsPerChannel;
    UInt32 mSampleRate = streamDescription->mSampleRate;
    UInt32 mChannelsPerFrame = streamDescription->mChannelsPerFrame;
    AudioFormatFlags mFormatFlags = streamDescription->mFormatFlags;
    
//    streamDescription->mFormatFlags = kLinearPCMFormatFlagIsFloat | kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsNonInterleaved;
    
    [self.engine connect:inputNode to:mixerNode format:inputFormat];
    //在添加tap之前先移除上一个  不然有可能报"Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio',"之类的错误
    [mixerNode removeTapOnBus:0];
    
    
    AVAudioFormat *mixerNodeFormat = [mixerNode outputFormatForBus:0];
    streamDescription = mixerNodeFormat.streamDescription;
    mBitsPerChannel = streamDescription->mBitsPerChannel;
    mSampleRate = streamDescription->mSampleRate;
    mFormatFlags = streamDescription->mFormatFlags;
    mChannelsPerFrame = streamDescription->mChannelsPerFrame;
    
//    [mixerNode installTapOnBus:0 bufferSize:self.bufferSize format:mixerNodeFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
//       
//        buffer.frameLength = self.bufferSize;
//        NSArray *spectrums = [self.analyzer analyse:buffer withAmplitudeLevel:25];
//        
////        NSLog(@"spectrums:%@", spectrums);
//        
//        if ([self.delegate respondsToSelector:@selector(recorderDidGenerateSpectrum:)]) {
//            [self.delegate recorderDidGenerateSpectrum:spectrums];
//        }
//    }];
    
    [inputNode installTapOnBus:0 bufferSize:self.bufferSize format:inputFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
       
        buffer.frameLength = self.bufferSize;
        NSArray *spectrums = [self.analyzer analyse:buffer withAmplitudeLevel:25];
        
//        NSLog(@"spectrums:%@", spectrums);
        
        if ([self.delegate respondsToSelector:@selector(recorderDidGenerateSpectrum:)]) {
            [self.delegate recorderDidGenerateSpectrum:spectrums];
        }
    }];
    
}


- (void)startRecord {
    [self.engine prepare];
    [self.engine startAndReturnError:nil];
}

- (void)stop {
    [self.engine stop];
}

- (AVAudioEngine *)engine {
    if (!_engine) {
        _engine = [[AVAudioEngine alloc] init];
    }
    return _engine;
}


@end
