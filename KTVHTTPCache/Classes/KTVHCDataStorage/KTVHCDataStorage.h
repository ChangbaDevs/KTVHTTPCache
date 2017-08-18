//
//  KTVHCDataManager.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVHCDataRequest.h"
#import "KTVHCDataReader.h"
#import "KTVHCDataCacheItem.h"

@interface KTVHCDataStorage : NSObject


+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)manager;


#pragma mark - Data Reader

- (KTVHCDataReader *)concurrentReaderWithRequest:(KTVHCDataRequest *)request;

- (KTVHCDataReader *)serialReaderWithRequest:(KTVHCDataRequest *)request;
- (void)serialReaderWithRequest:(KTVHCDataRequest *)request completionHandler:(void(^)(KTVHCDataReader *))completionHandler;


#pragma mark - Cache Control

@property (nonatomic, assign) long long maxCacheLength;

- (long long)totalCacheLength;

- (NSArray <KTVHCDataCacheItem *> *)fetchAllCacheItem;
- (KTVHCDataCacheItem *)fetchCacheItemWithURLString:(NSString *)URLString;

- (void)deleteAllCache;
- (void)deleteCacheWithURLString:(NSString *)URLString;

- (void)mergeAllCache;
- (void)mergeCacheWithURLString:(NSString *)URLString;


@end
