//
//  KTVHCDataUnitPool.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataUnitPool.h"
#import "KTVHCDataUnitQueue.h"
#import "KTVHCPathTools.h"
#import "KTVHCDataPrivate.h"
#import "KTVHCLog.h"


@interface KTVHCDataUnitPool ()


@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, strong) KTVHCDataUnitQueue * unitQueue;


@end


@implementation KTVHCDataUnitPool


+ (instancetype)unitPool
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
        self.lock = [[NSLock alloc] init];
        self.unitQueue = [KTVHCDataUnitQueue unitQueueWithArchiverPath:[KTVHCPathTools absolutePathForArchiver]];
    }
    return self;
}


- (KTVHCDataUnit *)unitWithURLString:(NSString *)URLString
{
    if (URLString.length <= 0) {
        return nil;
    }
    
    [self.lock lock];
    NSString * uniqueIdentifier = [KTVHCDataUnit uniqueIdentifierWithURLString:URLString];
    KTVHCDataUnit * unit = [self.unitQueue unitWithUniqueIdentifier:uniqueIdentifier];
    if (!unit)
    {
        KTVHCLogDataUnitPool(@"new unit, %@", URLString);
        
        unit = [KTVHCDataUnit unitWithURLString:URLString];
        [self.unitQueue putUnit:unit];
        [self.unitQueue archive];
    }
    [self.lock unlock];
    return unit;
}

- (long long)totalCacheLength
{
    long long length = 0;
    [self.lock lock];
    NSArray <KTVHCDataUnit *> * units = [self.unitQueue allUnits];
    for (KTVHCDataUnit * obj in units)
    {
        length += obj.totalCacheLength;
    }
    [self.lock unlock];
    return length;
}

- (KTVHCDataCacheItem *)cacheItemWithURLString:(NSString *)URLString
{
    if (URLString.length <= 0) {
        return nil;
    }
    
    [self.lock lock];
    KTVHCDataCacheItem * cacheItem = nil;
    NSString * uniqueIdentifier = [KTVHCDataUnit uniqueIdentifierWithURLString:URLString];
    KTVHCDataUnit * obj = [self.unitQueue unitWithUniqueIdentifier:uniqueIdentifier];
    if (obj)
    {
        NSMutableArray * itemZones = [NSMutableArray array];
        for (KTVHCDataUnitItem * unitItem in obj.unitItems)
        {
            KTVHCDataCacheItemZone * itemZone = [KTVHCDataCacheItemZone itemZoneWithOffset:unitItem.offset
                                                                                    length:unitItem.length];
            [itemZones addObject:itemZone];
        }
        if (itemZones.count <= 0) {
            itemZones = nil;
        }
        cacheItem = [KTVHCDataCacheItem itemWithURLString:obj.URLString
                                              totalLength:obj.totalContentLength
                                              cacheLength:obj.totalCacheLength
                                                    zones:itemZones];
    }
    [self.lock unlock];
    return cacheItem;
}

- (NSArray <KTVHCDataCacheItem *> *)allCacheItem
{
    [self.lock lock];
    NSMutableArray * cacheItems = [NSMutableArray array];
    NSArray <KTVHCDataUnit *> * units = [self.unitQueue allUnits];
    for (KTVHCDataUnit * obj in units)
    {
        NSMutableArray * itemZones = [NSMutableArray array];
        for (KTVHCDataUnitItem * unitItem in obj.unitItems)
        {
            KTVHCDataCacheItemZone * itemZone = [KTVHCDataCacheItemZone itemZoneWithOffset:unitItem.offset
                                                                                    length:unitItem.length];
            [itemZones addObject:itemZone];
        }
        if (itemZones.count <= 0) {
            itemZones = nil;
        }
        KTVHCDataCacheItem * cacheItem = [KTVHCDataCacheItem itemWithURLString:obj.URLString
                                                                  totalLength:obj.totalContentLength
                                                                  cacheLength:obj.totalCacheLength
                                                                        zones:itemZones];
        [cacheItems addObject:cacheItem];
    }
    if (cacheItems.count <= 0) {
        cacheItems = nil;
    }
    [self.lock unlock];
    return cacheItems;
}

- (void)deleteUnitWithURLString:(NSString *)URLString
{
    if (URLString.length <= 0) {
        return;
    }
    
    [self.lock lock];
    NSString * uniqueIdentifier = [KTVHCDataUnit uniqueIdentifierWithURLString:URLString];
    KTVHCDataUnit * obj = [self.unitQueue unitWithUniqueIdentifier:uniqueIdentifier];
    if (obj && !obj.working)
    {
        KTVHCLogDataUnit(@"delete unit 1, %@", URLString);
        
        [obj deleteFiles];
        [self.unitQueue popUnit:obj];
        [self.unitQueue archive];
    }
    [self.lock unlock];
}

