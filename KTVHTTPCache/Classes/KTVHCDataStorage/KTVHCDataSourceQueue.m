//
//  KTVHCDataSourceQueue.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataSourceQueue.h"

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
        self.totalSources = [NSMutableArray array];
    }
    return self;
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

- (void)sortSources
{
    [self.totalSources sortUsingComparator:^NSComparisonResult(id <KTVHCDataSourceProtocol> obj1, id <KTVHCDataSourceProtocol> obj2) {
        if (obj1.offset < obj2.offset) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
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
            return [self.totalSources objectAtIndex:index];
        }
    }
    return nil;
}

@end
