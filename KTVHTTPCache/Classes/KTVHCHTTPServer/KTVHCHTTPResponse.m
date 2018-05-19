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
#import "KTVHCLog.h"


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
        KTVHCLogAlloc(self);
        
        self.connection = connection;
        self.dataRequest = dataRequest;
        
        KTVHCLogHTTPResponse(@"data request\n%@\n%@", self.dataRequest.URLString, self.dataRequest.headerFields);
        
#if 1
        self.reader = [[KTVHCDataStorage storage] concurrentReaderWithRequest:self.dataRequest];
        self.reader.delegate = self;
        [self.reader prepare];
#else
        [[KTVHCDataStorage storage] serialReaderWithRequest:self.dataRequest completionHandler:^(KTVHCDataReader * reader) {
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
    
    KTVHCLogDealloc(self);
}


#pragma mark - HTTPResponse

- (NSData *)readDataOfLength:(NSUInteger)length
{
    NSData * data = [self.reader readDataOfLength:length];
    
    KTVHCLogHTTPResponse(@"read data length, %lld, %@", (long long)data.length, self.dataRequest.URLString);
    
    if (self.reader.didFinishRead) {
        
        KTVHCLogHTTPResponse(@"read data finished, %@", self.dataRequest.URLString);
        
        [self.reader close];
        [self.connection responseDidAbort:self];
    }
    return data;
}

- (BOOL)delayResponseHeaders
{
    BOOL waiting = !self.reader.didFinishPrepare;
    self.waitingResponseHeader = waiting;
    
    KTVHCLogHTTPResponse(@"delay response, %d", self.waitingResponseHeader);
    
    return waiting;
}

- (UInt64)contentLength
{
    KTVHCLogHTTPResponse(@"conetnt length, %lld", self.reader.response.totalContentLength);
    
    return self.reader.response.totalContentLength;
}

- (NSDictionary *)httpHeaders
{
    KTVHCLogHTTPResponse(@"header fields\n%@", self.reader.response.headerFieldsWithoutRangeAndLength);
    
    return self.reader.response.headerFieldsWithoutRangeAndLength;
}

- (UInt64)offset
{
    KTVHCLogHTTPResponse(@"offset, %lld", self.reader.readOffset);
    
    return self.reader.readOffset;
}

- (void)setOffset:(UInt64)offset
{
    KTVHCLogHTTPResponse(@"set offset, %lld, %lld", offset, self.reader.readOffset);
}

- (BOOL)isDone
{
    KTVHCLogHTTPResponse(@"check done, %d", self.reader.didFinishRead);
    
    return self.reader.didFinishRead;
}

- (void)connectionDidClose
{
    KTVHCLogHTTPResponse(@"connection did close, %lld, %lld", self.reader.response.currentContentLength, self.reader.readOffset);
    
    [self.reader close];
}


#pragma mark - KTVHCDataReaderDelegate

- (void)readerHasAvailableData:(KTVHCDataReader *)reader
{
    KTVHCLogHTTPResponse(@"has available data, %@", self.dataRequest.URLString);
    
    [self.connection responseHasAvailableData:self];
}

- (void)readerDidFinishPrepare:(KTVHCDataReader *)reader
{
    KTVHCLogHTTPResponse(@"prepare finished, %@", self.dataRequest.URLString);
    
    if (self.reader.didFinishPrepare && self.waitingResponseHeader == YES) {
        
        KTVHCLogHTTPResponse(@"prepare finished call, %@", self.dataRequest.URLString);
        
        [self.connection responseHasAvailableData:self];
    }
}

- (void)reader:(KTVHCDataReader *)reader didFailure:(NSError *)error
{
    KTVHCLogHTTPResponse(@"failure, %d, %@", (int)error.code, self.dataRequest.URLString);
    
    [self.reader close];
    [self.connection responseDidAbort:self];
}


@end
