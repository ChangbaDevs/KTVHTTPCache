//
//  KTVHCDataUnitPool.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVHCDataUnit.h"
#import "KTVHCDataCacheItem.h"

@interface KTVHCDataUnitPool : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)pool;

- (KTVHCDataUnit *)unitWithURLString:(NSString *)URLString;

- (long long)totalCacheLength;
- (NSArray <KTVHCDataCacheItem *> *)allCacheItem;
- (KTVHCDataCacheItem *)cacheItemWithURLString:(NSString *)URLString;

- (void)deleteUnitWithURLString:(NSString *)URLString;
- (void)deleteUnitsWithMinSize:(long long)minSize;
- (void)deleteAllUnits;

@end
