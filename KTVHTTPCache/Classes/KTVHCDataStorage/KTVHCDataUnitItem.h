//
//  KTVHCDataUnitItem.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KTVHCDataUnitItem : NSObject

+ (instancetype)unitItemWithOffset:(NSInteger)offset filePath:(NSString *)filePath;

@property (nonatomic, assign, readonly) NSInteger offset;
@property (nonatomic, assign) NSInteger size;

@property (nonatomic, copy, readonly) NSString * filePath;

@end