- (void)deleteUnitsWithMinSize:(long long)minSize
{
    if (minSize <= 0) {
        return;
    }
    
    [self.lock lock];
    
    BOOL needArchive = NO;
    long long currentSize = 0;
    
    NSArray <KTVHCDataUnit *> * units = [self.unitQueue allUnits];
    
#if 1
    [units sortedArrayUsingComparator:^NSComparisonResult(KTVHCDataUnit * obj1, KTVHCDataUnit * obj2) {
        NSTimeInterval timeInterval1 = obj1.lastItemCerateInterval;
        NSTimeInterval timeInterval2 = obj2.lastItemCerateInterval;
        if (timeInterval1 < timeInterval2) {
            return NSOrderedAscending;
        } else if (timeInterval1 == timeInterval2 && obj1.createTimeInterval < obj2.createTimeInterval) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
#endif
    
    for (KTVHCDataUnit * obj in units)
    {
        if (!obj.working)
        {
            KTVHCLogDataUnitPool(@"delete unit 2, %@", obj.URLString);
            
            currentSize += obj.totalCacheLength;
            [obj deleteFiles];
            [self.unitQueue popUnit:obj];
            needArchive = YES;
        }
        if (currentSize >= minSize)
        {
            break;
        }
    }
    if (needArchive) {
        [self.unitQueue archive];
    }
    [self.lock unlock];
}

- (void)deleteAllUnits
{
    [self.lock lock];
    BOOL needArchive = NO;
    NSArray <KTVHCDataUnit *> * units = [self.unitQueue allUnits];
    for (KTVHCDataUnit * obj in units)
    {
        if (!obj.working)
        {
            KTVHCLogDataUnitPool(@"delete unit 2, %@", obj.URLString);
            
            [obj deleteFiles];
            [self.unitQueue popUnit:obj];
            needArchive = YES;
        }
    }
    if (needArchive) {
        [self.unitQueue archive];
    }
    [self.lock unlock];
}

- (void)mergeUnitWithURLString:(NSString *)URLString
{
    if (URLString.length <= 0) {
        return;
    }
    
    [self.lock lock];
    NSString * uniqueIdentifier = [KTVHCDataUnit uniqueIdentifierWithURLString:URLString];
    KTVHCDataUnit * obj = [self.unitQueue unitWithUniqueIdentifier:uniqueIdentifier];
    BOOL success = [obj mergeFiles];
    if (success) {
        [self.unitQueue archive];
    }
    [self.lock unlock];
}

- (void)mergeAllUnits
{
    [self.lock lock];
    BOOL success = NO;
    NSArray <KTVHCDataUnit *> * units = [self.unitQueue allUnits];
    for (KTVHCDataUnit * obj in units)
    {
        if ([obj mergeFiles]) {
            success = YES;
        }
    }
    if (success) {
        [self.unitQueue archive];
    }
    [self.lock unlock];
}


#pragma mark - Unit Control

- (void)unit:(NSString *)unitURLString insertUnitItem:(KTVHCDataUnitItem *)unitItem
{
    if (unitURLString.length <= 0) {
        return;
    }
    
    KTVHCLogDataUnitPool(@"insert unit item :%@", unitItem);
    
    [self.lock lock];
    NSString * uniqueIdentifier = [KTVHCDataUnit uniqueIdentifierWithURLString:unitURLString];
    KTVHCDataUnit * unit = [self.unitQueue unitWithUniqueIdentifier:uniqueIdentifier];
    [unit insertUnitItem:unitItem];
    [self.unitQueue archive];
    [self.lock unlock];
}

- (void)unit:(NSString *)unitURLString updateRequestHeaderFields:(NSDictionary *)requestHeaderFields
{
    if (unitURLString.length <= 0) {
        return;
    }
    
    KTVHCLogDataUnitPool(@"update request header fields\n%@", requestHeaderFields);
    
    [self.lock lock];
    NSString * uniqueIdentifier = [KTVHCDataUnit uniqueIdentifierWithURLString:unitURLString];
    KTVHCDataUnit * unit = [self.unitQueue unitWithUniqueIdentifier:uniqueIdentifier];
    [unit updateRequestHeaderFields:requestHeaderFields];
    [self.lock unlock];
}

- (void)unit:(NSString *)unitURLString updateResponseHeaderFields:(NSDictionary *)responseHeaderFields
{
    if (unitURLString.length <= 0) {
        return;
    }
    
    KTVHCLogDataUnitPool(@"update response header fields\n%@", responseHeaderFields);
    
    [self.lock lock];
    NSString * uniqueIdentifier = [KTVHCDataUnit uniqueIdentifierWithURLString:unitURLString];
    KTVHCDataUnit * unit = [self.unitQueue unitWithUniqueIdentifier:uniqueIdentifier];
    [unit updateResponseHeaderFields:responseHeaderFields];
    [self.unitQueue archive];
    [self.lock unlock];
}


@end
