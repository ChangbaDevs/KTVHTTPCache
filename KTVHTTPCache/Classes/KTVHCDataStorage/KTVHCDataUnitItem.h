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

+ (instancetype)unitItemWithOffset:(long long)offset path:(NSString *)path;

@property (nonatomic, assign) BOOL writing;

@property (nonatomic, assign, readonly) long long offset;
@property (nonatomic, assign) long long length;

@property (nonatomic, copy, readonly) NSString * path;
@property (nonatomic, copy, readonly) NSString * filePath;

- (void)reloadFileLength;

@end
