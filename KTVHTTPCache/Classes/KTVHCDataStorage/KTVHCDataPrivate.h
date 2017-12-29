//
//  KTVHCDataReaderPrivate.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataReader.h"
#import "KTVHCDataRequest.h"
#import "KTVHCDataResponse.h"
#import "KTVHCDataCacheItem.h"
#import "KTVHCDataCacheItemZone.h"

@class KTVHCDataUnit;
@class KTVHCDataReader;


#pragma mark - KTVHCDataReader

@interface KTVHCDataReader (Private)


+ (instancetype)readerWithUnit:(KTVHCDataUnit *)unit
                       request:(KTVHCDataRequest *)request;

@property (nonatomic, strong, readonly) KTVHCDataUnit * unit;


@end


#pragma mark - KTVHCDataRequest

static long long const KTVHCDataRequestRangeMinVaule = 0;
static long long const KTVHCDataRequestRangeMaxVaule = -1;

@interface KTVHCDataRequest (Private)


@property (nonatomic, assign, readonly) long long rangeMin;     // default is KTVHCDataRequestRangeMinVaule.
@property (nonatomic, assign, readonly) long long rangeMax;     // default is KTVHCDataRequestRangeMaxVaule.

- (void)updateRangeMaxIfNeeded:(long long)ensureTotalContentLength;


@end


#pragma mark - KTVHCDataResponse

@interface KTVHCDataResponse (Private)


+ (instancetype)responseWithCurrentContentLength:(long long)currentContentLength
                              totalContentLength:(long long)totalContentLength
                                    headerFields:(NSDictionary *)headerFields
               headerFieldsWithoutRangeAndLength:(NSDictionary *)headerFieldsWithoutRangeAndLength;


@end


#pragma mark - KTVHCDataCacheItem

@interface KTVHCDataCacheItem (Private)


+ (instancetype)itemWithURLString:(NSString *)URLString
                      totalLength:(long long)totalLength
                      cacheLength:(long long)cacheLength
                            zones:(NSArray <KTVHCDataCacheItemZone *> *)zones;


@end

@interface KTVHCDataCacheItemZone (Private)


+ (instancetype)itemZoneWithOffset:(long long)offset length:(long long)length;


@end
