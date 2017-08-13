//
//  KTVHTTPCacheImp.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/13.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHTTPCacheImp.h"
#import "KTVHCHTTPServer.h"
#import "KTVHCHTTPURL.h"

@implementation KTVHTTPCache

+ (void)start:(NSError * __autoreleasing *)error
{
    [[KTVHCHTTPServer httpServer] start:error];
}

+ (void)stop
{
    [[KTVHCHTTPServer httpServer] stop];
}

+ (NSString *)URLStringWithOriginalURLString:(NSString *)urlString
{
#if 0
    return urlString;
#endif
    if ([KTVHCHTTPServer httpServer].running)
    {
        KTVHCHTTPURL * url = [KTVHCHTTPURL URLWithOriginalURLString:urlString];
        return [url proxyURLString];
    }
    return urlString;
}

@end
