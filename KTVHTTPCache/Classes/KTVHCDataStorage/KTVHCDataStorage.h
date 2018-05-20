//
//  KTVHCDataManager.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVHCDataReader.h"
#import "KTVHCDataRequest.h"
#import "KTVHCDataResponse.h"
#import "KTVHCDataCacheItem.h"

@interface KTVHCDataStorage : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)storage;

- (NSString *)completeFilePathWithURL:(NSURL *)URL;
- (KTVHCDataReader *)readerWithRequest:(KTVHCDataRequest *)request;

@property (nonatomic, assign) long long maxCacheLength;     // default is 500m.

- (long long)totalCacheLength;
- (NSArray <KTVHCDataCacheItem *> *)fetchAllCacheItem;
- (KTVHCDataCacheItem *)fetchCacheItemWithURL:(NSURL *)URL;

- (void)deleteAllCache;
- (void)deleteCacheWithURL:(NSURL *)URL;


@end
