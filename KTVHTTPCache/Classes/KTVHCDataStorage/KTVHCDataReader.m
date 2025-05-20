//
//  KTVHCDataReader.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataReader.h"
#import "KTVHCData+Internal.h"
#import "KTVHCDataSourceManager.h"
#import "KTVHCDataUnitPool.h"
#import "KTVHCDataCallback.h"
#import "KTVHCLog.h"
#import "KTVHCDataStorage.h"

@interface KTVHCDataReader () <KTVHCDataSourceManagerDelegate>

@property (nonatomic, strong) KTVHCDataUnit *unit;
@property (nonatomic, strong) NSRecursiveLock *coreLock;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;
@property (nonatomic, strong) dispatch_queue_t internalDelegateQueue;
@property (nonatomic, strong) KTVHCDataSourceManager *sourceManager;
@property (nonatomic) BOOL calledPrepare;

@end

@implementation KTVHCDataReader

- (instancetype)initWithRequest:(KTVHCDataRequest *)request
{
    if (self = [super init]) {
        KTVHCLogAlloc(self);
        self.unit = [[KTVHCDataUnitPool pool] unitWithURL:request.URL];
        self->_request = [request newRequestWithTotalLength:self.unit.totalLength];
        self.coreLock = [[NSRecursiveLock alloc] init];
        self.delegateQueue = dispatch_queue_create("KTVHCDataReader_delegateQueue", DISPATCH_QUEUE_SERIAL);
        self.internalDelegateQueue = dispatch_queue_create("KTVHCDataReader_internalDelegateQueue", DISPATCH_QUEUE_SERIAL);
        KTVHCLogDataReader(@"%p, Create reader\norignalRequest : %@\nfinalRequest : %@\nUnit : %@", self, request, self.request, self.unit);
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
    [self close];
    KTVHCLogDataReader(@"%p, Destory reader\nError : %@\nreadOffset : %lld", self, self.error, self.readedLength);
}

- (void)prepare
{
    [self lock];
    if (self.isClosed) {
        [self unlock];
        return;
    }
    if (self.calledPrepare) {
        [self unlock];
        return;
    }
    self->_calledPrepare = YES;
    KTVHCLogDataReader(@"%p, Call prepare", self);
    [self prepareSourceManager];
    [self unlock];
}

- (void)close
{
    [self lock];
    if (self.isClosed) {
        [self unlock];
        return;
    }
    self->_closed = YES;
    KTVHCLogDataReader(@"%p, Call close", self);
    [self.sourceManager close];
    [self.unit workingRelease];
    self.unit = nil;
    [self unlock];
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
    [self lock];
    if (self.isClosed) {
        [self unlock];
        return nil;
    }
    if (self.isFinished) {
        [self unlock];
        return nil;
    }
    if (self.error) {
        [self unlock];
        return nil;
    }
    NSAssert(self->_calledPrepare == YES, @"Prepare api must be called befor read data.");
    NSData *data = [self.sourceManager readDataOfLength:length];
    if (data.length > 0) {
        self->_readedLength += data.length;
        if (self.response.contentLength > 0) {
            self->_progress = (double)self.readedLength / (double)self.response.contentLength;
        }
    }
    KTVHCLogDataReader(@"%p, Read data : %lld", self, (long long)data.length);
    if (self.sourceManager.isFinished) {
        KTVHCLogDataReader(@"%p, Read data did finished", self);
        self->_finished = YES;
        [self close];
    }
    [self unlock];
    return data;
}

- (void)prepareSourceManager
{
    NSMutableArray<KTVHCDataFileSource *> *fileSources = [NSMutableArray array];
    NSMutableArray<KTVHCDataNetworkSource *> *networkSources = [NSMutableArray array];
    long long min = self.request.range.start;
    long long max = self.request.range.end;
    NSArray *unitItems = self.unit.unitItems;
    for (KTVHCDataUnitItem *item in unitItems) {
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
        KTVHCDataFileSource *source = [[KTVHCDataFileSource alloc] initWithPath:item.absolutePath range:range readRange:readRange];
        [fileSources addObject:source];
    }
    [fileSources sortUsingComparator:^NSComparisonResult(KTVHCDataFileSource *obj1, KTVHCDataFileSource *obj2) {
        if (obj1.range.start < obj2.range.start) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
    long long offset = self.request.range.start;
    long long length = KTVHCRangeGetLength(self.request.range);
    long long chunkSize = 0;
    if ([KTVHCDataStorage storage].requestHeaderRangeLength) {
        chunkSize = [KTVHCDataStorage storage].requestHeaderRangeLength(self.request.URL, self.unit.totalLength);
    }
    for (KTVHCDataFileSource *obj in fileSources) {
        long long delta = obj.range.start + obj.readRange.start - offset;
        if (delta > 0) {
            if (chunkSize > 0) {
                // 使用公共方法处理分片下载
                [self addNetworkSourcesWithOffset:offset length:delta chunkSize:chunkSize toArray:networkSources];
            }else {
                // 单个网络源的情况
                [self addSingleNetworkSourceWithStart:offset end:offset + delta - 1 toArray:networkSources];
            }
            offset += delta;
            length -= delta;
        }
        offset += KTVHCRangeGetLength(obj.readRange);
        length -= KTVHCRangeGetLength(obj.readRange);
    }
    
    // 处理剩余需要下载的部分
    if (length > 0) {
        if (chunkSize > 0) {
            // 使用公共方法处理分片下载
            [self addNetworkSourcesWithOffset:offset length:length chunkSize:chunkSize toArray:networkSources];
        } else {
            // 单个网络源的情况
            [self addSingleNetworkSourceWithStart:offset end:self.request.range.end toArray:networkSources];
        }
    }
    NSMutableArray<id<KTVHCDataSource>> *sources = [NSMutableArray array];
    [sources addObjectsFromArray:fileSources];
    [sources addObjectsFromArray:networkSources];
    self.sourceManager = [[KTVHCDataSourceManager alloc] initWithSources:sources delegate:self delegateQueue:self.internalDelegateQueue];
    [self.sourceManager prepare];
}

- (void)ktv_sourceManagerDidPrepare:(KTVHCDataSourceManager *)sourceManager
{
    [self lock];
    [self callbackForPrepared];
    [self unlock];
}

- (void)ktv_sourceManager:(KTVHCDataSourceManager *)sourceManager didReceiveResponse:(KTVHCDataResponse *)response
{
    [self lock];
    [self.unit updateResponseHeaders:response.headers totalLength:response.totalLength];
    [self callbackForPrepared];
    [self unlock];
}

- (void)ktv_sourceManagerHasAvailableData:(KTVHCDataSourceManager *)sourceManager
{
    [self lock];
    if (self.isClosed) {
        [self unlock];
        return;
    }
    if ([self.delegate respondsToSelector:@selector(ktv_readerHasAvailableData:)]) {
        KTVHCLogDataReader(@"%p, Callback for has available data - Begin", self);
        [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
            KTVHCLogDataReader(@"%p, Callback for has available data - End", self);
            [self.delegate ktv_readerHasAvailableData:self];
        }];
    }
    [self unlock];
}

- (void)ktv_sourceManager:(KTVHCDataSourceManager *)sourceManager didFailWithError:(NSError *)error
{
    if (!error) {
        return;
    }
    [self lock];
    if (self.isClosed) {
        [self unlock];
        return;
    }
    if (self.error) {
        [self unlock];
        return;
    }
    self->_error = error;
    [self close];
    [[KTVHCLog log] addError:self.error forURL:self.request.URL];
    if ([self.delegate respondsToSelector:@selector(ktv_reader:didFailWithError:)]) {
        KTVHCLogDataReader(@"%p, Callback for failed - Begin\nError : %@", self, self.error);
        [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
            KTVHCLogDataReader(@"%p, Callback for failed - End", self);
            [self.delegate ktv_reader:self didFailWithError:self.error];
        }];
    }
    [self unlock];
}

- (void)callbackForPrepared
{
    if (self.isClosed) {
        return;
    }
    if (self.isPrepared) {
        return;
    }
    if (self.sourceManager.isPrepared && self.unit.totalLength > 0) {
        long long totalLength = self.unit.totalLength;
        KTVHCRange range = KTVHCRangeWithEnsureLength(self.request.range, totalLength);
        NSDictionary *headers = KTVHCRangeFillToResponseHeaders(range, self.unit.responseHeaders, totalLength);
        self->_response = [[KTVHCDataResponse alloc] initWithURL:self.request.URL headers:headers];
        self->_prepared = YES;
        KTVHCLogDataReader(@"%p, Reader did prepared\nResponse : %@", self, self.response);
        if ([self.delegate respondsToSelector:@selector(ktv_readerDidPrepare:)]) {
            KTVHCLogDataReader(@"%p, Callback for prepared - Begin", self);
            [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
                KTVHCLogDataReader(@"%p, Callback for prepared - End", self);
                [self.delegate ktv_readerDidPrepare:self];
            }];
        }
    }
}

