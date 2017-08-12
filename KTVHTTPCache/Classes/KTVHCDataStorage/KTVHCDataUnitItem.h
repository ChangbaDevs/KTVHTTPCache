//
//  KTVHCDataUnitItem.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KTVHCDataUnitItem : NSObject <NSCoding>

+ (instancetype)unitItemWithOffset:(NSInteger)offset path:(NSString *)path;

@property (nonatomic, assign) BOOL writing;

@property (nonatomic, assign, readonly) NSInteger offset;
@property (nonatomic, assign) NSInteger size;

@property (nonatomic, copy, readonly) NSString * path;
@property (nonatomic, copy, readonly) NSString * filePath;

@end
