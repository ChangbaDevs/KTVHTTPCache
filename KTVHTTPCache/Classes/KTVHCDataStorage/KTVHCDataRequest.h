//
//  KTVHCDataRequest.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVHCRange.h"

@interface KTVHCDataRequest : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithURL:(NSURL *)URL headerFields:(NSDictionary *)headerFields NS_DESIGNATED_INITIALIZER;

@property (nonatomic, copy, readonly) NSURL *URL;
@property (nonatomic, copy, readonly) NSDictionary *headerFields;
@property (nonatomic, readonly) KTVHCRange range;

- (KTVHCDataRequest *)requestWithRange:(KTVHCRange)range;
- (KTVHCDataRequest *)requestWithTotalLength:(long long)totalLength;

@end
