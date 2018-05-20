//
//  KTVHCDataReader.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataReader.h"
#import "KTVHCDataUnit.h"
#import "KTVHCDataPrivate.h"
#import "KTVHCDataSourcer.h"
#import "KTVHCDataFunctions.h"
#import "KTVHCDataCallback.h"
#import "KTVHCDataUnitPool.h"
#import "KTVHCLog.h"
#import "KTVHCRange.h"

@interface KTVHCDataReader () <NSLocking, KTVHCDataSourcerDelegate>

@property (nonatomic, strong) NSRecursiveLock * coreLock;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;
@property (nonatomic, strong) dispatch_queue_t internalDelegateQueue;

@property (nonatomic, strong) KTVHCDataUnit * unit;
@property (nonatomic, strong) KTVHCDataSourcer * sourcer;

@property (nonatomic, assign) BOOL didCalledPrepare;

@end

@implementation KTVHCDataReader

+ (instancetype)readerWithRequest:(KTVHCDataRequest *)request
{
    return [[self alloc] initWithRequest:request];
}

- (instancetype)initWithRequest:(KTVHCDataRequest *)request
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        self.unit = [[KTVHCDataUnitPool pool] unitWithURL:request.URL];
        KTVHCRange range = KTVHCRangeWithEnsureLength(request.range, self.unit.totalLength);
        _request = KTVHCCopyRequestIfNeeded(request, range);
        [self.unit updateRequestHeaders:self.request.headers];
        self.delegateQueue = dispatch_queue_create("KTVHCDataReader_delegateQueue", DISPATCH_QUEUE_SERIAL);
        self.internalDelegateQueue = dispatch_queue_create("KTVHCDataReader_internalDelegateQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)dealloc
{
    [self close];
    KTVHCLogDealloc(self);
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
    KTVHCLogDataReader(@"call prepare\n%@\n%@", self.unit.URL, self.request.headers);
    [self prepareSourcer];
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
    KTVHCLogDataReader(@"call close, %@", self.unit.URL);
    [self.sourcer close];
    [self.unit workingRelease];
    self.unit = nil;
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
    NSData * data = [self.sourcer readDataOfLength:length];;
    _readOffset += data.length;
    KTVHCLogDataReader(@"read length : %lld", (long long)data.length);
    if (self.sourcer.didFinished) {
        KTVHCLogDataReader(@"read finished, %@", self.unit.URL);
        _didFinished = YES;
        [self close];
    }
    [self unlock];
    return data;
}

- (void)prepareSourcer
{
    self.sourcer = [[KTVHCDataSourcer alloc] initWithDelegate:self delegateQueue:self.internalDelegateQueue];
    NSMutableArray <KTVHCDataFileSource *> * fileSources = [NSMutableArray array];
    NSMutableArray <KTVHCDataNetworkSource *> * networkSources = [NSMutableArray array];
    long long min = self.request.range.start;
    long long max = self.request.range.end;
    NSArray * unitItems = self.unit.unitItems;
    for (KTVHCDataUnitItem * item in unitItems)
    {
        long long itemMin = item.offset;
        long long itemMax = item.offset + item.length - 1;
        if (itemMax < min || itemMin > max) {
            continue;
        }
        if (min > itemMin) {
            itemMin = min;
        }
        if (max < itemMax) {
            itemMax = max;
        }
        min = itemMax + 1;
        KTVHCRange range = KTVHCMakeRange(item.offset, item.offset + item.length - 1);
        KTVHCRange readRange = KTVHCMakeRange(itemMin - item.offset, itemMax - item.offset);
        KTVHCDataFileSource * source = [[KTVHCDataFileSource alloc] initWithPath:item.absolutePath range:range readRange:readRange];
        [fileSources addObject:source];
    }
    [fileSources sortUsingComparator:^NSComparisonResult(KTVHCDataFileSource * obj1, KTVHCDataFileSource * obj2) {
        if (obj1.range.start < obj2.range.start) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
    long long offset = self.request.range.start;
    long long length = self.request.range.end - offset + 1;
    for (KTVHCDataFileSource * obj in fileSources)
    {
        long long delta = obj.range.start + obj.readRange.start - offset;
        if (delta > 0)
        {
            KTVHCRange range = KTVHCMakeRange(offset, offset + delta - 1);
            KTVHCDataRequest * request = KTVHCCopyRequestIfNeeded(self.request, range);
            KTVHCDataNetworkSource * source = [[KTVHCDataNetworkSource alloc] initWithRequest:request range:range];
            [networkSources addObject:source];
            offset += delta;
            length -= delta;
        }
        offset += KTVHCRangeGetLength(obj.readRange);
        length -= KTVHCRangeGetLength(obj.readRange);
    }
    if (length > 0)
    {
        KTVHCRange range = KTVHCMakeRange(offset, self.request.range.end);
        KTVHCDataRequest * request = KTVHCCopyRequestIfNeeded(self.request, range);
        KTVHCDataNetworkSource * source = [[KTVHCDataNetworkSource alloc] initWithRequest:request range:range];
        [networkSources addObject:source];
    }
    for (KTVHCDataFileSource * obj in fileSources) {
        [self.sourcer putSource:obj];
    }
    for (KTVHCDataNetworkSource * obj in networkSources) {
        [self.sourcer putSource:obj];
    }
    [self.sourcer prepare];
}

- (void)callbackForPrepared
{
    if (self.didClosed) {
        return;
    }
    if (self.didPrepared) {
        return;
    }
    if (self.sourcer.didPrepared && self.unit.totalLength > 0) {
        long long totalLength = self.unit.totalLength;
        KTVHCRange range = KTVHCRangeWithEnsureLength(self.request.range, totalLength);
        NSDictionary * headers = KTVHCRangeFillToResponseHeaders(range, self.unit.responseHeaders, totalLength);
        _response = [[KTVHCDataResponse alloc] initWithURL:self.request.URL headers:headers];
        _didPrepared = YES;
        if ([self.delegate respondsToSelector:@selector(readerDidFinishPrepare:)]) {
            KTVHCLogDataReader(@"callback for prepare begin, %@", self.unit.URL);
            [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
                KTVHCLogDataReader(@"callback for prepare end, %@", self.unit.URL);
                [self.delegate readerDidFinishPrepare:self];
            }];
        }
    }
}

- (void)sourcerDidPrepared:(KTVHCDataSourcer *)sourcer
{
    [self callbackForPrepared];
}

- (void)sourcer:(KTVHCDataSourcer *)sourcer didReceiveResponse:(KTVHCDataResponse *)response
{
    [self.unit updateResponseHeaders:response.headers totalLength:response.totalLength];
    [self callbackForPrepared];
}

- (void)sourcerHasAvailableData:(KTVHCDataSourcer *)sourcer
{
    if (self.didClosed) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(readerHasAvailableData:)]) {
        KTVHCLogDataReader(@"callback for has available data begin, %@", self.unit.URL);
        [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
            KTVHCLogDataReader(@"callback for has available data end, %@", self.unit.URL);
            [self.delegate readerHasAvailableData:self];
        }];
    }
}

- (void)sourcer:(KTVHCDataSourcer *)sourcer didFailed:(NSError *)error
{
    if (self.didClosed) {
        return;
    }
    if (self.error) {
        return;
    }
    _error = error;
    [self close];
    if (self.error)
    {
        KTVHCLogDataReader(@"record error : %@", self.error);
        [[KTVHCLog log] addError:self.error];
        if ([self.delegate respondsToSelector:@selector(reader:didFailed:)]) {
            KTVHCLogDataReader(@"callback for failure begin, %@, %d", self.unit.URL, (int)error.code);
            [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
                KTVHCLogDataReader(@"callback for failure end, %@, %d", self.unit.URL, (int)error.code);
                [self.delegate reader:self didFailed:self.error];
            }];
        }
    }
}

- (void)lock
{
    if (!self.coreLock) {
        self.coreLock = [[NSRecursiveLock alloc] init];
    }
    [self.coreLock lock];
}

- (void)unlock
{
    [self.coreLock unlock];
}

@end
