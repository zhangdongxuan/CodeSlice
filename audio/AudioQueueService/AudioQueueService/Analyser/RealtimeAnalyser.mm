//
//  RealtimeAnalyser.m
//  AudioQueueService
//
//  Created by disen zhang on 2020/6/16.
//  Copyright © 2020 disen zhang. All rights reserved.
//

#import "RealtimeAnalyser.h"
#import <Accelerate/Accelerate.h>
#import "AudioBandsInfo.h"

#define InputBufferSize 2048 * 2
#define AUDIO_BIT_LEN 16

static constexpr double kSmoothingTimeConstant = 0.65;

@interface RealtimeAnalyser () {
    FFTSetup _fftSetup;

    Float32 *_inputBuffer;
    Float32 *_hannwindow;
    Float32 *_amplitudes;

    Float32 *_realData;
    Float32 *_imagData;
    DSPSplitComplex _frame;

    //创建权重数组
    Float32 *_loudnessWeights;
    Float32 *_spectrum;
}

@property (nonatomic, assign) UInt32 fftSize;
@property (nonatomic, assign) UInt32 log2FFTSize;

@property (atomic, assign) BOOL bDenyWriteData;

@property (atomic, assign) UInt32 circleHeadIndex;
@property (atomic, assign) UInt32 circleTailIndex;
@property (atomic, assign) UInt32 bufferLength;

@property (nonatomic, assign) UInt32 amplitudeLevel;
@property (nonatomic, assign) BOOL shouldDoFFTAnalysis;

@property (nonatomic, assign) float minFrequency;
@property (nonatomic, assign) float maxFrequency;

@property (nonatomic, strong) NSMutableArray *arrFrequencyBands;
@property (nonatomic, strong) dispatch_queue_t processQueue;

@end

@implementation RealtimeAnalyser

