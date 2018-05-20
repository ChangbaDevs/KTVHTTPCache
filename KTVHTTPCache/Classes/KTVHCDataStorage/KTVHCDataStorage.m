//
//  KTVHCDataManager.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataStorage.h"
#import "KTVHCDataUnitPool.h"
#import "KTVHCLog.h"

@implementation KTVHCDataStorage

+ (instancetype)storage
{
    static KTVHCDataStorage * obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[self alloc] init];
    });
    return obj;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.maxCacheLength = 500 * 1024 * 1024;
    }
    return self;
}

- (NSString *)completeFilePathWithURL:(NSURL *)URL
{
    return [[KTVHCDataUnitPool pool] unitWithURL:URL].filePath;
}

- (KTVHCDataReader *)readerWithRequest:(KTVHCDataRequest *)request
{
    if (!request || request.URL.absoluteString.length <= 0) {
        return nil;
    }
    KTVHCLogDataStorage(@"concurrent reader, %@", request.URL);
    KTVHCDataReader * reader = [KTVHCDataReader readerWithRequest:request];
    KTVHCLogDataStorage(@"create reader finished, %@", request.URL);
    return reader;
}

- (long long)totalCacheLength
{
    return [[KTVHCDataUnitPool pool] totalCacheLength];
}

- (NSArray <KTVHCDataCacheItem *> *)fetchAllCacheItem
{
    return [[KTVHCDataUnitPool pool] allCacheItem];
}

- (KTVHCDataCacheItem *)fetchCacheItemWithURL:(NSURL *)URL
{
    return [[KTVHCDataUnitPool pool] cacheItemWithURL:URL];
}

- (void)deleteAllCache
{
    [[KTVHCDataUnitPool pool] deleteAllUnits];
}

- (void)deleteCacheWithURL:(NSURL *)URL
{
    [[KTVHCDataUnitPool pool] deleteUnitWithURL:URL];
}

@end
