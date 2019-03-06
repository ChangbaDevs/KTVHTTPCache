//
//  KTVHTTPCache.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/13.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHTTPCache.h"
#import "KTVHCDataStorage.h"
#import "KTVHCHTTPServer.h"
#import "KTVHCDownload.h"
#import "KTVHCURLTool.h"
#import "KTVHCLog.h"

@implementation KTVHTTPCache

#pragma mark - HTTP Server

+ (BOOL)proxyStart:(NSError **)error
{
    return [[KTVHCHTTPServer server] start:error];
}

+ (void)proxyStop
{
    [[KTVHCHTTPServer server] stop];
}

+ (BOOL)proxyIsRunning
{
    return [KTVHCHTTPServer server].isRunning;
}

+ (NSURL *)proxyURLWithOriginalURL:(NSURL *)URL
{
    return [[KTVHCHTTPServer server] URLWithOriginalURL:URL];
}

#pragma mark - Data Storage

+ (NSURL *)cacheCompleteFileURLWithURL:(NSURL *)URL
{
    return [[KTVHCDataStorage storage] completeFileURLWithURL:URL];
}

+ (KTVHCDataReader *)cacheReaderWithRequest:(KTVHCDataRequest *)request
{
    return [[KTVHCDataStorage storage] readerWithRequest:request];
}

+ (KTVHCDataLoader *)cacheLoaderWithRequest:(KTVHCDataRequest *)request
{
    return [[KTVHCDataStorage storage] loaderWithRequest:request];
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
    return [KTVHCDataStorage storage].totalCacheLength;
}

+ (KTVHCDataCacheItem *)cacheCacheItemWithURL:(NSURL *)URL
{
    return [[KTVHCDataStorage storage] cacheItemWithURL:URL];
}

+ (NSArray<KTVHCDataCacheItem *> *)cacheAllCacheItems
{
    return [[KTVHCDataStorage storage] allCacheItems];
}

+ (void)cacheDeleteCacheWithURL:(NSURL *)URL
{
    [[KTVHCDataStorage storage] deleteCacheWithURL:URL];
}

+ (void)cacheDeleteAllCaches
{
    [[KTVHCDataStorage storage] deleteAllCaches];
}

#pragma mark - Encode

+ (void)encodeSetURLConverter:(NSURL * (^)(NSURL *URL))URLConverter;
{
    [KTVHCURLTool tool].URLConverter = URLConverter;
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

+ (void)downloadSetWhitelistHeaderKeys:(NSArray<NSString *> *)whitelistHeaderKeys
{
    [KTVHCDownload download].whitelistHeaderKeys = whitelistHeaderKeys;
}

+ (NSArray<NSString *> *)downloadWhitelistHeaderKeys
{
    return [KTVHCDownload download].whitelistHeaderKeys;
}

+ (void)downloadSetAdditionalHeaders:(NSDictionary<NSString *, NSString *> *)additionalHeaders
{
    [KTVHCDownload download].additionalHeaders = additionalHeaders;
}

+ (NSDictionary<NSString *, NSString *> *)downloadAdditionalHeaders
{
    return [KTVHCDownload download].additionalHeaders;
}

+ (void)downloadSetAcceptableContentTypes:(NSArray<NSString *> *)acceptableContentTypes
{
    [KTVHCDownload download].acceptableContentTypes = acceptableContentTypes;
}

+ (NSArray<NSString *> *)downloadAcceptableContentTypes
{
    return [KTVHCDownload download].acceptableContentTypes;
}

+ (void)downloadSetUnacceptableContentTypeDisposer:(BOOL(^)(NSURL *URL, NSString *contentType))unacceptableContentTypeDisposer
{
    [KTVHCDownload download].unacceptableContentTypeDisposer = unacceptableContentTypeDisposer;
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

+ (NSURL *)logRecordLogFileURL
{
    return [KTVHCLog log].recordLogFileURL;
}

+ (void)logSetRecordLogEnable:(BOOL)recordLogEnable
{
    [KTVHCLog log].recordLogEnable = recordLogEnable;
}

+ (void)logDeleteRecordLogFile
{
    [[KTVHCLog log] deleteRecordLogFile];
}

+ (NSDictionary<NSURL *, NSError *> *)logErrors
{
    return [[KTVHCLog log] errors];
}

+ (void)logCleanErrorForURL:(NSURL *)URL
{
    [[KTVHCLog log] cleanErrorForURL:URL];
}

+ (NSError *)logErrorForURL:(NSURL *)URL
{
    return [[KTVHCLog log] errorForURL:URL];
}

@end

#pragma mark - Deprecated

@implementation KTVHTTPCache (Deprecated)

+ (void)logDeleteRecordLog
{
    [self logDeleteRecordLogFile];
}

+ (NSString *)logRecordLogFilePath
{
    return [self logRecordLogFileURL].path;
}

+ (NSString *)proxyURLStringWithOriginalURLString:(NSString *)URLString
{
    NSURL *URL = [NSURL URLWithString:URLString];
    return [self proxyURLWithOriginalURL:URL].absoluteString;
}

+ (NSURL *)cacheCompleteFileURLIfExistedWithURL:(NSURL *)URL
{
    return [self cacheCompleteFileURLWithURL:URL];
}

+ (NSString *)cacheCompleteFilePathIfExistedWithURLString:(NSString *)URLString
{
    NSURL *URL = [NSURL URLWithString:URLString];
    return [self cacheCompleteFileURLWithURL:URL].path;
}

+ (KTVHCDataCacheItem *)cacheCacheItemWithURLString:(NSString *)URLString
{
    NSURL *URL = [NSURL URLWithString:URLString];
    return [self cacheCacheItemWithURL:URL];
}

+ (void)cacheDeleteCacheWithURLString:(NSString *)URLString
{
    NSURL *URL = [NSURL URLWithString:URLString];
    [self cacheDeleteCacheWithURL:URL];
}

+ (void)tokenSetURLFilter:(NSURL * (^)(NSURL *URL))URLFilter
{
    [self encodeSetURLConverter:URLFilter];
}

+ (void)downloadSetAcceptContentTypes:(NSArray<NSString *> *)acceptContentTypes
{
    [self downloadSetAcceptableContentTypes:acceptContentTypes];
}

+ (NSArray<NSString *> *)downloadAcceptContentTypes
{
    return [self downloadAcceptableContentTypes];
}

+ (void)downloadSetUnsupportContentTypeFilter:(BOOL(^)(NSURL *URL, NSString *contentType))contentTypeFilter
{
    [self downloadSetUnacceptableContentTypeDisposer:contentTypeFilter];
}

@end
