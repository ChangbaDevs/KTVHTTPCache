//
//  KTVHCPathTool.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/12.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCPathTool.h"
#import "KTVHCURLTool.h"

@implementation KTVHCPathTool

+ (NSString *)rootDirectory
{
    static NSString *obj = @"KTVHTTPCache";
    [self createDirectoryAtPath:obj];
    return obj;
}

+ (NSString *)logPath
{
    NSString *path = [[self rootDirectory] stringByAppendingPathComponent:@"KTVHTTPCache.log"];
    return [self converToAbsoultePath:path];
}

+ (NSString *)archivePath
{
    NSString *path = [[self rootDirectory] stringByAppendingPathComponent:@"KTVHTTPCache.archive"];
    return [self converToAbsoultePath:path];
}

+ (NSString *)directoryPathWithURL:(NSURL *)URL
{
    NSString *name = [[KTVHCURLTool tool] keyWithURL:URL];
    NSString *path = [[self rootDirectory] stringByAppendingPathComponent:name];
    [self createDirectoryAtPath:path];
    return [self converToAbsoultePath:path];
}

+ (NSString *)completeFilePathWithURL:(NSURL *)URL
{
    NSString *fileName = [[[KTVHCURLTool tool] keyWithURL:URL] stringByAppendingPathExtension:URL.pathExtension];
    NSString *directoryPath = [self directoryPathWithURL:URL];
    NSString *filePath = [directoryPath stringByAppendingPathComponent:fileName];
    return [self converToAbsoultePath:filePath];
}

+ (NSString *)filePathWithURL:(NSURL *)URL offset:(long long)offset
{
    NSString *baseFileName = [[KTVHCURLTool tool] keyWithURL:URL];
    NSString *directoryPath = [self directoryPathWithURL:URL];
    int number = 0;
    NSString *filePath = nil;
    while (!filePath) {
        NSString *fileName = [NSString stringWithFormat:@"%@_%lld_%d", baseFileName, offset, number];
        NSString *currentFilePath = [directoryPath stringByAppendingPathComponent:fileName];
        if (![[NSFileManager defaultManager] fileExistsAtPath:currentFilePath]) {
            [[NSFileManager defaultManager] createFileAtPath:currentFilePath contents:nil attributes:nil];
            filePath = currentFilePath;
        }
        number++;
    }
    return [self converToAbsoultePath:filePath];;
}

+ (NSString *)basePath
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

+ (BOOL)isRelativePath:(NSString *)path
{
    return ![path hasPrefix:[self basePath]];
}

+ (BOOL)isAbsolutePath:(NSString *)path
{
    return [path hasPrefix:[self basePath]];
}

+ (NSString *)converToRelativePath:(NSString *)path
{
    if ([self isAbsolutePath:path]) {
        path = [path stringByReplacingOccurrencesOfString:[self basePath] withString:@""];
    }
    return path;
}

+ (NSString *)converToAbsoultePath:(NSString *)path
{
    if ([self isRelativePath:path]) {
        path = [[self basePath] stringByAppendingPathComponent:path];;
    }
    return path;
}

+ (void)createFileAtPath:(NSString *)path
{
    if (path.length <= 0) {
        return;
    }
    path = [self converToAbsoultePath:path];
    BOOL isDirectory = NO;
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    if (!isExists || isDirectory) {
        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
    }
}

+ (void)createDirectoryAtPath:(NSString *)path
{
    if (path.length <= 0) {
        return;
    }
    path = [self converToAbsoultePath:path];
    BOOL isDirectory = NO;
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    if (!isExists || !isDirectory) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

+ (NSError *)deleteFileAtPath:(NSString *)path
{
    if (path.length <= 0) {
        return nil;
    }
    path = [self converToAbsoultePath:path];
    NSError *error = nil;
    BOOL isDirectory = NO;
    BOOL result = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    if (result && !isDirectory) {
        result = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    }
    return error;
}

+ (NSError *)deleteDirectoryAtPath:(NSString *)path
{
    if (path.length <= 0) {
        return nil;
    }
    path = [self converToAbsoultePath:path];
    NSError *error = nil;
    BOOL isDirectory = NO;
    BOOL result = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    if (result && isDirectory) {
        result = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    }
    return error;
}

+ (long long)sizeAtPath:(NSString *)path
{
    if (path.length <= 0) {
        return 0;
    }
    path = [self converToAbsoultePath:path];
    NSError *error = nil;
    NSDictionary<NSFileAttributeKey, id> *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
    if (!error || attributes.count > 0) {
        NSNumber *size = [attributes objectForKey:NSFileSize];
        return size.longLongValue;
    }
    return 0;
}

@end
