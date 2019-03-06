//
//  KTVHCPathTool.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/12.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KTVHCPathTool : NSObject

+ (NSString *)logPath;
+ (NSString *)archivePath;
+ (NSString *)directoryPathWithURL:(NSURL *)URL;
+ (NSString *)completeFilePathWithURL:(NSURL *)URL;
+ (NSString *)filePathWithURL:(NSURL *)URL offset:(long long)offset;
+ (NSString *)converToRelativePath:(NSString *)path;
+ (NSString *)converToAbsoultePath:(NSString *)path;

+ (void)createFileAtPath:(NSString *)path;
+ (void)createDirectoryAtPath:(NSString *)path;
+ (NSError *)deleteFileAtPath:(NSString *)path;
+ (NSError *)deleteDirectoryAtPath:(NSString *)path;

+ (long long)sizeAtPath:(NSString *)path;

@end
