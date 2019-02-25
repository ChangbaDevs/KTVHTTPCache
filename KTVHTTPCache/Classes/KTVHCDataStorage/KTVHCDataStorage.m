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

- (NSURL *)completeFileURLIfExistedWithURL:(NSURL *)URL
{
    KTVHCDataUnit * unit = [[KTVHCDataUnitPool pool] unitWithURL:URL];
    NSURL * fileURL = unit.fileURL;
    [unit workingRelease];
    return fileURL;
}

- (KTVHCDataReader *)readerWithRequest:(KTVHCDataRequest *)request
{
    if (!request || request.URL.absoluteString.length <= 0)
    {
        KTVHCLogDataStorage(@"Invaild reader request, %@", request.URL);
        return nil;
    }
    KTVHCDataReader * reader = [KTVHCDataReader readerWithRequest:request];
    return reader;
}

- (KTVHCDataLoader *)loaderWithRequest:(KTVHCDataRequest *)request
{
    if (!request || request.URL.absoluteString.length <= 0)
    {
        KTVHCLogDataStorage(@"Invaild loader request, %@", request.URL);
        return nil;
    }
    KTVHCDataLoader * loader = [KTVHCDataLoader loaderWithRequest:request];
    return loader;
}

- (KTVHCDataCacheItem *)cacheItemWithURL:(NSURL *)URL
{
    return [[KTVHCDataUnitPool pool] cacheItemWithURL:URL];
}

- (NSArray<KTVHCDataCacheItem *> *)allCacheItems
{
    return [[KTVHCDataUnitPool pool] allCacheItem];
}

- (long long)totalCacheLength
{
    return [[KTVHCDataUnitPool pool] totalCacheLength];
}
- (void)insertUnitWithURL:(NSURL *)URL fileURL:(NSURL *)fileURL;// zhou zhuoqian added
{
    [[KTVHCDataUnitPool pool] deleteUnitWithURL:URL];
    [[KTVHCDataUnitPool pool] insertUnitWithURL:URL fileURL:fileURL];
}

- (void)deleteCacheWithURL:(NSURL *)URL
{
    [[KTVHCDataUnitPool pool] deleteUnitWithURL:URL];
}

- (void)deleteAllCaches
{
    [[KTVHCDataUnitPool pool] deleteAllUnits];
}

@end
