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
#import "KTVHCDataCallback.h"

@interface KTVHCDataReader () <KTVHCDataUnitDelegate, KTVHCDataSourcerDelegate>

@property (nonatomic, weak) id <KTVHCDataReaderWorkingDelegate> workingDelegate;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;
@property (nonatomic, strong) dispatch_queue_t internalDelegateQueue;

@property (nonatomic, strong) KTVHCDataUnit * unit;
@property (nonatomic, strong) KTVHCDataRequest * request;
@property (nonatomic, strong) KTVHCDataSourcer * sourcer;

@property (nonatomic, strong) NSError * error;

@property (nonatomic, assign) BOOL didClose;
@property (nonatomic, assign) BOOL didCallPrepare;
@property (nonatomic, assign) BOOL didFinishPrepare;
@property (nonatomic, assign) BOOL didFinishRead;

@property (nonatomic, assign) BOOL stopWorkingCallbackToken;

@property (nonatomic, assign) long long currentContentLength;
@property (nonatomic, assign) long long readedContentLength;
@property (nonatomic, assign) long long totalContentLength;

@end

@implementation KTVHCDataReader

+ (instancetype)readerWithUnit:(KTVHCDataUnit *)unit
                       request:(KTVHCDataRequest *)request
               workingDelegate:(id <KTVHCDataReaderWorkingDelegate>)workingDelegate;
{
    return [[self alloc] initWithUnit:unit
                              request:request
                      workingDelegate:workingDelegate];
}

- (instancetype)initWithUnit:(KTVHCDataUnit *)unit
                     request:(KTVHCDataRequest *)request
             workingDelegate:(id <KTVHCDataReaderWorkingDelegate>)workingDelegate;
{
    if (self = [super init])
    {
        self.unit = unit;
        self.request = request;
        self.workingDelegate = workingDelegate;
        self.delegateQueue = dispatch_queue_create("KTVHCDataReader_delegateQueue", DISPATCH_QUEUE_SERIAL);
        self.internalDelegateQueue = dispatch_queue_create("KTVHCDataReader_internalDelegateQueue", DISPATCH_QUEUE_SERIAL);
        [self.unit setDelegate:self delegateQueue:self.internalDelegateQueue];
    }
    return self;
}

