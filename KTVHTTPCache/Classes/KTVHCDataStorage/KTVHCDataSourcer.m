//
//  KTVHCDataSourcer.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataSourcer.h"
#import "KTVHCDataSourceQueue.h"
#import "KTVHCDataCallback.h"
#import "KTVHCLog.h"

@interface KTVHCDataSourcer () <NSLocking, KTVHCDataFileSourceDelegate, KTVHCDataNetworkSourceDelegate>

@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) KTVHCDataSourceQueue * sourceQueue;
@property (nonatomic, strong) id <KTVHCDataSourceProtocol> currentSource;
@property (nonatomic, strong) KTVHCDataNetworkSource * currentNetworkSource;
@property (nonatomic, assign) BOOL didCalledPrepare;
@property (nonatomic, assign) BOOL didCalledReceiveResponse;

@end

@implementation KTVHCDataSourcer

- (instancetype)initWithDelegate:(id <KTVHCDataSourcerDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        _delegate = delegate;
        _delegateQueue = delegateQueue;
        self.sourceQueue = [KTVHCDataSourceQueue sourceQueue];
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}

- (void)putSource:(id<KTVHCDataSourceProtocol>)source
{
    KTVHCLogDataSourcer(@"put source, %@", source);
    [self.sourceQueue putSource:source];
}

- (void)prepare
{
    [self lock];
    if (self.didClosed) {
        [self unlock];
        return;
    }
    if (self.didCalledPrepare) {
        [self unlock];
        return;
    }
    _didCalledPrepare = YES;
    KTVHCLogDataSourcer(@"call prepare");
    [self.sourceQueue sortSources];
    [self.sourceQueue setAllSourceDelegate:self delegateQueue:self.delegateQueue];
    self.currentSource = [self.sourceQueue fetchFirstSource];
    self.currentNetworkSource = [self.sourceQueue fetchFirstNetworkSource];
    KTVHCLogDataSourcer(@"current source & network source, %@, %@", self.currentSource, self.currentNetworkSource);
    [self.currentSource prepare];
    if (self.currentSource != self.currentNetworkSource) {
        [self.currentNetworkSource prepare];
    }
    [self unlock];
}

- (void)close
{
    [self lock];
    if (self.didClosed) {
        [self unlock];
        return;
    }
    _didClosed = YES;
    KTVHCLogDataSourcer(@"call close");
    [self.sourceQueue closeAllSource];
    [self unlock];
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
    [self lock];
    if (self.didClosed) {
        [self unlock];
        return nil;
    }
    if (self.didFinished) {
        [self unlock];
        return nil;
    }
    if (self.error) {
        [self unlock];
        return nil;
    }
    NSData * data = [self.currentSource readDataOfLength:length];
    if (self.currentSource.didFinished) {
        self.currentSource = [self.sourceQueue fetchNextSource:self.currentSource];
        if (self.currentSource) {
            KTVHCLogDataSourcer(@"change to next source, %@", self.currentSource);
            if ([self.currentSource isKindOfClass:[KTVHCDataFileSource class]]) {
                [self.currentSource prepare];
            }
        } else {
            KTVHCLogDataSourcer(@"read finished, %@", self);
            _didFinished = YES;
        }
    }
    [self unlock];
    return data;
}

- (void)callbackForPrepared
{
    KTVHCLogDataSourcer(@"source did prepared, %@", self);
    if (self.didClosed) {
        return;
    }
    if (self.didPrepared) {
        return;
    }
    _didPrepared = YES;
    KTVHCLogDataSourcer(@"prepare finished, %@", self);
    if ([self.delegate respondsToSelector:@selector(sourcerDidPrepared:)]) {
        [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
            [self.delegate sourcerDidPrepared:self];
        }];
    }
}

- (void)callbackForReceiveResponse:(KTVHCDataResponse *)response
{
    if (self.didClosed) {
        return;
    }
    if (self.didCalledReceiveResponse) {
        return;
    }
    _didCalledReceiveResponse = YES;
    KTVHCLogDataSourcer(@"source did receive response, %@", self);
    if ([self.delegate respondsToSelector:@selector(sourcer:didReceiveResponse:)]) {
        [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
            [self.delegate sourcer:self didReceiveResponse:response];
        }];
    }
}

- (void)fileSourceDidPrepared:(KTVHCDataFileSource *)fileSource
{
    [self lock];
    [self callbackForPrepared];
    [self unlock];
}

- (void)networkSourceDidPrepared:(KTVHCDataNetworkSource *)networkSource
{
    [self lock];
    [self callbackForPrepared];
    [self callbackForReceiveResponse:networkSource.response];
    [self unlock];
}

- (void)networkSourceHasAvailableData:(KTVHCDataNetworkSource *)networkSource
{
    [self lock];
    KTVHCLogDataSourcer(@"network source has available data, %@", networkSource);
    if ([self.delegate respondsToSelector:@selector(sourcerHasAvailableData:)]) {
        [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
            [self.delegate sourcerHasAvailableData:self];
        }];
    }
    [self unlock];
}

- (void)networkSourceDidFinishedDownload:(KTVHCDataNetworkSource *)networkSource
{
    [self lock];
    KTVHCLogDataSourcer(@"network source download finsiehd, %@", networkSource);
    self.currentNetworkSource = [self.sourceQueue fetchNextNetworkSource:self.currentNetworkSource];
    [self.currentNetworkSource prepare];
    [self unlock];
}

- (void)networkSource:(KTVHCDataNetworkSource *)networkSource didFailed:(NSError *)error
{
    [self lock];
    KTVHCLogDataSourcer(@"network source failure, %d", (int)error.code);
    if (self.didClosed) {
        [self unlock];
        return;
    }
    if (self.error) {
        [self unlock];
        return;
    }
    _error = error;
    KTVHCLogDataSourcer(@"failure, %d", (int)self.error.code);
    if (self.error && [self.delegate respondsToSelector:@selector(sourcer:didFailed:)]) {
        [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
            [self.delegate sourcer:self didFailed:self.error];
        }];
    }
    [self unlock];
}

- (void)lock
{
    if (!self.coreLock) {
        self.coreLock = [[NSLock alloc] init];
    }
    [self.coreLock lock];
}

- (void)unlock
{
    [self.coreLock unlock];
}

@end
