//
//  AQDumpData.m
//  AudioQueueService
//
//  Created by disen zhang on 2020/6/17.
//  Copyright © 2020 disen zhang. All rights reserved.
//

#import "AQDumpData.h"

#define DUMP_DATA_MAX_LEN 100
#define DUMA_BUFFER_MAX_SIZE 4096
#define DUMP_DATA "DUMP_DATA"

@implementation AQDumpData

+ (void)dumpActualData:(const char *)des data:(uint8_t *)data dumpLen:(int)dumpLen {
    char buf[DUMA_BUFFER_MAX_SIZE] = { 0 };
    int i = 0;
    int len;
    int offset = 0;

    if (!data || (dumpLen <= 0)) {
        printf("dump data failed, data is nil or len is not match data:%p len:%d\n", data, dumpLen);
        return;
    }

    len = MIN(DUMP_DATA_MAX_LEN, dumpLen);

    for (i = 0; i < len; i++) {
        if (i % 16 == 0)
            offset += snprintf(buf + offset, (DUMA_BUFFER_MAX_SIZE - 1), "\n%2x ", data[i]);
        else
            offset += snprintf(buf + offset, (DUMA_BUFFER_MAX_SIZE - 1), "%2x ", data[i]);
    }
    printf("%s, dump data: %s \n", des, buf);
}

@end
