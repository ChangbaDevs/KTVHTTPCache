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
#import "KTVHCLog.h"


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
        
        self.request = request;
        [self.request updateRangeMaxIfNeeded:self.unit.totalContentLength];
        
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
    
    KTVHCLogDataReader(@"call prepare\n%@\n%@", self.unit.URLString, self.request.headerFields);
    
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
    
    KTVHCLogDataReader(@"read length : %lu", data.length);
    
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
        
        KTVHCDataFileSource * source = [KTVHCDataFileSource sourceWithFilePath:item.absolutePath
                                                                        offset:item.offset
                                                                        length:item.length
                                                                   startOffset:itemMin - item.offset
                                                                needReadLength:itemMax - itemMin + 1];
        [fileSources addObject:source];
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
                                                                 acceptContentTypePrefixs:self.request.acceptContentTypes
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
                                                                 acceptContentTypePrefixs:self.request.acceptContentTypes
                                                                                   offset:offset
                                                                                   length:KTVHCDataNetworkSourceLengthMaxVaule];
            [networkSources addObject:source];
            size = 0;
        }
        else
        {
            KTVHCDataNetworkSource * source = [KTVHCDataNetworkSource sourceWithURLString:self.request.URLString
                                                                             headerFields:self.request.headerFields
                                                                 acceptContentTypePrefixs:self.request.acceptContentTypes
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

- (void)setupResponse
{
    long long totalContentLength = self.unit.totalContentLength;
    
    long long currentContentLength = 0;
    if (self.request.rangeMax == KTVHCDataRequestRangeMaxVaule) {
        currentContentLength = totalContentLength - self.request.rangeMin;
    } else {
        currentContentLength = self.request.rangeMax - self.request.rangeMin + 1;
    }
    
    NSDictionary * headerFieldsWithoutRangeAndLength = self.unit.responseHeaderFieldsWithoutRangeAndLength;
    NSMutableDictionary * headerFields = [NSMutableDictionary dictionaryWithDictionary:headerFieldsWithoutRangeAndLength];
    
    [headerFields setObject:[NSString stringWithFormat:@"%lld", currentContentLength]
                     forKey:@"Content-Length"];
    [headerFields setObject:[NSString stringWithFormat:@"bytes %lld-%lld/%lld",
                             self.request.rangeMin,
                             self.request.rangeMin + currentContentLength - 1,
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
            KTVHCLogDataReader(@"callback for failure begin, %@, %ld", self.unit.URLString, error.code);
            
            [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
                
                KTVHCLogDataReader(@"callback for failure end, %@, %ld", self.unit.URLString, error.code);
                
                [self.delegate reader:self didFailure:self.error];
            }];
        }
    }
}


@end
