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

+ (NSString *)pathForInsertBasePath:(NSString *)path
{
    return [[self pathForDocumentDirectory] stringByAppendingPathComponent:path];
}

+ (NSString *)pathWithURLString:(NSString *)string offset:(NSInteger)offset
{
    NSString * folderName = [KTVHCURLTools md5:string];
    NSString * fileName = [NSString stringWithFormat:@"%@_%ld", folderName, offset];
    NSString * path = [[self pathForUnitItemDirectory:folderName] stringByAppendingPathComponent:fileName];
    NSString * filePath = [[self  pathForDocumentDirectory] stringByAppendingPathComponent:path];
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        [fileManager removeItemAtPath:filePath error:nil];
    }
    [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    
    return path;
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

+ (NSInteger)sizeOfItemAtFilePath:(NSString *)filePath
{
    if (filePath.length <= 0) {
        return 0;
    }
    NSError * error;
    NSDictionary <NSFileAttributeKey, id> * attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
    if (!error || attributes.count > 0) {
        NSNumber * fileSize = [attributes objectForKey:NSFileSize];
        return fileSize.integerValue;
    }
    return 0;
}

@end
