//
//  AudioRecorderFFT.m
//  AudioQueueService
//
//  Created by disen zhang on 2020/6/16.
//  Copyright © 2020 disen zhang. All rights reserved.
//

#import "AudioRecorderAnalyzer.h"
#import <Accelerate/Accelerate.h>
#import "AQDumpData.h"

@interface AudioBandsInfo : NSObject

@property (nonatomic, assign) float lowerFrequency;
@property (nonatomic, assign) float upperFrequency;

@end

@implementation AudioBandsInfo

+ (instancetype)createWith:(float)lowerFrequency upperFrequency:(float)upperFrequency {
    AudioBandsInfo *info = [[AudioBandsInfo alloc] init];
    info.lowerFrequency = lowerFrequency;
    info.upperFrequency = upperFrequency;
    return info;
}

@end


@interface AudioRecorderAnalyzer ()

@property (nonatomic, assign) UInt32 fftSize;
@property (nonatomic, assign) UInt32 sampleRate;
@property (nonatomic, assign) UInt32 amplitudeLevel;

@property (nonatomic, assign) float spectrumSmooth;

/** 频带数量 */
@property (nonatomic, assign) NSUInteger frequencyBands;
/** 起始帧率 */
@property (nonatomic, assign) float startFrequency;
/** 截止帧率 */
@property (nonatomic, assign) float endFrequency;

@property (nonatomic, strong) NSMutableArray *spectrumBuffer;
@property (nonatomic, strong) NSArray *aWeights;
@property (nonatomic, strong) NSArray *bands;


@end


@implementation AudioRecorderAnalyzer


- (instancetype)initWithFFTSize:(UInt32)fftSize sampleRate:(UInt32)sampleRate {
    self = [super init];
    if (self) {
        self.fftSize = fftSize;
        self.sampleRate = sampleRate;
        
        [self initData];
    }
    
    return self;
}


- (void)dealloc {
//    vDSP_destroy_fftsetup(_fft);
}

- (void)initData {
    self.frequencyBands = 80;
    self.startFrequency = 100.0;
    self.endFrequency = 18000.0;
    self.spectrumSmooth = 0.5; //缓动系数，数值越大动画越"缓"
    self.amplitudeLevel = 25;

    
//    self.fftSetup = vDSP_create_fftsetup((vDSP_Length)(round(log2(self.fftSize))), kFFTRadix2);
    
    self.spectrumBuffer = [NSMutableArray array];
    for (int j = 0; j < self.frequencyBands; j++) {
        [self.spectrumBuffer addObject: [NSNumber numberWithFloat:0.0]];
    }
    
    NSMutableArray *tmps = [NSMutableArray array];
    
    
    //1：根据起止频谱、频带数量确定增长的倍数：2^n
    float n = log2f(self.endFrequency / self.startFrequency) / (self.frequencyBands * 1.0);
    
    AudioBandsInfo *first = [AudioBandsInfo createWith:self.startFrequency upperFrequency:0];
    for (int i = 1; i <= self.frequencyBands; i++) {
        float highFrequency = first.lowerFrequency * powf(2, n);
        float upperFrequency = i == self.frequencyBands ? self.endFrequency : highFrequency;
        first.upperFrequency = upperFrequency;
        [tmps addObject:[AudioBandsInfo createWith:first.lowerFrequency upperFrequency:first.upperFrequency]];
        first.lowerFrequency = highFrequency;
    }
    self.bands = [NSArray arrayWithArray:tmps];
    
    //创建权重数组
    self.aWeights = [self createFrequencyWeights];
}
#pragma mark - override getter or setter
- (void)setSpectrumSmooth:(float)spectrumSmooth {
    _spectrumSmooth = MAX(0.0, spectrumSmooth);
    _spectrumSmooth = MIN(1.0, _spectrumSmooth);
}

#pragma mark - privte method
- (float)findMaxAmplitude:(AudioBandsInfo *)band amplitudes:(NSArray *)amplitudes bandWidth:(float)bandWidth {
    NSUInteger amplitudesCount = amplitudes.count;
    NSUInteger startIndex = (NSUInteger)(round(band.lowerFrequency / bandWidth));
    NSUInteger endIndex = MIN((NSUInteger)(round(band.upperFrequency / bandWidth)), amplitudesCount - 1);
    if (startIndex >= amplitudesCount || endIndex >= amplitudesCount) return 0;
    if ((endIndex - startIndex) == 0) {
        return [amplitudes[startIndex] floatValue];
    }
    NSMutableArray *tmps = [NSMutableArray array];
    for (NSUInteger i = startIndex; i <= endIndex; i++) {
        [tmps addObject:[amplitudes[i] copy]];
    }
    NSNumber *max = [tmps valueForKeyPath:@"@max.self"];
    return max.floatValue;
}

