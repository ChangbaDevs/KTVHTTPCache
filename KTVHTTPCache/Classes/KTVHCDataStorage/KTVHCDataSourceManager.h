//
//  KTVHCDataSourceManager.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVHCDataNetworkSource.h"
#import "KTVHCDataFileSource.h"

@class KTVHCDataSourceManager;

@protocol KTVHCDataSourceManagerDelegate <NSObject>

- (void)sourceManagerDidPrepare:(KTVHCDataSourceManager *)sourceManager;
- (void)sourceManagerHasAvailableData:(KTVHCDataSourceManager *)sourceManager;
- (void)sourceManager:(KTVHCDataSourceManager *)sourceManager didFailWithError:(NSError *)error;
- (void)sourceManager:(KTVHCDataSourceManager *)sourceManager didReceiveResponse:(KTVHCDataResponse *)response;

@end

@interface KTVHCDataSourceManager : NSObject <KTVHCDataSource>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithSources:(NSArray<id<KTVHCDataSource>> *)sources
                       delegate:(id <KTVHCDataSourceManagerDelegate>)delegate
                  delegateQueue:(dispatch_queue_t)delegateQueue;

@property (nonatomic, weak, readonly) id <KTVHCDataSourceManagerDelegate> delegate;
@property (nonatomic, strong, readonly) dispatch_queue_t delegateQueue;

@end
