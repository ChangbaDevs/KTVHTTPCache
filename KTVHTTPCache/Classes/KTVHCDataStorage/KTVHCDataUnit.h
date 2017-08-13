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

@interface KTVHCDataUnit : NSObject <NSCoding, NSLocking>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)unitWithURLString:(NSString *)URLString;

@property (nonatomic, weak) id <KTVHCDataUnitDelegate> delegate;

@property (nonatomic, copy, readonly) NSString * URLString;
@property (nonatomic, copy, readonly) NSString * uniqueIdentifier;

@property (nonatomic, strong, readonly) NSDictionary * requestHeaderFields;
@property (nonatomic, strong, readonly) NSDictionary * requestHeaderFieldsWithoutRange;
@property (nonatomic, strong, readonly) NSDictionary * responseHeaderFields;
@property (nonatomic, strong, readonly) NSDictionary * responseHeaderFieldsWithoutRangeAndLength;

@property (nonatomic, assign, readonly) long long totalContentLength;
@property (nonatomic, assign, readonly) long long totalCacheLength;

@property (nonatomic, strong, readonly) NSMutableArray <KTVHCDataUnitItem *> * unitItems;

- (void)sortUnitItems;
- (void)insertUnitItem:(KTVHCDataUnitItem *)unitItem;
- (void)updateRequestHeaderFields:(NSDictionary *)requestHeaderFields;
- (void)updateResponseHeaderFields:(NSDictionary *)responseHeaderFields;


#pragma mark - Working State

@property (nonatomic, assign, readonly) BOOL working;

- (void)workingRetain;
- (void)workingRelease;


#pragma mark - File

@property (nonatomic, copy, readonly) NSString * fileFolderPath;


#pragma mark - Class Functions

+ (NSString *)uniqueIdentifierWithURLString:(NSString *)URLString;

@end
