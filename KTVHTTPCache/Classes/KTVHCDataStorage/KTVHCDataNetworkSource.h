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

static NSInteger const KTVHCDataNetworkSourceSizeMaxVaule = -1;

@protocol KTVHCDataNetworkSourceDelegate <NSObject>

@optional
- (void)networkSourceDidFinishPrepare:(KTVHCDataNetworkSource *)networkSource;
- (void)networkSourceDidFinishDownload:(KTVHCDataNetworkSource *)networkSource;
- (void)networkSourceDidFinishRead:(KTVHCDataNetworkSource *)networkSource;
- (void)networkSourceDidCanceled:(KTVHCDataNetworkSource *)networkSource;
- (void)networkSource:(KTVHCDataNetworkSource *)networkSource didFailure:(NSError *)error;

@end

@interface KTVHCDataNetworkSource : NSObject <KTVHCDataSourceProtocol>

+ (instancetype)sourceWithDelegate:(id <KTVHCDataNetworkSourceDelegate>)delegate
                         URLString:(NSString *)URLString
                      headerFields:(NSDictionary *)headerFields
                            offset:(NSInteger)offset
                              size:(NSInteger)size;

@property (nonatomic, weak, readonly) id <KTVHCDataNetworkSourceDelegate> networkSourceDelegate;

@property (nonatomic, copy, readonly) NSString * URLString;

@property (nonatomic, strong, readonly) NSDictionary * requestHeaderFields;
@property (nonatomic, strong, readonly) NSDictionary * responseHeaderFields;

@property (nonatomic, strong, readonly) NSError * error;

@property (nonatomic, assign, readonly) BOOL didFinishPrepare;
@property (nonatomic, assign, readonly) BOOL didFinishDownload;

@property (nonatomic, assign, readonly) NSInteger totalContentLength;

@end
