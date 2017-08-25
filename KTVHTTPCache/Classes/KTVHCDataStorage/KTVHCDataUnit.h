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


@protocol KTVHCDataUnitWorkingDelegate <NSObject>

@optional
- (void)unitDidStopWorking:(KTVHCDataUnit *)unit;

@end


@interface KTVHCDataUnit : NSObject <NSCoding, NSLocking>


+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)unitWithURLString:(NSString *)URLString;

@property (nonatomic, copy, readonly) NSString * URLString;
@property (nonatomic, copy, readonly) NSString * uniqueIdentifier;

@property (nonatomic, assign, readonly) NSTimeInterval createTimeInterval;
@property (nonatomic, assign, readonly) NSTimeInterval lastItemCerateInterval;

@property (nonatomic, copy, readonly) NSDictionary * requestHeaderFields;
@property (nonatomic, copy, readonly) NSDictionary * requestHeaderFieldsWithoutRange;
@property (nonatomic, copy, readonly) NSDictionary * responseHeaderFields;
@property (nonatomic, copy, readonly) NSDictionary * responseHeaderFieldsWithoutRangeAndLength;

@property (nonatomic, assign, readonly) long long totalContentLength;
@property (nonatomic, assign, readonly) long long totalCacheLength;

@property (nonatomic, strong, readonly) NSMutableArray <KTVHCDataUnitItem *> * unitItems;


#pragma mark - Control

- (void)sortUnitItems;
- (void)insertUnitItem:(KTVHCDataUnitItem *)unitItem;
- (void)updateRequestHeaderFields:(NSDictionary *)requestHeaderFields;
- (void)updateResponseHeaderFields:(NSDictionary *)responseHeaderFields;


#pragma mark - Delegate

@property (nonatomic, weak, readonly) id <KTVHCDataUnitDelegate> delegate;
@property (nonatomic, strong, readonly) dispatch_queue_t delegateQueue;

- (void)setDelegate:(id <KTVHCDataUnitDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;


#pragma mark - Working State

@property (nonatomic, weak) id <KTVHCDataUnitWorkingDelegate> workingDelegate;

@property (nonatomic, assign, readonly) BOOL working;

- (void)workingRetain;
- (void)workingRelease;


#pragma mark - File

@property (nonatomic, copy, readonly) NSString * absolutePathForFileDirectory;

- (void)deleteFiles;
- (BOOL)mergeFiles;


#pragma mark - Class Functions

+ (NSString *)uniqueIdentifierWithURLString:(NSString *)URLString;


@end
