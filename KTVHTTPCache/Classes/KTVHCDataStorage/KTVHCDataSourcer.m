//
//  KTVHCDataSourcer.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataSourcer.h"
#import "KTVHCDataFileSource.h"
#import "KTVHCDataNetworkSource.h"

@interface KTVHCDataSourcer ()

@property (nonatomic, strong) NSMutableArray <id<KTVHCDataSourceProtocol>> * sources;

@end

@implementation KTVHCDataSourcer

+ (instancetype)sourcer
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.sources = [NSMutableArray array];
    }
    return self;
}

- (void)putSource:(id<KTVHCDataSourceProtocol>)source
{
    if (!source) {
        return;
    }
    
    if (![self.sources containsObject:source])
    {
        [self.sources addObject:source];
    }
}

- (void)popSource:(id<KTVHCDataSourceProtocol>)source
{
    if (!source) {
        return;
    }
    
    if ([self.sources containsObject:source])
    {
        [self.sources removeObject:source];
    }
}

- (void)start
{
    
}

- (void)stop
{
    
}

@end