- (instancetype)init {
    self = [super init];
    if (self) {
        _circleHeadIndex = 0;
        _circleTailIndex = 0;
        _bufferLength = 0;
        
        _amplitudeLevel = 50;
        _minFrequency = 60;
        _maxFrequency = 9000;
        _arrFrequencyBands = [NSMutableArray array];
        _spectrum = NULL;
        _loudnessWeights = NULL;
        _processQueue = dispatch_queue_create("Audio_Rcord_Analyser", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (instancetype)initWithFFTSize:(UInt32)fftSize sampleRate:(UInt32)sampleRate {
    self = [self init];
    if (self) {
        _fftSize = fftSize;
        _log2FFTSize = static_cast<unsigned>(log2(_fftSize));
        _fftSetup = vDSP_create_fftsetup(_log2FFTSize, FFT_RADIX2);

        _inputBuffer = (Float32 *)malloc(InputBufferSize * sizeof(Float32));

        _hannwindow = (Float32 *)malloc(_fftSize * sizeof(Float32));
        vDSP_hann_window(_hannwindow, (vDSP_Length)(_fftSize), vDSP_HANN_NORM);

        _realData = (Float32 *)malloc(_fftSize / 2 * sizeof(Float32));
        _imagData = (Float32 *)malloc(_fftSize / 2 * sizeof(Float32));

        _frame.realp = _realData;
        _frame.imagp = _imagData;

        _amplitudes = (Float32 *)malloc(_fftSize / 2 * sizeof(Float32));

        [self updateSampleRate:sampleRate];
    }

    return self;
}

- (void)dealloc {
    _bDenyWriteData = YES;

    if (_realData != NULL) {
        free(_realData);
        _realData = NULL;
    }

    if (_imagData != NULL) {
        free(_imagData);
        _imagData = NULL;
    }

    if (_inputBuffer != NULL) {
        free(_inputBuffer);
        _inputBuffer = NULL;
    }

    if (_hannwindow != NULL) {
        free(_hannwindow);
        _hannwindow = NULL;
    }

    if (_amplitudes != NULL) {
        free(_amplitudes);
        _amplitudes = NULL;
    }

    if (_spectrum != NULL) {
        free(_spectrum);
        _spectrum = NULL;
    }

    if (_loudnessWeights != NULL) {
        free(_loudnessWeights);
        _loudnessWeights = NULL;
    }

    vDSP_destroy_fftsetup(_fftSetup);
}

/**
 https://zh.wikipedia.org/wiki/響度
 对人类听觉来说，愈高的声压或声强[注 1]，会造成愈大的听觉感知。而在人类的可听频率范围（20 Hz 到 20 000 Hz）中，由于听觉对 3 000 Hz 左右的声音较为敏感，该段频率也能造成较大的听觉感知。
 首先对声音频率和听觉感知进行量化研究的，是美国的物理学家哈维·弗莱彻。1933年，他和蒙森以纯音作实验，找出不同频率和声压的组合，使得声音能造成相同的听觉感知。他们将结果画成曲线，称为弗莱彻－蒙森曲线（Fletcher–Munson curves）。

 */
- (void)initWeightings {
    float Δf = 1.0 * _sampleRate / _fftSize;
    int length = _fftSize;

    if (_loudnessWeights != NULL) {
        free(_loudnessWeights);
    }

    float value = 1;

    _loudnessWeights = (Float32 *)malloc(length * sizeof(Float32));
    vDSP_vfill(&value, _loudnessWeights, 1, length);

    //  (12194 * x^2)^2 / (x^2 + 20.6^2) / (x^2 + 12194^2) / sqrt((x^2 + 107.7^2) * (x^2 + 737.9^2))
    //   https://en.wikipedia.org/wiki/A-weighting#B

    float c1 = powf(12194, 2.0);
    float c2 = powf(20.6, 2.0);
    float c3 = powf(107.7, 2.0);
    float c4 = powf(737.9, 2.0);

    for (int i = 0; i < length; i++) {
        float f = powf(Δf * i, 2);
        float num = c1 * powf(f, 2);
        float den = (f + c2) * sqrtf((f + c3) * (f + c4)) * (f + c1);
        float Raf = num / den;
        float weights = 1.2589 * Raf;
        _loudnessWeights[i] = weights;
    }
}

#pragma mark - Public
- (void)updateSampleRate:(UInt32)sampleRate {
    _sampleRate = sampleRate;
    [self initWeightings];
    [self updateFrequencyBandsCount:_bandsCount];
}

/** 根据FFT的原理， N个音频信号样本参与计算将产生 N/2 个数据（2048/2=1024），其频率分辨率△f= Fs / N = 44100 / 2048 ≈ 21.5hz，而相邻数据的频率间隔是一样的，因此这1024个数据分别代表频率在0hz、21.5hz、43.0hz....22050hz下的振幅。
 奈奎斯特(nyquist)采样定理:  为了不失真地恢复模拟信号，采样频率应该不小于模拟信号频谱中最高频率的2倍。因此我们能采集到的最大频率是 max frequency = sample rate / 2;  根据心理声学，人耳能容易的分辨出100hz和200hz的音调不同，但是很难分辨出8100hz和8200hz的音调不同，尽管它们各自都是相差100hz，
 可以说频率和音调之间的变化并不是呈线性关系，而是某种对数的关系。
 */
- (void)updateFrequencyBandsCount:(UInt32)bandsCount {
    if (_arrFrequencyBands.count == bandsCount) {
        return;
    }

    _bandsCount = bandsCount;

    if (_spectrum != NULL) {
        free(_spectrum);
        _spectrum = NULL;
    }

    //https://juejin.cn/post/6844903784011792391
    NSMutableArray *arrFrequencyBands = [NSMutableArray array];

    //1：根据起止频谱、频带数量确定增长的倍数：2^n   log2x的意思就是求x是2的多少次幂.
    float n = log2f(_maxFrequency / _minFrequency) / bandsCount;

    float lowerFrequency = _minFrequency;
    float upperFrequency = _minFrequency;
    float bandWidth = 1.0 * _sampleRate / _fftSize;

    for (int i = 0; i < bandsCount; i++) {
        upperFrequency = lowerFrequency * powf(2, n);
        if (i == bandsCount - 1) {
            upperFrequency = _maxFrequency;
        }

        AudioBandsInfo *brandInfo = [AudioBandsInfo createWith:lowerFrequency upperFrequency:upperFrequency bandWidth:bandWidth];
        [arrFrequencyBands addObject:brandInfo];

        lowerFrequency = upperFrequency;
    }

    _arrFrequencyBands = arrFrequencyBands;
}

- (void)onRecievePcmData:(NSData *)rawData frameCount:(UInt32)frameCount {
    __weak typeof(self) weakSelf = self;
    dispatch_async(_processQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;

        float fft_data[frameCount];
        short *pcmbuffer = (short *)rawData.bytes;

        vDSP_vflt16(pcmbuffer, 1, fft_data, 1, frameCount);
        float scalar = 1.0 / (1 << (AUDIO_BIT_LEN - 1));
        vDSP_vsmul(fft_data, 1, &scalar, fft_data, 1, frameCount);

        [strongSelf writeInput:fft_data audioFrameCount:frameCount];
    });
}

- (void)cleanCacheData {
    _circleHeadIndex = 0;
    _bufferLength = 0;
}

- (void)writeInput:(float *)rawData audioFrameCount:(UInt32)framesToProcess {
    _shouldDoFFTAnalysis = NO;

    float *dest = _inputBuffer + _circleHeadIndex;
    float *source = rawData;

    // Then save the result in the _inputBuffer at the appropriate place.
    if (_circleHeadIndex + framesToProcess > InputBufferSize) {
        int length = InputBufferSize - _circleHeadIndex;
        memcpy(dest, source, sizeof(float) * length);

        dest = _inputBuffer;
        source = rawData + length;
        length = framesToProcess - length;
        memcpy(dest, source, sizeof(float) * length);
        _circleHeadIndex = length;

    } else {
        memcpy(dest, source, sizeof(float) * framesToProcess);

        _circleHeadIndex += framesToProcess;
        if (_circleHeadIndex == InputBufferSize) {
            _circleHeadIndex = 0;
        }
    }

    _bufferLength += framesToProcess;
    NSLog(@"_writeLength:%u", _bufferLength);

    // A new render quantum has been processed so we should do the FFT analysis again.
    _shouldDoFFTAnalysis = YES;
}

- (void)getFloatFrequencWithBands:(UInt32)count completion:(void (^)(NSData *spectrum))completion {
    if (_bDenyWriteData) {
        completion(NULL);
        return;
    }

    __weak typeof(self) weakSelf = self;
    dispatch_async(_processQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf updateFrequencyBandsCount:count];
        BOOL ret = [strongSelf doFFTAnalysisIfNecessary];

        if (ret && strongSelf->_spectrum) {
            NSData *data = [NSData dataWithBytes:strongSelf->_spectrum length:sizeof(float) * count];
            completion(data);
        } else {
            completion(nil);
        }
    });
}

