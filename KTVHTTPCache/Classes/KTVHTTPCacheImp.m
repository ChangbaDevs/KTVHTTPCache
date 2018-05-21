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

+ (void)proxyStart:(NSError * __autoreleasing *)error
{
    [[KTVHCHTTPServer server] start:error];
}

+ (void)proxyStop
{
    [[KTVHCHTTPServer server] stop];
}

+ (BOOL)proxyIsRunning
{
    return [KTVHCHTTPServer server].running;
}

+ (NSString *)proxyURLStringWithOriginalURLString:(NSString *)URLString
{
    return [[KTVHCHTTPServer server] URLStringWithOriginalURLString:URLString];
}

#pragma mark - Data Storage

- (NSString *)cacheCompleteFilePathIfExistedWithURLString:(NSString *)URLString
{
    NSURL * URL = [NSURL URLWithString:URLString];
    return [[KTVHCDataStorage storage] completeFilePathIfExistedWithURL:URL];
}

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

+ (KTVHCDataCacheItem *)cacheCacheItemWithURLString:(NSString *)URLString
{
    NSURL * URL = [NSURL URLWithString:URLString];
    return [[KTVHCDataStorage storage] cacheItemWithURL:URL];
}

+ (NSArray<KTVHCDataCacheItem *> *)cacheAllCacheItem
{
    return [[KTVHCDataStorage storage] allCacheItem];
}

+ (void)cacheDeleteCacheWithURLString:(NSString *)URLString
{
    NSURL * URL = [NSURL URLWithString:URLString];
    [[KTVHCDataStorage storage] deleteCacheWithURL:URL];
}

+ (void)cacheDeleteAllCache
{
    [[KTVHCDataStorage storage] deleteAllCache];
}


#pragma mark - Token

+ (void)tokenSetURLFilter:(NSURL * (^)(NSURL * URL))URLFilter
{
    [KTVHCURLTools URLTools].URLFilter = URLFilter;
}

#pragma mark - Download

+ (void)downloadSetTimeoutInterval:(NSTimeInterval)timeoutInterval
{
    [KTVHCDownload download].timeoutInterval = timeoutInterval;
}

+ (NSTimeInterval)downloadTimeoutInterval
{
    return [KTVHCDownload download].timeoutInterval;
}

+ (void)downloadSetWhitelistHeaderKeys:(NSArray <NSString *> *)whitelistHeaderKeys
{
    [KTVHCDownload download].whitelistHeaderKeys = whitelistHeaderKeys;
}

+ (NSArray <NSString *> *)downloadWhitelistHeaderKeys
{
    return [KTVHCDownload download].whitelistHeaderKeys;
}

+ (void)downloadSetAdditionalHeaders:(NSDictionary <NSString *, NSString *> *)additionalHeaders
{
    [KTVHCDownload download].additionalHeaders = additionalHeaders;
}

+ (NSDictionary <NSString *, NSString *> *)downloadAdditionalHeaders
{
    return [KTVHCDownload download].additionalHeaders;
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
    if (log.length > 0) {
        KTVHCLogCommon(@"%@", log);
    }
}

+ (void)logSetConsoleLogEnable:(BOOL)consoleLogEnable
{
    [KTVHCLog log].consoleLogEnable = consoleLogEnable;
}

+ (BOOL)logConsoleLogEnable
{
    return [KTVHCLog log].consoleLogEnable;
}

+ (BOOL)logRecordLogEnable
{
    return [KTVHCLog log].recordLogEnable;
}

+ (NSString *)logRecordLogFilePath
{
    return [KTVHCLog log].recordLogFilePath;
}

+ (void)logSetRecordLogEnable:(BOOL)recordLogEnable
{
    [KTVHCLog log].recordLogEnable = recordLogEnable;
}

+ (void)logDeleteRecordLog
{
    [[KTVHCLog log] deleteRecordLog];
}

+ (NSArray<NSError *> *)logAllErrors
{
    return [[KTVHCLog log] allErrors];
}

+ (NSError *)logLastError
{
    return [[KTVHCLog log] lastError];
}

@end
