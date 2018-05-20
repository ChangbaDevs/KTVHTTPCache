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
#import "KTVHCLog.h"
#import "KTVHCRange.h"


@interface KTVHCDataReader () <KTVHCDataUnitDelegate, KTVHCDataSourcerDelegate>


@property (nonatomic, strong) dispatch_queue_t delegateQueue;
@property (nonatomic, strong) dispatch_queue_t internalDelegateQueue;
@property (nonatomic, strong) NSRecursiveLock * interfaceLock;

@property (nonatomic, strong) KTVHCDataUnit * unit;
@property (nonatomic, strong) KTVHCDataSourcer * sourcer;

@property (nonatomic, strong) KTVHCDataRequest * request;
@property (nonatomic, strong) KTVHCDataResponse * response;

@property (nonatomic, strong) NSError * error;

@property (nonatomic, assign) BOOL didClose;
@property (nonatomic, assign) BOOL didFinishPrepare;
@property (nonatomic, assign) BOOL didFinishRead;

@property (nonatomic, assign) BOOL didCallPrepare;
@property (nonatomic, assign) BOOL didCallFailure;

@property (nonatomic, assign) long long readOffset;


@end


@implementation KTVHCDataReader


+ (instancetype)readerWithUnit:(KTVHCDataUnit *)unit
                       request:(KTVHCDataRequest *)request
{
    return [[self alloc] initWithUnit:unit
                              request:request];
}

- (instancetype)initWithUnit:(KTVHCDataUnit *)unit
                     request:(KTVHCDataRequest *)request
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        
        self.unit = unit;
        [self.unit workingRetain];
        
        KTVHCRange range = KTVHCRangeWithEnsureLength(request.range, self.unit.totalContentLength);
        self.request = KTVHCCopyRequestIfNeeded(request, range);
        
        self.delegateQueue = dispatch_queue_create("KTVHCDataReader_delegateQueue", DISPATCH_QUEUE_SERIAL);
        self.internalDelegateQueue = dispatch_queue_create("KTVHCDataReader_internalDelegateQueue", DISPATCH_QUEUE_SERIAL);
        [self.unit setDelegate:self delegateQueue:self.internalDelegateQueue];
        self.interfaceLock = [[NSRecursiveLock alloc] init];
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
    if (self.didClose) {
        return;
    }
    if (self.didCallPrepare) {
        return;
    }
    self.didCallPrepare = YES;
    
    KTVHCLogDataReader(@"call prepare\n%@\n%@", self.unit.URLString, self.request.headers);
    
    [self.interfaceLock lock];
    [self setupAndPrepareSourcer];
    [self.interfaceLock unlock];
}

- (void)close
{
    if (self.didClose) {
        return;
    }
    self.didClose = YES;
    
    KTVHCLogDataReader(@"call close, %@", self.unit.URLString);
    
    [self.interfaceLock lock];
    [self.sourcer close];
    [self.unit workingRelease];
    [self.interfaceLock unlock];
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
    if (self.didClose) {
        return nil;
    }
    if (self.didFinishRead) {
        return nil;
    }
    
    [self.interfaceLock lock];
    NSData * data = [self.sourcer readDataOfLength:length];;
    self.readOffset += data.length;
    
    KTVHCLogDataReader(@"read length : %lld", (long long)data.length);
    
    if (self.sourcer.didFinishRead) {
        
        KTVHCLogDataReader(@"read finished, %@", self.unit.URLString);
        
        self.didFinishRead = YES;
        
        [self close];
    }
    [self.interfaceLock unlock];
    return data;
}


#pragma mark - Setup

- (void)setupAndPrepareSourcer
{
    self.sourcer = [KTVHCDataSourcer sourcerWithDelegate:self delegateQueue:self.internalDelegateQueue];
    
    // File Source
    long long min = self.request.range.start;
    long long max = self.request.range.end;
    
    NSMutableArray <KTVHCDataFileSource *> * fileSources = [NSMutableArray array];
    NSMutableArray <KTVHCDataNetworkSource *> * networkSources = [NSMutableArray array];
    
    [self.unit lock];
    [self.unit sortUnitItems];
    for (KTVHCDataUnitItem * item in self.unit.unitItems)
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
    [self.unit unlock];
    
    // File Source Sort
    [fileSources sortUsingComparator:^NSComparisonResult(KTVHCDataFileSource * obj1, KTVHCDataFileSource * obj2) {
        if (obj1.range.start < obj2.range.start) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
    
    // Network Source
    long long offset = self.request.range.start;
    long long size = self.request.range.end - offset + 1;
    
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
            size -= delta;
        }
        offset += KTVHCRangeGetLength(obj.readRange);
        size -= KTVHCRangeGetLength(obj.readRange);
    }
    
    if (size > 0)
    {
        if (self.request.range.end == KTVHCNotFound)
        {
            KTVHCRange range = KTVHCMakeRange(offset, KTVHCNotFound);
            KTVHCDataRequest * request = KTVHCCopyRequestIfNeeded(self.request, range);
            KTVHCDataNetworkSource * source = [[KTVHCDataNetworkSource alloc] initWithRequest:request range:range];
            [networkSources addObject:source];
            size = 0;
        }
        else
        {
            KTVHCRange range = KTVHCMakeRange(offset, offset + size - 1);
            KTVHCDataRequest * request = KTVHCCopyRequestIfNeeded(self.request, range);
            KTVHCDataNetworkSource * source = [[KTVHCDataNetworkSource alloc] initWithRequest:request range:range];
            [networkSources addObject:source];
            offset += size;
            size -= size;
        }
    }
    
    // add Source
    for (KTVHCDataFileSource * obj in fileSources) {
        [self.sourcer putSource:obj];
    }
    for (KTVHCDataNetworkSource * obj in networkSources) {
        [self.sourcer putSource:obj];
    }
    
    [self.sourcer prepare];
}

