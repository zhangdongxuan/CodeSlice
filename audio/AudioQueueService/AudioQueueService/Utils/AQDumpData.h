//
//  AQDumpData.h
//  AudioQueueService
//
//  Created by disen zhang on 2020/6/17.
//  Copyright © 2020 disen zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AQDumpData : NSObject

+ (void)dumpActualData:(const char *)des data:(uint8_t *)data dumpLen:(int)dumpLen;

@end

NS_ASSUME_NONNULL_END
