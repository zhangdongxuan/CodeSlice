//
//  FileHelper.m
//  AudioQueueService
//
//  Created by disen zhang on 2020/5/17.
//  Copyright © 2020 disen zhang. All rights reserved.
//

#import "FileHelper.h"
#import <sys/file.h>
#include <sys/stat.h>

@implementation FileHelper

+ (BOOL) fileExist:(NSString*)nsFilePath {
    if([nsFilePath length] == 0) {
        NSLog(@"file exist error, nsFilePath nil");
        return NO;
    }
    
    struct stat temp;
    return lstat(nsFilePath.UTF8String, &temp) == 0;
}

+ (BOOL) createFile:(NSString*)nsFilePath {
    
    if ([nsFilePath length] == 0) {
        return NO;
    }
    
    if([[NSFileManager defaultManager] fileExistsAtPath:nsFilePath]) {
        return YES;
    }
    
    BOOL bCreated = [[NSFileManager defaultManager] createFileAtPath:nsFilePath contents:nil attributes:nil];
    if(bCreated) {
        return YES;
    }

    NSString *nsPath = [nsFilePath stringByDeletingLastPathComponent];
    if ([nsFilePath length] == 0) {
        return NO;
    }
    
    NSError *err;
    bCreated = [[NSFileManager defaultManager] createDirectoryAtPath:nsPath withIntermediateDirectories:YES attributes:nil error:&err];
    if(bCreated == NO) {
        NSLog(@"create file path:%@ fail:%@", nsPath, [err localizedDescription]);
        return NO;
    }
    
    bCreated = [[NSFileManager defaultManager] createFileAtPath:nsFilePath contents:nil attributes:nil];
    if(bCreated) {
        return YES;
    }
    
    NSLog(@"create file path:%@ fail.", nsFilePath);
    return NO;
}


+ (void) removeFile:(NSString*)nsFilePath {
    [[NSFileManager defaultManager] removeItemAtPath:nsFilePath error:nil];
}

+ (NSString *)getAudioDirPath {
    NSArray *array = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *nsCachePath = [[array objectAtIndex:0] stringByAppendingPathComponent:@"AudioFile"];
    return nsCachePath;
}

+ (NSString *)getAudioWriteFilePath {

    NSString *nsCachePath = [self getAudioDirPath];
    NSDateFormatter *dateFmt = [[NSDateFormatter alloc] init];
    [dateFmt setDateFormat:@"yyyyMMDD_HHmmss"];
    NSString *nsTimeInString = [dateFmt stringFromDate:[NSDate date]];
    
    NSString *nsWritePath = [NSString stringWithFormat:@"%@/%@.pcm", nsCachePath, nsTimeInString];
    
    return nsWritePath;
}


+ (NSArray *)getAllFilesWithDirPath:(NSString *)dirPath {
    if ([self fileExist:dirPath] == NO) {
        return nil;
    }
    
    NSMutableArray *arrFilePath = [NSMutableArray array];
    
    NSArray *filePathsArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:dirPath  error:nil];
    for (int i = 0; i < filePathsArray.count; i++) {
        [arrFilePath addObject:[dirPath stringByAppendingPathComponent:filePathsArray[i]]];
    }

    NSLog(@"files array %@", arrFilePath);
    
    return arrFilePath;
}


@end
