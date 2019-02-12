//
//  KTVHCDataLoader.m
//  KTVHTTPCache
//
//  Created by Single on 2018/6/7.
//  Copyright © 2018 Single. All rights reserved.
//

#import "KTVHCDataLoader.h"
#import "KTVHCData+Internal.h"
#import "KTVHCLog.h"

@interface KTVHCDataLoader () <KTVHCDataReaderDelegate>

@property (nonatomic, strong) KTVHCDataReader *reader;

@end

@implementation KTVHCDataLoader

- (instancetype)initWithRequest:(KTVHCDataRequest *)request
{
    if (self = [super init]) {
        KTVHCLogAlloc(self);
        self.reader = [[KTVHCDataReader alloc] initWithRequest:request];
        self.reader.delegate = self;
        KTVHCLogDataLoader(@"%p, Create loader\norignalRequest : %@\nreader : %@", self, request, self.reader);
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
    [self close];
    KTVHCLogDataLoader(@"%p, Destory reader\nError : %@\nprogress : %f", self, self.error, self.progress);
}

- (void)prepare
{
    KTVHCLogDataLoader(@"%p, Call prepare", self);
    [self.reader prepare];
}

- (void)close
{
    KTVHCLogDataLoader(@"%p, Call close", self);
    [self.reader close];
}

- (KTVHCDataRequest *)request
{
    return self.reader.request;
}

- (KTVHCDataResponse *)response
{
    return self.reader.response;
}

- (NSError *)error
{
    return self.reader.error;
}

- (BOOL)isFinished
{
    return self.reader.isFinished;
}

- (BOOL)isClosed
{
    return self.reader.isClosed;
}

#pragma mark - KTVHCDataReaderDelegate

- (void)readerDidPrepare:(KTVHCDataReader *)reader
{
    [self readData];
}

- (void)readerHasAvailableData:(KTVHCDataReader *)reader
{
    [self readData];
}

- (void)reader:(KTVHCDataReader *)reader didFailWithError:(NSError *)error
{
    KTVHCLogDataLoader(@"%p, Callback for failed", self);
    if ([self.delegate respondsToSelector:@selector(dataLoader:didFailWithError:)]) {
        [self.delegate dataLoader:self didFailWithError:error];
    }
}

- (void)readData
{
    while (YES) {
        @autoreleasepool {
            NSData *data = [self.reader readDataOfLength:1024 * 1024 * 1];
            if (self.reader.isFinished) {
                self->_loadedLength = self.reader.readedLength;
                self->_progress = 1.0f;
                if ([self.delegate respondsToSelector:@selector(dataLoader:didChangeProgress:)]) {
                    [self.delegate dataLoader:self didChangeProgress:self.progress];
                }
                KTVHCLogDataLoader(@"%p, Callback finished", self);
                if ([self.delegate respondsToSelector:@selector(dataLoaderDidFinish:)]) {
                    [self.delegate dataLoaderDidFinish:self];
                }
            } else if (data) {
                self->_loadedLength = self.reader.readedLength;
                if (self.response.contentLength > 0) {
                    self->_progress = (double)self.reader.readedLength / (double)self.response.contentLength;
                }
                if ([self.delegate respondsToSelector:@selector(dataLoader:didChangeProgress:)]) {
                    [self.delegate dataLoader:self didChangeProgress:self.progress];
                }
                KTVHCLogDataLoader(@"%p, read data progress %f", self, self.progress);
                continue;
            }
            KTVHCLogDataLoader(@"%p, read data break", self);
            break;
        }
    }
}

@end
