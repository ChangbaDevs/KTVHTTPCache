//
//  KTVHCDataNetworkSource.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataNetworkSource.h"
#import "KTVHCDataStorage.h"
#import "KTVHCPathTools.h"
#import "KTVHCDataUnitPool.h"
#import "KTVHCDataCallback.h"
#import "KTVHCDownload.h"
#import "KTVHCLog.h"

@interface KTVHCDataNetworkSource () <NSLocking, KTVHCDownloadDelegate>

@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, copy) NSString * path;
@property (nonatomic, strong) NSError * error;
@property (nonatomic, strong) KTVHCDataUnitItem * unitItem;
@property (nonatomic, strong) NSFileHandle * readingHandle;
@property (nonatomic, strong) NSFileHandle * writingHandle;
@property (nonatomic, assign) long long downloadLength;
@property (nonatomic, assign) long long downloadReadedLength;
@property (nonatomic, assign) BOOL downloadDidCallComplete;
@property (nonatomic, assign) BOOL needCallHasAvailableData;

@end

@implementation KTVHCDataNetworkSource

- (instancetype)initWithRequest:(KTVHCDataRequest *)reqeust range:(KTVHCRange)range
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        _request = reqeust;
        _range = range;
        KTVHCLogDataNetworkSource(@"did setup\n%@\n%@\n%@\n%@", self.request.URL, self.request.headers, self.request.acceptContentTypes, KTVHCStringFromRange(self.range));
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}

- (void)prepare
{
    if (self.didClosed) {
        return;
    }
    if (self.didPrepared) {
        return;
    }
    [self lock];
    KTVHCLogDataNetworkSource(@"call prepare");
    [[KTVHCDownload download] downloadWithRequest:self.request delegate:self];
    [self unlock];
}

- (void)close
{
    if (self.didClosed) {
        return;
    }
    KTVHCLogDataNetworkSource(@"call close begin");
    [self lock];
    _didClosed = YES;
    [self.readingHandle closeFile];
    self.readingHandle = nil;
    if (!self.downloadDidCallComplete) {
        [[KTVHCDownload download] cancelWithRequest:self.request];
    }
    [self.writingHandle synchronizeFile];
    [self.writingHandle closeFile];
    self.writingHandle = nil;
    KTVHCLogDataNetworkSource(@"call close end");
    [self unlock];
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
    if (self.didClosed) {
        return nil;
    }
    if (self.didFinished) {
        return nil;
    }
    if (self.error) {
        return nil;
    }
    [self lock];
    if (self.downloadReadedLength >= self.downloadLength)
    {
        if (self.downloadDidCallComplete)
        {
            KTVHCLogDataNetworkSource(@"read data error : %lld, %lld, %lld", self.downloadReadedLength, self.downloadLength, KTVHCRangeGetLength(self.range));
            [self.readingHandle closeFile];
            self.readingHandle = nil;
        }
        else
        {
            KTVHCLogDataNetworkSource(@"read data set need call");
            self.needCallHasAvailableData = YES;
        }
        [self unlock];
        return nil;
    }
    NSData * data = [self.readingHandle readDataOfLength:(NSUInteger)MIN(self.downloadLength - self.downloadReadedLength, length)];
    self.downloadReadedLength += data.length;
    KTVHCLogDataNetworkSource(@"read data : %lld, %lld, %lld, %lld", (long long)data.length, self.downloadReadedLength, self.downloadLength, KTVHCRangeGetLength(self.range));
    if (self.downloadReadedLength >= KTVHCRangeGetLength(self.range))
    {
        KTVHCLogDataNetworkSource(@"read data finished");
        [self.readingHandle closeFile];
        self.readingHandle = nil;
        _didFinished = YES;
    }
    [self unlock];
    return data;
}

- (void)setDelegate:(id <KTVHCDataNetworkSourceDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    _delegate = delegate;
    _delegateQueue = delegateQueue;
}


#pragma mark - KTVHCDownloadDelegate

