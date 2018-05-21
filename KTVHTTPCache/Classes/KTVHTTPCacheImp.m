//
//  KTVHTTPCacheImp.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/13.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHTTPCacheImp.h"
#import "KTVHCHTTPServer.h"
#import "KTVHCDataStorage.h"
#import "KTVHCDownload.h"
#import "KTVHCURLTools.h"
#import "KTVHCLog.h"

@implementation KTVHTTPCache


#pragma mark - HTTP Server

+ (BOOL)proxyIsRunning
{
    return [KTVHCHTTPServer server].running;
}

+ (void)proxyStart:(NSError * __autoreleasing *)error
{
    [[KTVHCHTTPServer server] start:error];
}

+ (void)proxyStop
{
    [[KTVHCHTTPServer server] stop];
}

+ (NSURL *)proxyURLWithOriginalURLString:(NSString *)URLString
{
    NSURL * URL = [NSURL URLWithString:URLString];
    NSString * completeFilePath = [[KTVHCDataStorage storage] completeFilePathWithURL:URL];
    if (completeFilePath.length > 0) {
        return [NSURL fileURLWithPath:completeFilePath];
    }
    NSString * proxyURLString = [[KTVHCHTTPServer server] URLStringWithOriginalURLString:URLString];
    return [NSURL URLWithString:proxyURLString];
}

+ (NSString *)proxyURLStringWithOriginalURLString:(NSString *)URLString
{
    return [[KTVHCHTTPServer server] URLStringWithOriginalURLString:URLString];
}


#pragma mark - Data Storage

+ (KTVHCDataReader *)cacheReaderWithRequest:(KTVHCDataRequest *)request
{
    return [[KTVHCDataStorage storage] readerWithRequest:request];
}

+ (void)cacheSetMaxCacheLength:(long long)maxCacheLength
{
    [KTVHCDataStorage storage].maxCacheLength = maxCacheLength;
}

+ (long long)cacheMaxCacheLength
{
    return [KTVHCDataStorage storage].maxCacheLength;
}

+ (long long)cacheTotalCacheLength
{
    return [[KTVHCDataStorage storage] totalCacheLength];
}

+ (NSArray<KTVHCDataCacheItem *> *)cacheAllCacheItem
{
    return [[KTVHCDataStorage storage] allCacheItem];
}

+ (KTVHCDataCacheItem *)cacheCacheItemWithURLString:(NSString *)URLString
{
    NSURL * URL = [NSURL URLWithString:URLString];
    return [[KTVHCDataStorage storage] cacheItemWithURL:URL];
}

+ (void)cacheDeleteAllCache
{
    [[KTVHCDataStorage storage] deleteAllCache];
}

+ (void)cacheDeleteCacheWithURLString:(NSString *)URLString
{
    NSURL * URL = [NSURL URLWithString:URLString];
    [[KTVHCDataStorage storage] deleteCacheWithURL:URL];
}


#pragma mark - URL

+ (void)cacheSetURLFilter:(NSURL * (^)(NSURL * URL))URLFilter
{
    [KTVHCURLTools URLTools].URLFilter = URLFilter;
}


#pragma mark - Download

+ (NSTimeInterval)downloadTimeoutInterval
{
    return [KTVHCDownload download].timeoutInterval;
}

+ (void)downloadSetTimeoutInterval:(NSTimeInterval)timeoutInterval
{
    [KTVHCDownload download].timeoutInterval = timeoutInterval;
}

+ (NSDictionary <NSString *, NSString *> *)downloadCommonHeaderFields
{
    return [KTVHCDownload download].commonHeaderFields;
}

+ (void)downloadSetCommonHeaderFields:(NSDictionary <NSString *, NSString *> *)commonHeaderFields
{
    [KTVHCDownload download].commonHeaderFields = commonHeaderFields;
}

+ (void)downloadSetAcceptContentTypes:(NSArray <NSString *> *)acceptContentTypes
{
    [KTVHCDownload download].acceptContentTypes = acceptContentTypes;
}

+ (NSArray <NSString *> *)downloadAcceptContentTypes
{
    return [KTVHCDownload download].acceptContentTypes;
}

+ (void)downloadSetUnsupportContentTypeFilter:(BOOL(^)(NSURL * URL, NSString * contentType))contentTypeFilter
{
    [KTVHCDownload download].unsupportContentTypeFilter = contentTypeFilter;
}


#pragma mark - Log

+ (void)logAddLog:(NSString *)log
{
    if (log.length > 0)
    {
        KTVHCLogCommon(@"%@", log);
    }
}

+ (BOOL)logConsoleLogEnable
{
    return [KTVHCLog log].consoleLogEnable;
}

+ (void)logSetConsoleLogEnable:(BOOL)consoleLogEnable
{
    [KTVHCLog log].consoleLogEnable = consoleLogEnable;
}

+ (BOOL)logRecordLogEnable
{
    return [KTVHCLog log].recordLogEnable;
}

+ (void)logSetRecordLogEnable:(BOOL)recordLogEnable
{
    [KTVHCLog log].recordLogEnable = recordLogEnable;
}

+ (NSString *)logRecordLogFilePath
{
    return [KTVHCLog log].recordLogFilePath;
}

+ (void)logDeleteRecordLog
{
    [[KTVHCLog log] deleteRecordLog];
}

+ (NSError *)logLastError
{
    return [[KTVHCLog log] lastError];
}

+ (NSArray<NSError *> *)logAllErrors
{
    return [[KTVHCLog log] allErrors];
}


@end
