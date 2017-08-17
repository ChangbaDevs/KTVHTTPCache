//
//  KTVHCDataSourceQueue.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataSourceQueue.h"
#import "KTVHCDataFileSource.h"
#import "KTVHCDataNetworkSource.h"
#import "KTVHCLog.h"


@interface KTVHCDataSourceQueue ()


@property (nonatomic, strong) NSMutableArray <id<KTVHCDataSourceProtocol>> * totalSources;


@end


@implementation KTVHCDataSourceQueue


+ (instancetype)sourceQueue
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        self.totalSources = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}

- (void)putSource:(id<KTVHCDataSourceProtocol>)source
{
    if (!source) {
        return;
    }
    
    if (![self.totalSources containsObject:source])
    {
        [self.totalSources addObject:source];
    }
}

- (void)popSource:(id<KTVHCDataSourceProtocol>)source
{
    if (!source) {
        return;
    }
    
    if ([self.totalSources containsObject:source])
    {
        [self.totalSources removeObject:source];
    }
}

- (void)setAllSourceDelegate:(id <KTVHCDataFileSourceDelegate, KTVHCDataNetworkSourceDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    KTVHCLogDataSourceQueue(@"set all sources delegate, %@", delegate);
    
    for (id <KTVHCDataSourceProtocol> obj in self.totalSources)
    {
        if ([obj isKindOfClass:[KTVHCDataFileSource class]])
        {
            KTVHCDataFileSource * source = (KTVHCDataFileSource *)obj;
            [source setDelegate:delegate delegateQueue:delegateQueue];
        }
        else if ([obj isKindOfClass:[KTVHCDataNetworkSource class]])
        {
            KTVHCDataNetworkSource * source = (KTVHCDataNetworkSource *)obj;
            [source setDelegate:delegate delegateQueue:delegateQueue];
        }
    }
}

- (void)sortSources
{
    KTVHCLogDataSourceQueue(@"sort sources");
    
    [self.totalSources sortUsingComparator:^NSComparisonResult(id <KTVHCDataSourceProtocol> obj1, id <KTVHCDataSourceProtocol> obj2) {
        if (obj1.offset < obj2.offset) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
}

- (void)closeAllSource
{
    KTVHCLogDataSourceQueue(@"close all sources");
    
    for (id <KTVHCDataSourceProtocol> obj in self.totalSources)
    {
        [obj close];
    }
}

- (id<KTVHCDataSourceProtocol>)fetchFirstSource
{
    return self.totalSources.firstObject;
}

- (id<KTVHCDataSourceProtocol>)fetchNextSource:(id<KTVHCDataSourceProtocol>)currentSource
{
    if ([self.totalSources containsObject:currentSource])
    {
        NSUInteger index = [self.totalSources indexOfObject:currentSource] + 1;
        if (index < self.totalSources.count)
        {
            KTVHCLogDataSourceQueue(@"fetch next source");
            
            return [self.totalSources objectAtIndex:index];
        }
    }
    
    KTVHCLogDataSourceQueue(@"fetch netxt source none");
    
    return nil;
}

- (KTVHCDataNetworkSource *)fetchFirstNetworkSource
{
    for (id<KTVHCDataSourceProtocol> obj in self.totalSources)
    {
        if ([obj isKindOfClass:[KTVHCDataNetworkSource class]]) {
            return obj;
        }
    }
    return nil;
}

- (KTVHCDataNetworkSource *)fetchNextNetworkSource:(KTVHCDataNetworkSource *)currentSource
{
    if ([self.totalSources containsObject:currentSource])
    {
        NSUInteger index = [self.totalSources indexOfObject:currentSource] + 1;
        for (; index < self.totalSources.count; index++)
        {
            id <KTVHCDataSourceProtocol> obj = [self.totalSources objectAtIndex:index];
            if ([obj isKindOfClass:[KTVHCDataNetworkSource class]]) {
                
                KTVHCLogDataSourceQueue(@"fetch next network source : %@", obj);
                
                return obj;
            }
        }
    }
    return nil;
}


@end
