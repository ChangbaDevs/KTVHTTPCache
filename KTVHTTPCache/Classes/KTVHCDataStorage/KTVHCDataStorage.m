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
    if (self = [super init]) {
        self.maxCacheLength = 500 * 1024 * 1024;
    }
    return self;
}

- (NSString *)completeFilePathWithURL:(NSURL *)URL
{
    KTVHCDataUnit * unit = [[KTVHCDataUnitPool pool] unitWithURL:URL];
    NSString * path = unit.filePath;
    [unit workingRelease];
    return path;
}

- (KTVHCDataReader *)readerWithRequest:(KTVHCDataRequest *)request
{
    if (!request || request.URL.absoluteString.length <= 0) {
        KTVHCLogDataStorage(@"Invaild request, %@", request.URL);
        return nil;
    }
    KTVHCDataReader * reader = [KTVHCDataReader readerWithRequest:request];
    return reader;
}

- (KTVHCDataCacheItem *)cacheItemWithURL:(NSURL *)URL
{
    return [[KTVHCDataUnitPool pool] cacheItemWithURL:URL];
}

- (NSArray<KTVHCDataCacheItem *> *)allCacheItem
{
    return [[KTVHCDataUnitPool pool] allCacheItem];
}

- (long long)totalCacheLength
{
    return [[KTVHCDataUnitPool pool] totalCacheLength];
}

- (void)deleteCacheWithURL:(NSURL *)URL
{
    [[KTVHCDataUnitPool pool] deleteUnitWithURL:URL];
}

- (void)deleteAllCache
{
    [[KTVHCDataUnitPool pool] deleteAllUnits];
}

@end
