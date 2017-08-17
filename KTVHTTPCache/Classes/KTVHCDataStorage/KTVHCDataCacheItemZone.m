//
//  KTVHCDataCacheItemZone.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/13.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataCacheItemZone.h"
#import "KTVHCDataPrivate.h"


@interface KTVHCDataCacheItemZone ()


@property (nonatomic, assign) long long offset;
@property (nonatomic, assign) long long length;


@end


@implementation KTVHCDataCacheItemZone


+ (instancetype)itemZoneWithOffset:(long long)offset length:(long long)length
{
    return [[self alloc] initWithOffset:offset length:length];
}

- (instancetype)initWithOffset:(long long)offset length:(long long)length
{
    if (self = [super init])
    {
        self.offset = offset;
        self.length = length;
    }
    return self;
}


@end