- (NSArray *)createFrequencyWeights {
    float Δf = self.sampleRate / (float)self.fftSize;
    int bins = self.fftSize;
    
    float f[bins];
    for (int i = 0; i < bins; i++) {
        f[i] = (1.0 * i ) * Δf;
        f[i] = f[i] * f[i];
    }
    
    float c1 = powf(12194.217, 2.0);
    float c2 = powf(20.598997, 2.0);
    float c3 = powf(107.65265, 2.0);
    float c4 = powf(737.86223, 2.0);
    
    float num[bins];
    float den[bins];
    NSMutableArray *weightsArray = [NSMutableArray arrayWithCapacity:bins];
    for (int i = 0; i < bins; i++) {
        num[i] = c1 * f[i] * f[i];
        den[i] = (f[i] + c2) * sqrtf((f[i] + c3) * (f[i] + c4)) * (f[i] + c1);
        float weights = 1.2589 * num[i] / den[i];
        [weightsArray addObject: [NSNumber numberWithFloat:weights]];
    }
    return weightsArray.copy;
}

//使用加权平均, 消除锯齿过多，使波形更明显
- (NSMutableArray *)highlightWaveform:(NSArray *)spectrum {
    //1: 定义权重数组，数组中间的5表示自己的权重
    //   可以随意修改，个数需要奇数
    int weightsCount = 7;
    float weights[] = {1, 2, 3, 5, 3, 2, 1};
    float totalWeights = 0;
    for (int i = 0; i < weightsCount; i++) {
        totalWeights += weights[i];
    }
    int startIndex = weightsCount / 2;
    //2: 开头几个不参与计算
    NSMutableArray *averagedSpectrum = [NSMutableArray array];
    
    NSUInteger spectrumCount = spectrum.count;
    for (NSUInteger i = 0; i < startIndex; i++) {
        [averagedSpectrum addObject:spectrum[i]];
    }
    
    for (int i = startIndex; i < (spectrumCount - startIndex); i++) {
        //3: zip作用: zip([a,b,c], [x,y,z]) -> [(a,x), (b,y), (c,z)]
        int count = MIN(((i + startIndex) - (i - startIndex) + 1), weightsCount);
        int zipOneIdx = (i - startIndex);
        float total = 0;
        for (int j = 0; j < count; j++) {
            total += [spectrum[zipOneIdx] floatValue] * weights[j];
            zipOneIdx++;
        }
        float averaged = total / totalWeights;
        [averagedSpectrum addObject: [NSNumber numberWithFloat:averaged]];
        
    }
    //4：末尾几个不参与计算
    NSUInteger idx = (spectrumCount - startIndex);
    for (NSUInteger i = idx; i < spectrumCount; i++) {
        [averagedSpectrum addObject:spectrum[i]];
    }
    return averagedSpectrum;
}


- (NSMutableArray *)analysisAmplitudesWithPCMData:(float *)rawData audioFrameCount:(UInt32)frameCount {
    NSMutableArray *arrAmplitudes = [self fft:rawData frameCount:frameCount];

    NSUInteger subCount = arrAmplitudes.count;
    NSMutableArray *weightedAmplitudes = [NSMutableArray array];
    for (NSUInteger j = 0; j < subCount; j++) {
        //2：原始频谱数据依次与权重相乘
        float weighted = [arrAmplitudes[j] floatValue] * [self.aWeights[j] floatValue];
        [weightedAmplitudes addObject: [NSNumber numberWithFloat:weighted]];
    }

    //3: findMaxAmplitude函数将从新的`weightedAmplitudes`中查找最大值
    NSMutableArray *spectrum = [NSMutableArray array];
    for (int t = 0; t < self.frequencyBands; t++) {
        float bandWidth = self.sampleRate * 1.0 / self.fftSize;
        float result = [self findMaxAmplitude:self.bands[t] amplitudes:weightedAmplitudes.copy bandWidth:bandWidth] * self.amplitudeLevel; //amplitudeLevel 调整动画幅度
        [spectrum addObject: [NSNumber numberWithFloat:result]];
    }

    //4：添加到数组之前调用highlightWaveform
    spectrum = [self highlightWaveform:spectrum];

    for (int t = 0; t < self.frequencyBands; t++) {
        float oldVal = [self.spectrumBuffer[t] floatValue];
        float newVal = [spectrum[t] floatValue];
        float result = oldVal * self.spectrumSmooth + newVal * (1.0 - self.spectrumSmooth);
        self.spectrumBuffer[t] = [NSNumber numberWithFloat:(isnan(result) ? 0 : result)];
    }
    
    return [self.spectrumBuffer copy];
}

