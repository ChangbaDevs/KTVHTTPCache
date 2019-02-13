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
#import "KTVHCDataResponse.h"
#import "KTVHCDataRequest.h"
#import "KTVHCDataReader.h"
#import "KTVHCDataLoader.h"

#pragma mark - KTVHCDataReader

@interface KTVHCDataReader ()

- (instancetype)initWithRequest:(KTVHCDataRequest *)request NS_DESIGNATED_INITIALIZER;

@end

#pragma mark - KTVHCDataLoader

@interface KTVHCDataLoader ()

- (instancetype)initWithRequest:(KTVHCDataRequest *)request NS_DESIGNATED_INITIALIZER;

@end

#pragma mark - KTVHCDataRequest

@interface KTVHCDataRequest ()

- (KTVHCDataRequest *)newRequestWithRange:(KTVHCRange)range;
- (KTVHCDataRequest *)newRequestWithTotalLength:(long long)totalLength;

@end

#pragma mark - KTVHCDataResponse

@interface KTVHCDataResponse ()

- (instancetype)initWithURL:(NSURL *)URL headers:(NSDictionary *)headers NS_DESIGNATED_INITIALIZER;

@end

#pragma mark - KTVHCDataCacheItem

@interface KTVHCDataCacheItem ()

- (instancetype)initWithURL:(NSURL *)URL
                      zones:(NSArray<KTVHCDataCacheItemZone *> *)zones
                totalLength:(long long)totalLength
                cacheLength:(long long)cacheLength
                vaildLength:(long long)vaildLength NS_DESIGNATED_INITIALIZER;

@end

#pragma mark - KTVHCDataCacheItemZone

@interface KTVHCDataCacheItemZone ()

- (instancetype)initWithOffset:(long long)offset length:(long long)length NS_DESIGNATED_INITIALIZER;

@end
