//
//  KTVHCHTTPResponse.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCHTTPResponse.h"
#import "KTVHCHTTPConnection.h"
#import "KTVHCHTTPRequest.h"
#import "KTVHCDataStorage.h"
#import "KTVHCLog.h"

@interface KTVHCHTTPResponse () <KTVHCDataReaderDelegate>

@property (nonatomic, weak) KTVHCHTTPConnection * connection;
@property (nonatomic, strong) KTVHCHTTPRequest * request;
@property (nonatomic, strong) KTVHCDataRequest * dataRequest;
@property (nonatomic, strong) KTVHCDataReader * reader;
@property (nonatomic, assign) BOOL waitingResponseHeader;

@end

@implementation KTVHCHTTPResponse

- (instancetype)initWithConnection:(KTVHCHTTPConnection *)connection request:(KTVHCHTTPRequest *)request
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        self.connection = connection;
        self.request = request;
        KTVHCDataRequest * dataRequest = [[KTVHCDataRequest alloc] initWithURL:self.request.URL headerFields:self.request.headers];
        self.reader = [[KTVHCDataStorage storage] readerWithRequest:dataRequest];
        self.reader.delegate = self;
        [self.reader prepare];
        KTVHCLogHTTPResponse(@"%p, Create response\nrequest : %@", self, self.request);
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
    KTVHCLogHTTPResponse(@"%p, Read data : %lld", self, (long long)data.length);
    if (self.reader.finished)
    {
        KTVHCLogHTTPResponse(@"%p, Read data did finished", self);
        [self.reader close];
        [self.connection responseDidAbort:self];
    }
    return data;
}

- (BOOL)delayResponseHeaders
{
    BOOL waiting = !self.reader.prepared;
    self.waitingResponseHeader = waiting;
    KTVHCLogHTTPResponse(@"%p, Delay response : %d", self, self.waitingResponseHeader);
    return waiting;
}

- (UInt64)contentLength
{
    KTVHCLogHTTPResponse(@"%p, Conetnt length : %lld", self, self.reader.response.totalLength);
    return self.reader.response.totalLength;
}

- (NSDictionary *)httpHeaders
{
    KTVHCLogHTTPResponse(@"%p, Header\n%@", self, self.reader.response.headerFieldsWithoutRangeAndLength);
    return self.reader.response.headerFieldsWithoutRangeAndLength;
}

- (UInt64)offset
{
    KTVHCLogHTTPResponse(@"%p, Offset : %lld", self, self.reader.readedLength);
    return self.reader.readedLength;
}

- (void)setOffset:(UInt64)offset
{
    KTVHCLogHTTPResponse(@"%p, Set offset : %lld, %lld", self, offset, self.reader.readedLength);
}

- (BOOL)isDone
{
    KTVHCLogHTTPResponse(@"%p, Check done : %d", self, self.reader.finished);
    return self.reader.finished;
}

- (void)connectionDidClose
{
    KTVHCLogHTTPResponse(@"%p, Connection did closed : %lld, %lld", self, self.reader.response.currentLength, self.reader.readedLength);
    [self.reader close];
}

#pragma mark - KTVHCDataReaderDelegate

- (void)readerDidPrepare:(KTVHCDataReader *)reader
{
    KTVHCLogHTTPResponse(@"%p, Prepared", self);
    if (self.reader.prepared && self.waitingResponseHeader == YES)
    {
        KTVHCLogHTTPResponse(@"%p, Call connection did prepared", self);
        [self.connection responseHasAvailableData:self];
    }
}

- (void)readerHasAvailableData:(KTVHCDataReader *)reader
{
    KTVHCLogHTTPResponse(@"%p, Has available data", self);
    [self.connection responseHasAvailableData:self];
}

- (void)reader:(KTVHCDataReader *)reader didFailWithError:(NSError *)error
{
    KTVHCLogHTTPResponse(@"%p, Failed\nError : %@", self, error);
    [self.reader close];
    [self.connection responseDidAbort:self];
}

@end
