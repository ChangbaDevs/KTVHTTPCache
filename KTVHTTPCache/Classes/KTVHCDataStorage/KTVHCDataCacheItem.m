//
//  KTVHCDataCacheItem.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/13.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataCacheItem.h"
#import "KTVHCDataPrivate.h"


@interface KTVHCDataCacheItem ()


@property (nonatomic, copy) NSString * URLString;
@property (nonatomic, assign) long long totalLength;
@property (nonatomic, assign) long long cacheLength;
@property (nonatomic, assign) long long vaildLength;
@property (nonatomic, copy) NSArray <KTVHCDataCacheItemZone *> * zones;


@end


@implementation KTVHCDataCacheItem


+ (instancetype)itemWithURLString:(NSString *)URLString
                      totalLength:(long long)totalLength
                      cacheLength:(long long)cacheLength
                      vaildLength:(long long)vaildLength
                            zones:(NSArray <KTVHCDataCacheItemZone *> *)zones
{
    return [[self alloc] initWithURLString:URLString
                               totalLength:totalLength
                               cacheLength:cacheLength
                                     zones:zones];
}

- (instancetype)initWithURLString:(NSString *)URLString
                      totalLength:(long long)totalLength
                      cacheLength:(long long)cacheLength
                            zones:(NSArray <KTVHCDataCacheItemZone *> *)zones
{
    if (self = [super init])
    {
        self.URLString = URLString;
        self.totalLength = totalLength;
        self.cacheLength = cacheLength;
        self.zones = zones;
    }
    return self;
}


@end
