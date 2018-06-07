//
//  KTVHCDataNetworkSource.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataNetworkSource.h"
#import "KTVHCDataUnitPool.h"
#import "KTVHCDataCallback.h"
#import "KTVHCPathTools.h"
#import "KTVHCDownload.h"
#import "KTVHCLog.h"

@interface KTVHCDataNetworkSource () <NSLocking, KTVHCDownloadDelegate>

@property (nonatomic, strong) NSError * error;
@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, assign) long long downloadLength;
@property (nonatomic, assign) long long downloadReadedLength;
@property (nonatomic, assign) BOOL downloadDidCallComplete;
@property (nonatomic, assign) BOOL needCallHasAvailableData;
@property (nonatomic, assign) BOOL didCalledPrepare;

@property (nonatomic, strong) KTVHCDataUnitItem * unitItem;
@property (nonatomic, strong) NSFileHandle * readingHandle;
@property (nonatomic, strong) NSFileHandle * writingHandle;
@property (nonatomic, assign) NSURLSessionTask * downlaodTask;

@end

@implementation KTVHCDataNetworkSource

- (instancetype)initWithRequest:(KTVHCDataRequest *)reqeust
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        _request = reqeust;
        _range = reqeust.range;
        KTVHCLogDataNetworkSource(@"%p, Create network source\nrequest : %@\nrange : %@", self, self.request, KTVHCStringFromRange(self.range));
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
    KTVHCLogDataNetworkSource(@"%p, Destory network source\nError : %@\ndownloadLength : %lld\nreadedLength : %lld", self, self.error, self.downloadLength, self.downloadReadedLength);
}

- (void)prepare
{
    [self lock];
    if (self.didClosed)
    {
        [self unlock];
        return;
    }
    if (self.didCalledPrepare)
    {
        [self unlock];
        return;
    }
    _didCalledPrepare = YES;
    KTVHCLogDataNetworkSource(@"%p, Call prepare", self);
    self.downlaodTask = [[KTVHCDownload download] downloadWithRequest:self.request delegate:self];
    [self unlock];
}

- (void)close
{
    [self lock];
    if (self.didClosed)
    {
        [self unlock];
        return;
    }
    _didClosed = YES;
    KTVHCLogDataNetworkSource(@"%p, Call close", self);
    [self.readingHandle closeFile];
    self.readingHandle = nil;
    if (!self.downloadDidCallComplete)
    {
        KTVHCLogDataNetworkSource(@"%p, Cancel download task", self);
        [self.downlaodTask cancel];
        self.downlaodTask = nil;
    }
    [self.writingHandle synchronizeFile];
    [self.writingHandle closeFile];
    self.writingHandle = nil;
    [self unlock];
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
    [self lock];
    if (self.didClosed)
    {
        [self unlock];
        return nil;
    }
    if (self.didFinished)
    {
        [self unlock];
        return nil;
    }
    if (self.error)
    {
        [self unlock];
        return nil;
    }
    if (self.downloadReadedLength >= self.downloadLength)
    {
        if (self.downloadDidCallComplete)
        {
            KTVHCLogDataNetworkSource(@"%p, Read data failed\ndownloadLength : %lld\nreadedLength : %lld", self, self.downloadReadedLength, self.downloadLength);
            [self.readingHandle closeFile];
            self.readingHandle = nil;
        }
        else
        {
            KTVHCLogDataNetworkSource(@"%p, Read data wait callback", self);
            self.needCallHasAvailableData = YES;
        }
        [self unlock];
        return nil;
    }
    NSData * data = [self.readingHandle readDataOfLength:(NSUInteger)MIN(self.downloadLength - self.downloadReadedLength, length)];
    self.downloadReadedLength += data.length;
    KTVHCLogDataNetworkSource(@"%p, Read data\nLength : %lld\ndownloadLength : %lld\nreadedLength : %lld", self, (long long)data.length, self.downloadReadedLength, self.downloadLength);
    if (self.downloadReadedLength >= KTVHCRangeGetLength(self.response.range))
    {
        _didFinished = YES;
        KTVHCLogDataNetworkSource(@"%p, Read data did finished", self);
        [self.readingHandle closeFile];
        self.readingHandle = nil;
    }
    [self unlock];
    return data;
}

- (void)setDelegate:(id <KTVHCDataNetworkSourceDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    _delegate = delegate;
    _delegateQueue = delegateQueue;
}

