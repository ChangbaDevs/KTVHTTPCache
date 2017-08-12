//
//  KTVHCDataUnit.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVHCDataUnitItem.h"

@class KTVHCDataUnit;

@protocol KTVHCDataUnitDelegate <NSObject>

@optional
- (void)unitDidUpdateTotalContentLength:(KTVHCDataUnit *)unit;
- (void)unitDidUpdateMetadata:(KTVHCDataUnit *)unit;

@end

@interface KTVHCDataUnit : NSObject <NSCoding>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)unitWithURLString:(NSString *)URLString;

@property (nonatomic, weak) id <KTVHCDataUnitDelegate> delegate;

@property (nonatomic, copy, readonly) NSString * URLString;
@property (nonatomic, copy, readonly) NSString * uniqueIdentifier;

@property (nonatomic, strong, readonly) NSDictionary * requestHeaderFields;
@property (nonatomic, strong, readonly) NSDictionary * responseHeaderFields;

@property (nonatomic, assign, readonly) NSInteger totalContentLength;
@property (nonatomic, assign, readonly) NSInteger totalCacheLength;

@property (nonatomic, strong, readonly) NSMutableArray <KTVHCDataUnitItem *> * unitItems;


- (void)insertUnitItem:(KTVHCDataUnitItem *)unitItem;
- (void)updateRequestHeaderFields:(NSDictionary *)requestHeaderFields;
- (void)updateResponseHeaderFields:(NSDictionary *)responseHeaderFields;


#pragma mark - Class Functions

+ (NSString *)uniqueIdentifierWithURLString:(NSString *)URLString;

@end