#pragma mark - Private
/**
 FFT变换完：
 第一个数是0Hz频率，0Hz就是没有波动，没有波动有个专业一点的说法，叫直流分量。

 第二个数，对应的频率是0Hz+频谱分辨率，每隔一个加一次，频谱分辨率Δf计算公式如下：
 Δf=Fs/N
 式中：
 Fs为采样频率
 N为FFT的点数
 因此只要Fs和N定了，频域就定下来了。
 https://blog.csdn.net/seekyong/article/details/104434128
 */
- (BOOL)doFFTAnalysisIfNecessary {
    if (_bDenyWriteData) {
        return NO;
    }

    NSLog(@"_shouldDoFFTAnalysis:%u", _shouldDoFFTAnalysis);
    if (_shouldDoFFTAnalysis == NO) {
        return NO;
    }

    // Unroll the input buffer into a temporary buffer, where we'll apply an analysis window followed by an FFT.
    int fftSize = self.fftSize;
    if (_bufferLength < fftSize) {
        return NO;
    }

    // Take the previous fftSize values from the input buffer and copy into the temporary buffer.
    float *inputBuffer = _inputBuffer;
    float *tempP = (float *)malloc(fftSize * sizeof(float));
    UInt32 tailLength = InputBufferSize - _circleTailIndex;
    
    if (tailLength < fftSize) {
        memcpy(tempP, inputBuffer + _circleTailIndex, sizeof(float) * (tailLength));
        memcpy(tempP + tailLength, inputBuffer, sizeof(float) * (fftSize - tailLength));
        
        _circleTailIndex = fftSize - tailLength;
    } else {
        memcpy(tempP, inputBuffer + _circleTailIndex, sizeof(float) * fftSize);
        _circleTailIndex += fftSize;
    }

    // 减去被消耗缓冲
    _bufferLength -= fftSize;
    
    // Window the input samples.
    vDSP_vmul(tempP, 1, _hannwindow, 1, tempP, 1, fftSize);

    int halfSize = fftSize / 2;

    float value = 0;
    vDSP_vfill(&value, _frame.imagp, 1, fftSize / 2);
    vDSP_vfill(&value, _frame.realp, 1, fftSize / 2);

    vDSP_ctoz(reinterpret_cast<const DSPComplex *>(tempP), 2, &_frame, 1, halfSize);

    free(tempP);

    // Perform the FFT via Accelerate
    // Use FFT forward for standard PCM audio
    // n位样本数据（n/2位复数）进行fft计算会得到n/2+1位复数结果：{[DC,0],C[2],...,C[n/2],[NY,0]}    (其中DC是直流分量，NY是奈奎斯特频率的值,C是复数数组)，其中[DC,0]和[NY,0]的虚部都是0，所以可以将NY放到DC中的虚部中，其结果变成{[DC,NY],C[2],C[3],...,C[n/2]}，与输入位数一致。
    vDSP_fft_zrip(_fftSetup, &_frame, 1, _log2FFTSize, FFT_FORWARD);

    // Blow away the packed nyquist component.
    _frame.imagp[0] = 0;

    // Normalize so than an input sine wave at 0dBfs registers as 0dBfs (undo FFT scaling factor).
    //    https://blog.csdn.net/seekyong/article/details/104434128
    //    https://zhuanlan.zhihu.com/p/137433994   当输入样点数据为复数时除以N
    float magnitudeScale = 1.0 / fftSize;

    // To provide the best possible execution speeds, the vDSP library's functions don't always adhere strictly
    // to textbook formulas for Fourier transforms, and must be scaled accordingly.
    // (See https://developer.apple.com/library/archive/documentation/Performance/Conceptual/vDSP_Programming_Guide/UsingFourierTransforms/UsingFourierTransforms.html#//apple_ref/doc/uid/TP40005147-CH3-SW5)
    // In the case of a Real forward Transform like above: RFimp = RFmath * 2 so we need to divide the output
    // by 2 to get the correct value.
    //http://pkmital.com/home/2011/04/14/real-fftifft-with-the-accelerate-framework/

    magnitudeScale = magnitudeScale / 2;

    vDSP_vsmul(_frame.realp, 1, &magnitudeScale, _frame.realp, 1, halfSize);
    vDSP_vsmul(_frame.imagp, 1, &magnitudeScale, _frame.imagp, 1, halfSize);

    vDSP_vfill(&value, _amplitudes, 1, halfSize);

    //Take the absolute value of the output to get in range of 0 to 1
    vDSP_zvabs(&_frame, 1, _amplitudes, 1, halfSize);

    //直流分量的振幅需要再除以2
    _amplitudes[0] = _amplitudes[0] / 2;

    [self processAmplitudes];

    _shouldDoFFTAnalysis = NO;

    return YES;
}

