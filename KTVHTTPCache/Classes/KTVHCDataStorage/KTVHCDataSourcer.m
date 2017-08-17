//
//  KTVHCDataSourcer.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataSourcer.h"
#import "KTVHCDataSourceQueue.h"
#import "KTVHCDataCallback.h"
#import "KTVHCLog.h"


@interface KTVHCDataSourcer () <KTVHCDataFileSourceDelegate, KTVHCDataNetworkSourceDelegate>


#pragma mark - Setter

@property (nonatomic, weak) id <KTVHCDataSourcerDelegate> delegate;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;

@property (nonatomic, strong) NSError * error;

@property (nonatomic, assign) BOOL didClose;
@property (nonatomic, assign) BOOL didCallPrepare;
@property (nonatomic, assign) BOOL didFinishPrepare;
@property (nonatomic, assign) BOOL didFinishRead;


#pragma mark - Sources

@property (nonatomic, strong) id <KTVHCDataSourceProtocol> currentSource;
@property (nonatomic, strong) KTVHCDataNetworkSource * currentNetworkSource;
@property (nonatomic, strong) KTVHCDataSourceQueue * sourceQueue;


@end


@implementation KTVHCDataSourcer


+ (instancetype)sourcerWithDelegate:(id <KTVHCDataSourcerDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    return [[self alloc] initWithDelegate:delegate delegateQueue:delegateQueue];
}

- (instancetype)initWithDelegate:(id <KTVHCDataSourcerDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        self.delegate = delegate;
        self.delegateQueue = delegateQueue;
        self.sourceQueue = [KTVHCDataSourceQueue sourceQueue];
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}


- (void)putSource:(id<KTVHCDataSourceProtocol>)source
{
    [self.sourceQueue putSource:source];
}

- (void)sortAndFetchSources
{
    [self.sourceQueue sortSources];
    [self.sourceQueue setAllSourceDelegate:self delegateQueue:self.delegateQueue];
    self.currentSource = [self.sourceQueue fetchFirstSource];
    self.currentNetworkSource = [self.sourceQueue fetchFirstNetworkSource];
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
    
    [self sortAndFetchSources];
    [self.currentSource prepare];
    if (self.currentSource != self.currentNetworkSource) {
        [self.currentNetworkSource prepare];
    }
}

- (void)close
{
    if (self.didClose) {
        return;
    }
    
    self.didClose = YES;
    [self.sourceQueue closeAllSource];
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
    if (self.didClose) {
        return nil;
    }
    if (self.didFinishRead) {
        return nil;
    }
    
    NSData * data = [self.currentSource readDataOfLength:length];
    if (self.currentSource.didFinishRead)
    {
        self.currentSource = [self.sourceQueue fetchNextSource:self.currentSource];
        if (self.currentSource)
        {
            if ([self.currentSource isKindOfClass:[KTVHCDataFileSource class]]) {
                [self.currentSource prepare];
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
    if (self.didFinishPrepare) {
        return;
    }
    
    self.didFinishPrepare = YES;
    if ([self.delegate respondsToSelector:@selector(sourcerDidFinishPrepare:)]) {
        [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
            [self.delegate sourcerDidFinishPrepare:self];
        }];
    }
}

- (void)callbackForFailure:(NSError *)error
{
    self.error = error;
    if (self.error && [self.delegate respondsToSelector:@selector(sourcer:didFailure:)]) {
        [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
            [self.delegate sourcer:self didFailure:self.error];
        }];
    }
}


#pragma mark - KTVHCDataFileSourceDelegate

- (void)fileSourceDidFinishPrepare:(KTVHCDataFileSource *)fileSource
{
    [self callbackForFinishPrepare];
}


#pragma mark - KTVHCDataNetworkSourceDelegate

- (void)networkSourceHasAvailableData:(KTVHCDataNetworkSource *)networkSource
{
    if ([self.delegate respondsToSelector:@selector(sourcerHasAvailableData:)]) {
        [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
            [self.delegate sourcerHasAvailableData:self];
        }];
    }
}

- (void)networkSourceDidFinishPrepare:(KTVHCDataNetworkSource *)networkSource
{
    [self callbackForFinishPrepare];
}

- (void)networkSourceDidFinishDownload:(KTVHCDataNetworkSource *)networkSource
{
    self.currentNetworkSource = [self.sourceQueue fetchNextNetworkSource:self.currentNetworkSource];
    [self.currentNetworkSource prepare];
}

- (void)networkSource:(KTVHCDataNetworkSource *)networkSource didFailure:(NSError *)error
{
    [self callbackForFailure:error];
}


@end
