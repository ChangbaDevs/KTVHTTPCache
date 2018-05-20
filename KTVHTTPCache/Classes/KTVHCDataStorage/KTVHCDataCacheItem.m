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

@property (nonatomic, copy) NSURL * URL;
@property (nonatomic, assign) long long totalLength;
@property (nonatomic, assign) long long cacheLength;
@property (nonatomic, assign) long long vaildLength;
@property (nonatomic, copy) NSArray <KTVHCDataCacheItemZone *> * zones;

@end

@implementation KTVHCDataCacheItem

+ (instancetype)itemWithURL:(NSURL *)URL
                totalLength:(long long)totalLength
                cacheLength:(long long)cacheLength
                vaildLength:(long long)vaildLength
                      zones:(NSArray <KTVHCDataCacheItemZone *> *)zones
{
    return [[self alloc] initWithURL:URL
                         totalLength:totalLength
                         cacheLength:cacheLength
                         vaildLength:vaildLength
                               zones:zones];
}

- (instancetype)initWithURL:(NSURL *)URL
                totalLength:(long long)totalLength
                cacheLength:(long long)cacheLength
                vaildLength:(long long)vaildLength
                      zones:(NSArray <KTVHCDataCacheItemZone *> *)zones
{
    if (self = [super init])
    {
        self.URL = URL;
        self.totalLength = totalLength;
        self.cacheLength = cacheLength;
        self.vaildLength = vaildLength;
        self.zones = zones;
    }
    return self;
}


@end
