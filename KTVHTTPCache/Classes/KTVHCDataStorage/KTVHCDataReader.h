//
//  KTVHCDataReader.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KTVHCDataReader;
@class KTVHCDataRequest;
@class KTVHCDataResponse;


@protocol KTVHCDataReaderDelegate <NSObject>

- (void)readerHasAvailableData:(KTVHCDataReader *)reader;
- (void)readerDidFinishPrepare:(KTVHCDataReader *)reader;
- (void)reader:(KTVHCDataReader *)reader didFailure:(NSError *)error;

@end


@interface KTVHCDataReader : NSObject


+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, weak) id <KTVHCDataReaderDelegate> delegate;
@property (nonatomic, strong, readonly) dispatch_queue_t delegateQueue;     // a serial queue. don't block it.

@property (nonatomic, strong) id object;

@property (nonatomic, strong, readonly) KTVHCDataRequest * request;
@property (nonatomic, strong, readonly) KTVHCDataResponse * response;

@property (nonatomic, strong, readonly) NSError * error;

@property (nonatomic, assign, readonly) BOOL didClose;
@property (nonatomic, assign, readonly) BOOL didFinishPrepare;
@property (nonatomic, assign, readonly) BOOL didFinishRead;

@property (nonatomic, assign, readonly) long long readOffset;

- (void)prepare;
- (void)close;      // must call.

- (NSData *)readDataOfLength:(NSUInteger)length;


@end
