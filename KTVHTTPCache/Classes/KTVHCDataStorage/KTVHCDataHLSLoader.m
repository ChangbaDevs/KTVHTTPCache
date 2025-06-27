//
//  KTVHCDataHLSLoader.m
//  KTVHTTPCache
//
//  Created by Single on 2025/6/27.
//  Copyright © 2025 Single. All rights reserved.
//

#import "KTVHCDataHLSLoader.h"
#import "KTVHCData+Internal.h"
#import "KTVHCDataUnitPool.h"
#import "KTVHCHLSTool.h"
#import "KTVHCLog.h"

@interface KTVHCDataHLSLoader () <KTVHCDataLoaderDelegate>

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) KTVHCDataUnit *unit;
@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic, strong) NSMutableArray<KTVHCDataLoader *> *waitingLoaders;
@property (nonatomic, strong) NSMutableArray<KTVHCDataLoader *> *runningLoaders;
@property (nonatomic, strong) NSMutableArray<KTVHCDataLoader *> *finishedLoaders;

@end

@implementation KTVHCDataHLSLoader

- (instancetype)initWithRequest:(KTVHCDataRequest *)request
{
    if (self = [super init]) {
        KTVHCLogAlloc(self);
        self->_request = request;
        self.waitingLoaders = [NSMutableArray array];
        self.runningLoaders = [NSMutableArray array];
        self.finishedLoaders = [NSMutableArray array];
        self.unit = [[KTVHCDataUnitPool pool] unitWithURL:self.request.URL];
        KTVHCLogDataHLSLoader(@"%p, Create loader\norignalRequest : %@", self, self.request);
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
    [self.unit workingRelease];
    [self close];
    KTVHCLogDataHLSLoader(@"%p, Destory reader\nError : %@\nprogress : %f", self, self.error, self.progress);
}

- (void)prepare
{
    KTVHCLogDataHLSLoader(@"%p, Call prepare", self);
    NSURL *completeURL = self.unit.completeURL;
    if (completeURL) {
        self.data = [NSData dataWithContentsOfURL:completeURL];
        [self setupLoaders];
    } else {
        __weak typeof(self) weakSelf = self;
        self.task = [[KTVHCHLSTool tool] taskWithURL:self.request.URL completionHandler:^(NSData *data, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf handleResponeWithData:data error:error];
        }];
        [self.task resume];
    }
}

- (void)close
{
    KTVHCLogDataHLSLoader(@"%p, Call close", self);
    self->_closed = YES;
    [self.task cancel];
    for (KTVHCDataLoader *obj in self.waitingLoaders) {
        [obj close];
    }
    for (KTVHCDataLoader *obj in self.runningLoaders) {
        [obj close];
    }
    for (KTVHCDataLoader *obj in self.finishedLoaders) {
        [obj close];
    }
}

- (void)handleResponeWithData:(NSData *)data error:(NSError *)error
{
    if (error || data.length == 0) {
        self->_error = error;
        [self close];
        if ([self.delegate respondsToSelector:@selector(ktv_HLSLoader:didFailWithError:)]) {
            [self.delegate ktv_HLSLoader:self didFailWithError:error];
        }
    } else {
        self.data = data;
        [self setupLoaders];
    }
}

- (void)setupLoaders
{
    NSString *content = [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
    NSArray<NSURL *> *URLs = nil;
    if ([self.delegate respondsToSelector:@selector(ktv_HLSLoader:makeURLsForContent:)]) {
        URLs = [self.delegate ktv_HLSLoader:self makeURLsForContent:content];
    } else {
        URLs = [[KTVHCHLSTool tool] makeURLsForContent:content sourceURL:self.request.URL];
    }
    KTVHCLogDataHLSLoader(@"%p, URLs %@", self, URLs);
    if ([self.delegate respondsToSelector:@selector(ktv_HLSLoader:makeLoadersForURLs:)]) {
        NSArray *loaders = [self.delegate ktv_HLSLoader:self makeLoadersForURLs:URLs];
        [self.waitingLoaders addObjectsFromArray:loaders];
    } else {
        for (NSURL* URL in URLs) {
            KTVHCDataRequest *request = [[KTVHCDataRequest alloc] initWithURL:URL headers:nil];
            KTVHCDataLoader *segmentLoader = [[KTVHCDataLoader alloc] initWithRequest:request];
            [self.waitingLoaders addObject:segmentLoader];
        }
    }
    KTVHCLogDataHLSLoader(@"%p, Waiting loaders %@", self, self.waitingLoaders);
    [self prepareNextLoader];
}

- (void)prepareNextLoader
{
    KTVHCLogDataHLSLoader(@"%p, Prepare next loader", self);
    KTVHCDataLoader *next = self.waitingLoaders.firstObject;
    if (!next) {
        KTVHCLogDataHLSLoader(@"%p, Callback for finished", self);
        self->_finished = true;
        if ([self.delegate respondsToSelector:@selector(ktv_HLSLoaderDidFinish:)]) {
            [self.delegate ktv_HLSLoaderDidFinish:self];
        }
        return;
    }
    [self.waitingLoaders removeObject:next];
    [self.runningLoaders addObject:next];
    next.delegate = self;
    [next prepare];
}

#pragma mark - KTVHCDataLoaderDelegate

- (void)ktv_loaderDidFinish:(KTVHCDataLoader *)loader
{
    [self.runningLoaders removeObject:loader];
    [self.finishedLoaders addObject:loader];
    [self prepareNextLoader];
}

- (void)ktv_loader:(KTVHCDataLoader *)loader didChangeProgress:(double)progress
{
    double count = self.waitingLoaders.count + self.runningLoaders.count + self.finishedLoaders.count;
    self->_progress = self.finishedLoaders.count / count + 1.0 / count * progress;
    if ([self.delegate respondsToSelector:@selector(ktv_HLSLoader:didChangeProgress:)]) {
        [self.delegate ktv_HLSLoader:self didChangeProgress:self.progress];
    }
}

- (void)ktv_loader:(KTVHCDataLoader *)loader didFailWithError:(NSError *)error
{
    KTVHCLogDataHLSLoader(@"%p, Callback for failed", self);
    self->_error = error;
    [self close];
    if ([self.delegate respondsToSelector:@selector(ktv_HLSLoader:didFailWithError:)]) {
        [self.delegate ktv_HLSLoader:self didFailWithError:error];
    }
}

@end
