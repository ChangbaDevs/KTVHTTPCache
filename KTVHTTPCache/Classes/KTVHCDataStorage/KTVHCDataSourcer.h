//
//  KTVHCDataSourcer.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVHCDataSourceProtocol.h"
#import "KTVHCDataFileSource.h"
#import "KTVHCDataNetworkSource.h"

@class KTVHCDataSourcer;

@protocol KTVHCDataSourcerDelegate <NSObject>

- (void)sourcerDidFinishPrepare:(KTVHCDataSourcer *)sourcer;
- (void)sourcer:(KTVHCDataSourcer *)sourcer didFailure:(NSError *)error;

@end

@interface KTVHCDataSourcer : NSObject <KTVHCDataFileSourceDelegate, KTVHCDataNetworkSourceDelegate>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)sourcerWithDelegate:(id <KTVHCDataSourcerDelegate>)delegate;

@property (nonatomic, weak, readonly) id <KTVHCDataSourcerDelegate> delegate;

@property (nonatomic, strong, readonly) NSError * error;

@property (nonatomic, assign, readonly) BOOL didClose;
@property (nonatomic, assign, readonly) BOOL didFinishPrepare;
@property (nonatomic, assign, readonly) BOOL didFinishRead;

- (void)putSource:(id<KTVHCDataSourceProtocol>)source;
- (void)putSourceDidFinish;

- (void)prepare;
- (void)close;

- (NSData *)syncReadDataOfLength:(NSUInteger)length;

@end
