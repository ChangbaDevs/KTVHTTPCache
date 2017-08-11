//
//  KTVHCDataSourcer.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataSourcer.h"
#import "KTVHCDataSourceQueue.h"

@interface KTVHCDataSourcer () <KTVHCDataSourceDelegate>

@property (nonatomic, strong) id <KTVHCDataSourceProtocol> currentSource;
@property (nonatomic, strong) KTVHCDataSourceQueue * sourceQueue;

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
        self.sourceQueue = [KTVHCDataSourceQueue sourceQueue];
    }
    return self;
}

- (void)putSource:(id<KTVHCDataSourceProtocol>)source
{
    [self.sourceQueue putSource:source];
}

- (void)sortSources
{
    [self.sourceQueue sortSources];
}

- (void)start
{
    self.currentSource = [self.sourceQueue fetchFirstSource];
    self.currentSource.delegate = self;
}

- (void)stop
{
    
}


#pragma mark - KTVHCDataSourceDelegate

- (void)sourceDidFinishRead:(id<KTVHCDataSourceProtocol>)source
{
    self.currentSource = [self.sourceQueue fetchNextSource:self.currentSource];
    self.currentSource.delegate = self;
}

@end