- (void)download:(KTVHCDownload *)download didCompleteWithError:(NSError *)error
{
    [self lock];
    self.downloadDidCallComplete = YES;
    [self.writingHandle synchronizeFile];
    [self.writingHandle closeFile];
    self.writingHandle = nil;
    if (self.didClosed) {
        KTVHCLogDataNetworkSource(@"complete but did close, %@, %d", self.request.URL.absoluteString, (int)error.code);
    } else {
        if (error) {
            self.error = error;
            if (self.error.code != NSURLErrorCancelled) {
                KTVHCLogDataNetworkSource(@"complete by error, %@, %d",  self.request.URL.absoluteString, (int)error.code);
                if ([self.delegate respondsToSelector:@selector(networkSource:didFailed:)]) {
                    [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
                        [self.delegate networkSource:self didFailed:self.error];
                    }];
                }
            } else {
                KTVHCLogDataNetworkSource(@"complete by cancel, %@, %d",  self.request.URL.absoluteString, (int)error.code);
            }
        } else {
            if (self.downloadLength >= KTVHCRangeGetLength(self.range)) {
                KTVHCLogDataNetworkSource(@"complete by donwload finished, %@", self.request.URL.absoluteString);
                if ([self.delegate respondsToSelector:@selector(networkSourceDidFinishedDownload:)]) {
                    [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
                        [self.delegate networkSourceDidFinishedDownload:self];
                    }];
                }
            } else {
                KTVHCLogDataNetworkSource(@"complete by unkonwn, %@", self.request.URL.absoluteString);
            }
        }
    }
    [self unlock];
}

- (void)download:(KTVHCDownload *)download didReceiveResponse:(KTVHCDataResponse *)response
{
    [self lock];
    [[KTVHCDataUnitPool unitPool] unit:self.request.URL.absoluteString updateResponseHeaderFields:response.headers];
    NSString * relativePath = [KTVHCPathTools relativePathForUnitItemFileWithURLString:self.request.URL.absoluteString
                                                                                offset:self.range.start];
    self.unitItem = [KTVHCDataUnitItem unitItemWithOffset:self.range.start relativePath:relativePath];
    [[KTVHCDataUnitPool unitPool] unit:self.request.URL.absoluteString insertUnitItem:self.unitItem];
    self.path = self.unitItem.absolutePath;
    self.writingHandle = [NSFileHandle fileHandleForWritingAtPath:self.path];
    self.readingHandle = [NSFileHandle fileHandleForReadingAtPath:self.path];
    [self callbackForPrepared];
    [self unlock];
}

- (void)download:(KTVHCDownload *)download didReceiveData:(NSData *)data
{
    if (self.didClosed) {
        return;
    }
    [self lock];
    [self.writingHandle writeData:data];
    self.downloadLength += data.length;
    self.unitItem.length = self.downloadLength;
    KTVHCLogDataNetworkSource(@"receive data, %lld, %llu, %llu", (long long)data.length, self.downloadLength, self.unitItem.length);
    [self callbackForHasAvailableData];
    [self unlock];
}


#pragma mark - Callback

- (void)callbackForPrepared
{
    if (self.didClosed) {
        return;
    }
    if (self.didPrepared) {
        return;
    }
    KTVHCLogDataNetworkSource(@"prepared");
    _didPrepared = YES;
    if ([self.delegate respondsToSelector:@selector(sourceDidPrepared:)]) {
        [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
            [self.delegate sourceDidPrepared:self];
        }];
    }
}

- (void)callbackForHasAvailableData
{
    if (self.didClosed) {
        return;
    }
    if (!self.needCallHasAvailableData) {
        return;
    }
    KTVHCLogDataNetworkSource(@"has available data");
    self.needCallHasAvailableData = NO;
    if ([self.delegate respondsToSelector:@selector(networkSourceHasAvailableData:)]) {
        [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
            [self.delegate networkSourceHasAvailableData:self];
        }];
    }
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
