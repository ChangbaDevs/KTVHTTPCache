//
//  KTVHCDataManager.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataStorage.h"
#import "KTVHCDataUnitPool.h"
#import "KTVHCDataPrivate.h"
#import "KTVHCLog.h"

@interface KTVHCDataStorage ()

@property (nonatomic, strong) NSLock * lock;

@end

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
        self.lock = [[NSLock alloc] init];
    }
    return self;
}

- (NSString *)completeFilePathWithURLString:(NSString *)URLString
{
    return [[KTVHCDataUnitPool pool] unitWithURLString:URLString].filePath;
}

- (KTVHCDataReader *)readerWithRequest:(KTVHCDataRequest *)request
{
    if (!request || request.URL.absoluteString.length <= 0)
    {
        return nil;
    }
    KTVHCLogDataStorage(@"concurrent reader, %@", request.URL);
    [self.lock lock];
    KTVHCDataUnit * unit = [[KTVHCDataUnitPool pool] unitWithURLString:request.URL.absoluteString];
    [unit updateRequestHeaderFields:request.headers];
    KTVHCDataReader * reader = [KTVHCDataReader readerWithUnit:unit
                                                       request:request];
    KTVHCLogDataStorage(@"create reader finished, %@", request.URL);
    [self.lock unlock];
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

- (KTVHCDataCacheItem *)fetchCacheItemWithURLString:(NSString *)URLString
{
    return [[KTVHCDataUnitPool pool] cacheItemWithURLString:URLString];
}

- (void)deleteAllCache
{
    [[KTVHCDataUnitPool pool] deleteAllUnits];
}

- (void)deleteCacheWithURLString:(NSString *)URLString
{
    [[KTVHCDataUnitPool pool] deleteUnitWithURLString:URLString];
}

@end
