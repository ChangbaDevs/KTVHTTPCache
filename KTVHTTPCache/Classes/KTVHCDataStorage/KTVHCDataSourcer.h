//
//  KTVHCDataSourcer.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVHCDataSourceProtocol.h"

@interface KTVHCDataSourcer : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)sourcer;

- (void)putSource:(id<KTVHCDataSourceProtocol>)source;
- (void)popSource:(id<KTVHCDataSourceProtocol>)source;

- (void)start;
- (void)stop;

@end
