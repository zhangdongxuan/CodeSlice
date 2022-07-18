//
//  FileHelper.h
//  AudioQueueService
//
//  Created by disen zhang on 2020/5/17.
//  Copyright © 2020 disen zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FileHelper : NSObject

+ (BOOL)fileExist:(NSString *)nsFilePath;
+ (BOOL)createFile:(NSString *)nsFilePath;
+ (void)removeFile:(NSString *)nsFilePath;

+ (NSString *)getAudioDirPath;
+ (NSString *)getAudioWriteFilePath;

+ (NSArray *)getAllFilesWithDirPath:(NSString *)dirPath;

@end

NS_ASSUME_NONNULL_END
