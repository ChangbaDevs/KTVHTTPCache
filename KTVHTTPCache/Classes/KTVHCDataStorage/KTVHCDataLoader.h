//
//  KTVHCDataLoader.h
//  KTVHTTPCache
//
//  Created by Single on 2018/6/7.
//  Copyright © 2018 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KTVHCDataLoader;
@class KTVHCDataRequest;
@class KTVHCDataResponse;

@protocol KTVHCDataLoaderDelegate <NSObject>

- (void)loaderDidFinish:(KTVHCDataLoader *)loader;
- (void)loader:(KTVHCDataLoader *)loader didFailWithError:(NSError *)error;
- (void)loader:(KTVHCDataLoader *)loader didChangeProgress:(double)progress;

@end

@interface KTVHCDataLoader : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithRequest:(KTVHCDataRequest *)request NS_DESIGNATED_INITIALIZER;

@property (nonatomic, weak) id <KTVHCDataLoaderDelegate> delegate;
@property (nonatomic, strong) id object;

@property (nonatomic, strong, readonly) KTVHCDataRequest *request;
@property (nonatomic, strong, readonly) KTVHCDataResponse *response;

@property (nonatomic, copy, readonly) NSError *error;

@property (nonatomic, readonly) BOOL finished;
@property (nonatomic, readonly) BOOL closed;

@property (nonatomic, readonly) double progress;

- (void)prepare;
- (void)close;

@end