- (void)setupAndPrepareSourcer
{
    self.sourcer = [KTVHCDataSourcer sourcerWithDelegate:self delegateQueue:self.internalDelegateQueue];
    
    // File Source
    long long min = self.request.rangeMin;
    long long max = self.request.rangeMax;
    if (self.request.rangeMax == KTVHCDataRequestRangeMaxVaule) {
        max = LONG_MAX;
    }
    
    NSMutableArray <KTVHCDataFileSource *> * fileSources = [NSMutableArray array];
    NSMutableArray <KTVHCDataNetworkSource *> * networkSources = [NSMutableArray array];
    
    [self.unit lock];
    [self.unit sortUnitItems];
    for (KTVHCDataUnitItem * item in self.unit.unitItems)
    {
        [item lock];
        
        long long itemMin = item.offset;
        long long itemMax = item.offset + item.length - 1;
        
        if (itemMax < min || itemMin > max) {
            [item unlock];
            continue;
        }
        
        if (min >= itemMin) {
            itemMin = min;
        }
        if (max <= itemMax) {
            itemMax = max;
        }
        
        min = item.offset + (itemMin - item.offset) + (itemMax - itemMin + 1);
        
        KTVHCDataFileSource * source = [KTVHCDataFileSource sourceWithFilePath:item.filePath
                                                                        offset:item.offset
                                                                        length:item.length
                                                                   startOffset:itemMin - item.offset
                                                                needReadLength:itemMax - itemMin + 1];
        [fileSources addObject:source];
        
        [item unlock];
    }
    [self.unit unlock];
    
    // File Source Sort
    [fileSources sortUsingComparator:^NSComparisonResult(KTVHCDataFileSource * obj1, KTVHCDataFileSource * obj2) {
        if (obj1.offset < obj2.offset) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
    
    // Network Source
    long long offset = self.request.rangeMin;
    long long size = self.request.rangeMax - offset + 1;
    if (self.request.rangeMax == KTVHCDataRequestRangeMaxVaule) {
        size = LONG_MAX;
    }
    
    for (KTVHCDataFileSource * obj in fileSources)
    {
        long long delta = obj.offset + obj.startOffset - offset;
        if (delta > 0)
        {
            KTVHCDataNetworkSource * source = [KTVHCDataNetworkSource sourceWithURLString:self.request.URLString
                                                                             headerFields:self.request.headerFields
                                                                                   offset:offset
                                                                                   length:delta];
            [networkSources addObject:source];
            offset += delta;
            size -= delta;
        }
        offset += obj.needReadLength;
        size -= obj.needReadLength;
    }
    
    if (size > 0)
    {
        if (self.request.rangeMax == KTVHCDataRequestRangeMaxVaule)
        {
            KTVHCDataNetworkSource * source = [KTVHCDataNetworkSource sourceWithURLString:self.request.URLString
                                                                             headerFields:self.request.headerFields
                                                                                   offset:offset
                                                                                   length:KTVHCDataNetworkSourceLengthMaxVaule];
            [networkSources addObject:source];
            size = 0;
        }
        else
        {
            KTVHCDataNetworkSource * source = [KTVHCDataNetworkSource sourceWithURLString:self.request.URLString
                                                                             headerFields:self.request.headerFields
                                                                                   offset:offset
                                                                                   length:size];
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

- (void)prepare
{
    if (self.didClose) {
        return;
    }
    if (self.didCallPrepare) {
        return;
    }
    self.didCallPrepare = YES;
    
    [self setupAndPrepareSourcer];
}

- (void)close
{
    if (self.didClose) {
        return;
    }
    
    self.didClose = YES;
    [self.sourcer close];
    
    [self callbackForStopWorking];
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
    if (self.didClose) {
        return nil;
    }
    if (self.didFinishRead) {
        return nil;
    }
    
    NSData * data = [self.sourcer readDataOfLength:length];;
    self.readedContentLength += data.length;
    if (self.sourcer.didFinishRead) {
        self.didFinishRead = YES;
    }
    return data;
}


#pragma mark - Setter/Getter

- (NSDictionary *)headerFields
{
    NSMutableDictionary * headers = [NSMutableDictionary dictionaryWithDictionary:self.unit.responseHeaderFields];
    [headers setObject:[NSString stringWithFormat:@"%lld", self.currentContentLength]
                forKey:@"Content-Length"];
    [headers setObject:[NSString stringWithFormat:@"bytes %lld-%lld/%lld",
                        self.request.rangeMin,
                        self.request.rangeMin + self.currentContentLength - 1,
                        self.totalContentLength]
                forKey:@"Content-Range"];
    return headers;
}

- (NSDictionary *)headerFieldsWithoutRangeAndLengt
{
    return self.unit.responseHeaderFieldsWithoutRangeAndLength;
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
        self.totalContentLength = self.unit.totalContentLength;
        if (self.request.rangeMax == KTVHCDataRequestRangeMaxVaule) {
            self.currentContentLength = self.totalContentLength - self.request.rangeMin;
        } else {
            self.currentContentLength = self.request.rangeMax - self.request.rangeMin + 1;
        }
        self.didFinishPrepare = YES;
        if ([self.delegate respondsToSelector:@selector(readerDidFinishPrepare:)]) {
            [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
                [self.delegate readerDidFinishPrepare:self];
            }];
        }
    }
}

- (void)callbackForStopWorking
{
    if (self.stopWorkingCallbackToken) {
        return;
    }
    
    self.stopWorkingCallbackToken = YES;
    if ([self.workingDelegate respondsToSelector:@selector(readerDidStopWorking:)]) {
        [KTVHCDataCallback workingCallbackWithBlock:^{
            [self.workingDelegate readerDidStopWorking:self];
        }];
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
    if ([self.delegate respondsToSelector:@selector(readerHasAvailableData:)]) {
        [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
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
    self.error = error;
    if (self.error && [self.delegate respondsToSelector:@selector(reader:didFailure:)]) {
        [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
            [self.delegate reader:self didFailure:self.error];
        }];
    }
}


- (void)dealloc
{
    [self close];
}


@end