- (void)setupResponse
{
    long long totalContentLength = self.unit.totalContentLength;
    
    KTVHCRange range = KTVHCRangeWithEnsureLength(self.request.range, totalContentLength);
    long long currentContentLength = KTVHCRangeGetLength(range);
    
    NSDictionary * headerFieldsWithoutRangeAndLength = self.unit.responseHeaderFieldsWithoutRangeAndLength;
    NSMutableDictionary * headerFields = [NSMutableDictionary dictionaryWithDictionary:headerFieldsWithoutRangeAndLength];
    
    [headerFields setObject:[NSString stringWithFormat:@"%lld", currentContentLength]
                     forKey:@"Content-Length"];
    [headerFields setObject:[NSString stringWithFormat:@"bytes %lld-%lld/%lld",
                             range.start,
                             range.end,
                             totalContentLength]
                     forKey:@"Content-Range"];
    
    self.response = [KTVHCDataResponse responseWithCurrentContentLength:currentContentLength
                                                     totalContentLength:totalContentLength
                                                           headerFields:headerFields
                                      headerFieldsWithoutRangeAndLength:headerFieldsWithoutRangeAndLength];
}


#pragma mark - Callback

- (void)callbackForFinishPrepare
{
    if (self.didClose) {
        return;
    }
    if (self.didFinishPrepare) {
        return;
    }
    if (self.sourcer.didFinishPrepare && self.unit.totalContentLength > 0)
    {
        [self setupResponse];
        
        self.didFinishPrepare = YES;
        
        if ([self.delegate respondsToSelector:@selector(readerDidFinishPrepare:)]) {
         
            KTVHCLogDataReader(@"callback for prepare begin, %@", self.unit.URLString);
            
            [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
                
                KTVHCLogDataReader(@"callback for prepare end, %@", self.unit.URLString);
                
                [self.delegate readerDidFinishPrepare:self];
            }];
        }
    }
}


#pragma mark - KTVHCDataUnitDelegate

- (void)unitDidUpdateTotalContentLength:(KTVHCDataUnit *)unit
{
    [self callbackForFinishPrepare];
}


#pragma mark - KTVHCDataSourcerDelegate

- (void)sourcerHasAvailableData:(KTVHCDataSourcer *)sourcer
{
    if (self.didClose) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(readerHasAvailableData:)]) {
        
        KTVHCLogDataReader(@"callback for has available data begin, %@", self.unit.URLString);
        
        [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
            
            KTVHCLogDataReader(@"callback for has available data end, %@", self.unit.URLString);
            
            [self.delegate readerHasAvailableData:self];
        }];
    }
}

- (void)sourcerDidFinishPrepare:(KTVHCDataSourcer *)sourcer
{
    [self callbackForFinishPrepare];
}

- (void)sourcer:(KTVHCDataSourcer *)sourcer didFailure:(NSError *)error
{
    if (self.didClose) {
        return;
    }
    if (self.didCallFailure) {
        return;
    }
    self.didCallFailure = YES;
    
    self.error = error;
    [self close];
    
    if (self.error)
    {
        KTVHCLogDataReader(@"record error : %@", self.error);
        
        [[KTVHCLog log] addError:self.error];
        
        if ([self.delegate respondsToSelector:@selector(reader:didFailure:)])
        {
            KTVHCLogDataReader(@"callback for failure begin, %@, %d", self.unit.URLString, (int)error.code);
            
            [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
                
                KTVHCLogDataReader(@"callback for failure end, %@, %d", self.unit.URLString, (int)error.code);
                
                [self.delegate reader:self didFailure:self.error];
            }];
        }
    }
}


@end
