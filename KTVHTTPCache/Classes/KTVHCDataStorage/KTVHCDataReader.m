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

@property (nonatomic, strong) KTVHCDataUnit * unit;
@property (nonatomic, strong) KTVHCDataRequest * request;
@property (nonatomic, strong) KTVHCDataSourcer * sourcer;

@property (nonatomic, strong) NSError * error;

@property (nonatomic, assign) BOOL didClose;
@property (nonatomic, assign) BOOL didFinishPrepare;
@property (nonatomic, assign) BOOL didFinishRead;

@property (nonatomic, assign) BOOL stopWorkingCallbackToken;
@property (nonatomic, assign) BOOL startWorkingCallbackToken;

@property (nonatomic, assign) NSInteger currentContentLength;
@property (nonatomic, assign) NSInteger readedContentLength;
@property (nonatomic, assign) NSInteger totalContentLength;

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
        self.unit.delegate = self;
        self.request = request;
        self.workingDelegate = workingDelegate;
        [self callbackForStartWorking];
        [self setupSourcer];
    }
    return self;
}

- (void)setupSourcer
{
    self.sourcer = [KTVHCDataSourcer sourcerWithDelegate:self];
    
    // File Source
    NSInteger min = self.request.rangeMin;
    NSInteger max = self.request.rangeMax;
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
        
        NSInteger itemMin = item.offset;
        NSInteger itemMax = item.offset + item.size - 1;
        
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
        
        min += item.offset + (itemMin - item.offset) + (itemMax - itemMin + 1);
        
        KTVHCDataFileSource * source = [KTVHCDataFileSource sourceWithDelegate:self.sourcer
                                                                      filePath:item.filePath
                                                                        offset:item.offset
                                                                          size:item.size
                                                                   startOffset:itemMin - item.offset
                                                                  needReadSize:itemMax - itemMin + 1];
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
    NSInteger offset = self.request.rangeMin;
    NSInteger size = self.request.rangeMax - offset + 1;
    if (self.request.rangeMax == KTVHCDataRequestRangeMaxVaule) {
        size = LONG_MAX;
    }
    
    for (KTVHCDataFileSource * obj in fileSources)
    {
        NSInteger delta = obj.offset + obj.startOffset - offset;
        if (delta > 0)
        {
            KTVHCDataNetworkSource * source = [KTVHCDataNetworkSource sourceWithDelegate:self.sourcer
                                                                               URLString:self.request.URLString
                                                                            headerFields:self.request.headerFields
                                                                                  offset:offset
                                                                                    size:delta];
            [networkSources addObject:source];
            offset += delta;
            size -= delta;
        }
        offset += obj.needReadSize;
        size -= obj.needReadSize;
    }
    
    if (size > 0)
    {
        if (self.request.rangeMax == KTVHCDataRequestRangeMaxVaule)
        {
            KTVHCDataNetworkSource * source = [KTVHCDataNetworkSource sourceWithDelegate:self.sourcer
                                                                               URLString:self.request.URLString
                                                                            headerFields:self.request.headerFields
                                                                                  offset:offset
                                                                                    size:KTVHCDataNetworkSourceSizeMaxVaule];
            [networkSources addObject:source];
            size = 0;
        }
        else
        {
            KTVHCDataNetworkSource * source = [KTVHCDataNetworkSource sourceWithDelegate:self.sourcer
                                                                               URLString:self.request.URLString
                                                                            headerFields:self.request.headerFields
                                                                                  offset:offset
                                                                                    size:size];
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
    
    [self.sourcer putSourceDidFinish];
}

- (void)prepare
{
    if (self.didClose) {
        return;
    }
    [self.sourcer prepare];
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
            [KTVHCDataCallback callbackWithBlock:^{
                [self.delegate readerDidFinishPrepare:self];
            }];
        }
    }
}

- (void)callbackForStartWorking
{
    if (self.startWorkingCallbackToken) {
        return;
    }
    
    self.startWorkingCallbackToken = YES;
    if ([self.workingDelegate respondsToSelector:@selector(readerDidStartWorking:)]) {
        [KTVHCDataCallback callbackWithBlock:^{
            [self.workingDelegate readerDidStartWorking:self];
        }];
    }
}

- (void)callbackForStopWorking
{
    if (self.stopWorkingCallbackToken) {
        return;
    }
    
    self.stopWorkingCallbackToken = YES;
    if ([self.workingDelegate respondsToSelector:@selector(readerDidStopWorking:)]) {
        [KTVHCDataCallback callbackWithBlock:^{
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
        [KTVHCDataCallback callbackWithBlock:^{
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
        [KTVHCDataCallback callbackWithBlock:^{
            [self.delegate reader:self didFailure:self.error];
        }];
    }
}

@end
