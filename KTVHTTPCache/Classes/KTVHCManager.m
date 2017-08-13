//
//  KTVHCManager.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCManager.h"
#import "KTVHCHTTPServer.h"
#import "KTVHCHTTPURL.h"

@implementation KTVHCManager

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
