//
//  KTVHCHTTPResponse.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCHTTPResponse.h"
#import "KTVHCHTTPConnection.h"
#import "KTVHCDataStorage.h"

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
        self.reader = [[KTVHCDataStorage manager] concurrentReaderWithRequest:self.dataRequest];
        self.reader.delegate = self;
        [self.reader prepare];
#else
        [[KTVHCDataStorage manager] serialReaderWithRequest:self.dataRequest completionHandler:^(KTVHCDataReader * reader) {
            self.reader = reader;
            self.reader.delegate = self;
            [self.reader prepare];
        }];
#endif
    }
    return self;
}

- (void)dealloc
{
    [self.reader close];
    [self.connection responseDidAbort:self];
}


#pragma mark - HTTPResponse

- (NSData *)readDataOfLength:(NSUInteger)length
{
    NSData * data = [self.reader readDataOfLength:length];
    if (self.reader.didFinishRead) {
        [self.reader close];
        [self.connection responseDidAbort:self];
    }
    return data;
}

- (BOOL)delayResponseHeaders
{
    BOOL waiting = !self.reader.didFinishPrepare;
    self.waitingResponseHeader = waiting;
    return waiting;
}

- (UInt64)contentLength
{
    return self.reader.totalContentLength;
}

- (NSDictionary *)httpHeaders
{
    return @{
             @"Accept-Ranges" : @"bytes",
             @"Connection" : @"keep-alive",
             @"Content-Type" : @"video/mp4"
             };
}

- (UInt64)offset
{
    
    return self.reader.readedContentLength;
}

- (void)setOffset:(UInt64)offset
{
    
}

- (BOOL)isDone
{
    return self.reader.didFinishRead;
}

- (void)connectionDidClose
{
    [self.reader close];
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
    [self.reader close];
    [self.connection responseDidAbort:self];
}


@end