-(NSMutableArray *)analysisAmplitudesWithAmplitudes:(NSMutableArray *)arrAmplitudes {
    
    NSUInteger subCount = arrAmplitudes.count;
    NSMutableArray *weightedAmplitudes = [NSMutableArray array];
    for (NSUInteger j = 0; j < subCount; j++) {
        //2：原始频谱数据依次与权重相乘
        float weighted = [arrAmplitudes[j] floatValue] * [self.aWeights[j] floatValue];
        [weightedAmplitudes addObject: [NSNumber numberWithFloat:weighted]];
    }

    //3: findMaxAmplitude函数将从新的`weightedAmplitudes`中查找最大值
    NSMutableArray *spectrum = [NSMutableArray array];
    for (int t = 0; t < self.frequencyBands; t++) {
        float bandWidth = self.sampleRate * 1.0 / self.fftSize;
        float result = [self findMaxAmplitude:self.bands[t] amplitudes:weightedAmplitudes.copy bandWidth:bandWidth] * self.amplitudeLevel; //amplitudeLevel 调整动画幅度
        [spectrum addObject: [NSNumber numberWithFloat:result]];
    }

    //4：添加到数组之前调用highlightWaveform
    spectrum = [self highlightWaveform:spectrum];

    for (int t = 0; t < self.frequencyBands; t++) {
        float oldVal = [self.spectrumBuffer[t] floatValue];
        float newVal = [spectrum[t] floatValue];
        float result = oldVal * self.spectrumSmooth + newVal * (1.0 - self.spectrumSmooth);
        self.spectrumBuffer[t] = [NSNumber numberWithFloat:(isnan(result) ? 0 : result)];
    }
    
    return [self.spectrumBuffer copy];
}




-(NSMutableArray *)fft:(float *)buffer frameCount:(UInt32)frameCount {
    
    vDSP_Length log2n = round(log2(frameCount));
    FFTSetup fftsetup = vDSP_create_fftsetup(log2n,  kFFTRadix2);

    float window[frameCount];
    vDSP_hann_window(window, (vDSP_Length)(frameCount), vDSP_HANN_NORM);
    vDSP_vmul(buffer, 1, window, 1, buffer, 1, frameCount);
    
    int length = frameCount / 2;
    float outReal[length];
    float outImaginary[length];
    
    float value = 0;
    vDSP_vfill(&value, outReal, 1, length);
    vDSP_vfill(&value, outImaginary, 1, length);

    COMPLEX_SPLIT output = { .realp = outReal, .imagp = outImaginary };
    
    //Put all of the even numbered elements into outReal and odd numbered into outImaginary
    vDSP_ctoz((COMPLEX *)buffer, 2, &output, 1, length);
    
//    [AQDumpData dumpActualData:"output" data:(uint8_t *)output.imagp dumpLen:sizeof(float) / sizeof(uint8_t) * length];
    
    //Perform the FFT via Accelerate
    //Use FFT forward for standard PCM audio
    vDSP_fft_zrip(fftsetup, &output, 1, log2n, FFT_FORWARD);
    
    //Scale the FFT data
    float fftNormFactor = 1.0 / (frameCount);
    
    output.imagp[0] = 0;
    
    vDSP_vsmul(output.realp, 1, &fftNormFactor, output.realp, 1, length);
    vDSP_vsmul(output.imagp, 1, &fftNormFactor, output.imagp, 1, length);
    
    float amplitudes[length];
    vDSP_vfill(&value, amplitudes, 1, length);
    
    //Take the absolute value of the output to get in range of 0 to 1
    //vDSP_zvabs(&output, 1, frequencyData, 1, numberOfFramesOver2);
    vDSP_zvabs(&output, 1, amplitudes, 1, length);
    
    //直流分量的振幅需要再除以2
    amplitudes[0] = amplitudes[0] / 2;
    
//        [AQDumpData dumpActualData:"fft result" data:(uint8_t *)_frequencyData dumpLen:sizeof(float) / sizeof(uint8_t) * length];
    
    vDSP_destroy_fftsetup(fftsetup);
    
    NSMutableArray *arrAmplitudes = [NSMutableArray arrayWithCapacity:length];
    for (int i = 0; i < length; i ++) {
        float value = amplitudes[i];
        [arrAmplitudes addObject:@(value)];
    }
    

    return arrAmplitudes;
}

@end

