//
//  KTVHCPathTools.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/12.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface KTVHCPathTools : NSObject


+ (NSString *)absolutePathWithRelativePath:(NSString *)relativePath;
+ (NSString *)absolutePathForArchiver;
+ (NSString *)absolutePathForLog;
+ (NSString *)absolutePathForDirectoryWithURLString:(NSString *)URLString;
+ (NSString *)relativePathForFileWithURLString:(NSString *)URLString offset:(long long)offset;

+ (void)createFolderIfNeed:(NSString *)folderPath;
+ (void)createFileIfNeed:(NSString *)filePath;
+ (NSError *)deleteFolderAtPath:(NSString *)folderPath;
+ (NSError *)deleteFileAtPath:(NSString *)filePath;

+ (long long)sizeOfItemAtFilePath:(NSString *)filePath;


@end
