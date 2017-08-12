//
//  KTVHCHTTPResponse.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCHTTPResponse.h"
#import "KTVHCHTTPConnection.h"
#import "KTVHCDataManager.h"

@interface KTVHCHTTPResponse () <KTVHCDataReaderDelegate>

@property (nonatomic, weak) KTVHCHTTPConnection * connection;
@property (nonatomic, strong) KTVHCDataRequest * dataRequest;
@property (nonatomic, strong) KTVHCDataReader * reader;

@property (nonatomic, assign) BOOL waitingResponseHeader;

@end

@implementation KTVHCHTTPResponse

+ (instancetype)responseWithConnection:(KTVHCHTTPConnection *)connection dataRequest:(KTVHCDataRequest *)dataRequest
{
    return [[self alloc] initWithConnection:connection dataRequest:dataRequest];
}

- (instancetype)initWithConnection:(KTVHCHTTPConnection *)connection dataRequest:(KTVHCDataRequest *)dataRequest
{
    if (self = [super init])
    {
        self.connection = connection;
        self.dataRequest = dataRequest;
        
#if 1
        self.reader = [[KTVHCDataManager manager] syncReaderWithRequest:self.dataRequest];
        self.reader.delegate = self;
        [self.reader prepare];
#else
        [[KTVHCDataManager manager] asyncReaderWithRequest:self.dataRequest completionHandler:^(KTVHCDataReader * reader) {
            self.reader = reader;
            self.reader.delegate = self;
            [self.reader prepare];
        }];
#endif
    }
    return self;
}

- (UInt64)contentLength
{
    return self.reader.totalContentLength;
}

- (UInt64)offset
{
    return 0;
}

- (void)setOffset:(UInt64)offset
{
    
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
    NSData * data = [self.reader readDataOfLength:length];
    NSLog(@"%s, %ld, %ld", __func__, self.reader.currentContentLength, self.reader.readedContentLength);
    if (self.reader.didFinishRead) {
        NSLog(@"%s 完成", __func__);
        [self.reader close];
    }
    return data;
}

- (BOOL)delayResponseHeaders
{
    if (!self.reader.didFinishPrepare) {
        self.waitingResponseHeader = YES;
    } else {
        self.waitingResponseHeader = NO;
    }
    return self.waitingResponseHeader;
}

- (NSDictionary *)httpHeaders
{
    return @{
             @"Accept-Ranges" : @"bytes",
             @"Connection" : @"keep-alive",
             @"Content-Type" : @"video/mp4"
             };
}

- (void)connectionDidClose
{
    NSLog(@"%s", __func__);
    [self.reader close];
}

- (BOOL)isDone
{
    NSLog(@"%s", __func__);
    return NO;
}


#pragma mark - KTVHCDataReaderDelegate

- (void)readerHasAvailableData:(KTVHCDataReader *)reader
{
    [self.connection responseHasAvailableData:self];
}

- (void)readerDidFinishPrepare:(KTVHCDataReader *)reader
{
    if (self.reader.didFinishPrepare && self.waitingResponseHeader == YES) {
        [self.connection responseHasAvailableData:self];
    }
}

- (void)reader:(KTVHCDataReader *)reader didFailure:(NSError *)error
{
    [self.connection responseDidAbort:self];
}


@end
