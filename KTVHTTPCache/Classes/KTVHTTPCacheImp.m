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

+ (NSString *)proxyURLStringWithOriginalURLString:(NSString *)urlString
{
    return [[KTVHCHTTPServer server] URLStringWithOriginalURLString:urlString];
}


#pragma mark - Data Storage

+ (KTVHCDataReader *)cacheConcurrentReaderWithRequest:(KTVHCDataRequest *)request
{
    return [[KTVHCDataStorage storage] concurrentReaderWithRequest:request];
}

+ (KTVHCDataReader *)cacheSerialReaderWithRequest:(KTVHCDataRequest *)request
{
    return [[KTVHCDataStorage storage] serialReaderWithRequest:request];
}

+ (void)cacheSerialReaderWithRequest:(KTVHCDataRequest *)request
                   completionHandler:(void(^)(KTVHCDataReader *))completionHandler
{
    [[KTVHCDataStorage storage] serialReaderWithRequest:request
                                      completionHandler:completionHandler];
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

+ (NSArray <KTVHCDataCacheItem *> *)cacheFetchAllCacheItem
{
    return [[KTVHCDataStorage storage] fetchAllCacheItem];
}

+ (KTVHCDataCacheItem *)cacheFetchCacheItemWithURLString:(NSString *)URLString
{
    return [[KTVHCDataStorage storage] fetchCacheItemWithURLString:URLString];
}

+ (void)cacheDeleteAllCache
{
    [[KTVHCDataStorage storage] deleteAllCache];
}

+ (void)cacheDeleteCacheWithURLString:(NSString *)URLString
{
    [[KTVHCDataStorage storage] deleteCacheWithURLString:URLString];
}

+ (void)cacheMergeAllCache
{
    [[KTVHCDataStorage storage] mergeAllCache];
}

+ (void)cacheMergeCacheWtihURLString:(NSString *)URLString
{
    [[KTVHCDataStorage storage] mergeCacheWithURLString:URLString];
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
