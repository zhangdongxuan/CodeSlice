//
//  AudioPlayer.h
//  AudioPlayer
//
//  Created by disen zhang on 2020/5/6.
//  Copyright © 2020 disen zhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioServiceDefine.h"

NS_ASSUME_NONNULL_BEGIN


@protocol AudioPlayerDelegate <NSObject>

-(void) onPlayToEnd;
-(void) onPlayTimeUpdate:(float)time;

@end


@interface AudioPlayer : NSObject {
    
    @public
    AudioPlayState mAqState;
}

- (instancetype)initWithPCMFile:(NSString *)path delegate:(id<AudioPlayerDelegate>)delegate;

-(void) play;
-(void) pause;
-(void) stop;
-(void) resume;
-(void) playFromOffsetms:(UInt32)timems;

-(float) getCurrentTime;

-(BOOL) isPlaying;

@end

NS_ASSUME_NONNULL_END
