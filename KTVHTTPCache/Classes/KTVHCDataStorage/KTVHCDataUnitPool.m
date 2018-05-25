//
//  KTVHCDataUnitPool.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataUnitPool.h"
#import "KTVHCDataUnitQueue.h"
#import "KTVHCDataPrivate.h"
#import "KTVHCPathTools.h"
#import "KTVHCURLTools.h"
#import "KTVHCLog.h"

@interface KTVHCDataUnitPool () <NSLocking, KTVHCDataUnitFileDelegate>

@property (nonatomic, strong) NSRecursiveLock * coreLock;
@property (nonatomic, strong) KTVHCDataUnitQueue * unitQueue;

@end

@implementation KTVHCDataUnitPool

+ (instancetype)pool
{
    static KTVHCDataUnitPool * obj = nil;
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
        self.unitQueue = [KTVHCDataUnitQueue queueWithPath:[KTVHCPathTools archivePath]];
        for (KTVHCDataUnit * obj in self.unitQueue.allUnits)
        {
            obj.fileDelegate = self;
        }
        KTVHCLogDataUnitPool(@"%p, Create Pool\nUnits : %@", self, self.unitQueue.allUnits);
    }
    return self;
}

- (KTVHCDataUnit *)unitWithURL:(NSURL *)URL
{
    if (URL.absoluteString.length <= 0)
    {
        return nil;
    }
    [self lock];
    NSString * key = [KTVHCURLTools keyWithURL:URL];
    KTVHCDataUnit * unit = [self.unitQueue unitWithKey:key];
    if (!unit)
    {
        unit = [KTVHCDataUnit unitWithURL:URL];
        unit.fileDelegate = self;
        KTVHCLogDataUnitPool(@"%p, Insert Unit, %@", self, unit);
        [self.unitQueue putUnit:unit];
        [self.unitQueue archive];
    }
    [unit workingRetain];
    [self unlock];
    return unit;
}

- (long long)totalCacheLength
{
    [self lock];
    long long length = 0;
    NSArray <KTVHCDataUnit *> * units = [self.unitQueue allUnits];
    for (KTVHCDataUnit * obj in units)
    {
        length += obj.cacheLength;
    }
    [self unlock];
    return length;
}

- (KTVHCDataCacheItem *)cacheItemWithURL:(NSURL *)URL
{
    if (URL.absoluteString.length <= 0)
    {
        return nil;
    }
    [self lock];
    KTVHCDataCacheItem * cacheItem = nil;
    NSString * key = [KTVHCURLTools keyWithURL:URL];
    KTVHCDataUnit * obj = [self.unitQueue unitWithKey:key];
    if (obj)
    {
        NSArray * items = obj.unitItems;
        NSMutableArray * itemZones = [NSMutableArray array];
        for (KTVHCDataUnitItem * unitItem in items)
        {
            KTVHCDataCacheItemZone * itemZone = [KTVHCDataCacheItemZone itemZoneWithOffset:unitItem.offset length:unitItem.length];
            [itemZones addObject:itemZone];
        }
        if (itemZones.count <= 0)
        {
            itemZones = nil;
        }
        cacheItem = [KTVHCDataCacheItem itemWithURL:obj.URL totalLength:obj.totalLength cacheLength:obj.cacheLength vaildLength:obj.validLength zones:itemZones];
    }
    [self unlock];
    return cacheItem;
}

- (NSArray <KTVHCDataCacheItem *> *)allCacheItem
{
    [self lock];
    NSMutableArray * cacheItems = [NSMutableArray array];
    NSArray <KTVHCDataUnit *> * units = [self.unitQueue allUnits];
    for (KTVHCDataUnit * obj in units)
    {
        KTVHCDataCacheItem * cacheItem = [self cacheItemWithURL:obj.URL];
        if (cacheItem)
        {
            [cacheItems addObject:cacheItem];
        }
    }
    if (cacheItems.count <= 0)
    {
        cacheItems = nil;
    }
    [self unlock];
    return cacheItems;
}

- (void)deleteUnitWithURL:(NSURL *)URL
{
    if (URL.absoluteString.length <= 0)
    {
        return;
    }
    [self lock];
    NSString * key = [KTVHCURLTools keyWithURL:URL];
    KTVHCDataUnit * obj = [self.unitQueue unitWithKey:key];
    if (obj && obj.workingCount <= 0)
    {
        KTVHCLogDataUnit(@"%p, Delete Unit\nUnit : %@\nFunc : %s", self, obj, __func__);
        [obj deleteFiles];
        [self.unitQueue popUnit:obj];
        [self.unitQueue archive];
    }
    [self unlock];
}

- (void)deleteUnitsWithLength:(long long)length
{
    if (length <= 0)
    {
        return;
    }
    [self lock];
    BOOL needArchive = NO;
    long long currentLength = 0;
    NSArray <KTVHCDataUnit *> * units = [self.unitQueue allUnits];
    [units sortedArrayUsingComparator:^NSComparisonResult(KTVHCDataUnit * obj1, KTVHCDataUnit * obj2) {
        NSComparisonResult result = NSOrderedDescending;
        [obj1 lock];
        [obj2 lock];
        NSTimeInterval timeInterval1 = obj1.lastItemCreateInterval;
        NSTimeInterval timeInterval2 = obj2.lastItemCreateInterval;
        if (timeInterval1 < timeInterval2) {
            result = NSOrderedAscending;
        } else if (timeInterval1 == timeInterval2 && obj1.createTimeInterval < obj2.createTimeInterval) {
            result = NSOrderedAscending;
        }
        [obj1 unlock];
        [obj2 unlock];
        return result;
    }];
    for (KTVHCDataUnit * obj in units)
    {
        if (obj.workingCount <= 0)
        {
            [obj lock];
            currentLength += obj.cacheLength;
            KTVHCLogDataUnit(@"%p, Delete Unit\nUnit : %@\nFunc : %s", self, obj, __func__);
            [obj deleteFiles];
            [obj unlock];
            [self.unitQueue popUnit:obj];
            needArchive = YES;
        }
        if (currentLength >= length)
        {
            break;
        }
    }
    if (needArchive)
    {
        [self.unitQueue archive];
    }
    [self unlock];
}

- (void)deleteAllUnits
{
    [self lock];
    BOOL needArchive = NO;
    NSArray <KTVHCDataUnit *> * units = [self.unitQueue allUnits];
    for (KTVHCDataUnit * obj in units)
    {
        if (obj.workingCount <= 0)
        {
            KTVHCLogDataUnit(@"%p, Delete Unit\nUnit : %@\nFunc : %s", self, obj, __func__);
            [obj deleteFiles];
            [self.unitQueue popUnit:obj];
            needArchive = YES;
        }
    }
    if (needArchive)
    {
        [self.unitQueue archive];
    }
    [self unlock];
}

- (void)unitShouldRearchive:(KTVHCDataUnit *)unit
{
    [self lock];
    [self.unitQueue archive];
    [self unlock];
}

- (void)lock
{
    if (!self.coreLock)
    {
        self.coreLock = [[NSRecursiveLock alloc] init];
    }
    [self.coreLock lock];
}

- (void)unlock
{
    [self.coreLock unlock];
}

@end
