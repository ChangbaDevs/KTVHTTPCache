//
//  KTVHCData+Internal.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVHCDataCacheItemZone.h"
#import "KTVHCDataCacheItem.h"

@interface KTVHCDataCacheItem (Internal)

- (instancetype)initWithURL:(NSURL *)URL
                      zones:(NSArray <KTVHCDataCacheItemZone *> *)zones
                totalLength:(long long)totalLength
                cacheLength:(long long)cacheLength
                vaildLength:(long long)vaildLength;

@end

@interface KTVHCDataCacheItemZone (Internal)

- (instancetype)initWithOffset:(long long)offset length:(long long)length;

@end
