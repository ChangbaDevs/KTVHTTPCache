//
//  KTVHCDataManager.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataManager.h"
#import "KTVHCDataUnitPool.h"
#import "KTVHCDataReaderPrivate.h"

@implementation KTVHCDataManager

+ (KTVHCDataReader *)readerWithRequest:(KTVHCDataRequest *)request
{
    KTVHCDataUnit * unit = [[KTVHCDataUnitPool unitPool] unitWithURLString:request.URLString];
    KTVHCDataReader * reader = [KTVHCDataReader readerWithUnit:unit request:request];
    return reader;
}

@end
