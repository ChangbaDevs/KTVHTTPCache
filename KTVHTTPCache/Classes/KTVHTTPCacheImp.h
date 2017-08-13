//
//  KTVHTTPCacheImp.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/13.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KTVHTTPCache : NSObject

+ (void)start:(NSError **)error;
+ (void)stop;

+ (NSString *)URLStringWithOriginalURLString:(NSString *)urlString;

@end
