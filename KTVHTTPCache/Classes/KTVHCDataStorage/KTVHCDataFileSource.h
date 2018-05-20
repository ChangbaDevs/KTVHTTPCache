//
//  KTVHCDataFileSource.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVHCDataSourceProtocol.h"

@interface KTVHCDataFileSource : NSObject <KTVHCDataSourceProtocol>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithPath:(NSString *)path
                      offset:(long long)offset
                      length:(long long)length
                  readOffset:(long long)readOffset
                  readLength:(long long)readLength;

@property (nonatomic, copy, readonly) NSString * path;
@property (nonatomic, assign, readonly) long long offset;
@property (nonatomic, assign, readonly) long long length;
@property (nonatomic, assign, readonly) long long readOffset;
@property (nonatomic, assign, readonly) long long readLength;

@property (nonatomic, assign, readonly) BOOL didPrepared;
@property (nonatomic, assign, readonly) BOOL didFinished;
@property (nonatomic, assign, readonly) BOOL didClosed;

- (void)prepare;
- (void)close;

- (NSData *)readDataOfLength:(NSUInteger)length;

@property (nonatomic, weak, readonly) id <KTVHCDataSourceDelegate> delegate;
@property (nonatomic, strong, readonly) dispatch_queue_t delegateQueue;

- (void)setDelegate:(id <KTVHCDataSourceDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;

@end
