//
//  KTVHCDataUnitItem.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVHCDataRequest.h"

@interface KTVHCDataUnitItem : NSObject <NSCoding, NSLocking>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithPath:(NSString *)path;
- (instancetype)initWithRequest:(KTVHCDataRequest *)request;

@property (nonatomic, copy, readonly) NSString * relativePath;
@property (nonatomic, copy, readonly) NSString * absolutePath;
@property (nonatomic, assign, readonly) NSTimeInterval createTimeInterval;
@property (nonatomic, assign, readonly) long long offset;
@property (nonatomic, assign, readonly) long long length;

- (void)setLength:(long long)length;

@end
