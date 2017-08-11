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

@interface KTVHCDataReader ()

@property (nonatomic, strong) KTVHCDataUnit * unit;
@property (nonatomic, strong) KTVHCDataRequest * request;
@property (nonatomic, strong) KTVHCDataSourcer * sourcer;

@property (nonatomic, assign) NSInteger contentSize;

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
        self.request = request;
        self.sourcer = [KTVHCDataSourcer sourcer];
        [self setupSourcer];
    }
    return self;
}

- (void)setupSourcer
{
    // File Source
    NSInteger min = self.request.rangeMin;
    NSInteger max = self.request.rangeMax;
    if (self.request.rangeMax == KTVHCDataRequestRangeMaxVaule) {
        max = LONG_MAX;
    }
    
    NSMutableArray <KTVHCDataFileSource *> * fileSources = [NSMutableArray array];
    NSMutableArray <KTVHCDataNetworkSource *> * networkSources = [NSMutableArray array];
    
    for (KTVHCDataUnitItem * item in self.unit.fileUnitItems)
    {
        NSInteger itemMin = item.offset;
        NSInteger itemMax = item.offset + item.size;
        
        if (itemMax < min || itemMin > max) {
            continue;
        }
        
        if (min >= itemMin) {
            itemMin = min;
        }
        if (max <= itemMax) {
            itemMax = max;
        }
        
        KTVHCDataFileSource * source = [KTVHCDataFileSource sourceWithFilePath:item.filePath
                                                                        offset:item.offset
                                                                          size:item.size
                                                                    readOffset:itemMin - item.offset
                                                                      readSize:itemMax - itemMin];
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
        NSInteger delta = obj.offset + obj.readOffset - offset;
        if (delta > 0)
        {
            KTVHCDataNetworkSource * source = [KTVHCDataNetworkSource sourceWithURLString:self.request.URLString
                                                                             headerFields:self.request.headerFields
                                                                                   offset:offset
                                                                                     size:delta];
            [networkSources addObject:source];
            offset += delta;
            size -= delta;
        }
        offset += obj.readSize;
        size -= obj.readSize;
    }
    
    if (size > 0)
    {
        if (self.request.rangeMax == KTVHCDataRequestRangeMaxVaule)
        {
            KTVHCDataNetworkSource * source = [KTVHCDataNetworkSource sourceWithURLString:self.request.URLString
                                                                             headerFields:self.request.headerFields
                                                                                   offset:offset
                                                                                     size:KTVHCDataNetworkSourceSizeMaxVaule];
            [networkSources addObject:source];
            size = 0;
        }
        else
        {
            KTVHCDataNetworkSource * source = [KTVHCDataNetworkSource sourceWithURLString:self.request.URLString
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
    
    [self.sourcer sortSources];
}

- (void)prepare
{
    [self.delegate reaaderPrepareDidSuccess:self];
}

- (void)start
{
    [self.sourcer start];
}


@end
