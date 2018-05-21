//
//  KTVHTTPCacheImp.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/13.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KTVHCDataReader;
@class KTVHCDataRequest;
@class KTVHCDataCacheItem;


@interface KTVHTTPCache : NSObject


#pragma mark - HTTP Server

+ (BOOL)proxyIsRunning;

+ (void)proxyStart:(NSError **)error;
+ (void)proxyStop;

/**
 *  If the content of the URLString is finish cache, return the File URL for the content.
 *  Otherwise return the URL for local server.
 */
+ (NSURL *)proxyURLWithOriginalURLString:(NSString *)URLString;

/**
 *  Return the URL string for local server.
 */
+ (NSString *)proxyURLStringWithOriginalURLString:(NSString *)URLString;


#pragma mark - Data Storage

/**
 *  Data Reader
 */
+ (KTVHCDataReader *)cacheReaderWithRequest:(KTVHCDataRequest *)request;

/**
 *  Cache Control
 */
+ (void)cacheSetMaxCacheLength:(long long)maxCacheLength;
+ (long long)cacheMaxCacheLength;
+ (long long)cacheTotalCacheLength;

+ (KTVHCDataCacheItem *)cacheCacheItemWithURLString:(NSString *)URLString;
+ (NSArray <KTVHCDataCacheItem *> *)cacheAllCacheItem;

+ (void)cacheDeleteCacheWithURLString:(NSString *)URLString;
+ (void)cacheDeleteAllCache;


#pragma mark - Token

/**
 *  URL Filter
 *
 *  High frequency call. Make it simple.
 */
+ (void)tokenSetURLFilter:(NSURL * (^)(NSURL * URL))URLFilter;


#pragma mark - Download

+ (void)downloadSetTimeoutInterval:(NSTimeInterval)timeoutInterval;
+ (NSTimeInterval)downloadTimeoutInterval;

/**
 *  Common Header Fields.
 */
+ (NSDictionary <NSString *, NSString *> *)downloadCommonHeaderFields;
+ (void)downloadSetCommonHeaderFields:(NSDictionary <NSString *, NSString *> *)commonHeaderFields;

/**
 *  Default values: 'video/x', 'audio/x', 'application/mp4', 'application/octet-stream', 'binary/octet-stream'
 */
+ (void)downloadSetAcceptContentTypes:(NSArray <NSString *> *)acceptContentTypes;
+ (NSArray <NSString *> *)downloadAcceptContentTypes;

/**
 *  If the receive response's Content-Type not included in acceptContentTypes, this method will be called.
 *  The return value of block to decide whether to continue to load resources. Otherwise the HTTP task will be rejected.
 */
+ (void)downloadSetUnsupportContentTypeFilter:(BOOL(^)(NSURL * URL, NSString * contentType))contentTypeFilter;


#pragma mark - Log

/**
 *  Console & Record
 */
+ (void)logAddLog:(NSString *)log;

/**
 *  DEBUG & RELEASE : default is NO.
 */
+ (BOOL)logConsoleLogEnable;
+ (void)logSetConsoleLogEnable:(BOOL)consoleLogEnable;

/**
 *  DEBUG & RELEASE : default is NO.
 */
+ (BOOL)logRecordLogEnable;
+ (void)logSetRecordLogEnable:(BOOL)recordLogEnable;

+ (NSString *)logRecordLogFilePath;      // nullable
+ (void)logDeleteRecordLog;

/**
 *  Error
 */
+ (NSError *)logLastError;
+ (NSArray <NSError *> *)logAllErrors;


@end
