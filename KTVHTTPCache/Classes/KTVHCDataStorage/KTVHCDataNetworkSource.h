//
//  KTVHCDataNetworkSource.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVHCDataSourceProtocol.h"

static NSInteger const KTVHCDataNetworkSourceSizeMaxVaule = -1;

@interface KTVHCDataNetworkSource : NSObject <KTVHCDataSourceProtocol>

+ (instancetype)sourceWithURLString:(NSString *)URLString
                       headerFields:(NSDictionary *)headerFields
                             offset:(NSInteger)offset
                               size:(NSInteger)size;

@property (nonatomic, copy, readonly) NSString * URLString;
@property (nonatomic, strong, readonly) NSDictionary * headrFields;

@property (nonatomic, assign, readonly) NSInteger offset;
@property (nonatomic, assign, readonly) NSInteger size;

@end
