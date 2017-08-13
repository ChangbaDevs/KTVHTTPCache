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

+ (void)proxyStart:(NSError **)error;
+ (void)proxyStop;

+ (NSString *)proxyURLStringWithOriginalURLString:(NSString *)urlString;


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
+ (long long)cacheTotalCacheLength;

+ (NSArray <KTVHCDataCacheItem *> *)cacheFetchAllCacheItem;
+ (KTVHCDataCacheItem *)cacheFetchCacheItemWithURLString:(NSString *)URLString;

+ (void)cacheDeleteAllCache;
+ (void)cacheDeleteCacheWithURLString:(NSString *)URLString;


@end
