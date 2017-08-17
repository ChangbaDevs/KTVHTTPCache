//
//  KTVHCLog.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/17.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCLog.h"

@implementation KTVHCLog

static BOOL logEnable = NO;

+ (void)setLogEnable:(BOOL)enable
{
    logEnable = enable;
}

+ (BOOL)logEnable
{
    return logEnable;
}

@end
