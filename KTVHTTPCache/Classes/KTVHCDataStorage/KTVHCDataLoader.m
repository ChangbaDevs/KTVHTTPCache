//
//  KTVHCDataLoader.m
//  KTVHTTPCache
//
//  Created by Single on 2018/6/7.
//  Copyright © 2018 Single. All rights reserved.
//

#import "KTVHCDataLoader.h"
#import "KTVHCDataReader.h"
#import "KTVHCDataResponse.h"
#import "KTVHCLog.h"

@interface KTVHCDataLoader () <KTVHCDataReaderDelegate>

@property (nonatomic, strong) KTVHCDataReader * reader;

@end

@implementation KTVHCDataLoader

+ (instancetype)loaderWithRequest:(KTVHCDataRequest *)request
{
    return [[self alloc] initWithRequest:request];
}

- (instancetype)initWithRequest:(KTVHCDataRequest *)request
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        self.reader = [KTVHCDataReader readerWithRequest:request];
        self.reader.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
    [self close];
}

- (void)prepare
{
    [self.reader prepare];
}

- (void)close
{
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

- (BOOL)didClosed
{
    return self.reader.didClosed;
}

- (BOOL)didFinished
{
    return self.reader.didFinished;
}

#pragma mark - KTVHCDataReaderDelegate

- (void)readerDidPrepared:(KTVHCDataReader *)reader
{
    [self readData];
}

- (void)readerHasAvailableData:(KTVHCDataReader *)reader
{
    [self readData];
}

- (void)reader:(KTVHCDataReader *)reader didFailed:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(loader:didFailed:)])
    {
        [self.delegate loader:self didFailed:error];
    }
}

- (void)readData
{
    while (YES)
    {
        @autoreleasepool
        {
            NSData * data = [self.reader readDataOfLength:1024 * 1024 * 1];
            if (self.reader.didFinished)
            {
                _progress = 1.0f;
                if ([self.delegate respondsToSelector:@selector(loaderDidFinished:)])
                {
                    [self.delegate loaderDidFinished:self];
                }
            }
            else if (data)
            {
                _progress = (double)self.reader.readOffset / (double)self.response.currentLength;
                continue;
            }
            break;
        }
    }
}

@end
