//
//  KTVHCPathTools.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/12.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface KTVHCPathTools : NSObject


+ (NSString *)absolutePathForLog;
+ (NSString *)absolutePathForArchiver;

+ (NSString *)absolutePathWithRelativePath:(NSString *)relativePath;
+ (NSString *)absolutePathForDirectoryWithURLString:(NSString *)URLString;
+ (NSString *)absolutePathForCompleteFileWithURLString:(NSString *)URLString;
+ (NSString *)relativePathForCompleteFileWithURLString:(NSString *)URLString;
+ (NSString *)relativePathForUnitItemFileWithURLString:(NSString *)URLString offset:(long long)offset;

+ (void)createFileIfNeeded:(NSString *)filePath;
+ (void)createFolderIfNeeded:(NSString *)folderPath;

+ (NSError *)deleteFileAtPath:(NSString *)filePath;
+ (NSError *)deleteFolderAtPath:(NSString *)folderPath;

+ (long long)sizeOfItemAtFilePath:(NSString *)filePath;


@end
