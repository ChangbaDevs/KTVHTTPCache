//
//  KTVHCManager.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KTVHCManager : NSObject

+ (void)start:(NSError **)error;
+ (void)stop;

+ (NSString *)URLStringWithOriginalURLString:(NSString *)urlString;

@end
