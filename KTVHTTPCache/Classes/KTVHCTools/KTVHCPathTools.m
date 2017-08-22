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

+ (NSString *)pathForArchiver
{
    NSString * path = [[self pathForRootDirectory] stringByAppendingPathComponent:@"KTVHTTPCache.archiver"];
    return [[self pathForDocumentDirectory] stringByAppendingPathComponent:path];
}

+ (NSString *)pathForLog
{
    NSString * path = [[self pathForRootDirectory] stringByAppendingPathComponent:@"KTVHTTPCache.log"];
    return [[self pathForDocumentDirectory] stringByAppendingPathComponent:path];
}

+ (NSString *)pathForInsertBasePath:(NSString *)path
{
    return [[self pathForDocumentDirectory] stringByAppendingPathComponent:path];
}

+ (NSString *)pathWithURLString:(NSString *)string offset:(long long)offset
{
    NSString * folderName = [KTVHCURLTools md5:string];
    
    NSString * path;
    NSInteger number = 0;
    BOOL condition = YES;
    while (condition)
    {
        NSString * fileName = [NSString stringWithFormat:@"%@_%lld_%ld", folderName, offset, number];
        path = [[self pathForUnitItemDirectory:folderName] stringByAppendingPathComponent:fileName];
        NSString * filePath = [[self pathForDocumentDirectory] stringByAppendingPathComponent:path];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            number++;
        } else {
            [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
            condition = NO;
        }
    }
    return path;
}

+ (NSString *)folderPathWithURLString:(NSString *)URLString
{
    NSString * folderName = [KTVHCURLTools md5:URLString];
    NSString * directory = [self pathForUnitItemDirectory:folderName];
    return [[self pathForDocumentDirectory] stringByAppendingPathComponent:directory];
}

+ (NSString *)pathForUnitItemDirectory:(NSString *)folderName
{
    NSString * path = [[self pathForRootDirectory] stringByAppendingPathComponent:folderName];
    [self createFolderIfNeed:path];
    return path;
}

+ (NSString *)pathForRootDirectory
{
    static NSString * rootDirectory = @"KTVHTTPCache";
    [self createFolderIfNeed:rootDirectory];
    return rootDirectory;
}

+ (NSString *)pathForDocumentDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

+ (void)createFolderIfNeed:(NSString *)path
{
    path = [[self pathForDocumentDirectory] stringByAppendingPathComponent:path];
    BOOL isDirectory;
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    if (!isExists || !isDirectory) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
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

@end
