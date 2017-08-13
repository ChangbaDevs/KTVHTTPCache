//
//  KTVHCDataReaderPrivate.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataReader.h"
#import "KTVHCDataRequest.h"
#import "KTVHCDataCacheItem.h"
#import "KTVHCDataCacheItemZone.h"

@class KTVHCDataUnit;
@class KTVHCDataReader;


#pragma mark - KTVHCDataReader

@protocol KTVHCDataReaderWorkingDelegate <NSObject>

@optional
- (void)readerDidStartWorking:(KTVHCDataReader *)reader;
- (void)readerDidStopWorking:(KTVHCDataReader *)reader;

@end

@interface KTVHCDataReader (Private)

+ (instancetype)readerWithUnit:(KTVHCDataUnit *)unit
                       request:(KTVHCDataRequest *)request
               workingDelegate:(id <KTVHCDataReaderWorkingDelegate>)workingDelegate;

@property (nonatomic, weak, readonly) id <KTVHCDataReaderWorkingDelegate> workingDelegate;

@property (nonatomic, strong, readonly) KTVHCDataUnit * unit;

@end


#pragma mark - KTVHCDataRequest

static long long const KTVHCDataRequestRangeMinVaule = 0;
static long long const KTVHCDataRequestRangeMaxVaule = -1;

@interface KTVHCDataRequest (Private)

@property (nonatomic, assign, readonly) long long rangeMin;     // default is KTVHCDataRequestRangeMinVaule.
@property (nonatomic, assign, readonly) long long rangeMax;     // default is KTVHCDataRequestRangeMaxVaule.

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
