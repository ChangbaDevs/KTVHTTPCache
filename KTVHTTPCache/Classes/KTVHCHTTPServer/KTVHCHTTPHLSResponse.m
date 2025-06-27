//
//  KTVHCHTTPHLSResponse.m
//  KTVHTTPCache
//
//  Created by Gary Zhao on 2024/1/7.
//  Copyright © 2024 Single. All rights reserved.
//

#import "KTVHCHTTPHLSResponse.h"
#import "KTVHCHTTPConnection.h"
#import "KTVHCDataUnitPool.h"
#import "KTVHCDownload.h"
#import "KTVHCHLSTool.h"
#import "KTVHCLog.h"

@interface KTVHCHTTPHLSResponse ()

@property (nonatomic, weak) KTVHCHTTPConnection *connection;

@property (nonatomic) UInt64 readedLength;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) KTVHCDataUnit *unit;
@property (nonatomic, strong) NSURLSessionDataTask *task;

@end

@implementation KTVHCHTTPHLSResponse

- (instancetype)initWithConnection:(KTVHCHTTPConnection *)connection dataRequest:(KTVHCDataRequest *)dataRequest
{
    if (self = [super init]) {
        KTVHCLogAlloc(self);
        KTVHCLogHTTPHLSResponse(@"%p, Create response\nrequest : %@", self, dataRequest);
        self.connection = connection;
        self.unit = [[KTVHCDataUnitPool pool] unitWithURL:dataRequest.URL];
        NSURL *completeURL = self.unit.completeURL;
        if (completeURL) {
            self.data = [NSData dataWithContentsOfURL:completeURL];
        } else {
            __weak typeof(self) weakSelf = self;
            self.task = [[KTVHCHLSTool tool] taskWithURL:dataRequest.URL completionHandler:^(NSData *data, NSError *error) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf handleResponeWithData:data error:error];
            }];
            [self.task resume];
        }
    }
    return self;
}

- (void)dealloc
{
    [self.unit workingRelease];
    [self.task cancel];
    KTVHCLogDealloc(self);
}

#pragma mark - HTTPResponse

- (void)handleResponeWithData:(NSData *)data error:(NSError *)error
{
    if (error || data.length == 0) {
        [self.connection responseDidAbort:self];
        KTVHCLogHTTPHLSResponse(@"%p, Handle response error: %@", self, error);
    } else {
        self.data = data;
        [self.connection responseHasAvailableData:self];
    }
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
    KTVHCLogHTTPHLSResponse(@"%p, Read data : %lld", self, (long long)self.data.length);
    self.readedLength = self.data.length;
    return self.data;
}

- (BOOL)delayResponseHeaders
{
    KTVHCLogHTTPHLSResponse(@"%p, Delay response : %d", self, self.self.data.length == 0);
    return self.data.length == 0;
}

- (UInt64)contentLength
{
    KTVHCLogHTTPHLSResponse(@"%p, Conetnt length : %lld", self, self.unit.totalLength);
    return self.data.length;
}

- (NSDictionary *)httpHeaders
{
    KTVHCLogHTTPHLSResponse(@"%p, Header\n%@", self, self.unit.responseHeaders);
    return self.unit.responseHeaders;
}

- (UInt64)offset
{
    KTVHCLogHTTPHLSResponse(@"%p, Offset : %lld", self, self.readedLength);
    return self.readedLength;
}

- (void)setOffset:(UInt64)offset
{
    KTVHCLogHTTPHLSResponse(@"%p, Set offset : %lld, %ld", self, offset, self.data.length);
}

- (BOOL)isDone
{
    KTVHCLogHTTPHLSResponse(@"%p, Check done : %lld", self, self.unit.totalLength);
    return self.readedLength > 0;
}

- (void)connectionDidClose
{
    KTVHCLogHTTPHLSResponse(@"%p, Connection did closed : %lld, %lld", self, self.unit.totalLength, self.unit.cacheLength);
    [self.task cancel];
}

@end
