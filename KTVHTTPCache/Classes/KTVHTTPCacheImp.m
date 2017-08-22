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

+ (void)downloadSetTimeoutInterval:(NSTimeInterval)timeoutInterval
{
    [KTVHCDownload download].timeoutInterval = timeoutInterval;
}

+ (NSTimeInterval)downloadTimeoutInterval
{
    return [KTVHCDownload download].timeoutInterval;
}


#pragma mark - Log

+ (void)setLogEnable:(BOOL)enable
{
    [KTVHCLog log].logEnable = enable;
}

+ (BOOL)logEnable
{
    return [KTVHCLog log].logEnable;
}


@end