- (void)lock
{
    [self.coreLock lock];
}

- (void)unlock
{
    [self.coreLock unlock];
}

#pragma mark - Private Methods

// 添加单个网络源
- (void)addSingleNetworkSourceWithStart:(long long)start
                                    end:(long long)end
                                toArray:(NSMutableArray<KTVHCDataNetworkSource *> *)networkSources
{
    KTVHCRange range = KTVHCMakeRange(start, end);
    KTVHCDataRequest *request = [self.request newRequestWithRange:range];
    KTVHCDataNetworkSource *source = [[KTVHCDataNetworkSource alloc] initWithRequest:request];
    [networkSources addObject:source];
}

// 添加分片网络源
- (void)addNetworkSourcesWithOffset:(long long)offset
                           length:(long long)length
                       chunkSize:(long long)chunkSize
                        toArray:(NSMutableArray<KTVHCDataNetworkSource *> *)networkSources
{
    long long remainingLength = length;
    long long currentOffset = offset;
    while (remainingLength > 0) {
        // 计算当前分片的大小
        long long chunkLength = MIN(remainingLength, chunkSize);
        // 确保最后一个分片的结束位置不超过原始请求范围
        long long endOffset = MIN(currentOffset + chunkLength - 1, self.request.range.end);
        
        KTVHCRange chunkRange = KTVHCMakeRange(currentOffset, endOffset);
        KTVHCDataRequest *request = [self.request newRequestWithRange:chunkRange];
        KTVHCDataNetworkSource *source = [[KTVHCDataNetworkSource alloc] initWithRequest:request];
        [networkSources addObject:source];
        
        currentOffset += chunkLength;
        remainingLength -= chunkLength;
    }
}

@end
