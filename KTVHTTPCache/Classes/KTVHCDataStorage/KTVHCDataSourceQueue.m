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

@property (nonatomic, strong) NSMutableArray <id<KTVHCDataSourceProtocol>> * sources;

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
        self.sources = [NSMutableArray array];
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
    } {
        [self.sources addObject:source];
    }
}

- (void)popSource:(id<KTVHCDataSourceProtocol>)source
{
    if (!source) {
        return;
    }
    if ([self.sources containsObject:source]) {
        [self.sources removeObject:source];
    }
}

- (void)setAllSourceDelegate:(id<KTVHCDataFileSourceDelegate, KTVHCDataNetworkSourceDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    KTVHCLogDataSourceQueue(@"set all sources delegate, %@", delegate);
    for (id <KTVHCDataSourceProtocol> obj in self.sources) {
        if ([obj isKindOfClass:[KTVHCDataFileSource class]]) {
            KTVHCDataFileSource * source = (KTVHCDataFileSource *)obj;
            [source setDelegate:delegate delegateQueue:delegateQueue];
        } else if ([obj isKindOfClass:[KTVHCDataNetworkSource class]]) {
            KTVHCDataNetworkSource * source = (KTVHCDataNetworkSource *)obj;
            [source setDelegate:delegate delegateQueue:delegateQueue];
        }
    }
}

- (void)sortSources
{
    KTVHCLogDataSourceQueue(@"sort sources");
    [self.sources sortUsingComparator:^NSComparisonResult(id <KTVHCDataSourceProtocol> obj1, id <KTVHCDataSourceProtocol> obj2) {
        if (obj1.range.start < obj2.range.start) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
}

- (void)closeAllSource
{
    KTVHCLogDataSourceQueue(@"close all sources");
    for (id <KTVHCDataSourceProtocol> obj in self.sources) {
        [obj close];
    }
}

- (id<KTVHCDataSourceProtocol>)fetchFirstSource
{
    return self.sources.firstObject;
}

- (id<KTVHCDataSourceProtocol>)fetchNextSource:(id<KTVHCDataSourceProtocol>)currentSource
{
    if ([self.sources containsObject:currentSource]) {
        NSUInteger index = [self.sources indexOfObject:currentSource] + 1;
        if (index < self.sources.count) {
            KTVHCLogDataSourceQueue(@"fetch next source");
            return [self.sources objectAtIndex:index];
        }
    }
    KTVHCLogDataSourceQueue(@"fetch netxt source none");
    return nil;
}

- (KTVHCDataNetworkSource *)fetchFirstNetworkSource
{
    for (id<KTVHCDataSourceProtocol> obj in self.sources) {
        if ([obj isKindOfClass:[KTVHCDataNetworkSource class]]) {
            return obj;
        }
    }
    return nil;
}

- (KTVHCDataNetworkSource *)fetchNextNetworkSource:(KTVHCDataNetworkSource *)currentSource
{
    if ([self.sources containsObject:currentSource]) {
        NSUInteger index = [self.sources indexOfObject:currentSource] + 1;
        for (; index < self.sources.count; index++) {
            id <KTVHCDataSourceProtocol> obj = [self.sources objectAtIndex:index];
            if ([obj isKindOfClass:[KTVHCDataNetworkSource class]]) {
                KTVHCLogDataSourceQueue(@"fetch next network source : %@", obj);
                return obj;
            }
        }
    }
    return nil;
}

@end
