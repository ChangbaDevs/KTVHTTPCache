//
//  KTVHCPathTools.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/12.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCPathTools.h"
#import "KTVHCURLTools.h"


@implementation KTVHCPathTools


+ (NSString *)basePath
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

+ (NSString *)absolutePathForLog
{
    NSString * relativePath = [[self relativePathForRootDirectory] stringByAppendingPathComponent:@"KTVHTTPCache.log"];
    return [self absolutePathWithRelativePath:relativePath];
}

+ (NSString *)absolutePathForArchiver
{
    NSString * relativePath = [[self relativePathForRootDirectory] stringByAppendingPathComponent:@"KTVHTTPCache.archive"];
    return [self absolutePathWithRelativePath:relativePath];
}

+ (NSString *)absolutePathWithRelativePath:(NSString *)relativePath
{
    return [[self basePath] stringByAppendingPathComponent:relativePath];
}

+ (NSString *)absolutePathForDirectoryWithURLString:(NSString *)URLString
{
    NSString * directoryName = [KTVHCURLTools uniqueIdentifierWithURLString:URLString];
    NSString * directoryPath = [self relativePathForUnitItemDirectory:directoryName];
    return [self absolutePathWithRelativePath:directoryPath];
}

+ (NSString *)absolutePathForCompleteFileWithURLString:(NSString *)URLString
{
    NSString * directoryPath = [self relativePathForCompleteFileWithURLString:URLString];
    return [self absolutePathWithRelativePath:directoryPath];
}

+ (NSString *)relativePathForUnitItemDirectory:(NSString *)folderName
{
    NSString * path = [[self relativePathForRootDirectory] stringByAppendingPathComponent:folderName];
    [self createFolderIfNeeded:path];
    return path;
}

+ (NSString *)relativePathForCompleteFileWithURLString:(NSString *)URLString
{
    NSURL * URL = [NSURL URLWithString:URLString];
    NSString * directoryName = [KTVHCURLTools uniqueIdentifierWithURLString:URLString];
    NSString * directoryPath = [self relativePathForUnitItemDirectory:directoryName];
    NSString * fileName = [directoryName stringByAppendingPathExtension:URL.pathExtension];
    return [directoryPath stringByAppendingPathComponent:fileName];
}

+ (NSString *)relativePathForUnitItemFileWithURLString:(NSString *)URLString
                                                offset:(long long)offset
{
    NSString * folderName = [KTVHCURLTools uniqueIdentifierWithURLString:URLString];
    
    NSString * relativePath;
    int number = 0;
    BOOL condition = YES;
    while (condition)
    {
        NSString * fileName = [NSString stringWithFormat:@"%@_%lld_%d", folderName, offset, number];
        relativePath = [[self relativePathForUnitItemDirectory:folderName] stringByAppendingPathComponent:fileName];
        NSString * absolutePath = [self absolutePathWithRelativePath:relativePath];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:absolutePath]) {
            number++;
        } else {
            [[NSFileManager defaultManager] createFileAtPath:absolutePath contents:nil attributes:nil];
            condition = NO;
        }
    }
    return relativePath;
}

+ (NSString *)relativePathForRootDirectory
{
    static NSString * rootDirectory = @"KTVHTTPCache";
    [self createFolderIfNeeded:rootDirectory];
    return rootDirectory;
}

+ (void)createFileIfNeeded:(NSString *)filePath
{
    if (![filePath hasPrefix:[self basePath]])
    {
        filePath = [self absolutePathWithRelativePath:filePath];
    }
    BOOL isDirectory;
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
    if (!isExists || isDirectory) {
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    }
}

+ (void)createFolderIfNeeded:(NSString *)folderPath
{
    if (![folderPath hasPrefix:[self basePath]])
    {
        folderPath = [self absolutePathWithRelativePath:folderPath];
    }
    BOOL isDirectory;
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:folderPath isDirectory:&isDirectory];
    if (!isExists || !isDirectory) {
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

+ (NSError *)deleteFileAtPath:(NSString *)filePath
{
    if (filePath.length <= 0) {
        return nil;
    }
    
    NSError * error = nil;
    BOOL isDirectory = NO;
    BOOL result = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
    if (result && !isDirectory) {
        result = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    }
    return error;
}

+ (NSError *)deleteFolderAtPath:(NSString *)folderPath
{
    if (folderPath.length <= 0) {
        return nil;
    }
    
    NSError * error = nil;
    BOOL isDirectory = NO;
    BOOL result = [[NSFileManager defaultManager] fileExistsAtPath:folderPath isDirectory:&isDirectory];
    if (result && isDirectory) {
        result = [[NSFileManager defaultManager] removeItemAtPath:folderPath error:&error];
    }
    return error;
}

+ (long long)sizeOfItemAtFilePath:(NSString *)filePath
{
    if (filePath.length <= 0) {
        return 0;
    }
    NSError * error;
    NSDictionary <NSFileAttributeKey, id> * attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
    if (!error || attributes.count > 0) {
        NSNumber * fileSize = [attributes objectForKey:NSFileSize];
        return fileSize.longLongValue;
    }
    return 0;
}


@end
