//
//  KTVHCDataFileSource.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataFileSource.h"
#import "KTVHCDataCallback.h"
#import "KTVHCLog.h"

@interface KTVHCDataFileSource () <NSLocking>

@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) NSFileHandle * readingHandle;
@property (nonatomic, assign) long long readedLength;

@end

@implementation KTVHCDataFileSource

- (instancetype)initWithPath:(NSString *)path offset:(long long)offset length:(long long)length readOffset:(long long)readOffset readLength:(long long)readLength
{
    if (self = [super init])
    {
        _path = path;
        _offset = offset;
        _length = length;
        _readOffset = readOffset;
        _readLength = readLength;
        KTVHCLogAlloc(self);
        KTVHCLogDataFileSource(@"did setup, %lld, %lld, %lld, %lld", self.offset, self.length, self.readOffset, self.readLength);
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}

- (void)prepare
{
    if (self.didPrepared) {
        return;
    }
    [self lock];
    _didPrepared = YES;
    KTVHCLogDataFileSource(@"call prepare");
    self.readingHandle = [NSFileHandle fileHandleForReadingAtPath:self.path];
    @try {
        [self.readingHandle seekToFileOffset:self.readOffset];
    } @catch (NSException *exception) {
        KTVHCLogDataSourcer(@"seek file exception, %@, %@, %@, %lld, %lld, %lld, %lld",
                            exception.name,
                            exception.reason,
                            exception.userInfo,
                            self.length,
                            self.offset,
                            self.readOffset,
                            self.readLength);
    }
    [self unlock];
    if ([self.delegate respondsToSelector:@selector(sourceDidPrepared:)])
    {
        [KTVHCDataCallback callbackWithQueue:self.delegateQueue block:^{
            [self.delegate sourceDidPrepared:self];
        }];
    }
}

- (void)close
{
    if (self.didClosed) {
        return;
    }
    [self lock];
    _didClosed = YES;
    KTVHCLogDataFileSource(@"call close");
    [self.readingHandle closeFile];
    self.readingHandle = nil;
    [self unlock];
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
    if (self.didClosed) {
        return nil;
    }
    if (self.didFinished) {
        return nil;
    }
    [self lock];
    length = (NSUInteger)MIN(self.readLength - self.readedLength, length);
    NSData * data = [self.readingHandle readDataOfLength:length];
    self.readedLength += data.length;
    KTVHCLogDataFileSource(@"read data : %lld, %lld, %lld", (long long)data.length, self.readedLength, self.readLength);
    if (self.readedLength >= self.readLength)
    {
        KTVHCLogDataFileSource(@"read data finished");
        [self.readingHandle closeFile];
        self.readingHandle = nil;
        _didFinished = YES;
    }
    [self unlock];
    return data;
}

- (void)setDelegate:(id <KTVHCDataSourceDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    _delegate = delegate;
    _delegateQueue = delegateQueue;
}

- (void)lock
{
    if (!self.coreLock) {
        self.coreLock = [[NSLock alloc] init];
    }
    [self.coreLock lock];
}

- (void)unlock
{
    [self.coreLock unlock];
}

@end
