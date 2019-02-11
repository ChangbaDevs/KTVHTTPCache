//
//  KTVHTTPCache.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/13.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<KTVHTTPCache/KTVHTTPCache.h>)

FOUNDATION_EXPORT double KTVHTTPCacheVersionNumber;
FOUNDATION_EXPORT const unsigned char KTVHTTPCacheVersionString[];

#import <KTVHTTPCache/KTVHCRange.h>
#import <KTVHTTPCache/KTVHCDataReader.h>
#import <KTVHTTPCache/KTVHCDataLoader.h>
#import <KTVHTTPCache/KTVHCDataRequest.h>
#import <KTVHTTPCache/KTVHCDataResponse.h>
#import <KTVHTTPCache/KTVHCDataCacheItem.h>
#import <KTVHTTPCache/KTVHCDataCacheItemZone.h>

#else

#import "KTVHCRange.h"
#import "KTVHCDataReader.h"
#import "KTVHCDataLoader.h"
#import "KTVHCDataRequest.h"
#import "KTVHCDataResponse.h"
#import "KTVHCDataCacheItem.h"
#import "KTVHCDataCacheItemZone.h"

#endif

@interface KTVHTTPCache : NSObject

#pragma mark - HTTP Server

/**
 *  Start & Stop HTTP Server.
 */
+ (BOOL)proxyStart:(NSError **)error;
+ (void)proxyStop;

+ (BOOL)proxyIsRunning;

/**
 *  Return the URL string for local server.
 */
+ (NSURL *)proxyURLWithOriginalURL:(NSURL *)URL;

#pragma mark - Data Storage

/**
 *  If the content of the URL is finish cached, return the file path for the content. Otherwise return nil.
 */
+ (NSURL *)cacheCompleteFileURLWithURL:(NSURL *)URL;

/**
 *  Data Reader.
 */
+ (KTVHCDataReader *)cacheReaderWithRequest:(KTVHCDataRequest *)request;

/**
 *  Data Loader.
 */
+ (KTVHCDataLoader *)cacheLoaderWithRequest:(KTVHCDataRequest *)request;

/**
 *  Cache State.
 */
+ (void)cacheSetMaxCacheLength:(long long)maxCacheLength;
+ (long long)cacheMaxCacheLength;
+ (long long)cacheTotalCacheLength;

/**
 *  Cache Item.
 */
+ (KTVHCDataCacheItem *)cacheCacheItemWithURL:(NSURL *)URL;
+ (NSArray<KTVHCDataCacheItem *> *)cacheAllCacheItems;

/**
 *  Delete Cache.
 */
+ (void)cacheDeleteCacheWithURL:(NSURL *)URL;
+ (void)cacheDeleteAllCaches;

#pragma mark - Encode

/**
 *  URL Converter.
 *
 *  High frequency call. Make it simple.
 */
+ (void)encodeSetURLConverter:(NSURL * (^)(NSURL *URL))URLConverter;

#pragma mark - Download

+ (void)downloadSetTimeoutInterval:(NSTimeInterval)timeoutInterval;
+ (NSTimeInterval)downloadTimeoutInterval;

/**
 *  Whitelist Header Fields.
 */
+ (void)downloadSetWhitelistHeaderKeys:(NSArray<NSString *> *)whitelistHeaderKeys;
+ (NSArray<NSString *> *)downloadWhitelistHeaderKeys;

/**
 *  Additional Header Fields.
 */
+ (void)downloadSetAdditionalHeaders:(NSDictionary<NSString *, NSString *> *)additionalHeaders;
+ (NSDictionary<NSString *, NSString *> *)downloadAdditionalHeaders;

/**
 *  Default values: 'video/x', 'audio/x', 'application/mp4', 'application/octet-stream', 'binary/octet-stream'
 */
+ (void)downloadSetAcceptableContentTypes:(NSArray<NSString *> *)acceptableContentTypes;
+ (NSArray<NSString *> *)downloadAcceptableContentTypes;

/**
 *  If the receive response's Content-Type not included in acceptContentTypes, this method will be called.
 *  The return value of block to decide whether to continue to load resources. Otherwise the HTTP task will be rejected.
 */
+ (void)downloadSetUnacceptableContentTypeDisposer:(BOOL(^)(NSURL *URL, NSString *contentType))unacceptableContentTypeDisposer;

#pragma mark - Log

/**
 *  Console & Record.
 */
+ (void)logAddLog:(NSString *)log;

/**
 *  DEBUG & RELEASE : Default is NO.
 */
+ (void)logSetConsoleLogEnable:(BOOL)consoleLogEnable;
+ (BOOL)logConsoleLogEnable;

/**
 *  DEBUG & RELEASE : Default is NO.
 */
+ (void)logSetRecordLogEnable:(BOOL)recordLogEnable;
+ (BOOL)logRecordLogEnable;

+ (NSString *)logRecordLogFilePath;      // nullable
+ (void)logDeleteRecordLog;

/**
 *  Error
 */
+ (NSDictionary<NSURL *, NSError *> *)logErrors;
+ (NSError *)logErrorForURL:(NSURL *)URL;
+ (void)logCleanErrorForURL:(NSURL *)URL;

@end

#pragma mark - Deprecated

@interface KTVHTTPCache (Deprecated)

/**
 *  These APIs will be removed in future versions.
 */
+ (NSString *)proxyURLStringWithOriginalURLString:(NSString *)URLString         __attribute__((deprecated("Use +proxyURLWithOriginalURL: instead.")));
+ (NSURL *)cacheCompleteFileURLIfExistedWithURL:(NSURL *)URL                    __attribute__((deprecated("Use +cacheCompleteFileURLWithURL: instead.")));
+ (NSString *)cacheCompleteFilePathIfExistedWithURLString:(NSString *)URLString __attribute__((deprecated("Use +cacheCompleteFileURLWithURL: instead.")));
+ (KTVHCDataCacheItem *)cacheCacheItemWithURLString:(NSString *)URLString       __attribute__((deprecated("Use +cacheCacheItemWithURL: instead.")));
+ (void)cacheDeleteCacheWithURLString:(NSString *)URLString                     __attribute__((deprecated("Use +cacheDeleteCacheWithURL: instead.")));
+ (void)tokenSetURLFilter:(NSURL * (^)(NSURL * URL))URLFilter                   __attribute__((deprecated("Use +encodeSetURLConverter: instead.")));
+ (void)downloadSetAcceptContentTypes:(NSArray<NSString *> *)acceptContentTypes __attribute__((deprecated("Use +downloadSetAcceptableContentTypes: instead.")));
+ (NSArray<NSString *> *)downloadAcceptContentTypes                             __attribute__((deprecated("Use +downloadAcceptableContentTypes instead.")));
+ (void)downloadSetUnsupportContentTypeFilter:(BOOL(^)(NSURL *URL, NSString *contentType))contentTypeFilter __attribute__((deprecated("Use +downloadSetUnacceptableContentTypeDisposer: instead.")));

@end
