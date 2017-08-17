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


typedef NS_ENUM(NSInteger, KTVHCErrorCode)
{
    KTVHCErrorCodeResponseUnavailable = -192700,
};


@interface KTVHCError : NSObject


+ (NSError *)errorForResponseUnavailable:(NSString *)URLString response:(NSHTTPURLResponse *)response;


@end
