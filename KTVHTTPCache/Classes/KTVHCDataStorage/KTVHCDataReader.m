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

@interface KTVHCDataReader () <KTVHCDataUnitDelegate, KTVHCDataSourcerDelegate>

@property (nonatomic, strong) KTVHCDataUnit * unit;
@property (nonatomic, strong) KTVHCDataRequest * request;
@property (nonatomic, strong) KTVHCDataSourcer * sourcer;

@property (nonatomic, strong) NSError * error;

@property (nonatomic, assign) BOOL didFinishPrepare;
@property (nonatomic, assign) BOOL didFinishRead;

@property (nonatomic, assign) NSInteger currentContentLength;
@property (nonatomic, assign) NSInteger readedContentLength;
@property (nonatomic, assign) NSInteger totalContentLength;

@end

@implementation KTVHCDataReader

+ (instancetype)readerWithUnit:(KTVHCDataUnit *)unit request:(KTVHCDataRequest *)request
{
    return [[self alloc] initWithUnit:unit request:request];
}

- (instancetype)initWithUnit:(KTVHCDataUnit *)unit request:(KTVHCDataRequest *)request
{
    if (self = [super init])
    {
        self.unit = unit;
        self.unit.delegate = self;
        self.request = request;
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
    
    for (KTVHCDataUnitItem * item in self.unit.unitItems)
    {
        NSInteger itemMin = item.offset;
        NSInteger itemMax = item.offset + item.size - 1;
        
        if (itemMax < min || itemMin > max) {
            continue;
        }
        
        if (min >= itemMin) {
            itemMin = min;
        }
        if (max <= itemMax) {
            itemMax = max;
        }
        
        KTVHCDataFileSource * source = [KTVHCDataFileSource sourceWithDelegate:self.sourcer
                                                                      filePath:item.filePath
                                                                        offset:item.offset
                                                                          size:item.size
                                                                   startOffset:itemMin - item.offset
                                                                  needReadSize:itemMax - itemMin + 1];
        [fileSources addObject:source];
    }
    
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
    [self.sourcer prepare];
}

- (void)close
{
    [self.sourcer close];
}

- (NSData *)syncReadDataOfLength:(NSUInteger)length
{
    if (self.didFinishRead) {
        return nil;
    }
    
    NSData * data = [self.sourcer syncReadDataOfLength:length];
    self.readedContentLength += data.length;
    if (self.sourcer.didFinishRead) {
        self.didFinishRead = YES;
    }
    return data;
}


#pragma mark - Callback

- (void)callbackForFinishPrepare
{
    if (self.didFinishPrepare) {
        return;
    }
    if (self.sourcer.didFinishPrepare && self.unit.totalContentLength > 0)
    {
        self.totalContentLength = self.unit.totalContentLength;
        if (self.request.rangeMax == KTVHCDataRequestRangeMaxVaule) {
            self.currentContentLength = self.totalContentLength - self.request.rangeMin;
        } else {
            self.currentContentLength = self.request.rangeMax - self.request.rangeMin;
        }
        self.didFinishPrepare = YES;
        if ([self.delegate respondsToSelector:@selector(reaaderDidFinishPrepare:)]) {
            [self.delegate reaaderDidFinishPrepare:self];
        }
    }
}


#pragma mark - KTVHCDataUnitDelegate

- (void)unitDidUpdateTotalContentLength:(KTVHCDataUnit *)unit
{
    [self callbackForFinishPrepare];
}


#pragma mark - KTVHCDataSourcerDelegate

- (void)sourcerDidFinishPrepare:(KTVHCDataSourcer *)sourcer
{
    [self callbackForFinishPrepare];
}

- (void)sourcer:(KTVHCDataSourcer *)sourcer didFailure:(NSError *)error
{
    self.error = error;
    if (self.error && [self.delegate respondsToSelector:@selector(reaader:didFailure:)]) {
        [self.delegate reaader:self didFailure:self.error];
    }
}


@end