- (void)processAmplitudes {
    if (_bDenyWriteData) {
        return;
    }

    int length = _fftSize / 2;

    // 添加声响权重
    vDSP_vmul(_amplitudes, 1, _loudnessWeights, 1, _amplitudes, 1, length);

    //3: findMaxAmplitude函数将从新的`weightedAmplitudes`中查找最大值
    Float32 *spectrum = (Float32 *)malloc(_bandsCount * sizeof(Float32));

    for (int i = 0; i < _bandsCount; i++) {
        AudioBandsInfo *brandInfo = [_arrFrequencyBands objectAtIndex:i];
        float maxAmplitude = [brandInfo getMaxAmplitude:_amplitudes length:length];
        float result = maxAmplitude * _amplitudeLevel; //amplitudeLevel 调整动画幅度
        spectrum[i] = result;
    }

    [self smoothHorizontalSpectrum:spectrum length:_bandsCount];
    [self smoothVerticalSpectrum:spectrum length:_bandsCount];

    if (_spectrum != NULL) {
        free(_spectrum);
    }

    _spectrum = spectrum;
}

- (void)smoothVerticalSpectrum:(float *)spectrum length:(int)length {
    if (_spectrum == NULL) {
        return;
    }

    for (int i = 0; i < length; i++) {
        float oldVal = _spectrum[i];
        float newVal = spectrum[i];
        spectrum[i] = oldVal * kSmoothingTimeConstant + newVal * (1.0 - kSmoothingTimeConstant);
    }
}

// 使用加权平均解决锯齿过多
- (void)smoothHorizontalSpectrum:(float *)spectrum length:(int)length {
    int count = 3;
    float weights[] = { 1, 4, 1 };

    float totalWeights = 0;
    for (int i = 0; i < count; i++) {
        totalWeights += weights[i];
    }

    int startIndex = count / 2;

    for (int i = startIndex; i < length - count; i++) {
        float total = 0;
        for (int j = 0; j < count; j++) {
            total += spectrum[i + j] * weights[j];
        }

        float averaged = total / totalWeights;
        spectrum[i] = averaged;
    }
}

@end
