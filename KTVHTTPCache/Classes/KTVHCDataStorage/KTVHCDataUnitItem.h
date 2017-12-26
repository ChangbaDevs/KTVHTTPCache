//
//  KTVHCDataUnitItem.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface KTVHCDataUnitItem : NSObject <NSCoding, NSLocking>


+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)unitItemWithOffset:(long long)offset relativePath:(NSString *)relativePath;

@property (nonatomic, assign, readonly) NSTimeInterval createTimeInterval;

@property (nonatomic, assign) BOOL writing;

@property (nonatomic, assign, readonly) long long offset;
@property (nonatomic, assign) long long length;

@property (nonatomic, copy, readonly) NSString * relativePath;
@property (nonatomic, copy, readonly) NSString * absolutePath;


@end
