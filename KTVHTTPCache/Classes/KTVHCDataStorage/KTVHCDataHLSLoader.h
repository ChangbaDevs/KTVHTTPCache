//
//  KTVHCDataHLSLoader.h
//  KTVHTTPCache
//
//  Created by Single on 2025/6/27.
//  Copyright © 2025 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KTVHCDataLoader;
@class KTVHCDataHLSLoader;
@class KTVHCDataRequest;
@class KTVHCDataResponse;

@protocol KTVHCDataHLSLoaderDelegate <NSObject>

- (void)ktv_HLSLoaderDidFinish:(KTVHCDataHLSLoader *)loader;
- (void)ktv_HLSLoader:(KTVHCDataHLSLoader *)loader didFailWithError:(NSError *)error;
- (void)ktv_HLSLoader:(KTVHCDataHLSLoader *)loader didChangeProgress:(double)progress;

@optional
- (NSArray<NSURL *> *)ktv_HLSLoader:(KTVHCDataHLSLoader *)loader makeURLsForContent:(NSString *)content;
- (NSArray<KTVHCDataLoader *> *)ktv_HLSLoader:(KTVHCDataHLSLoader *)loader makeLoadersForURLs:(NSArray<NSURL *> *)URLs;

@end

@interface KTVHCDataHLSLoader : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, weak) id <KTVHCDataHLSLoaderDelegate> delegate;
@property (nonatomic, strong) id object;

@property (nonatomic, strong, readonly) KTVHCDataRequest *request;

@property (nonatomic, copy, readonly) NSError *error;

@property (nonatomic, readonly, getter=isFinished) BOOL finished;
@property (nonatomic, readonly, getter=isClosed) BOOL closed;

@property (nonatomic, readonly) double progress;

- (void)prepare;
- (void)close;

@end
