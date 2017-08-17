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

@interface KTVHCDataStorage () <KTVHCDataReaderWorkingDelegate>


@property (nonatomic, strong) NSCondition * condition;
@property (nonatomic, strong) NSOperationQueue * operationQueue;


@end


@implementation KTVHCDataStorage


+ (instancetype)manager
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
        self.condition = [[NSCondition alloc] init];
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}


- (KTVHCDataReader *)concurrentReaderWithRequest:(KTVHCDataRequest *)request
{
    return [self readerWithRequest:request concurrent:YES];
}

- (KTVHCDataReader *)serialReaderWithRequest:(KTVHCDataRequest *)request
{
    return [self readerWithRequest:request concurrent:NO];
}

- (void)serialReaderWithRequest:(KTVHCDataRequest *)request completionHandler:(void (^)(KTVHCDataReader *))completionHandler
{
    if (!completionHandler) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.operationQueue addOperationWithBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (completionHandler) {
            completionHandler([strongSelf serialReaderWithRequest:request]);
        }
    }];
}

- (KTVHCDataReader *)readerWithRequest:(KTVHCDataRequest *)request concurrent:(BOOL)concurrent;
{
    if (!request || request.URLString.length <= 0) {
        return nil;
    }
    
    [self.condition lock];
    KTVHCDataUnit * unit = [[KTVHCDataUnitPool unitPool] unitWithURLString:request.URLString];
    
    if (!concurrent)
    {
        while (unit.working) {
            [self.condition wait];
        }
    }
    
    [unit workingRetain];
    [[KTVHCDataUnitPool unitPool] unit:request.URLString updateRequestHeaderFields:request.headerFields];
    KTVHCDataReader * reader = [KTVHCDataReader readerWithUnit:unit
                                                       request:request
                                               workingDelegate:self];
    [self.condition unlock];
    return reader;
}


#pragma mark - Cache Control

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

- (void)mergeAllCache
{
    [[KTVHCDataUnitPool unitPool] mergeAllUnits];
}

- (void)mergeCacheWithURLString:(NSString *)URLString
{
    [[KTVHCDataUnitPool unitPool] mergeUnitWithURLString:URLString];
}


#pragma mark - KTVHCDataReaderWorkingDelegate

- (void)readerDidStopWorking:(KTVHCDataReader *)reader
{
    [self.condition lock];
    [reader.unit workingRelease];
    if (!reader.unit.working)
    {
        [self.condition signal];
    }
    [self.condition unlock];
}


@end
