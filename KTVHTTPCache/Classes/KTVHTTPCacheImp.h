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


+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;


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
+ (KTVHCDataReader *)cacheConcurrentReaderWithRequest:(KTVHCDataRequest *)request;

+ (KTVHCDataReader *)cacheSerialReaderWithRequest:(KTVHCDataRequest *)request;
+ (void)cacheSerialReaderWithRequest:(KTVHCDataRequest *)request
                   completionHandler:(void(^)(KTVHCDataReader *))completionHandler;

/**
 *  Cache Control
 */
+ (void)cacheSetMaxCacheLength:(long long)maxCacheLength;
+ (long long)cacheMaxCacheLength;

+ (long long)cacheTotalCacheLength;

+ (NSArray <KTVHCDataCacheItem *> *)cacheFetchAllCacheItem;
+ (KTVHCDataCacheItem *)cacheFetchCacheItemWithURLString:(NSString *)URLString;

+ (void)cacheDeleteAllCache;
+ (void)cacheDeleteCacheWithURLString:(NSString *)URLString;


#pragma mark - Data Stroage Filters

/**
 *  URL Filter
 *
 *  High frequency call. Make it simple.
 */
+ (void)cacheSetURLFilterForArchive:(NSString *(^)(NSString * originalURLString))URLFilterBlock;

/**
 *  Content-Type Filter
 *
 *  Used to verify the HTTP Response Content-Type.
 *  The return value of block to decide whether to continue to load resources.
 *  The defaultAcceptContentTypes is copy from acceptContentTypes of the KTVHCDataRequest.
 */
+ (void)cacheSetContentTypeFilterForResponseVerify:(BOOL(^)(NSString * URLString,
                                                            NSString * contentType,
                                                            NSArray <NSString *> * defaultAcceptContentTypes))contentTypeFilterBlock;


#pragma mark - Accept Content Types

/**
 *  Default Accept Context Types
 *
 *  If 'cacheSetContentTypeFilterForResponseVerify' is set, this method will be invalid.
 */
+ (void)cacheSetDefaultAcceptContextTypes:(NSArray <NSString *> *)defaultAcceptContextTypes;
+ (NSArray <NSString *> *)cacheDefaultAcceptContextTypes;


#pragma mark - Download

+ (NSTimeInterval)downloadTimeoutInterval;
+ (void)downloadSetTimeoutInterval:(NSTimeInterval)timeoutInterval;

/**
 *  Common Header Fields.
 */
+ (NSDictionary <NSString *, NSString *> *)downloadCommonHeaderFields;
+ (void)downloadSetCommonHeaderFields:(NSDictionary <NSString *, NSString *> *)commonHeaderFields;


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
