//
//  KTVHCError.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/17.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVHCCommon.h"


KTVHTTPCACHE_EXTERN NSString * const KTVHCErrorDomainResponseUnavailable;
KTVHTTPCACHE_EXTERN NSString * const KTVHCErrorDomainNotEnoughDiskSpace;


typedef NS_ENUM(NSInteger, KTVHCErrorCode)
{
    KTVHCErrorCodeResponseUnavailable   = -192700,
    KTVHCErrorCodeNotEnoughDiskSpace    = -192701,
};


@interface KTVHCError : NSObject


+ (NSError *)errorForResponseUnavailable:(NSString *)URLString
                                 request:(NSURLRequest *)request
                                response:(NSHTTPURLResponse *)response;

+ (NSError *)errorForNotEnoughDiskSpace:(long long)totlaContentLength
                                request:(long long)currentContentLength
                       totalCacheLength:(long long)totalCacheLength
                         maxCacheLength:(long long)maxCacheLength;


@end
