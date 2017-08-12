//
//  KTVHCDataSourcer.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataSourcer.h"
#import "KTVHCDataSourceQueue.h"

@interface KTVHCDataSourcer () <KTVHCDataNetworkSourceDelegate>


#pragma mark - Setter

@property (nonatomic, weak) id <KTVHCDataSourcerDelegate> delegate;

@property (nonatomic, strong) NSError * error;

@property (nonatomic, assign) BOOL didFinishPrepare;
@property (nonatomic, assign) BOOL didFinishRead;


#pragma mark - Sources

@property (nonatomic, strong) id <KTVHCDataSourceProtocol> currentSource;
@property (nonatomic, strong) KTVHCDataNetworkSource * currentNetworkSource;
@property (nonatomic, strong) KTVHCDataSourceQueue * sourceQueue;

@end

@implementation KTVHCDataSourcer

+ (instancetype)sourcerWithDelegate:(id <KTVHCDataSourcerDelegate>)delegate
{
    return [[self alloc] initWithDelegate:delegate];
}

- (instancetype)initWithDelegate:(id <KTVHCDataSourcerDelegate>)delegate
{
    if (self = [super init])
    {
        self.delegate = delegate;
        self.sourceQueue = [KTVHCDataSourceQueue sourceQueue];
    }
    return self;
}

- (void)putSource:(id<KTVHCDataSourceProtocol>)source
{
    [self.sourceQueue putSource:source];
}

- (void)putSourceDidFinish
{
    [self.sourceQueue sortSources];
    self.currentSource = [self.sourceQueue fetchFirstSource];
    self.currentNetworkSource = [self.sourceQueue fetchFirstNetworkSource];
    self.currentNetworkSource.networkSourceDelegate = self;
}

- (void)prepare
{
    if (self.currentSource != self.currentNetworkSource) {
        [self callbackForFinishPrepare];
    } else {
        [self.currentNetworkSource prepareAndStart];
    }
}

- (NSData *)syncReadDataOfLength:(NSUInteger)length
{
    NSMutableData * data = [NSMutableData dataWithData:[self.currentSource syncReadDataOfLength:length]];
    if (self.currentSource.didFinishRead)
    {
        self.currentSource = [self.sourceQueue fetchNextSource:self.currentSource];
        if (self.currentSource)
        {
            if (data.length < length)
            {
                [data appendData:[self syncReadDataOfLength:length - data.length]];
            }
        }
        else
        {
            self.didFinishRead = YES;
        }
    }
    return data;
}


#pragma mark - Callback

- (void)callbackForFinishPrepare
{
    if (!self.didFinishPrepare) {
        self.didFinishPrepare = YES;
        if ([self.delegate respondsToSelector:@selector(sourcerDidFinishPrepare:)]) {
            [self.delegate sourcerDidFinishPrepare:self];
        }
    }
}

- (void)callbackForFailure:(NSError *)error
{
    self.error = error;
    if (self.error && [self.delegate respondsToSelector:@selector(sourcer:didFailure:)]) {
        [self.delegate sourcer:self didFailure:self.error];
    }
}


#pragma mark - KTVHCDataFileSourceDelegate


#pragma mark - KTVHCDataNetworkSourceDelegate

- (void)networkSourceDidFinishPrepare:(KTVHCDataNetworkSource *)networkSource
{
    [self callbackForFinishPrepare];
}

- (void)networkSourceDidFinishDownload:(KTVHCDataNetworkSource *)networkSource
{
    self.currentNetworkSource = [self.sourceQueue fetchNextNetworkSource:self.currentNetworkSource];
    [self.currentNetworkSource prepareAndStart];
}

- (void)networkSource:(KTVHCDataNetworkSource *)networkSource didFailure:(NSError *)error
{
    [self callbackForFailure:error];
}


@end
