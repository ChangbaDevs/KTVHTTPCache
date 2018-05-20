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
    return [[KTVHCDataUnitPool unitPool] unitWithURLString:URLString].filePath;
}

- (KTVHCDataReader *)readerWithRequest:(KTVHCDataRequest *)request
{
    if (!request || request.URLString.length <= 0)
    {
        return nil;
    }
    KTVHCLogDataStorage(@"concurrent reader, %@", request.URLString);
    [self.lock lock];
    KTVHCDataUnit * unit = [[KTVHCDataUnitPool unitPool] unitWithURLString:request.URLString];
    [[KTVHCDataUnitPool unitPool] unit:request.URLString updateRequestHeaderFields:request.headerFields];
    KTVHCDataReader * reader = [KTVHCDataReader readerWithUnit:unit
                                                       request:request];
    KTVHCLogDataStorage(@"create reader finished, %@", request.URLString);
    [self.lock unlock];
    return reader;
}

- (long long)totalCacheLength
{
    return [[KTVHCDataUnitPool unitPool] totalCacheLength];
}

- (NSArray <KTVHCDataCacheItem *> *)fetchAllCacheItem
{
    return [[KTVHCDataUnitPool unitPool] allCacheItem];
}

- (KTVHCDataCacheItem *)fetchCacheItemWithURLString:(NSString *)URLString
{
    return [[KTVHCDataUnitPool unitPool] cacheItemWithURLString:URLString];
}

- (void)deleteAllCache
{
    [[KTVHCDataUnitPool unitPool] deleteAllUnits];
}

- (void)deleteCacheWithURLString:(NSString *)URLString
{
    [[KTVHCDataUnitPool unitPool] deleteUnitWithURLString:URLString];
}

@end
