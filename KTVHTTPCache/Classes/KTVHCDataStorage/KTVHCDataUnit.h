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

- (instancetype)initWithURL:(NSURL *)URL;

@property (nonatomic, copy, readonly) NSError *error;

@property (nonatomic, copy, readonly) NSURL *URL;
@property (nonatomic, copy, readonly) NSURL *fileURL;
@property (nonatomic, copy, readonly) NSString *key;       // Unique Identifier.

@property (nonatomic, readonly) NSTimeInterval createTimeInterval;
@property (nonatomic, readonly) NSTimeInterval lastItemCreateInterval;

@property (nonatomic, copy, readonly) NSDictionary *requestHeaders;
@property (nonatomic, copy, readonly) NSDictionary *responseHeaders;

@property (nonatomic, readonly) long long totalLength;
@property (nonatomic, readonly) long long cacheLength;
@property (nonatomic, readonly) long long validLength;

/**
 *  Unit Item
 */
- (NSArray <KTVHCDataUnitItem *> *)unitItems;
- (void)insertUnitItem:(KTVHCDataUnitItem *)unitItem;

/**
 *  Info Sync
 */
- (void)updateRequestHeaders:(NSDictionary *)requestHeaders;
- (void)updateResponseHeaders:(NSDictionary *)responseHeaders totalLength:(long long)totalLength;

/**
 *  Working
 */
@property (nonatomic, assign, readonly) NSInteger workingCount;

- (void)workingRetain;
- (void)workingRelease;

/**
 *  File Control
 */
@property (nonatomic, weak) id <KTVHCDataUnitFileDelegate> fileDelegate;

- (void)deleteFiles;

@end
