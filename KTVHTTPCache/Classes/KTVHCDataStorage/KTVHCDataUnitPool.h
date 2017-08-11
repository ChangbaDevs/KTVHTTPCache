//
//  KTVHCDataUnitPool.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVHCDataUnit.h"

@interface KTVHCDataUnitPool : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)unitPool;

- (KTVHCDataUnit *)unitWithURLString:(NSString *)URLString;

@end