- (void)download:(KTVHCDownload *)download didCompleteWithError:(NSError *)error
{
    [self lock];
    self.downloadDidCallComplete = YES;
    [self.writingHandle synchronizeFile];
    [self.writingHandle closeFile];
    self.writingHandle = nil;
    if (self.didClosed)
    {
        KTVHCLogDataNetworkSource(@"%p, Complete but did closed\nError : %@", self, error);
    }
    else
    {
        if (error)
        {
            self.error = error;
            if (self.error.code != NSURLErrorCancelled)
            {
                KTVHCLogDataNetworkSource(@"%p, Complete with error\nError : %@", self, error);
                if ([self.delegate respondsToSelector:@selector(networkSource:didFailed:)])
                {
                    [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
                        [self.delegate networkSource:self didFailed:self.error];
                    }];
                }
            }
            else
            {
                KTVHCLogDataNetworkSource(@"%p, Complete with cancel\nError : %@", self, error);
            }
        }
        else
        {
            if (self.downloadLength >= KTVHCRangeGetLength(self.response.range))
            {
                KTVHCLogDataNetworkSource(@"%p, Complete and finisehed", self);
                if ([self.delegate respondsToSelector:@selector(networkSourceDidFinishedDownload:)])
                {
                    [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
                        [self.delegate networkSourceDidFinishedDownload:self];
                    }];
                }
            }
            else
            {
                KTVHCLogDataNetworkSource(@"%p, Complete but not finisehed\nError : %@\ndownloadLength : %lld", self, error, self.downloadLength);
            }
        }
    }
    [self unlock];
}

- (void)download:(KTVHCDownload *)download didReceiveResponse:(KTVHCDataResponse *)response
{
    [self lock];
    _response = response;
    NSString * path = [KTVHCPathTools unitItemPathWithURL:self.request.URL offset:self.request.range.start];
    self.unitItem = [[KTVHCDataUnitItem alloc] initWithPath:path offset:self.request.range.start];
    KTVHCDataUnit * unit = [[KTVHCDataUnitPool pool] unitWithURL:self.request.URL];
    [unit insertUnitItem:self.unitItem];
    KTVHCLogDataNetworkSource(@"%p, Receive response\nResponse : %@\nUnit : %@\nUnitItem : %@", self, response, unit, self.unitItem);
    [unit workingRelease];
    self.writingHandle = [NSFileHandle fileHandleForWritingAtPath:self.unitItem.absolutePath];
    self.readingHandle = [NSFileHandle fileHandleForReadingAtPath:self.unitItem.absolutePath];
    [self callbackForPrepared];
    [self unlock];
}

- (void)download:(KTVHCDownload *)download didReceiveData:(NSData *)data
{
    [self lock];
    if (self.didClosed)
    {
        [self unlock];
        return;
    }
    [self.writingHandle writeData:data];
    self.downloadLength += data.length;
    [self.unitItem setLength:self.downloadLength];
    KTVHCLogDataNetworkSource(@"%p, Receive data : %lld, %lld, %lld", self, (long long)data.length, self.downloadLength, self.unitItem.length);
    [self callbackForHasAvailableData];
    [self unlock];
}

- (void)callbackForPrepared
{
    if (self.didClosed)
    {
        return;
    }
    if (self.didPrepared)
    {
        return;
    }
    _didPrepared = YES;
    if ([self.delegate respondsToSelector:@selector(networkSourceDidPrepared:)])
    {
        KTVHCLogDataNetworkSource(@"%p, Callback for prepared - Begin", self);
        [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
            KTVHCLogDataNetworkSource(@"%p, Callback for prepared - End", self);
            [self.delegate networkSourceDidPrepared:self];
        }];
    }
}

- (void)callbackForHasAvailableData
{
    if (self.didClosed)
    {
        return;
    }
    if (!self.needCallHasAvailableData)
    {
        return;
    }
    self.needCallHasAvailableData = NO;
    if ([self.delegate respondsToSelector:@selector(networkSourceHasAvailableData:)])
    {
        KTVHCLogDataNetworkSource(@"%p, Callback for has available data - Begin", self);
        [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
            KTVHCLogDataNetworkSource(@"%p, Callback for has available data - End", self);
            [self.delegate networkSourceHasAvailableData:self];
        }];
    }
}

- (void)lock
{
    if (!self.coreLock)
    {
        self.coreLock = [[NSLock alloc] init];
    }
    [self.coreLock lock];
}

- (void)unlock
{
    [self.coreLock unlock];
}

@end
