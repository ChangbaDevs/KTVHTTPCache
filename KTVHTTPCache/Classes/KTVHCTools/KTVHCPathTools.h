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
+ (NSString *)absolutePathForDirectoryWithURL:(NSURL *)URL;
+ (NSString *)absolutePathForCompleteFileWithURL:(NSURL *)URL;
+ (NSString *)relativePathForCompleteFileWithURL:(NSURL *)URL;
+ (NSString *)relativePathForUnitItemFileWithURL:(NSURL *)URL offset:(long long)offset;

+ (BOOL)isRelativePath:(NSString *)path;
+ (BOOL)isAbsolutePath:(NSString *)path;

+ (NSString *)convertAbsoultePathToRelativePath:(NSString *)path;

+ (void)createFileIfNeeded:(NSString *)filePath;
+ (void)createFolderIfNeeded:(NSString *)folderPath;

+ (NSError *)deleteFileAtPath:(NSString *)filePath;
+ (NSError *)deleteFolderAtPath:(NSString *)folderPath;

+ (long long)sizeOfItemAtFilePath:(NSString *)filePath;

@end
