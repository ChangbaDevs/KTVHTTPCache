//
//  KTVHCDataSourcer.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataSourcer.h"
#import "KTVHCDataSourceQueue.h"

@interface KTVHCDataSourcer ()


#pragma mark - Setter

@property (nonatomic, weak) id <KTVHCDataSourcerDelegate> delegate;

@property (nonatomic, strong) NSError * error;

@property (nonatomic, assign) BOOL didClose;
@property (nonatomic, assign) BOOL didFinishClose;
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
    [self callbackForFinishClose];
}

- (NSData *)syncReadDataOfLength:(NSUInteger)length
{
    if (self.didClose) {
        return nil;
    }
    if (self.didFinishRead) {
        return nil;
    }
    
    NSData * data = [self.currentSource syncReadDataOfLength:length];
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
        [self.delegate sourcerDidFinishPrepare:self];
    }
}

- (void)callbackForFinishClose
{
    if (self.didFinishClose) {
        return;
    }
    
    self.didFinishClose = YES;
    if ([self.delegate respondsToSelector:@selector(sourcerDidFinishClose:)]) {
        [self.delegate sourcerDidFinishClose:self];
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

- (void)fileSourceDidFinishPrepare:(KTVHCDataFileSource *)fileSource
{
    [self callbackForFinishPrepare];
}


#pragma mark - KTVHCDataNetworkSourceDelegate

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

- (void)networkSourceDidFinishClose:(KTVHCDataNetworkSource *)networkSource
{
    if (self.sourceQueue.didAllFinishClose) {
        [self callbackForFinishClose];
    }
}


@end
