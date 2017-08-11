//
//  KTVHCDataUnit.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVHCDataUnitItem.h"

@interface KTVHCDataUnit : NSObject

+ (instancetype)unitWithURLString:(NSString *)URLString;

+ (NSString *)uniqueIdentifierWithURLString:(NSString *)URLString;

@property (nonatomic, copy, readonly) NSString * URLString;
@property (nonatomic, copy, readonly) NSString * uniqueIdentifier;

@property (nonatomic, assign, readonly) NSInteger totalContentSize;
@property (nonatomic, assign, readonly) NSInteger totalCacheSize;

@property (nonatomic, strong, readonly) NSArray <KTVHCDataUnitItem *> * fileUnitItems;

@end
