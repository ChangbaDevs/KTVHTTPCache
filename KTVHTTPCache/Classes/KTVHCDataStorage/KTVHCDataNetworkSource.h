//
//  KTVHCDataNetworkSource.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVHCDataSourceProtocol.h"

@class KTVHCDataNetworkSource;


static long long const KTVHCDataNetworkSourceLengthMaxVaule = -1;


@protocol KTVHCDataNetworkSourceDelegate <NSObject>

@optional
- (void)networkSourceHasAvailableData:(KTVHCDataNetworkSource *)networkSource;
- (void)networkSourceDidFinishPrepare:(KTVHCDataNetworkSource *)networkSource;
- (void)networkSourceDidFinishDownload:(KTVHCDataNetworkSource *)networkSource;
- (void)networkSource:(KTVHCDataNetworkSource *)networkSource didFailure:(NSError *)error;

@end


@interface KTVHCDataNetworkSource : NSObject <KTVHCDataSourceProtocol>


+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)sourceWithURLString:(NSString *)URLString
                       headerFields:(NSDictionary *)headerFields
           acceptContentTypePrefixs:(NSArray <NSString *> *)acceptContentTypePrefixs
                             offset:(long long)offset
                             length:(long long)length;

@property (nonatomic, copy, readonly) NSString * URLString;

@property (nonatomic, copy, readonly) NSDictionary * requestHeaderFields;
@property (nonatomic, copy, readonly) NSDictionary * responseHeaderFields;

@property (nonatomic, strong, readonly) NSError * error;

@property (nonatomic, assign, readonly) BOOL didFinishPrepare;
@property (nonatomic, assign, readonly) BOOL didFinishDownload;

@property (nonatomic, assign, readonly) long long totalContentLength;


#pragma mark - Delegate

@property (nonatomic, weak, readonly) id <KTVHCDataNetworkSourceDelegate> delegate;
@property (nonatomic, strong, readonly) dispatch_queue_t delegateQueue;

- (void)setDelegate:(id <KTVHCDataNetworkSourceDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;


#pragma mark - Class

+ (void)setContentTypeFilterBlock:(BOOL(^)(NSString * URLString,
                                           NSString * contentType,
                                           NSArray <NSString *> * defaultAcceptContentTypes))contentTypeFilterBlock;


@end
