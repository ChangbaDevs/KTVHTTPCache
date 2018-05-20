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

@protocol KTVHCDataUnitFileDelegate <NSObject>

- (void)unitShouldRearchive:(KTVHCDataUnit *)unit;

@end

@interface KTVHCDataUnit : NSObject <NSCoding, NSLocking>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)unitWithURL:(NSURL *)URL;

@property (nonatomic, copy, readonly) NSURL * URL;
@property (nonatomic, copy, readonly) NSString * filePath;
@property (nonatomic, copy, readonly) NSString * uniqueIdentifier;

@property (nonatomic, assign, readonly) NSTimeInterval createTimeInterval;
@property (nonatomic, assign, readonly) NSTimeInterval lastItemCreateInterval;

@property (nonatomic, copy, readonly) NSDictionary * requestHeaders;
@property (nonatomic, copy, readonly) NSDictionary * responseHeaders;

@property (nonatomic, assign, readonly) long long totalLength;
@property (nonatomic, assign, readonly) long long cacheLength;
@property (nonatomic, assign, readonly) long long validLength;

- (NSArray <KTVHCDataUnitItem *> *)unitItems;
- (void)insertUnitItem:(KTVHCDataUnitItem *)unitItem;

- (void)updateRequestHeaders:(NSDictionary *)requestHeaders;
- (void)updateResponseHeaders:(NSDictionary *)responseHeaders totalLength:(long long)totalLength;

@property (nonatomic, assign, readonly) NSInteger workingCount;

- (void)workingRetain;
- (void)workingRelease;

@property (nonatomic, weak) id <KTVHCDataUnitFileDelegate> fileDelegate;

- (void)deleteFiles;

@end
