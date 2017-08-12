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

@interface KTVHCDataSourcer ()


#pragma mark - Setter

@property (nonatomic, weak) id <KTVHCDataSourcerDelegate> delegate;

@property (nonatomic, strong) NSError * error;

@property (nonatomic, assign) BOOL didClose;
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
}

- (void)prepare
{
    if (self.didClose) {
        return;
    }
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
        [KTVHCDataCallback callbackWithBlock:^{
            [self.delegate sourcerDidFinishPrepare:self];
        }];
    }
}

- (void)callbackForFailure:(NSError *)error
{
    self.error = error;
    if (self.error && [self.delegate respondsToSelector:@selector(sourcer:didFailure:)]) {
        [KTVHCDataCallback callbackWithBlock:^{
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
        [KTVHCDataCallback callbackWithBlock:^{
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
