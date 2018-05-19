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

@interface KTVHCDataStorage () <KTVHCDataUnitWorkingDelegate>


@property (nonatomic, strong) NSCondition * condition;
@property (nonatomic, strong) NSOperationQueue * operationQueue;


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
        self.condition = [[NSCondition alloc] init];
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}


#pragma mark - File

- (NSString *)completeFilePathWithURLString:(NSString *)URLString
{
    return [[KTVHCDataUnitPool unitPool] unitWithURLString:URLString].filePath;
}


#pragma mark - Data Reader

- (KTVHCDataReader *)concurrentReaderWithRequest:(KTVHCDataRequest *)request
{
    KTVHCLogDataStorage(@"concurrent reader, %@", request.URLString);
    
    return [self readerWithRequest:request concurrent:YES];
}

- (KTVHCDataReader *)serialReaderWithRequest:(KTVHCDataRequest *)request
{
    KTVHCLogDataStorage(@"serial reader sync, %@", request.URLString);
    
    return [self readerWithRequest:request concurrent:NO];
}

- (void)serialReaderWithRequest:(KTVHCDataRequest *)request completionHandler:(void (^)(KTVHCDataReader *))completionHandler
{
    if (!completionHandler) {
        return;
    }
    
    KTVHCLogDataStorage(@"serial reader async begin, %@", request.URLString);
    
    __weak typeof(self) weakSelf = self;
    [self.operationQueue addOperationWithBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (completionHandler) {
            
            KTVHCLogDataStorage(@"serial reader async end, %@", request.URLString);
            
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
        while (unit.working)
        {
            KTVHCLogDataStorage(@"wait begin, %@", request.URLString);
            
            unit.workingDelegate = self;
            [self.condition wait];
            
            KTVHCLogDataStorage(@"wait end, %@", request.URLString);
        }
    }
    
    [[KTVHCDataUnitPool unitPool] unit:request.URLString updateRequestHeaderFields:request.headerFields];
    KTVHCDataReader * reader = [KTVHCDataReader readerWithUnit:unit
                                                       request:request];
    
    KTVHCLogDataStorage(@"create reader finished, %@", request.URLString);
    
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


#pragma mark - KTVHCDataUnitWorkingDelegate

- (void)unitDidStopWorking:(KTVHCDataUnit *)unit
{
    [self.condition lock];
    
    KTVHCLogDataStorage(@"unit did stop working begin, %@", unit.URLString);
    
    [self.condition signal];
    
    KTVHCLogDataStorage(@"unit did stop working end, %@", unit.URLString);
    
    [self.condition unlock];
}


@end
